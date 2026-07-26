package domain

import "github.com/google/uuid"

type DeliveryFee struct {
	ID            int       `db:"id" json:"id"`
	MerchantID    uuid.UUID `db:"merchant_id" json:"merchant_id"`
	GovernorateID int       `db:"governorate_id" json:"governorate_id"`
	FeeIQD        float64   `db:"fee_iqd" json:"fee_iqd"`
	EstimatedDays int       `db:"estimated_days" json:"estimated_days"`
}

type UpdateDeliveryFeeRequest struct {
	GovernorateID int     `json:"governorate_id" binding:"required"`
	FeeIQD        float64 `json:"fee_iqd" binding:"required"`
	EstimatedDays int     `json:"estimated_days" binding:"required"`
}
