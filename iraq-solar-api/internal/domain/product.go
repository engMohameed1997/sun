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
	ID                uuid.UUID       `db:"id" json:"id"`
	CategoryID        *int            `db:"category_id" json:"category_id,omitempty"`
	MerchantID        *uuid.UUID      `db:"merchant_id" json:"merchant_id,omitempty"`
	StoreID           *uuid.UUID      `db:"store_id" json:"store_id,omitempty"`
	BranchID          *uuid.UUID      `db:"branch_id" json:"branch_id,omitempty"`
	SKU               string          `db:"sku" json:"sku"`
	Name              string          `db:"name" json:"name"`
	BrandID           *uuid.UUID      `db:"brand_id" json:"brand_id,omitempty"`
	Model             string          `db:"model" json:"model"`
	Type              ProductType     `db:"type" json:"type"`
	PriceUSD          float64         `db:"price_usd" json:"price_usd"`
	StockQuantity     int             `db:"stock_quantity" json:"stock_quantity"`
	ReservedQuantity  int             `db:"reserved_quantity" json:"reserved_quantity"`
	LowStockThreshold int             `db:"low_stock_threshold" json:"low_stock_threshold"`
	Specifications    json.RawMessage `db:"specifications" json:"specifications"`
	Images            []string        `db:"images" json:"images"`
	IsAvailable       bool            `db:"is_available" json:"is_available"`
	CreatedAt         time.Time       `db:"created_at" json:"created_at"`
	UpdatedAt         time.Time       `db:"updated_at" json:"updated_at"`
	DeletedAt         *time.Time      `db:"deleted_at" json:"deleted_at,omitempty"`
	
	// Joined fields
	BrandName         string          `db:"brand_name" json:"brand_name,omitempty"`
}

func (p Product) AvailableQuantity() int {
	avail := p.StockQuantity - p.ReservedQuantity
	if avail < 0 {
		return 0
	}
	return avail
}

type UpdateProductRequest struct {
	CategoryID        *int            `json:"category_id"`
	StoreID           *uuid.UUID      `json:"store_id"`
	BranchID          *uuid.UUID      `json:"branch_id"`
	SKU               string          `json:"sku"`
	Name              string          `json:"name"`
	BrandID           *uuid.UUID      `json:"brand_id"`
	Model             string          `json:"model"`
	Type              ProductType     `json:"type"`
	PriceUSD          float64         `json:"price_usd"`
	StockQuantity     *int            `json:"stock_quantity"`
	LowStockThreshold *int            `json:"low_stock_threshold"`
	Specifications    json.RawMessage `json:"specifications"`
	IsAvailable       *bool           `json:"is_available"`
	Images            []string        `json:"images"`
}

type CreateProductRequest struct {
	CategoryID        *int            `json:"category_id"`
	StoreID           *uuid.UUID      `json:"store_id"`
	BranchID          *uuid.UUID      `json:"branch_id"`
	SKU               string          `json:"sku" binding:"required"`
	Name              string          `json:"name" binding:"required"`
	BrandID           *uuid.UUID      `json:"brand_id" binding:"required"`
	Model             string          `json:"model" binding:"required"`
	Type              ProductType     `json:"type" binding:"required"`
	PriceUSD          float64         `json:"price_usd" binding:"required,gt=0"`
	StockQuantity     int             `json:"stock_quantity" binding:"gte=0"`
	LowStockThreshold int             `json:"low_stock_threshold"`
	Specifications    json.RawMessage `json:"specifications"`
	Images            []string        `json:"images"`
}
