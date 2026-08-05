package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// --- Enums ---

type TechnicianRole string

const (
	TechRoleEngineer   TechnicianRole = "engineer"
	TechRoleInstaller  TechnicianRole = "installer"
	TechRoleTechnician TechnicianRole = "technician"
	TechRoleWorker     TechnicianRole = "worker"
)

type AvailabilityStatus string

const (
	AvailabilityAvailable AvailabilityStatus = "available"
	AvailabilityBusy      AvailabilityStatus = "busy"
	AvailabilitySuspended AvailabilityStatus = "suspended"
	AvailabilityOffline   AvailabilityStatus = "offline"
	AvailabilityVacation  AvailabilityStatus = "vacation"
)

type ServiceOrderType string

const (
	ServiceTypeInstallation ServiceOrderType = "installation"
	ServiceTypeMaintenance  ServiceOrderType = "maintenance"
	ServiceTypeInspection   ServiceOrderType = "inspection"
	ServiceTypeConsultation ServiceOrderType = "consultation"
	ServiceTypeRepair       ServiceOrderType = "repair"
)

type ServiceOrderStatus string

const (
	SvcStatusNew                   ServiceOrderStatus = "new"
	SvcStatusDispatching           ServiceOrderStatus = "dispatching"
	SvcStatusAssigned              ServiceOrderStatus = "assigned"
	SvcStatusTechAccepted          ServiceOrderStatus = "tech_accepted"
	SvcStatusOnTheWay              ServiceOrderStatus = "on_the_way"
	SvcStatusArrived               ServiceOrderStatus = "arrived"
	SvcStatusWorking               ServiceOrderStatus = "working"
	SvcStatusWaitingCustomer       ServiceOrderStatus = "waiting_customer"
	SvcStatusCompleted             ServiceOrderStatus = "completed"
	SvcStatusCancelled             ServiceOrderStatus = "cancelled"
	SvcStatusNoTechnicianAvailable ServiceOrderStatus = "no_technician_available"
)

type DocumentType string

const (
	DocIDCard                DocumentType = "id_card"
	DocElectricalCertificate DocumentType = "electrical_certificate"
	DocSolarCertificate      DocumentType = "solar_certificate"
	DocLicense               DocumentType = "license"
	DocPersonalPhoto         DocumentType = "personal_photo"
	DocWorkPhoto             DocumentType = "work_photo"
)

type DocumentStatus string

const (
	DocStatusPending     DocumentStatus = "pending"
	DocStatusUnderReview DocumentStatus = "under_review"
	DocStatusApproved    DocumentStatus = "approved"
	DocStatusRejected    DocumentStatus = "rejected"
)

type AssignmentStatus string

const (
	AssignmentPending   AssignmentStatus = "pending"
	AssignmentAccepted  AssignmentStatus = "accepted"
	AssignmentRejected  AssignmentStatus = "rejected"
	AssignmentCompleted AssignmentStatus = "completed"
	AssignmentExpired   AssignmentStatus = "expired"
)

type DispatchMode string

const (
	DispatchSequential DispatchMode = "sequential"
	DispatchParallel   DispatchMode = "parallel"
	DispatchHybrid     DispatchMode = "hybrid"
)

type DispatchStatus string

const (
	DispatchQueued    DispatchStatus = "queued"
	DispatchSent      DispatchStatus = "sent"
	DispatchAccepted  DispatchStatus = "accepted"
	DispatchRejected  DispatchStatus = "rejected"
	DispatchExpired   DispatchStatus = "expired"
	DispatchCancelled DispatchStatus = "cancelled"
)

type LeadStatus string

const (
	LeadPendingReview LeadStatus = "pending_review"
	LeadApproved      LeadStatus = "approved"
	LeadRejected      LeadStatus = "rejected"
	LeadConverted     LeadStatus = "converted"
)

type TrackingStatus string

const (
	TrackingOnTheWay TrackingStatus = "on_the_way"
	TrackingArrived  TrackingStatus = "arrived"
	TrackingWorking  TrackingStatus = "working"
	TrackingIdle     TrackingStatus = "idle"
)

type ServicePaymentStatus string

const (
	PayUnpaid           ServicePaymentStatus = "unpaid"
	PayPending          ServicePaymentStatus = "pending"
	PayPaidToTechnician ServicePaymentStatus = "paid_to_technician"
	PaySettled          ServicePaymentStatus = "settled"
)

// --- Entities ---

// TechnicianLevel defines commission tiers (Bronze/Silver/Gold/Platinum).
type TechnicianLevel struct {
	ID             uuid.UUID `db:"id" json:"id"`
	Name           string    `db:"name" json:"name"`
	NameAr         string    `db:"name_ar" json:"name_ar"`
	MinJobs        int       `db:"min_jobs" json:"min_jobs"`
	MinRating      float64   `db:"min_rating" json:"min_rating"`
	CommissionRate float64   `db:"commission_rate" json:"commission_rate"`
	BadgeColor     string    `db:"badge_color" json:"badge_color"`
	SortOrder      int       `db:"sort_order" json:"sort_order"`
	CreatedAt      time.Time `db:"created_at" json:"created_at"`
}

// Technician is the workforce profile linked to a user account.
type Technician struct {
	ID                 uuid.UUID          `db:"id" json:"id"`
	UserID             uuid.UUID          `db:"user_id" json:"user_id"`
	FullName           string             `db:"full_name" json:"full_name"`
	ProfileImageURL    *string            `db:"profile_image_url" json:"profile_image_url,omitempty"`
	PhonePrivate       *string            `db:"phone_private" json:"phone_private,omitempty"`
	PhonePublic        *string            `db:"phone_public" json:"phone_public,omitempty"`
	Role               TechnicianRole     `db:"role" json:"role"`
	Specializations    json.RawMessage    `db:"specializations" json:"specializations"`
	GovernorateID      *int               `db:"governorate_id" json:"governorate_id,omitempty"`
	DistrictID         *int               `db:"district_id" json:"district_id,omitempty"`
	ExperienceYears    int                `db:"experience_years" json:"experience_years"`
	Bio                *string            `db:"bio" json:"bio,omitempty"`
	IsVerified         bool               `db:"is_verified" json:"is_verified"`
	IsActive           bool               `db:"is_active" json:"is_active"`
	AvailabilityStatus AvailabilityStatus `db:"availability_status" json:"availability_status"`
	Rating             float64            `db:"rating" json:"rating"`
	CompletedJobsCount int                `db:"completed_jobs_count" json:"completed_jobs_count"`
	AcceptanceRate     float64            `db:"acceptance_rate" json:"acceptance_rate"`
	AvgResponseMinutes int                `db:"avg_response_minutes" json:"avg_response_minutes"`
	VerificationLevel  int                `db:"verification_level" json:"verification_level"`
	ComplaintCount     int                `db:"complaint_count" json:"complaint_count"`
	LevelID            *uuid.UUID         `db:"level_id" json:"level_id,omitempty"`
	CreatedAt          time.Time          `db:"created_at" json:"created_at"`
	UpdatedAt          time.Time          `db:"updated_at" json:"updated_at"`

	// Joined fields
	LevelName       *string `db:"level_name" json:"level_name,omitempty"`
	LevelNameAr     *string `db:"level_name_ar" json:"level_name_ar,omitempty"`
	LevelBadgeColor *string `db:"level_badge_color" json:"level_badge_color,omitempty"`
	CommissionRate  *float64 `db:"commission_rate" json:"commission_rate,omitempty"`
	GovernorateName *string `db:"governorate_name" json:"governorate_name,omitempty"`
	PriorityScore   *float64 `db:"priority_score" json:"priority_score,omitempty"`
	IsFeatured      *bool    `db:"is_featured" json:"is_featured,omitempty"`
	IsHidden        *bool    `db:"is_hidden" json:"is_hidden,omitempty"`
}

// TechnicianPublic is the customer-facing safe projection (no phone numbers).
type TechnicianPublic struct {
	ID                 uuid.UUID       `json:"id"`
	FirstName          string          `json:"first_name"`
	ProfileImageURL    *string         `json:"profile_image_url,omitempty"`
	Role               TechnicianRole  `json:"role"`
	Specializations    json.RawMessage `json:"specializations"`
	ExperienceYears    int             `json:"experience_years"`
	Rating             float64         `json:"rating"`
	CompletedJobsCount int             `json:"completed_jobs_count"`
	VerificationLevel  int             `json:"verification_level"`
	LevelNameAr        *string         `json:"level_name_ar,omitempty"`
	LevelBadgeColor    *string         `json:"level_badge_color,omitempty"`
	GovernorateName    *string         `json:"governorate_name,omitempty"`
}

// TechnicianAvailability holds live status and working hours.
type TechnicianAvailability struct {
	ID                 uuid.UUID       `db:"id" json:"id"`
	TechnicianID       uuid.UUID       `db:"technician_id" json:"technician_id"`
	Status             string          `db:"status" json:"status"`
	AvailableFrom      *string         `db:"available_from" json:"available_from,omitempty"`
	AvailableUntil     *string         `db:"available_until" json:"available_until,omitempty"`
	WorkingDays        json.RawMessage `db:"working_days" json:"working_days"`
	CurrentLat         *float64        `db:"current_lat" json:"current_lat,omitempty"`
	CurrentLng         *float64        `db:"current_lng" json:"current_lng,omitempty"`
	LastStatusChangeAt time.Time       `db:"last_status_change_at" json:"last_status_change_at"`
	UpdatedAt          time.Time       `db:"updated_at" json:"updated_at"`
}

type TechnicianDocument struct {
	ID           uuid.UUID      `db:"id" json:"id"`
	TechnicianID uuid.UUID      `db:"technician_id" json:"technician_id"`
	Type         DocumentType   `db:"type" json:"type"`
	URL          string         `db:"url" json:"url"`
	Status       DocumentStatus `db:"status" json:"status"`
	ReviewedBy   *uuid.UUID     `db:"reviewed_by" json:"reviewed_by,omitempty"`
	ReviewedAt   *time.Time     `db:"reviewed_at" json:"reviewed_at,omitempty"`
	CreatedAt    time.Time      `db:"created_at" json:"created_at"`
}

type TechnicianPortfolio struct {
	ID               uuid.UUID       `db:"id" json:"id"`
	TechnicianID     uuid.UUID       `db:"technician_id" json:"technician_id"`
	Title            string          `db:"title" json:"title"`
	Description      *string         `db:"description" json:"description,omitempty"`
	BeforeImages     json.RawMessage `db:"before_images" json:"before_images"`
	AfterImages      json.RawMessage `db:"after_images" json:"after_images"`
	VideoURL         *string         `db:"video_url" json:"video_url,omitempty"`
	ProjectType      string          `db:"project_type" json:"project_type"`
	SystemCapacityKW *float64        `db:"system_capacity_kw" json:"system_capacity_kw,omitempty"`
	Governorate      *string         `db:"governorate" json:"governorate,omitempty"`
	City             *string         `db:"city" json:"city,omitempty"`
	ExecutionDate    *time.Time      `db:"execution_date" json:"execution_date,omitempty"`
	CreatedAt        time.Time       `db:"created_at" json:"created_at"`
}

type TechnicianServiceZone struct {
	ID            uuid.UUID `db:"id" json:"id"`
	TechnicianID  uuid.UUID `db:"technician_id" json:"technician_id"`
	GovernorateID int       `db:"governorate_id" json:"governorate_id"`
	IsPrimary     bool      `db:"is_primary" json:"is_primary"`
	CreatedAt     time.Time `db:"created_at" json:"created_at"`

	GovernorateNameAr *string `db:"governorate_name_ar" json:"governorate_name_ar,omitempty"`
}

type TechnicianWallet struct {
	ID                 uuid.UUID  `db:"id" json:"id"`
	TechnicianID       uuid.UUID  `db:"technician_id" json:"technician_id"`
	BalanceIQD         float64    `db:"balance_iqd" json:"balance_iqd"`
	TotalEarnedIQD     float64    `db:"total_earned_iqd" json:"total_earned_iqd"`
	TotalCommissionIQD float64    `db:"total_commission_iqd" json:"total_commission_iqd"`
	PendingPayoutIQD   float64    `db:"pending_payout_iqd" json:"pending_payout_iqd"`
	LastSettlementAt   *time.Time `db:"last_settlement_at" json:"last_settlement_at,omitempty"`
	CreatedAt          time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt          time.Time  `db:"updated_at" json:"updated_at"`
}

type TechnicianRanking struct {
	ID                 uuid.UUID `db:"id" json:"id"`
	TechnicianID       uuid.UUID `db:"technician_id" json:"technician_id"`
	PriorityScore      float64   `db:"priority_score" json:"priority_score"`
	ManualOrder        int       `db:"manual_order" json:"manual_order"`
	IsFeatured         bool      `db:"is_featured" json:"is_featured"`
	IsHidden           bool      `db:"is_hidden" json:"is_hidden"`
	LastRecalculatedAt time.Time `db:"last_recalculated_at" json:"last_recalculated_at"`
}

type TechnicianDispatchStats struct {
	ID                       uuid.UUID  `db:"id" json:"id"`
	TechnicianID             uuid.UUID  `db:"technician_id" json:"technician_id"`
	OrdersReceivedThisMonth  int        `db:"orders_received_this_month" json:"orders_received_this_month"`
	OrdersReceivedThisWeek   int        `db:"orders_received_this_week" json:"orders_received_this_week"`
	TotalOrdersReceived      int        `db:"total_orders_received" json:"total_orders_received"`
	TotalEarningsThisMonth   float64    `db:"total_earnings_this_month" json:"total_earnings_this_month"`
	LastOrderReceivedAt      *time.Time `db:"last_order_received_at" json:"last_order_received_at,omitempty"`
	LastOrderCompletedAt     *time.Time `db:"last_order_completed_at" json:"last_order_completed_at,omitempty"`
	DaysSinceLastOrder       int        `db:"days_since_last_order" json:"days_since_last_order"`
	IsNewTechnician          bool       `db:"is_new_technician" json:"is_new_technician"`
	NewTechnicianOrdersCount int        `db:"new_technician_orders_count" json:"new_technician_orders_count"`
	FairnessBoost            float64    `db:"fairness_boost" json:"fairness_boost"`
	LastBoostCalculatedAt    *time.Time `db:"last_boost_calculated_at" json:"last_boost_calculated_at,omitempty"`
	UpdatedAt                time.Time  `db:"updated_at" json:"updated_at"`

	TechnicianName *string `db:"technician_name" json:"technician_name,omitempty"`
}

type TechnicianTracking struct {
	ID           uuid.UUID      `db:"id" json:"id"`
	OrderID      uuid.UUID      `db:"order_id" json:"order_id"`
	TechnicianID uuid.UUID      `db:"technician_id" json:"technician_id"`
	Lat          float64        `db:"lat" json:"lat"`
	Lng          float64        `db:"lng" json:"lng"`
	Status       TrackingStatus `db:"status" json:"status"`
	CreatedAt    time.Time      `db:"created_at" json:"created_at"`
}

type TechnicianLead struct {
	ID                uuid.UUID        `db:"id" json:"id"`
	TechnicianID      uuid.UUID        `db:"technician_id" json:"technician_id"`
	CustomerName      string           `db:"customer_name" json:"customer_name"`
	CustomerPhone     string           `db:"customer_phone" json:"customer_phone"`
	OrderType         ServiceOrderType `db:"order_type" json:"order_type"`
	Description       *string          `db:"description" json:"description,omitempty"`
	SystemSizeKW      *float64         `db:"system_size_kw" json:"system_size_kw,omitempty"`
	GovernorateID     *int             `db:"governorate_id" json:"governorate_id,omitempty"`
	DistrictID        *int             `db:"district_id" json:"district_id,omitempty"`
	Address           *string          `db:"address" json:"address,omitempty"`
	EstimatedPriceIQD *float64         `db:"estimated_price_iqd" json:"estimated_price_iqd,omitempty"`
	Status            LeadStatus       `db:"status" json:"status"`
	ReviewedBy        *uuid.UUID       `db:"reviewed_by" json:"reviewed_by,omitempty"`
	ReviewedAt        *time.Time       `db:"reviewed_at" json:"reviewed_at,omitempty"`
	ConvertedOrderID  *uuid.UUID       `db:"converted_order_id" json:"converted_order_id,omitempty"`
	CreatedAt         time.Time        `db:"created_at" json:"created_at"`

	TechnicianName *string `db:"technician_name" json:"technician_name,omitempty"`
}

type DispatchSettings struct {
	ID                      uuid.UUID    `db:"id" json:"id"`
	ServiceType             string       `db:"service_type" json:"service_type"`
	DispatchMode            DispatchMode `db:"dispatch_mode" json:"dispatch_mode"`
	ResponseTimeoutMinutes  int          `db:"response_timeout_minutes" json:"response_timeout_minutes"`
	ParallelCandidatesCount int          `db:"parallel_candidates_count" json:"parallel_candidates_count"`
	MinimumScore            float64      `db:"minimum_score" json:"minimum_score"`
	AutoAssignEnabled       bool         `db:"auto_assign_enabled" json:"auto_assign_enabled"`
	CreatedAt               time.Time    `db:"created_at" json:"created_at"`
	UpdatedAt               time.Time    `db:"updated_at" json:"updated_at"`
}

type DispatchQueueEntry struct {
	ID              uuid.UUID       `db:"id" json:"id"`
	ServiceOrderID  uuid.UUID       `db:"service_order_id" json:"service_order_id"`
	TechnicianID    uuid.UUID       `db:"technician_id" json:"technician_id"`
	PriorityScore   float64         `db:"priority_score" json:"priority_score"`
	DispatchMode    DispatchMode    `db:"dispatch_mode" json:"dispatch_mode"`
	Position        int             `db:"position" json:"position"`
	Status          DispatchStatus  `db:"status" json:"status"`
	SelectionReason json.RawMessage `db:"selection_reason" json:"selection_reason"`
	SentAt          *time.Time      `db:"sent_at" json:"sent_at,omitempty"`
	RespondedAt     *time.Time      `db:"responded_at" json:"responded_at,omitempty"`
	ExpiresAt       *time.Time      `db:"expires_at" json:"expires_at,omitempty"`
	CreatedAt       time.Time       `db:"created_at" json:"created_at"`

	TechnicianName *string `db:"technician_name" json:"technician_name,omitempty"`
}

// DispatchOffer is what the technician sees before accepting (limited details).
type DispatchOffer struct {
	DispatchID      uuid.UUID        `db:"dispatch_id" json:"dispatch_id"`
	OrderID         uuid.UUID        `db:"order_id" json:"order_id"`
	OrderNumber     string           `db:"order_number" json:"order_number"`
	OrderType       ServiceOrderType `db:"order_type" json:"order_type"`
	SystemSizeKW    *float64         `db:"system_size_kw" json:"system_size_kw,omitempty"`
	GovernorateName *string          `db:"governorate_name" json:"governorate_name,omitempty"`
	DistrictName    *string          `db:"district_name" json:"district_name,omitempty"`
	Priority        string           `db:"priority" json:"priority"`
	PreferredDate   *time.Time       `db:"preferred_date" json:"preferred_date,omitempty"`
	ExpiresAt       *time.Time       `db:"expires_at" json:"expires_at,omitempty"`
	SelectionReason json.RawMessage  `db:"selection_reason" json:"selection_reason"`
	Status          DispatchStatus   `db:"status" json:"status"`
	CreatedAt       time.Time        `db:"created_at" json:"created_at"`

	// Computed
	EstimatedPayoutIQD float64 `db:"-" json:"estimated_payout_iqd"`
	SelectionReasonAr  string  `db:"-" json:"selection_reason_ar"`
}

type ServiceOrder struct {
	ID                   uuid.UUID          `db:"id" json:"id"`
	OrderNumber          string             `db:"order_number" json:"order_number"`
	CustomerID           *uuid.UUID         `db:"customer_id" json:"customer_id,omitempty"`
	OrderType            ServiceOrderType   `db:"order_type" json:"order_type"`
	Description          *string            `db:"description" json:"description,omitempty"`
	SystemSizeKW         *float64           `db:"system_size_kw" json:"system_size_kw,omitempty"`
	GovernorateID        *int               `db:"governorate_id" json:"governorate_id,omitempty"`
	DistrictID           *int               `db:"district_id" json:"district_id,omitempty"`
	Address              *string            `db:"address" json:"address,omitempty"`
	Lat                  *float64           `db:"lat" json:"lat,omitempty"`
	Lng                  *float64           `db:"lng" json:"lng,omitempty"`
	PreferredDate        *time.Time         `db:"preferred_date" json:"preferred_date,omitempty"`
	Status               ServiceOrderStatus `db:"status" json:"status"`
	Priority             string             `db:"priority" json:"priority"`
	CalculatorResult     json.RawMessage    `db:"calculator_result" json:"calculator_result,omitempty"`
	AssignedTechnicianID *uuid.UUID         `db:"assigned_technician_id" json:"assigned_technician_id,omitempty"`
	DispatchMode         DispatchMode       `db:"dispatch_mode" json:"dispatch_mode"`
	CreatedAt            time.Time          `db:"created_at" json:"created_at"`
	UpdatedAt            time.Time          `db:"updated_at" json:"updated_at"`
	CompletedAt          *time.Time         `db:"completed_at" json:"completed_at,omitempty"`

	// Joined
	CustomerName    *string `db:"customer_name" json:"customer_name,omitempty"`
	CustomerPhone   *string `db:"customer_phone" json:"customer_phone,omitempty"`
	GovernorateName *string `db:"governorate_name" json:"governorate_name,omitempty"`
	DistrictName    *string `db:"district_name" json:"district_name,omitempty"`
	TechnicianName  *string `db:"technician_name" json:"technician_name,omitempty"`
}

// CustomerServiceOrderView hides technician identity/contact details.
type CustomerServiceOrderView struct {
	ID              uuid.UUID                  `json:"id"`
	OrderNumber     string                     `json:"order_number"`
	OrderType       ServiceOrderType           `json:"order_type"`
	Description     *string                    `json:"description,omitempty"`
	SystemSizeKW    *float64                   `json:"system_size_kw,omitempty"`
	Address         *string                    `json:"address,omitempty"`
	GovernorateName *string                    `json:"governorate_name,omitempty"`
	PreferredDate   *time.Time                 `json:"preferred_date,omitempty"`
	Status          ServiceOrderStatus         `json:"status"`
	StatusLabelAr   string                     `json:"status_label_ar"`
	CreatedAt       time.Time                  `json:"created_at"`
	CompletedAt     *time.Time                 `json:"completed_at,omitempty"`
	Technician      *AssignedTechnicianSummary `json:"technician,omitempty"`
	Tracking        *TechnicianTracking        `json:"tracking,omitempty"`
	Timeline        []ServiceOrderStatusEvent  `json:"timeline,omitempty"`
	Pricing         *ServicePricing            `json:"pricing,omitempty"`
}

// AssignedTechnicianSummary is the limited technician info exposed to customers.
type AssignedTechnicianSummary struct {
	FirstName          string  `json:"first_name"`
	ProfileImageURL    *string `json:"profile_image_url,omitempty"`
	Rating             float64 `json:"rating"`
	CompletedJobsCount int     `json:"completed_jobs_count"`
	LevelNameAr        *string `json:"level_name_ar,omitempty"`
	LevelBadgeColor    *string `json:"level_badge_color,omitempty"`
}

type OrderAssignment struct {
	ID              uuid.UUID        `db:"id" json:"id"`
	OrderID         uuid.UUID        `db:"order_id" json:"order_id"`
	TechnicianID    uuid.UUID        `db:"technician_id" json:"technician_id"`
	AssignedBy      string           `db:"assigned_by" json:"assigned_by"`
	AssignedByAdmin *uuid.UUID       `db:"assigned_by_admin" json:"assigned_by_admin,omitempty"`
	Status          AssignmentStatus `db:"status" json:"status"`
	AssignedAt      time.Time        `db:"assigned_at" json:"assigned_at"`
	AcceptedAt      *time.Time       `db:"accepted_at" json:"accepted_at,omitempty"`
	RejectedAt      *time.Time       `db:"rejected_at" json:"rejected_at,omitempty"`
	RejectionReason *string          `db:"rejection_reason" json:"rejection_reason,omitempty"`
	CompletionTime  *time.Time       `db:"completion_time" json:"completion_time,omitempty"`
}

// TechnicianAssignment is an accepted job with full order details.
type TechnicianAssignment struct {
	OrderAssignment
	Order ServiceOrder `json:"order"`
}

type ServiceOrderStatusEvent struct {
	ID        uuid.UUID  `db:"id" json:"id"`
	OrderID   uuid.UUID  `db:"order_id" json:"order_id"`
	Status    string     `db:"status" json:"status"`
	ChangedBy *uuid.UUID `db:"changed_by" json:"changed_by,omitempty"`
	Notes     *string    `db:"notes" json:"notes,omitempty"`
	CreatedAt time.Time  `db:"created_at" json:"created_at"`
}

type JobTask struct {
	ID          uuid.UUID  `db:"id" json:"id"`
	OrderID     uuid.UUID  `db:"order_id" json:"order_id"`
	Title       string     `db:"title" json:"title"`
	IsCompleted bool       `db:"is_completed" json:"is_completed"`
	CompletedAt *time.Time `db:"completed_at" json:"completed_at,omitempty"`
	SortOrder   int        `db:"sort_order" json:"sort_order"`
}

type JobMedia struct {
	ID           uuid.UUID  `db:"id" json:"id"`
	OrderID      uuid.UUID  `db:"order_id" json:"order_id"`
	TechnicianID *uuid.UUID `db:"technician_id" json:"technician_id,omitempty"`
	Type         string     `db:"type" json:"type"`
	URL          *string    `db:"url" json:"url,omitempty"`
	Content      *string    `db:"content" json:"content,omitempty"`
	Lat          *float64   `db:"lat" json:"lat,omitempty"`
	Lng          *float64   `db:"lng" json:"lng,omitempty"`
	CreatedAt    time.Time  `db:"created_at" json:"created_at"`
}

type CustomerReview struct {
	ID                uuid.UUID  `db:"id" json:"id"`
	OrderID           uuid.UUID  `db:"order_id" json:"order_id"`
	CustomerID        *uuid.UUID `db:"customer_id" json:"customer_id,omitempty"`
	TechnicianID      uuid.UUID  `db:"technician_id" json:"technician_id"`
	QualityRating     int        `db:"quality_rating" json:"quality_rating"`
	PunctualityRating int        `db:"punctuality_rating" json:"punctuality_rating"`
	SpeedRating       int        `db:"speed_rating" json:"speed_rating"`
	Comment           *string    `db:"comment" json:"comment,omitempty"`
	CreatedAt         time.Time  `db:"created_at" json:"created_at"`
}

type ServicePricing struct {
	ID                        uuid.UUID            `db:"id" json:"id"`
	OrderID                   uuid.UUID            `db:"order_id" json:"order_id"`
	BasePriceIQD              float64              `db:"base_price_iqd" json:"base_price_iqd"`
	PlatformCommissionPercent float64              `db:"platform_commission_percent" json:"platform_commission_percent"`
	PlatformCommissionIQD     float64              `db:"platform_commission_iqd" json:"platform_commission_iqd"`
	TechnicianPayoutIQD       float64              `db:"technician_payout_iqd" json:"technician_payout_iqd"`
	PaymentStatus             ServicePaymentStatus `db:"payment_status" json:"payment_status"`
	SettledAt                 *time.Time           `db:"settled_at" json:"settled_at,omitempty"`
	CreatedAt                 time.Time            `db:"created_at" json:"created_at"`

	OrderNumber    *string `db:"order_number" json:"order_number,omitempty"`
	TechnicianName *string `db:"technician_name" json:"technician_name,omitempty"`
}

type ServicePriceTier struct {
	ID                uuid.UUID `db:"id" json:"id"`
	ServiceType       string    `db:"service_type" json:"service_type"`
	MinPriceIQD       float64   `db:"min_price_iqd" json:"min_price_iqd"`
	MaxPriceIQD       float64   `db:"max_price_iqd" json:"max_price_iqd"`
	DefaultPriceIQD   float64   `db:"default_price_iqd" json:"default_price_iqd"`
	PricePerKWIQD     float64   `db:"price_per_kw_iqd" json:"price_per_kw_iqd"`
	CommissionPercent float64   `db:"commission_percent" json:"commission_percent"`
	CreatedAt         time.Time `db:"created_at" json:"created_at"`
	UpdatedAt         time.Time `db:"updated_at" json:"updated_at"`
}

// TechnicianCandidate is an internal dispatch-engine projection used for scoring.
type TechnicianCandidate struct {
	TechnicianID       uuid.UUID `db:"technician_id"`
	FullName           string    `db:"full_name"`
	Rating             float64   `db:"rating"`
	CompletedJobsCount int       `db:"completed_jobs_count"`
	AcceptanceRate     float64   `db:"acceptance_rate"`
	AvgResponseMinutes int       `db:"avg_response_minutes"`
	VerificationLevel  int       `db:"verification_level"`
	ComplaintCount     int       `db:"complaint_count"`
	IsPrimaryZone      bool      `db:"is_primary_zone"`
	GovernorateName    *string   `db:"governorate_name"`

	// Fair dispatch stats
	OrdersThisMonth    int     `db:"orders_this_month"`
	EarningsThisMonth  float64 `db:"earnings_this_month"`
	DaysSinceLastOrder int     `db:"days_since_last_order"`
	IsNewTechnician    bool    `db:"is_new_technician"`
	NewTechOrdersCount int     `db:"new_tech_orders_count"`

	// Computed by the dispatch engine
	QualityScore  float64 `db:"-"`
	FairnessScore float64 `db:"-"`
	FinalScore    float64 `db:"-"`
}

// --- Request DTOs ---

type CreateTechnicianRequest struct {
	UserID          *uuid.UUID     `json:"user_id"`
	FullName        string         `json:"full_name" binding:"required"`
	Phone           string         `json:"phone"`
	Password        string         `json:"password"`
	ProfileImageURL *string        `json:"profile_image_url"`
	PhonePublic     *string        `json:"phone_public"`
	Role            TechnicianRole `json:"role" binding:"required"`
	Specializations []string       `json:"specializations"`
	GovernorateID   *int           `json:"governorate_id"`
	DistrictID      *int           `json:"district_id"`
	ExperienceYears int            `json:"experience_years"`
	Bio             *string        `json:"bio"`
	ServiceZones    []int          `json:"service_zones"`
}

type UpdateTechnicianRequest struct {
	FullName        *string         `json:"full_name"`
	ProfileImageURL *string         `json:"profile_image_url"`
	PhonePublic     *string         `json:"phone_public"`
	Role            *TechnicianRole `json:"role"`
	Specializations []string        `json:"specializations"`
	GovernorateID   *int            `json:"governorate_id"`
	DistrictID      *int            `json:"district_id"`
	ExperienceYears *int            `json:"experience_years"`
	Bio             *string         `json:"bio"`
	IsActive        *bool           `json:"is_active"`
	LevelID         *uuid.UUID      `json:"level_id"`
}

type VerifyTechnicianRequest struct {
	IsVerified        bool `json:"is_verified"`
	VerificationLevel int  `json:"verification_level"`
}

type UpdateAvailabilityRequest struct {
	Status         string   `json:"status" binding:"required"`
	AvailableFrom  *string  `json:"available_from"`
	AvailableUntil *string  `json:"available_until"`
	WorkingDays    []string `json:"working_days"`
}

type UpdateRankingRequest struct {
	ManualOrder *int  `json:"manual_order"`
	IsFeatured  *bool `json:"is_featured"`
	IsHidden    *bool `json:"is_hidden"`
}

type UpdateServiceZonesRequest struct {
	GovernorateIDs     []int `json:"governorate_ids" binding:"required"`
	PrimaryGovernorate *int  `json:"primary_governorate"`
}

type AddDocumentRequest struct {
	Type DocumentType `json:"type" binding:"required"`
	URL  string       `json:"url" binding:"required"`
}

type ReviewDocumentRequest struct {
	Status DocumentStatus `json:"status" binding:"required"`
}

type AddPortfolioRequest struct {
	Title            string     `json:"title" binding:"required"`
	Description      *string    `json:"description"`
	BeforeImages     []string   `json:"before_images"`
	AfterImages      []string   `json:"after_images"`
	VideoURL         *string    `json:"video_url"`
	ProjectType      string     `json:"project_type"`
	SystemCapacityKW *float64   `json:"system_capacity_kw"`
	Governorate      *string    `json:"governorate"`
	City             *string    `json:"city"`
	ExecutionDate    *time.Time `json:"execution_date"`
}

type CreateServiceOrderRequest struct {
	OrderType     ServiceOrderType `json:"order_type" binding:"required"`
	Description   *string          `json:"description"`
	SystemSizeKW  *float64         `json:"system_size_kw"`
	GovernorateID *int             `json:"governorate_id" binding:"required"`
	DistrictID    *int             `json:"district_id"`
	Address       *string          `json:"address"`
	Lat           *float64         `json:"lat"`
	Lng           *float64         `json:"lng"`
	PreferredDate *time.Time       `json:"preferred_date"`
	Priority      string           `json:"priority"`
}

type CreateServiceOrderFromCalculatorRequest struct {
	CreateServiceOrderRequest
	CalculatorResult json.RawMessage `json:"calculator_result"`
}

type RejectDispatchRequest struct {
	Reason *string `json:"reason"`
}

type UpdateServiceOrderStatusRequest struct {
	Status ServiceOrderStatus `json:"status" binding:"required"`
	Notes  *string            `json:"notes"`
}

type AddJobMediaRequest struct {
	Type    string   `json:"type" binding:"required"`
	URL     *string  `json:"url"`
	Content *string  `json:"content"`
	Lat     *float64 `json:"lat"`
	Lng     *float64 `json:"lng"`
}

type UpdateTrackingRequest struct {
	Lat    float64        `json:"lat" binding:"required"`
	Lng    float64        `json:"lng" binding:"required"`
	Status TrackingStatus `json:"status"`
}

type SubmitReviewRequest struct {
	QualityRating     int     `json:"quality_rating" binding:"required,min=1,max=5"`
	PunctualityRating int     `json:"punctuality_rating" binding:"required,min=1,max=5"`
	SpeedRating       int     `json:"speed_rating" binding:"required,min=1,max=5"`
	Comment           *string `json:"comment"`
}

type CreateLeadRequest struct {
	CustomerName      string           `json:"customer_name" binding:"required"`
	CustomerPhone     string           `json:"customer_phone" binding:"required"`
	OrderType         ServiceOrderType `json:"order_type" binding:"required"`
	Description       *string          `json:"description"`
	SystemSizeKW      *float64         `json:"system_size_kw"`
	GovernorateID     *int             `json:"governorate_id"`
	DistrictID        *int             `json:"district_id"`
	Address           *string          `json:"address"`
	EstimatedPriceIQD *float64         `json:"estimated_price_iqd"`
}

type ApproveLeadRequest struct {
	BasePriceIQD *float64 `json:"base_price_iqd"`
}

type RejectLeadRequest struct {
	Reason *string `json:"reason"`
}

type ManualAssignRequest struct {
	TechnicianID uuid.UUID `json:"technician_id" binding:"required"`
}

type UpsertDispatchSettingsRequest struct {
	ServiceType             string       `json:"service_type" binding:"required"`
	DispatchMode            DispatchMode `json:"dispatch_mode" binding:"required"`
	ResponseTimeoutMinutes  int          `json:"response_timeout_minutes" binding:"required,min=1"`
	ParallelCandidatesCount int          `json:"parallel_candidates_count" binding:"required,min=1"`
	MinimumScore            float64      `json:"minimum_score"`
	AutoAssignEnabled       bool         `json:"auto_assign_enabled"`
}

type UpsertTechnicianLevelRequest struct {
	Name           string  `json:"name" binding:"required"`
	NameAr         string  `json:"name_ar" binding:"required"`
	MinJobs        int     `json:"min_jobs"`
	MinRating      float64 `json:"min_rating"`
	CommissionRate float64 `json:"commission_rate" binding:"required"`
	BadgeColor     string  `json:"badge_color"`
	SortOrder      int     `json:"sort_order"`
}

type SetPricingRequest struct {
	BasePriceIQD              float64  `json:"base_price_iqd" binding:"required"`
	PlatformCommissionPercent *float64 `json:"platform_commission_percent"`
}

type UpdatePaymentStatusRequest struct {
	PaymentStatus ServicePaymentStatus `json:"payment_status" binding:"required"`
}

// --- Filters ---

type TechnicianFilters struct {
	Role          string `form:"role"`
	GovernorateID int    `form:"governorate_id"`
	Status        string `form:"status"`
	Search        string `form:"search"`
	IsVerified    *bool  `form:"is_verified"`
	Page          int    `form:"page"`
	Limit         int    `form:"limit"`
}

type ServiceOrderFilters struct {
	Status        string `form:"status"`
	OrderType     string `form:"order_type"`
	GovernorateID int    `form:"governorate_id"`
	TechnicianID  string `form:"technician_id"`
	Search        string `form:"search"`
	Page          int    `form:"page"`
	Limit         int    `form:"limit"`
}

// --- Responses ---

type TechniciansResponse struct {
	Technicians []Technician `json:"technicians"`
	Total       int          `json:"total"`
	Page        int          `json:"page"`
	Limit       int          `json:"limit"`
	TotalPages  int          `json:"total_pages"`
}

type ServiceOrdersResponse struct {
	Orders     []ServiceOrder `json:"orders"`
	Total      int            `json:"total"`
	Page       int            `json:"page"`
	Limit      int            `json:"limit"`
	TotalPages int            `json:"total_pages"`
}

type WalletSummary struct {
	Wallet       TechnicianWallet `json:"wallet"`
	Transactions []ServicePricing `json:"transactions"`
}

// DispatchNotificationPayload is the WS payload sent to a technician on new dispatch.
type DispatchNotificationPayload struct {
	DispatchID        uuid.UUID        `json:"dispatch_id"`
	OrderID           uuid.UUID        `json:"order_id"`
	OrderNumber       string           `json:"order_number"`
	OrderType         ServiceOrderType `json:"order_type"`
	GovernorateName   *string          `json:"governorate_name,omitempty"`
	EstimatedPayout   float64          `json:"estimated_payout_iqd"`
	SelectionReasonAr string           `json:"selection_reason_ar"`
	ExpiresAt         *time.Time       `json:"expires_at,omitempty"`
}

// ServiceOrderStatusLabels maps internal statuses to customer-facing Arabic labels.
var ServiceOrderStatusLabels = map[ServiceOrderStatus]string{
	SvcStatusNew:                   "تم استلام طلبك",
	SvcStatusDispatching:           "جاري التعيين",
	SvcStatusAssigned:              "تم تعيين فني معتمد",
	SvcStatusTechAccepted:          "تم تعيين فني معتمد",
	SvcStatusOnTheWay:              "الفني في الطريق",
	SvcStatusArrived:               "وصل الفني",
	SvcStatusWorking:               "جاري التنفيذ",
	SvcStatusWaitingCustomer:       "بانتظار الزبون",
	SvcStatusCompleted:             "تم الإنجاز",
	SvcStatusCancelled:             "تم الإلغاء",
	SvcStatusNoTechnicianAvailable: "لا يوجد فني متوفر حالياً",
}
