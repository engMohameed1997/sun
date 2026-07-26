package domain

import (
	"time"

	"github.com/google/uuid"
)

type HomeBanner struct {
	ID           uuid.UUID  `db:"id" json:"id"`
	Title        *string    `db:"title" json:"title"`
	Subtitle     *string    `db:"subtitle" json:"subtitle"`
	ImageURL     string     `db:"image_url" json:"image_url"`
	LinkURL      *string    `db:"link_url" json:"link_url"`
	DisplayOrder int        `db:"display_order" json:"display_order"`
	IsActive     bool       `db:"is_active" json:"is_active"`
	StartsAt     *time.Time `db:"starts_at" json:"starts_at"`
	EndsAt       *time.Time `db:"ends_at" json:"ends_at"`
	CreatedAt    time.Time  `db:"created_at" json:"created_at"`
}

type StoreBanner struct {
	ID         uuid.UUID `db:"id" json:"id"`
	MerchantID uuid.UUID `db:"merchant_id" json:"merchant_id"`
	Title      *string   `db:"title" json:"title"`
	ImageURL   string    `db:"image_url" json:"image_url"`
	IsActive   bool      `db:"is_active" json:"is_active"`
	CreatedAt  time.Time `db:"created_at" json:"created_at"`
}

type CreateHomeBannerRequest struct {
	Title        *string    `json:"title"`
	Subtitle     *string    `json:"subtitle"`
	ImageURL     string     `json:"image_url" binding:"required"`
	LinkURL      *string    `json:"link_url"`
	DisplayOrder int        `json:"display_order"`
	IsActive     *bool      `json:"is_active"`
	StartsAt     *time.Time `json:"starts_at"`
	EndsAt       *time.Time `json:"ends_at"`
}

type UpdateHomeBannerRequest struct {
	Title        *string    `json:"title"`
	Subtitle     *string    `json:"subtitle"`
	ImageURL     *string    `json:"image_url"`
	LinkURL      *string    `json:"link_url"`
	DisplayOrder *int       `json:"display_order"`
	IsActive     *bool      `json:"is_active"`
	StartsAt     *time.Time `json:"starts_at"`
	EndsAt       *time.Time `json:"ends_at"`
}

type CreateStoreBannerRequest struct {
	MerchantID uuid.UUID `json:"merchant_id" binding:"required"`
	Title      *string   `json:"title"`
	ImageURL   string    `json:"image_url" binding:"required"`
	IsActive   *bool     `json:"is_active"`
}

type UpdateStoreBannerRequest struct {
	Title    *string `json:"title"`
	ImageURL *string `json:"image_url"`
	IsActive *bool   `json:"is_active"`
}

type ReorderBannersRequest struct {
	BannerIDs []uuid.UUID `json:"banner_ids" binding:"required"`
}
