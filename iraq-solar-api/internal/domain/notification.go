package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type NotificationType string

const (
	NotificationTypeNewOrder    NotificationType = "new_order"
	NotificationTypeNewUser     NotificationType = "new_user"
	NotificationTypeOrderStatus NotificationType = "order_status"
	NotificationTypeSystem      NotificationType = "system"
)

type Notification struct {
	ID          uuid.UUID       `db:"id" json:"id"`
	RecipientID uuid.UUID       `db:"recipient_id" json:"recipient_id"`
	Type        NotificationType `db:"type" json:"type"`
	Title       string          `db:"title" json:"title"`
	Body        string          `db:"body" json:"body"`
	Data        json.RawMessage `db:"data" json:"data"`
	IsRead      bool            `db:"is_read" json:"is_read"`
	CreatedAt   time.Time       `db:"created_at" json:"created_at"`
}
