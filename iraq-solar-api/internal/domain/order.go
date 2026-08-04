package domain

import (
	"time"

	"github.com/google/uuid"
)

type OrderStatus string

const (
	StatusPending        OrderStatus = "pending"
	StatusConfirmed      OrderStatus = "confirmed"
	StatusProcessing     OrderStatus = "processing"
	StatusReadyForPickup OrderStatus = "ready_for_pickup"
	StatusDelivered      OrderStatus = "delivered"
	StatusCompleted      OrderStatus = "completed"
	StatusCancelled      OrderStatus = "cancelled"
)

// OrderItem represents a single product line within an order.
type OrderItem struct {
	ID            uuid.UUID  `db:"id" json:"id"`
	OrderID       uuid.UUID  `db:"order_id" json:"order_id"`
	ProductID     uuid.UUID  `db:"product_id" json:"product_id"`
	StoreID       *uuid.UUID `db:"store_id" json:"store_id,omitempty"`
	BranchID      *uuid.UUID `db:"branch_id" json:"branch_id,omitempty"`
	Quantity      int        `db:"quantity" json:"quantity"`
	UnitPriceIQD  float64    `db:"unit_price_iqd" json:"unit_price_iqd"`
	TotalPriceIQD float64    `db:"total_price_iqd" json:"total_price_iqd"`
}

// OrderItemFull embeds OrderItem with extra joined product info.
type OrderItemFull struct {
	OrderItem
	ProductName  string  `db:"product_name" json:"product_name,omitempty"`
	ProductSKU   string  `db:"product_sku" json:"product_sku,omitempty"`
	ProductImage *string `db:"product_image" json:"product_image,omitempty"`
}

// Order is the core order record stored in the database.
type Order struct {
	ID              uuid.UUID   `db:"id" json:"id"`
	UserID          uuid.UUID   `db:"user_id" json:"user_id"`
	StoreID         *uuid.UUID  `db:"store_id" json:"store_id,omitempty"`
	BranchID        *uuid.UUID  `db:"branch_id" json:"branch_id,omitempty"`
	Status          OrderStatus `db:"status" json:"status"`
	TotalAmountIQD  float64     `db:"total_amount_iqd" json:"total_amount_iqd"`
	ShippingAddress string      `db:"shipping_address" json:"shipping_address"`
	PaymentMethod   string      `db:"payment_method" json:"payment_method"`
	PaymentStatus   string      `db:"payment_status" json:"payment_status"`
	CreatedAt       time.Time   `db:"created_at" json:"created_at"`
	UpdatedAt       time.Time   `db:"updated_at" json:"updated_at"`
	Items           []OrderItem `json:"items,omitempty"`
}

// OrderFull is a rich view of an order including all related entity data,
// used for admin responses and WebSocket broadcasts.
type OrderFull struct {
	ID              uuid.UUID   `db:"id" json:"id"`
	UserID          uuid.UUID   `db:"user_id" json:"user_id"`
	StoreID         *uuid.UUID  `db:"store_id" json:"store_id,omitempty"`
	BranchID        *uuid.UUID  `db:"branch_id" json:"branch_id,omitempty"`
	Status          OrderStatus `db:"status" json:"status"`
	TotalAmountIQD  float64     `db:"total_amount_iqd" json:"total_amount_iqd"`
	ShippingAddress string      `db:"shipping_address" json:"shipping_address"`
	PaymentMethod   string      `db:"payment_method" json:"payment_method"`
	PaymentStatus   string      `db:"payment_status" json:"payment_status"`
	CreatedAt       time.Time   `db:"created_at" json:"created_at"`
	UpdatedAt       time.Time   `db:"updated_at" json:"updated_at"`

	// Customer info (from JOIN with users)
	CustomerName        string `db:"customer_name" json:"customer_name"`
	CustomerPhone       string `db:"customer_phone" json:"customer_phone"`
	CustomerGovernorate string `db:"customer_governorate" json:"customer_governorate,omitempty"`
	CustomerCity        string `db:"customer_city" json:"customer_city,omitempty"`

	// Store info (from JOIN with stores)
	StoreName    *string `db:"store_name" json:"store_name,omitempty"`
	StoreSlug    *string `db:"store_slug" json:"store_slug,omitempty"`
	StoreLogoURL *string `db:"store_logo_url" json:"store_logo_url,omitempty"`
	StorePhone   *string `db:"store_phone" json:"store_phone,omitempty"`

	// Branch info (from JOIN with store_branches)
	BranchName          *string `db:"branch_name" json:"branch_name,omitempty"`
	BranchAddress       *string `db:"branch_address" json:"branch_address,omitempty"`
	BranchCity          *string `db:"branch_city" json:"branch_city,omitempty"`
	BranchPhone         *string `db:"branch_phone" json:"branch_phone,omitempty"`
	BranchGovernorateAr *string `db:"branch_governorate_ar" json:"branch_governorate_ar,omitempty"`
	BranchGovernorateEn *string `db:"branch_governorate_en" json:"branch_governorate_en,omitempty"`

	// Related collections (populated separately)
	Items         []OrderItemFull      `json:"items,omitempty"`
	StatusHistory []OrderStatusHistory `json:"status_history,omitempty"`
}

// AdminOrderFilters holds all possible filters for the admin order listing.
type AdminOrderFilters struct {
	Status   string `form:"status"`
	Search   string `form:"search"` // searches customer name, phone, order ID prefix
	StoreID  string `form:"store_id"`
	BranchID string `form:"branch_id"`
	FromDate string `form:"from_date"` // RFC3339 or date string
	ToDate   string `form:"to_date"`
	Page     int    `form:"page"`
	Limit    int    `form:"limit"`
}

// AdminOrdersResponse is the paginated admin orders response.
type AdminOrdersResponse struct {
	Orders     []OrderFull `json:"orders"`
	Total      int         `json:"total"`
	Page       int         `json:"page"`
	Limit      int         `json:"limit"`
	TotalPages int         `json:"total_pages"`
}

// OrderStatusChangedPayload is the WS broadcast payload for status changes.
type OrderStatusChangedPayload struct {
	OrderID    uuid.UUID   `json:"order_id"`
	FromStatus OrderStatus `json:"from_status"`
	ToStatus   OrderStatus `json:"to_status"`
	ChangedBy  string      `json:"changed_by"`
	Notes      string      `json:"notes,omitempty"`
	UpdatedAt  time.Time   `json:"updated_at"`
}

// --- Request/Response types ---

type CreateOrderItemRequest struct {
	ProductID uuid.UUID  `json:"product_id" binding:"required"`
	StoreID   *uuid.UUID `json:"store_id,omitempty"`
	BranchID  *uuid.UUID `json:"branch_id,omitempty"`
	Quantity  int        `json:"quantity" binding:"required,gt=0"`
}

type CreateOrderRequest struct {
	StoreID         *uuid.UUID               `json:"store_id,omitempty"`
	BranchID        *uuid.UUID               `json:"branch_id,omitempty"`
	ShippingAddress string                   `json:"shipping_address" binding:"required"`
	PaymentMethod   string                   `json:"payment_method"`
	Items           []CreateOrderItemRequest `json:"items" binding:"required,min=1"`
}

type UpdateOrderStatusRequest struct {
	Status OrderStatus `json:"status" binding:"required"`
	Notes  string      `json:"notes,omitempty"`
}

type OrderStatusHistory struct {
	ID         uuid.UUID  `db:"id" json:"id"`
	OrderID    uuid.UUID  `db:"order_id" json:"order_id"`
	FromStatus *string    `db:"from_status" json:"from_status,omitempty"`
	ToStatus   string     `db:"to_status" json:"to_status"`
	ChangedBy  *uuid.UUID `db:"changed_by" json:"changed_by,omitempty"`
	Notes      *string    `db:"notes" json:"notes,omitempty"`
	CreatedAt  time.Time  `db:"created_at" json:"created_at"`

	// Joined
	ChangedByName *string `db:"changed_by_name" json:"changed_by_name,omitempty"`
}
