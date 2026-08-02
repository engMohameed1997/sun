package domain

import (
	"time"

	"github.com/google/uuid"
)

type Brand struct {
	ID        uuid.UUID  `db:"id" json:"id"`
	Name      string     `db:"name" json:"name"`
	LogoURL   *string    `db:"logo_url" json:"logo_url,omitempty"`
	IsActive  bool       `db:"is_active" json:"is_active"`
	CreatedAt time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt time.Time  `db:"updated_at" json:"updated_at"`
}

type CreateBrandRequest struct {
	Name     string  `json:"name" binding:"required"`
	LogoURL  *string `json:"logo_url"`
	IsActive *bool   `json:"is_active"`
}

type UpdateBrandRequest struct {
	Name     *string `json:"name"`
	LogoURL  *string `json:"logo_url"`
	IsActive *bool   `json:"is_active"`
}
