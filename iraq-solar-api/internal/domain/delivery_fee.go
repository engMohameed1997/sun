package domain

import "github.com/google/uuid"

type DeliveryFee struct {
	ID                int        `db:"id" json:"id"`
	MerchantID        uuid.UUID  `db:"merchant_id" json:"merchant_id"`
	StoreID           *uuid.UUID `db:"store_id" json:"store_id,omitempty"`
	GovernorateID     int        `db:"governorate_id" json:"governorate_id"`
	FeeIQD            float64   `db:"fee_iqd" json:"fee_iqd"`
	EstimatedDays     int       `db:"estimated_days" json:"estimated_days"`
	IsActive          bool      `db:"is_active" json:"is_active"`
	GovernorateNameAr string    `db:"governorate_name_ar" json:"governorate_name_ar,omitempty"`
	GovernorateNameEn string    `db:"governorate_name_en" json:"governorate_name_en,omitempty"`
}

type UpdateDeliveryFeeRequest struct {
	GovernorateID int     `json:"governorate_id" binding:"required"`
	FeeIQD        float64 `json:"fee_iqd" binding:"required"`
	EstimatedDays int     `json:"estimated_days" binding:"required"`
	IsActive      *bool   `json:"is_active"`
}

