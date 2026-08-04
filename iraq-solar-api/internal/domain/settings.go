package domain

import "time"

const (
	SettingKeyPlatformFee   = "platform_fee_percentage"
	SettingKeyContactPhone  = "contact_phone"
	SettingKeyMinOrderValue = "min_order_value"
)

type SystemSetting struct {
	Key       string    `db:"key" json:"key"`
	Value     string    `db:"value" json:"value"`
	UpdatedAt time.Time `db:"updated_at" json:"updated_at"`
}

type UpdateSettingRequest struct {
	Value string `json:"value" binding:"required"`
}
