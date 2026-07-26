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
	ID            uuid.UUID `db:"id" json:"id"`
	OrderID       uuid.UUID `db:"order_id" json:"order_id"`
	ProductID     uuid.UUID `db:"product_id" json:"product_id"`
	Quantity      int       `db:"quantity" json:"quantity"`
	UnitPriceUSD  float64   `db:"unit_price_usd" json:"unit_price_usd"`
	TotalPriceUSD float64   `db:"total_price_usd" json:"total_price_usd"`
}

type Order struct {
	ID              uuid.UUID   `db:"id" json:"id"`
	UserID          uuid.UUID   `db:"user_id" json:"user_id"`
	Status          OrderStatus `db:"status" json:"status"`
	TotalAmountUSD  float64     `db:"total_amount_usd" json:"total_amount_usd"`
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
}
