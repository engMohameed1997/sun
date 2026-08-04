package handler

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	"github.com/iraq-solar/api/internal/hub"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// In production, restrict to your domain
		return true
	},
}

// WebSocketHandler manages WebSocket connections for the orders system.
type WebSocketHandler struct {
	orderHub *hub.OrderHub
}

func NewWebSocketHandler(orderHub *hub.OrderHub) *WebSocketHandler {
	return &WebSocketHandler{orderHub: orderHub}
}

// HandleAdminOrders upgrades the connection and registers the client in the OrderHub.
// Requires authentication middleware to set user_id and user_role in context.
//
// Route: GET /ws/orders
func (h *WebSocketHandler) HandleAdminOrders(c *gin.Context) {
	// Extract identity from JWT middleware
	userIDVal, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "غير مصرح"})
		return
	}

	var userID string
	switch v := userIDVal.(type) {
	case uuid.UUID:
		userID = v.String()
	case string:
		userID = v
	default:
		c.JSON(http.StatusUnauthorized, gin.H{"error": "معرف المستخدم غير صالح"})
		return
	}

	role := c.GetString("user_role")
	if role == "" {
		role = "admin" // default fallback — middleware should always set this
	}

	merchantID := c.GetString("merchant_id") // set by middleware for merchant role

	// Upgrade HTTP → WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("[WebSocketHandler] upgrade failed: %v", err)
		return
	}

	client := &hub.Client{
		Hub:        h.orderHub,
		Conn:       conn,
		Send:       make(chan []byte, 256),
		UserID:     userID,
		Role:       role,
		MerchantID: merchantID,
	}

	// Register client in the hub
	h.orderHub.Register <- client

	// Start goroutines for this client
	go client.WritePump()
	go client.ReadPump()
}
