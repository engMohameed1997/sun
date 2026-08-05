package domain

import (
	"time"

	"github.com/google/uuid"
)

type Calculator struct {
	ID                 uuid.UUID `db:"id" json:"id"`
	RouteKey           string    `db:"route_key" json:"route_key"`
	TitleAr            string    `db:"title_ar" json:"title_ar"`
	TitleEn            *string   `db:"title_en" json:"title_en,omitempty"`
	SubtitleAr         *string   `db:"subtitle_ar" json:"subtitle_ar,omitempty"`
	SubtitleEn         *string   `db:"subtitle_en" json:"subtitle_en,omitempty"`
	IconKey            string    `db:"icon_key" json:"icon_key"`
	BackgroundImageUrl *string   `db:"background_image_url" json:"background_image_url,omitempty"`
	Badge              *string   `db:"badge" json:"badge,omitempty"`
	ColorHex           string    `db:"color_hex" json:"color_hex"`
	IsFeatured         bool      `db:"is_featured" json:"is_featured"`
	SortOrder          int       `db:"sort_order" json:"sort_order"`
	IsActive           bool      `db:"is_active" json:"is_active"`
	Version            int       `db:"version" json:"version"`
	CreatedAt          time.Time `db:"created_at" json:"created_at"`
	UpdatedAt          time.Time `db:"updated_at" json:"updated_at"`
}

type CalculatorPublicResponse struct {
	ID                 uuid.UUID `json:"id"`
	RouteKey           string    `json:"route_key"`
	Title              string    `json:"title"`
	Subtitle           string    `json:"subtitle"`
	IconKey            string    `json:"icon_key"`
	BackgroundImageUrl string    `json:"background_image_url,omitempty"`
	Badge              string    `json:"badge,omitempty"`
	ColorHex           string    `json:"color_hex"`
	IsFeatured         bool      `json:"is_featured"`
	SortOrder          int       `json:"sort_order"`
	Version            int       `json:"version"`
}

type CalculatorAdminResponse struct {
	CalculatorPublicResponse
	AllowedRoles []string  `json:"allowed_roles"`
	IsActive     bool      `json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type CreateCalculatorRequest struct {
	RouteKey           string   `json:"route_key" binding:"required"`
	TitleAr            string   `json:"title_ar" binding:"required"`
	TitleEn            string   `json:"title_en"`
	SubtitleAr         string   `json:"subtitle_ar"`
	SubtitleEn         string   `json:"subtitle_en"`
	IconKey            string   `json:"icon_key" binding:"required"`
	BackgroundImageUrl string   `json:"background_image_url"`
	Badge              string   `json:"badge"`
	ColorHex           string   `json:"color_hex"`
	IsFeatured         bool     `json:"is_featured"`
	SortOrder          int      `json:"sort_order"`
	AllowedRoles       []string `json:"allowed_roles" binding:"required"`
}

type UpdateCalculatorRequest struct {
	TitleAr            string   `json:"title_ar" binding:"required"`
	TitleEn            string   `json:"title_en"`
	SubtitleAr         string   `json:"subtitle_ar"`
	SubtitleEn         string   `json:"subtitle_en"`
	IconKey            string   `json:"icon_key" binding:"required"`
	BackgroundImageUrl string   `json:"background_image_url"`
	Badge              string   `json:"badge"`
	ColorHex           string   `json:"color_hex"`
	IsFeatured         bool     `json:"is_featured"`
	SortOrder          int      `json:"sort_order"`
	AllowedRoles       []string `json:"allowed_roles" binding:"required"`
}

type UpdateCalculatorStatusRequest struct {
	IsActive bool `json:"is_active"`
}
