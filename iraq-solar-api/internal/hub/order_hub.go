package hub

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// Time allowed to write a message to the peer.
	writeWait = 10 * time.Second

	// Time allowed to read the next pong message from the peer.
	pongWait = 60 * time.Second

	// Send pings to peer with this period. Must be less than pongWait.
	pingPeriod = (pongWait * 9) / 10

	// Maximum message size allowed from peer.
	maxMessageSize = 512
)

// WSMessageType defines the types of WebSocket messages for the orders system.
type WSMessageType string

const (
	MsgOrderNew           WSMessageType = "order.new"
	MsgOrderStatusChanged WSMessageType = "order.status_changed"
	MsgOrderCancelled     WSMessageType = "order.cancelled"
	MsgPing               WSMessageType = "ping"
	MsgPong               WSMessageType = "pong"
)

// WSMessage is the envelope sent over WebSocket.
type WSMessage struct {
	Type      WSMessageType `json:"type"`
	Payload   any           `json:"payload"`
	Timestamp time.Time     `json:"timestamp"`
}

// Client represents a single WebSocket connection.
type Client struct {
	Hub        *OrderHub
	Conn       *websocket.Conn
	Send       chan []byte
	UserID     string
	Role       string
	MerchantID string // populated when role == "merchant"
}

// OrderHub manages all active WebSocket clients and broadcasts.
type OrderHub struct {
	// Registered clients
	clients map[*Client]bool

	// Inbound messages from clients (e.g. pings)
	inbound chan []byte

	// Register requests from clients
	Register chan *Client

	// Unregister requests from clients
	Unregister chan *Client

	// Outbound broadcast messages
	broadcast chan broadcastEnvelope

	mu sync.RWMutex
}

type broadcastEnvelope struct {
	msg        WSMessage
	targetRole string // "" = everyone, "admin" = admins only, merchantID = specific merchant
}

// NewOrderHub creates a new hub instance.
func NewOrderHub() *OrderHub {
	return &OrderHub{
		clients:    make(map[*Client]bool),
		inbound:    make(chan []byte, 256),
		Register:   make(chan *Client, 64),
		Unregister: make(chan *Client, 64),
		broadcast:  make(chan broadcastEnvelope, 256),
	}
}

// Run starts the hub's main event loop. Call as a goroutine.
func (h *OrderHub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			log.Printf("[OrderHub] client connected: userID=%s role=%s", client.UserID, client.Role)

		case client := <-h.Unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.Send)
			}
			h.mu.Unlock()
			log.Printf("[OrderHub] client disconnected: userID=%s", client.UserID)

		case envelope := <-h.broadcast:
			data, err := json.Marshal(envelope.msg)
			if err != nil {
				log.Printf("[OrderHub] marshal error: %v", err)
				continue
			}

			h.mu.RLock()
			for client := range h.clients {
				if !h.shouldSend(client, envelope) {
					continue
				}
				select {
				case client.Send <- data:
				default:
					// Slow client — drop and unregister
					go func(c *Client) { h.Unregister <- c }(client)
				}
			}
			h.mu.RUnlock()
		}
	}
}

// shouldSend decides whether a message should be sent to a specific client.
func (h *OrderHub) shouldSend(client *Client, env broadcastEnvelope) bool {
	switch env.targetRole {
	case "admin":
		return client.Role == "admin"
	case "":
		return true // broadcast to all
	default:
		// merchantID-targeted
		return client.MerchantID == env.targetRole
	}
}

// BroadcastToAdmins sends a message to all connected admin clients.
func (h *OrderHub) BroadcastToAdmins(msgType WSMessageType, payload any) {
	h.broadcast <- broadcastEnvelope{
		msg: WSMessage{
			Type:      msgType,
			Payload:   payload,
			Timestamp: time.Now(),
		},
		targetRole: "admin",
	}
}

// BroadcastToMerchant sends a message to a specific merchant's connected clients.
func (h *OrderHub) BroadcastToMerchant(merchantID string, msgType WSMessageType, payload any) {
	h.broadcast <- broadcastEnvelope{
		msg: WSMessage{
			Type:      msgType,
			Payload:   payload,
			Timestamp: time.Now(),
		},
		targetRole: merchantID,
	}
}

// BroadcastToAll sends a message to all connected clients.
func (h *OrderHub) BroadcastToAll(msgType WSMessageType, payload any) {
	h.broadcast <- broadcastEnvelope{
		msg: WSMessage{
			Type:      msgType,
			Payload:   payload,
			Timestamp: time.Now(),
		},
		targetRole: "",
	}
}

// ConnectedAdmins returns the count of connected admin clients.
func (h *OrderHub) ConnectedAdmins() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	count := 0
	for c := range h.clients {
		if c.Role == "admin" {
			count++
		}
	}
	return count
}

// --- Client Pump Methods ---

// ReadPump pumps messages from the WebSocket connection to the hub.
// Run as a goroutine per client.
func (c *Client) ReadPump() {
	defer func() {
		c.Hub.Unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadLimit(maxMessageSize)
	_ = c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error {
		return c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("[OrderHub] read error: %v", err)
			}
			break
		}
		// Handle ping from client
		var msg WSMessage
		if jsonErr := json.Unmarshal(message, &msg); jsonErr == nil && msg.Type == MsgPing {
			pong, _ := json.Marshal(WSMessage{Type: MsgPong, Timestamp: time.Now()})
			select {
			case c.Send <- pong:
			default:
			}
		}
	}
}

// WritePump pumps messages from the hub to the WebSocket connection.
// Run as a goroutine per client.
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				// Hub closed the channel
				_ = c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				return
			}

		case <-ticker.C:
			_ = c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
