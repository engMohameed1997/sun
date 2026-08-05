package domain

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

type ActionType string

const (
	ActionNone         ActionType = "none"
	ActionOpenStore    ActionType = "open_store"
	ActionOpenProduct  ActionType = "open_product"
	ActionOpenCategory ActionType = "open_category"
	ActionOpenSearch   ActionType = "open_search"
	ActionOpenURL      ActionType = "open_url"
)

type RecurrenceType string

const (
	RecurrenceNone    RecurrenceType = "none"
	RecurrenceDaily   RecurrenceType = "daily"
	RecurrenceWeekly  RecurrenceType = "weekly"
	RecurrenceMonthly RecurrenceType = "monthly"
)

type EventType string

const (
	EventImpression EventType = "impression"
	EventClick      EventType = "click"
)

// JSONBMap is a custom type for database JSONB scan/value handling
type JSONBMap map[string]interface{}

func (j JSONBMap) Value() (driver.Value, error) {
	if j == nil {
		return "{}", nil
	}
	return json.Marshal(j)
}

func (j *JSONBMap) Scan(value interface{}) error {
	if value == nil {
		*j = make(JSONBMap)
		return nil
	}
	bytes, ok := value.([]byte)
	if !ok {
		str, ok := value.(string)
		if !ok {
			return errors.New("type assertion to []byte or string failed")
		}
		bytes = []byte(str)
	}
	return json.Unmarshal(bytes, j)
}

type Banner struct {
	ID             uuid.UUID      `db:"id" json:"id"`
	ImageURL       string         `db:"image_url" json:"image_url"`
	MobileImageURL *string        `db:"mobile_image_url" json:"mobile_image_url,omitempty"`
	Priority       int            `db:"priority" json:"priority"`
	DisplayOrder   int            `db:"display_order" json:"display_order"`
	IsActive       bool           `db:"is_active" json:"is_active"`
	StartsAt       *time.Time     `db:"starts_at" json:"starts_at,omitempty"`
	EndsAt         *time.Time     `db:"ends_at" json:"ends_at,omitempty"`
	ActionType     ActionType     `db:"action_type" json:"action_type"`
	ActionPayload  JSONBMap       `db:"action_payload" json:"action_payload"`
	TargetingRules JSONBMap       `db:"targeting_rules" json:"targeting_rules"`
	RecurrenceType RecurrenceType `db:"recurrence_type" json:"recurrence_type"`
	RecurrenceTime *string        `db:"recurrence_time" json:"recurrence_time,omitempty"`
	RecurrenceEnd  *time.Time     `db:"recurrence_end" json:"recurrence_end,omitempty"`
	Timezone       string         `db:"timezone" json:"timezone"`
	CreatedBy      *uuid.UUID     `db:"created_by" json:"created_by,omitempty"`
	MerchantID     *uuid.UUID     `db:"merchant_id" json:"merchant_id,omitempty"`
	CreatedAt      time.Time      `db:"created_at" json:"created_at"`
	UpdatedAt      time.Time      `db:"updated_at" json:"updated_at"`

	// Relational aggregations
	Placements   []string            `db:"-" json:"placements,omitempty"`
	StoreIDs     []uuid.UUID         `db:"-" json:"store_ids,omitempty"`
	BranchIDs    []uuid.UUID         `db:"-" json:"branch_ids,omitempty"`
	StoreTargets []BannerStoreTarget `db:"-" json:"store_targets,omitempty"`
}

type BannerPlacement struct {
	ID        uuid.UUID `db:"id" json:"id"`
	BannerID  uuid.UUID `db:"banner_id" json:"banner_id"`
	Placement string    `db:"placement" json:"placement"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

type BannerStoreTarget struct {
	StoreID  *uuid.UUID `db:"store_id" json:"store_id,omitempty"`
	BranchID *uuid.UUID `db:"branch_id" json:"branch_id,omitempty"`
}

type BannerStore struct {
	ID        uuid.UUID  `db:"id" json:"id"`
	BannerID  uuid.UUID  `db:"banner_id" json:"banner_id"`
	StoreID   *uuid.UUID `db:"store_id" json:"store_id,omitempty"`
	BranchID  *uuid.UUID `db:"branch_id" json:"branch_id,omitempty"`
	CreatedAt time.Time  `db:"created_at" json:"created_at"`
}

type BannerEvent struct {
	ID        uuid.UUID  `db:"id" json:"id"`
	BannerID  uuid.UUID  `db:"banner_id" json:"banner_id"`
	EventType EventType  `db:"event_type" json:"event_type"`
	UserID    *uuid.UUID `db:"user_id" json:"user_id,omitempty"`
	DeviceID  *string    `db:"device_id" json:"device_id,omitempty"`
	Metadata  JSONBMap   `db:"metadata" json:"metadata"`
	CreatedAt time.Time  `db:"created_at" json:"created_at"`
}

type BannerAnalyticsSummary struct {
	ID           uuid.UUID `db:"id" json:"id"`
	BannerID     uuid.UUID `db:"banner_id" json:"banner_id"`
	Date         string    `db:"date" json:"date"`
	Impressions  int       `db:"impressions" json:"impressions"`
	Clicks       int       `db:"clicks" json:"clicks"`
	UniqueViews  int       `db:"unique_views" json:"unique_views"`
	UniqueClicks int       `db:"unique_clicks" json:"unique_clicks"`
	CTR          float64   `db:"-" json:"ctr"`
}

type CreateBannerRequest struct {
	ImageURL       string                 `json:"image_url" binding:"required"`
	MobileImageURL *string                `json:"mobile_image_url"`
	Priority       int                    `json:"priority"`
	DisplayOrder   int                    `json:"display_order"`
	IsActive       *bool                  `json:"is_active"`
	StartsAt       *time.Time             `json:"starts_at"`
	EndsAt         *time.Time             `json:"ends_at"`
	ActionType     string                 `json:"action_type"`
	ActionPayload  map[string]interface{} `json:"action_payload"`
	TargetingRules map[string]interface{} `json:"targeting_rules"`
	RecurrenceType string                 `json:"recurrence_type"`
	RecurrenceTime *string                `json:"recurrence_time"`
	RecurrenceEnd  *time.Time             `json:"recurrence_end"`
	Timezone       string                 `json:"timezone"`
	MerchantID     *uuid.UUID             `json:"merchant_id"`
	Placements     []string               `json:"placements" binding:"required"`
	StoreIDs       []uuid.UUID            `json:"store_ids"`
	BranchIDs      []uuid.UUID            `json:"branch_ids"`
	StoreTargets   []BannerStoreTarget    `json:"store_targets"`
}

type UpdateBannerRequest struct {
	ImageURL       *string                `json:"image_url"`
	MobileImageURL *string                `json:"mobile_image_url"`
	Priority       *int                   `json:"priority"`
	DisplayOrder   *int                   `json:"display_order"`
	IsActive       *bool                  `json:"is_active"`
	StartsAt       *time.Time             `json:"starts_at"`
	EndsAt         *time.Time             `json:"ends_at"`
	ActionType     *string                `json:"action_type"`
	ActionPayload  map[string]interface{} `json:"action_payload"`
	TargetingRules map[string]interface{} `json:"targeting_rules"`
	RecurrenceType *string                `json:"recurrence_type"`
	RecurrenceTime *string                `json:"recurrence_time"`
	RecurrenceEnd  *time.Time             `json:"recurrence_end"`
	Timezone       *string                `json:"timezone"`
	Placements     []string               `json:"placements"`
	StoreIDs       []uuid.UUID            `json:"store_ids"`
	BranchIDs      []uuid.UUID            `json:"branch_ids"`
	StoreTargets   []BannerStoreTarget    `json:"store_targets"`
}

type ReorderBannersRequest struct {
	BannerIDs []uuid.UUID `json:"banner_ids" binding:"required"`
}

type TrackBannerEventRequest struct {
	EventType string                 `json:"event_type" binding:"required"`
	DeviceID  string                 `json:"device_id"`
	Metadata  map[string]interface{} `json:"metadata"`
}

type BannerFilterParams struct {
	Placement    string
	StoreID      *uuid.UUID
	CategoryID   *uuid.UUID
	ProductID    *uuid.UUID
	Role         string
	GovernorateID int
}
