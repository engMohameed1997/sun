package handler

import (
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/hub"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Read allowed origins from environment
		allowedOriginsStr := os.Getenv("WS_ALLOWED_ORIGINS")
		if allowedOriginsStr == "" {
			// Development mode: allow all
			return true
		}

		origin := r.Header.Get("Origin")
		if origin == "" {
			return true
		}

		allowedOrigins := strings.Split(allowedOriginsStr, ",")
		for _, allowed := range allowedOrigins {
			if strings.TrimSpace(allowed) == origin {
				return true
			}
		}
		return false
	},
}

// WebSocketHandler manages WebSocket connections for the realtime system.
type WebSocketHandler struct {
	realtimeHub *hub.RealtimeHub
}

func NewWebSocketHandler(realtimeHub *hub.RealtimeHub) *WebSocketHandler {
	return &WebSocketHandler{realtimeHub: realtimeHub}
}

// HandleAdminOrders upgrades the connection and registers the client in the RealtimeHub.
// Requires authentication middleware to set user_id and role in context.
//
// Route: GET /ws/orders
func (h *WebSocketHandler) HandleAdminOrders(c *gin.Context) {
	client, err := h.upgradeAndCreateClient(c)
	if err != nil {
		return
	}

	h.realtimeHub.Register <- client
	go client.WritePump()
	go client.ReadPump()
}

// HandleAppNotifications upgrades the connection for app users (customers) to receive
// real-time notifications (order status changes, new notifications, etc.).
//
// Route: GET /ws/notifications
func (h *WebSocketHandler) HandleAppNotifications(c *gin.Context) {
	client, err := h.upgradeAndCreateClient(c)
	if err != nil {
		return
	}

	h.realtimeHub.Register <- client
	go client.WritePump()
	go client.ReadPump()
}

// upgradeAndCreateClient extracts identity from context, upgrades to WebSocket, and creates a Client.
func (h *WebSocketHandler) upgradeAndCreateClient(c *gin.Context) (*hub.Client, error) {
	// Extract identity from JWT middleware (AuthMiddleware or WSAuthMiddleware)
	userIDVal, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "غير مصرح"})
		return nil, http.ErrAbortHandler
	}

	var userID string
	switch v := userIDVal.(type) {
	case uuid.UUID:
		userID = v.String()
	case string:
		userID = v
	default:
		c.JSON(http.StatusUnauthorized, gin.H{"error": "معرف المستخدم غير صالح"})
		return nil, http.ErrAbortHandler
	}

	// Fixed: read "role" (not "user_role") — matches what AuthMiddleware/WSAuthMiddleware sets
	roleVal, _ := c.Get("role")
	role := "customer"
	if roleVal != nil {
		roleStr := strings.ToLower(strings.TrimSpace(string(roleVal.(domain.Role))))
		if roleStr != "" {
			role = roleStr
		}
	}

	merchantID := c.GetString("merchant_id") // set by middleware for merchant role

	// Upgrade HTTP → WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("[WebSocketHandler] upgrade failed: %v", err)
		return nil, err
	}

	client := &hub.Client{
		Hub:        h.realtimeHub,
		Conn:       conn,
		Send:       make(chan []byte, 256),
		UserID:     userID,
		Role:       role,
		MerchantID: merchantID,
	}

	return client, nil
}
