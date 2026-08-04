package service

import (
	"context"
	"encoding/json"

	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/hub"
	"github.com/iraq-solar/api/internal/repository"
)

// NotificationService handles notification business logic (CRUD + realtime broadcast).
// The WebSocket transport is delegated entirely to RealtimeHub.
type NotificationService struct {
	repo *repository.NotificationRepository
	hub  *hub.RealtimeHub
}

// NewNotificationService creates a new NotificationService.
func NewNotificationService(repo *repository.NotificationRepository, realtimeHub *hub.RealtimeHub) *NotificationService {
	return &NotificationService{
		repo: repo,
		hub:  realtimeHub,
	}
}

// Create creates a notification in the DB and broadcasts it to the recipient via WebSocket.
func (s *NotificationService) Create(ctx context.Context, recipientID uuid.UUID, notifType domain.NotificationType, title, body string, data json.RawMessage) (*domain.Notification, error) {
	notification := &domain.Notification{
		ID:          uuid.New(),
		RecipientID: recipientID,
		Type:        notifType,
		Title:       title,
		Body:        body,
		Data:        data,
		IsRead:      false,
	}

	if s.repo != nil {
		if err := s.repo.Create(ctx, notification); err != nil {
			return nil, err
		}
	}

	// Broadcast to the recipient's connected devices
	if s.hub != nil {
		go s.hub.BroadcastToUser(recipientID.String(), hub.MsgNotif, hub.EventNotificationCreated, notification)
	}

	return notification, nil
}
