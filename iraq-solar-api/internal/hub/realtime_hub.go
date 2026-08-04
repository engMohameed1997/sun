package hub

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
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
	maxMessageSize = 8192
)

// --- Message Protocol ---

// WSMessageType defines the high-level category of a WebSocket message.
type WSMessageType string

const (
	MsgOrder  WSMessageType = "order"
	MsgNotif  WSMessageType = "notification"
	MsgSystem WSMessageType = "system"
)

// Event constants — specific events within each message type.
const (
	EventOrderCreated        = "order.created"
	EventOrderStatusChanged  = "order.status_changed"
	EventOrderCancelled      = "order.cancelled"
	EventNotificationCreated = "notification.created"
)

// WSMessage is the envelope sent over WebSocket.
type WSMessage struct {
	Version   int           `json:"version"`
	ID        uuid.UUID     `json:"id"`
	Type      WSMessageType `json:"type"`
	Event     string        `json:"event"`
	Payload   any           `json:"payload"`
	Timestamp time.Time     `json:"timestamp"`
}

// --- Targeting ---

// TargetType defines how a broadcast should be routed.
type TargetType int

const (
	TargetAll          TargetType = iota // Everyone connected
	TargetAdmin                         // Admin role only
	TargetUser                          // Specific user by ID
	TargetMerchant                      // Specific merchant by ID
	TargetAllCustomers                  // All customers
	TargetRole                          // Any specific role
)

// Target specifies the intended recipients of a broadcast.
type Target struct {
	Type       TargetType
	UserID     string // for TargetUser
	MerchantID string // for TargetMerchant
	Role       string // for TargetRole
}

// --- Client ---

// Client represents a single WebSocket connection.
type Client struct {
	Hub        *RealtimeHub
	Conn       *websocket.Conn
	Send       chan []byte
	UserID     string
	Role       string
	MerchantID string // populated when role == "merchant"
}

// --- Hub ---

// RealtimeHub manages all active WebSocket clients and broadcasts.
type RealtimeHub struct {
	// Registered clients
	clients map[*Client]bool

	// Inbound messages from clients
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
	msg    WSMessage
	target Target
}

// NewRealtimeHub creates a new hub instance.
func NewRealtimeHub() *RealtimeHub {
	return &RealtimeHub{
		clients:    make(map[*Client]bool),
		inbound:    make(chan []byte, 256),
		Register:   make(chan *Client, 64),
		Unregister: make(chan *Client, 64),
		broadcast:  make(chan broadcastEnvelope, 256),
	}
}

// Run starts the hub's main event loop. Call as a goroutine.
func (h *RealtimeHub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			log.Printf("[RealtimeHub] client connected: userID=%s role=%s", client.UserID, client.Role)

		case client := <-h.Unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.Send)
			}
			h.mu.Unlock()
			log.Printf("[RealtimeHub] client disconnected: userID=%s", client.UserID)

		case envelope := <-h.broadcast:
			data, err := json.Marshal(envelope.msg)
			if err != nil {
				log.Printf("[RealtimeHub] marshal error: %v", err)
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
func (h *RealtimeHub) shouldSend(client *Client, env broadcastEnvelope) bool {
	switch env.target.Type {
	case TargetAll:
		return true
	case TargetAdmin:
		return client.Role == "admin"
	case TargetUser:
		return client.UserID == env.target.UserID
	case TargetMerchant:
		return client.MerchantID == env.target.MerchantID
	case TargetAllCustomers:
		return client.Role == "customer"
	case TargetRole:
		return client.Role == env.target.Role
	default:
		return false
	}
}

// --- Core Broadcast ---

// Broadcast sends a message to clients matching the given target.
func (h *RealtimeHub) Broadcast(target Target, msgType WSMessageType, event string, payload any) {
	h.broadcast <- broadcastEnvelope{
		msg: WSMessage{
			Version:   1,
			ID:        uuid.New(),
			Type:      msgType,
			Event:     event,
			Payload:   payload,
			Timestamp: time.Now(),
		},
		target: target,
	}
}

// --- Convenience Wrappers ---

// BroadcastToAdmins sends a message to all connected admin clients.
func (h *RealtimeHub) BroadcastToAdmins(msgType WSMessageType, event string, payload any) {
	h.Broadcast(Target{Type: TargetAdmin}, msgType, event, payload)
}

// BroadcastToUser sends a message to all devices of a specific user.
func (h *RealtimeHub) BroadcastToUser(userID string, msgType WSMessageType, event string, payload any) {
	h.Broadcast(Target{Type: TargetUser, UserID: userID}, msgType, event, payload)
}

// BroadcastToMerchant sends a message to a specific merchant's connected clients.
func (h *RealtimeHub) BroadcastToMerchant(merchantID string, msgType WSMessageType, event string, payload any) {
	h.Broadcast(Target{Type: TargetMerchant, MerchantID: merchantID}, msgType, event, payload)
}

// BroadcastToAllCustomers sends a message to all connected customer clients.
func (h *RealtimeHub) BroadcastToAllCustomers(msgType WSMessageType, event string, payload any) {
	h.Broadcast(Target{Type: TargetAllCustomers}, msgType, event, payload)
}

// BroadcastToAll sends a message to all connected clients.
func (h *RealtimeHub) BroadcastToAll(msgType WSMessageType, event string, payload any) {
	h.Broadcast(Target{Type: TargetAll}, msgType, event, payload)
}

// ConnectedAdmins returns the count of connected admin clients.
func (h *RealtimeHub) ConnectedAdmins() int {
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
		_, _, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("[RealtimeHub] read error: %v", err)
			}
			break
		}
		// Client messages are currently ignored — heartbeat handled by gorilla Ping/Pong
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
