package domain

import (
	"time"

	"github.com/google/uuid"
)

type StoreBranch struct {
	ID            uuid.UUID `db:"id" json:"id"`
	StoreID       uuid.UUID `db:"store_id" json:"store_id"`
	Name          string    `db:"name" json:"name"`
	GovernorateID *int      `db:"governorate_id" json:"governorate_id,omitempty"`
	City          *string   `db:"city" json:"city,omitempty"`
	Address       *string   `db:"address" json:"address,omitempty"`
	Phone         *string   `db:"phone" json:"phone,omitempty"`
	IsActive      bool      `db:"is_active" json:"is_active"`
	CreatedAt     time.Time `db:"created_at" json:"created_at"`
	UpdatedAt     time.Time `db:"updated_at" json:"updated_at"`

	// Joined
	GovernorateNameAr string `db:"governorate_name_ar" json:"governorate_name_ar,omitempty"`
	GovernorateNameEn string `db:"governorate_name_en" json:"governorate_name_en,omitempty"`
}

type CreateBranchRequest struct {
	Name          string  `json:"name" binding:"required"`
	GovernorateID *int    `json:"governorate_id,omitempty"`
	City          *string `json:"city,omitempty"`
	Address       *string `json:"address,omitempty"`
	Phone         *string `json:"phone,omitempty"`
}

type UpdateBranchRequest struct {
	Name          *string `json:"name,omitempty"`
	GovernorateID *int    `json:"governorate_id,omitempty"`
	City          *string `json:"city,omitempty"`
	Address       *string `json:"address,omitempty"`
	Phone         *string `json:"phone,omitempty"`
	IsActive      *bool   `json:"is_active,omitempty"`
}
