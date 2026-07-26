package domain

import "time"

type Governorate struct {
	ID        int       `db:"id" json:"id"`
	NameAr    string    `db:"name_ar" json:"name_ar"`
	NameEn    string    `db:"name_en" json:"name_en"`
	IsActive  bool      `db:"is_active" json:"is_active"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

type CreateGovernorateRequest struct {
	NameAr   string `json:"name_ar" binding:"required"`
	NameEn   string `json:"name_en" binding:"required"`
	IsActive *bool  `json:"is_active"`
}

type UpdateGovernorateRequest struct {
	NameAr   string `json:"name_ar"`
	NameEn   string `json:"name_en"`
	IsActive *bool  `json:"is_active"`
}
