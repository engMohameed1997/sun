package domain

import (
	"time"

	"github.com/google/uuid"
)

type SupportTicket struct {
	ID        uuid.UUID `db:"id" json:"id"`
	UserID    uuid.UUID `db:"user_id" json:"user_id"`
	Subject   string    `db:"subject" json:"subject"`
	Message   string    `db:"message" json:"message"`
	Status    string    `db:"status" json:"status"` // open, in_progress, resolved, closed
	Response  *string   `db:"response" json:"response,omitempty"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
	UpdatedAt time.Time `db:"updated_at" json:"updated_at"`
}

type CreateTicketRequest struct {
	Subject string `json:"subject"`
	Message string `json:"message" binding:"required"`
}
