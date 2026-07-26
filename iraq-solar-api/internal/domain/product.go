package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type ProductType string

const (
	TypePanel     ProductType = "panel"
	TypeInverter  ProductType = "inverter"
	TypeBattery   ProductType = "battery"
	TypeStructure ProductType = "structure"
	TypeCable     ProductType = "cable"
	TypeAccessory ProductType = "accessory"
)

type Product struct {
	ID            uuid.UUID       `db:"id" json:"id"`
	CategoryID    *int            `db:"category_id" json:"category_id,omitempty"`
	SKU           string          `db:"sku" json:"sku"`
	Name          string          `db:"name" json:"name"`
	Brand         string          `db:"brand" json:"brand"`
	Model         string          `db:"model" json:"model"`
	Type          ProductType     `db:"type" json:"type"`
	PriceUSD      float64         `db:"price_usd" json:"price_usd"`
	StockQuantity int             `db:"stock_quantity" json:"stock_quantity"`
	Specifications json.RawMessage `db:"specifications" json:"specifications"`
	Images        []string        `db:"images" json:"images"`
	IsAvailable   bool            `db:"is_available" json:"is_available"`
	CreatedAt     time.Time       `db:"created_at" json:"created_at"`
	UpdatedAt     time.Time       `db:"updated_at" json:"updated_at"`
}

type UpdateProductRequest struct {
	CategoryID     *int            `json:"category_id"`
	SKU            string          `json:"sku"`
	Name           string          `json:"name"`
	Brand          string          `json:"brand"`
	Model          string          `json:"model"`
	Type           ProductType     `json:"type"`
	PriceUSD       float64         `json:"price_usd"`
	StockQuantity  *int            `json:"stock_quantity"`
	Specifications json.RawMessage `json:"specifications"`
	IsAvailable    *bool           `json:"is_available"`
	Images         []string        `json:"images"`
}

type CreateProductRequest struct {
	SKU            string          `json:"sku" binding:"required"`
	Name           string          `json:"name" binding:"required"`
	Brand          string          `json:"brand" binding:"required"`
	Model          string          `json:"model" binding:"required"`
	Type           ProductType     `json:"type" binding:"required"`
	PriceUSD       float64         `json:"price_usd" binding:"required,gt=0"`
	StockQuantity  int             `json:"stock_quantity" binding:"gte=0"`
	Specifications json.RawMessage `json:"specifications"`
}
