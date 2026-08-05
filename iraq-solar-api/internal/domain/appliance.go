package domain

import (
	"time"

	"github.com/google/uuid"
)

type AppliancePreset struct {
	ID                uuid.UUID `db:"id" json:"id"`
	NameAr            string    `db:"name_ar" json:"name_ar"`
	NameEn            string    `db:"name_en" json:"name_en"`
	DefaultWattage    float64   `db:"default_wattage" json:"default_wattage"`
	PowerFactor       float64   `db:"power_factor" json:"power_factor"`
	SurgeMultiplier   float64   `db:"surge_multiplier" json:"surge_multiplier"`
	Voltage           float64   `db:"voltage" json:"voltage"`
	Phase             int       `db:"phase" json:"phase"`
	Frequency         float64   `db:"frequency" json:"frequency"`
	DefaultDailyHours float64   `db:"default_daily_hours" json:"default_daily_hours"`
	Category          string    `db:"category" json:"category"`
	IconKey           string    `db:"icon_key" json:"icon_key"`
	SortOrder         int       `db:"sort_order" json:"sort_order"`
	IsActive          bool      `db:"is_active" json:"is_active"`
	CreatedAt         time.Time `db:"created_at" json:"created_at"`
}
