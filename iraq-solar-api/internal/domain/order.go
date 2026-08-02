package domain

import (
	"time"

	"github.com/google/uuid"
)

type OrderStatus string

const (
	StatusPending    OrderStatus = "pending"
	StatusConfirmed  OrderStatus = "confirmed"
	StatusProcessing OrderStatus = "processing"
	StatusCompleted  OrderStatus = "completed"
	StatusCancelled  OrderStatus = "cancelled"
)

type OrderItem struct {
	ID            uuid.UUID  `db:"id" json:"id"`
	OrderID       uuid.UUID  `db:"order_id" json:"order_id"`
	ProductID     uuid.UUID  `db:"product_id" json:"product_id"`
	StoreID       *uuid.UUID `db:"store_id" json:"store_id,omitempty"`
	Quantity      int        `db:"quantity" json:"quantity"`
	UnitPriceIQD  float64   `db:"unit_price_iqd" json:"unit_price_iqd"`
	TotalPriceIQD float64   `db:"total_price_iqd" json:"total_price_iqd"`
}

type Order struct {
	ID              uuid.UUID   `db:"id" json:"id"`
	UserID          uuid.UUID   `db:"user_id" json:"user_id"`
	StoreID         *uuid.UUID  `db:"store_id" json:"store_id,omitempty"`
	Status          OrderStatus `db:"status" json:"status"`
	TotalAmountIQD  float64     `db:"total_amount_iqd" json:"total_amount_iqd"`
	ShippingAddress string      `db:"shipping_address" json:"shipping_address"`
	PaymentMethod   string      `db:"payment_method" json:"payment_method"`
	PaymentStatus   string      `db:"payment_status" json:"payment_status"`
	CreatedAt       time.Time   `db:"created_at" json:"created_at"`
	UpdatedAt       time.Time   `db:"updated_at" json:"updated_at"`
	Items           []OrderItem `json:"items,omitempty"`
}

type CreateOrderItemRequest struct {
	ProductID uuid.UUID `json:"product_id" binding:"required"`
	Quantity  int       `json:"quantity" binding:"required,gt=0"`
}

type CreateOrderRequest struct {
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
}

