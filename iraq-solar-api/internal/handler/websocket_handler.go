package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/iraq-solar/api/internal/service"
)

type WebSocketHandler struct {
	notificationService *service.NotificationService
}

func NewWebSocketHandler(notificationService *service.NotificationService) *WebSocketHandler {
	return &WebSocketHandler{notificationService: notificationService}
}

func (h *WebSocketHandler) HandleConnections(c *gin.Context) {
	// Require authentication middleware before this
	userID := c.GetString("user_id")
	h.notificationService.HandleWebSocket(c.Writer, c.Request, userID)
}
