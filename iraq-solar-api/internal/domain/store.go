package domain

import (
	"time"

	"github.com/google/uuid"
)

type Store struct {
	ID           uuid.UUID  `db:"id" json:"id"`
	MerchantID   uuid.UUID  `db:"merchant_id" json:"merchant_id"`
	Name         string     `db:"name" json:"name"`
	Slug         string     `db:"slug" json:"slug"`
	Description  *string    `db:"description" json:"description,omitempty"`
	LogoURL      *string    `db:"logo_url" json:"logo_url,omitempty"`
	CoverURL     *string    `db:"cover_url" json:"cover_url,omitempty"`
	Phone        *string    `db:"phone" json:"phone,omitempty"`
	Email        *string    `db:"email" json:"email,omitempty"`
	IsVerified   bool       `db:"is_verified" json:"is_verified"`
	IsActive     bool       `db:"is_active" json:"is_active"`
	Rating       float64    `db:"rating" json:"rating"`
	TotalRatings int        `db:"total_ratings" json:"total_ratings"`
	CreatedAt    time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt    time.Time  `db:"updated_at" json:"updated_at"`

	// Relational
	Branches []StoreBranch `json:"branches,omitempty"`
}

type CreateStoreRequest struct {
	MerchantID  uuid.UUID `json:"merchant_id" binding:"required"`
	Name        string    `json:"name" binding:"required"`
	Slug        string    `json:"slug"`
	Description string    `json:"description,omitempty"`
	LogoURL     string    `json:"logo_url,omitempty"`
	CoverURL    string    `json:"cover_url,omitempty"`
	Phone       string    `json:"phone,omitempty"`
	Email       string    `json:"email,omitempty"`
}

type UpdateStoreRequest struct {
	Name        *string `json:"name,omitempty"`
	Slug        *string `json:"slug,omitempty"`
	Description *string `json:"description,omitempty"`
	LogoURL     *string `json:"logo_url,omitempty"`
	CoverURL    *string `json:"cover_url,omitempty"`
	Phone       *string `json:"phone,omitempty"`
	Email       *string `json:"email,omitempty"`
	IsActive    *bool   `json:"is_active,omitempty"`
}
