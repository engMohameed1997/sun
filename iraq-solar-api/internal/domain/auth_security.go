package domain

import (
	"time"

	"github.com/google/uuid"
)

type LoginAttempt struct {
	ID            uuid.UUID `db:"id" json:"id"`
	Identifier    string    `db:"identifier" json:"identifier"`
	IPAddress     string    `db:"ip_address" json:"ip_address"`
	UserAgent     string    `db:"user_agent" json:"user_agent"`
	IsSuccess     bool      `db:"is_success" json:"is_success"`
	FailureReason string    `db:"failure_reason" json:"failure_reason"`
	CreatedAt     time.Time `db:"created_at" json:"created_at"`
}

type UserLockout struct {
	ID          uuid.UUID `db:"id" json:"id"`
	Identifier  string    `db:"identifier" json:"identifier"`
	FailedCount int       `db:"failed_count" json:"failed_count"`
	LockedUntil time.Time `db:"locked_until" json:"locked_until"`
	CreatedAt   time.Time `db:"created_at" json:"created_at"`
	UpdatedAt   time.Time `db:"updated_at" json:"updated_at"`
}

type RefreshTokenRecord struct {
	ID        uuid.UUID `db:"id" json:"id"`
	UserID    uuid.UUID `db:"user_id" json:"user_id"`
	TokenHash string    `db:"token_hash" json:"token_hash"`
	UserAgent string    `db:"user_agent" json:"user_agent"`
	IPAddress string    `db:"ip_address" json:"ip_address"`
	IsRevoked bool      `db:"is_revoked" json:"is_revoked"`
	ExpiresAt time.Time `db:"expires_at" json:"expires_at"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

type AuthAuditLog struct {
	ID        uuid.UUID  `db:"id" json:"id"`
	UserID    *uuid.UUID `db:"user_id" json:"user_id,omitempty"`
	Event     string     `db:"event" json:"event"`
	IPAddress string     `db:"ip_address" json:"ip_address"`
	UserAgent string     `db:"user_agent" json:"user_agent"`
	Details   string     `db:"details" json:"details"`
	CreatedAt time.Time  `db:"created_at" json:"created_at"`
}

type LoginSecurityContext struct {
	IPAddress string
	UserAgent string
}
