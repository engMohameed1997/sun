package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type ProductRepository interface {
	Create(ctx context.Context, product *domain.Product) error
	ListAll(ctx context.Context) ([]domain.Product, error)
	FindByID(ctx context.Context, id uuid.UUID) (*domain.Product, error)
	FindByType(ctx context.Context, pType domain.ProductType) ([]domain.Product, error)
	ListByMerchant(ctx context.Context, merchantID uuid.UUID) ([]domain.Product, error)
	Update(ctx context.Context, product *domain.Product) error
	SoftDelete(ctx context.Context, id uuid.UUID, merchantID *uuid.UUID) error
}

type postgresProductRepository struct {
	db *sqlx.DB
}

func NewProductRepository(db *sqlx.DB) ProductRepository {
	return &postgresProductRepository{db: db}
}

func (r *postgresProductRepository) Create(ctx context.Context, product *domain.Product) error {
	if r.db == nil {
		return nil
	}

	query := `
		INSERT INTO products (id, category_id, merchant_id, store_id, branch_id, sku, name, brand_id, model, type, price_iqd, stock_quantity, reserved_quantity, low_stock_threshold, specifications, is_available, created_at, updated_at)
		VALUES (:id, :category_id, :merchant_id, :store_id, :branch_id, :sku, :name, :brand_id, :model, :type, :price_iqd, :stock_quantity, :reserved_quantity, :low_stock_threshold, :specifications, :is_available, :created_at, :updated_at)
	`

	_, err := r.db.NamedExecContext(ctx, query, product)
	if err != nil {
		return fmt.Errorf("failed to insert product: %w", err)
	}
	return nil
}

func (r *postgresProductRepository) ListAll(ctx context.Context) ([]domain.Product, error) {
	if r.db == nil {
		return nil, nil
	}

	var products []domain.Product
	query := `SELECT p.id, p.category_id, p.merchant_id, p.store_id, p.branch_id, p.sku, p.name, p.brand_id, b.name AS brand_name, p.model, p.type, p.price_iqd, p.stock_quantity, p.reserved_quantity, p.low_stock_threshold, p.specifications, p.is_available, p.created_at, p.updated_at 
                  FROM products p 
                  LEFT JOIN brands b ON p.brand_id = b.id 
                  WHERE p.is_available = true AND p.deleted_at IS NULL 
                  ORDER BY p.created_at DESC`
	err := r.db.SelectContext(ctx, &products, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list products: %w", err)
	}
	return products, nil
}

func (r *postgresProductRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.Product, error) {
	if r.db == nil {
		return nil, nil
	}

	var product domain.Product
	query := `SELECT p.id, p.category_id, p.merchant_id, p.store_id, p.branch_id, p.sku, p.name, p.brand_id, b.name AS brand_name, p.model, p.type, p.price_iqd, p.stock_quantity, p.reserved_quantity, p.low_stock_threshold, p.specifications, p.is_available, p.created_at, p.updated_at 
                  FROM products p 
                  LEFT JOIN brands b ON p.brand_id = b.id 
                  WHERE p.id = $1 AND p.deleted_at IS NULL LIMIT 1`
	err := r.db.GetContext(ctx, &product, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get product by id: %w", err)
	}
	return &product, nil
}

func (r *postgresProductRepository) FindByType(ctx context.Context, pType domain.ProductType) ([]domain.Product, error) {
	if r.db == nil {
		return nil, nil
	}

	var products []domain.Product
	query := `SELECT p.id, p.category_id, p.merchant_id, p.store_id, p.branch_id, p.sku, p.name, p.brand_id, b.name AS brand_name, p.model, p.type, p.price_iqd, p.stock_quantity, p.reserved_quantity, p.low_stock_threshold, p.specifications, p.is_available, p.created_at, p.updated_at 
                  FROM products p 
                  LEFT JOIN brands b ON p.brand_id = b.id 
                  WHERE p.type = $1 AND p.is_available = true AND p.deleted_at IS NULL`
	err := r.db.SelectContext(ctx, &products, query, pType)
	if err != nil {
		return nil, fmt.Errorf("failed to get products by type: %w", err)
	}
	return products, nil
}

func (r *postgresProductRepository) ListByMerchant(ctx context.Context, merchantID uuid.UUID) ([]domain.Product, error) {
	if r.db == nil {
		return nil, nil
	}

	var products []domain.Product
	query := `SELECT p.id, p.category_id, p.merchant_id, p.store_id, p.branch_id, p.sku, p.name, p.brand_id, b.name AS brand_name, p.model, p.type, p.price_iqd, p.stock_quantity, p.reserved_quantity, p.low_stock_threshold, p.specifications, p.is_available, p.created_at, p.updated_at 
                  FROM products p 
                  LEFT JOIN brands b ON p.brand_id = b.id 
                  WHERE p.merchant_id = $1 AND p.deleted_at IS NULL ORDER BY p.created_at DESC`
	err := r.db.SelectContext(ctx, &products, query, merchantID)
	if err != nil {
		return nil, fmt.Errorf("failed to list merchant products: %w", err)
	}
	return products, nil
}

func (r *postgresProductRepository) Update(ctx context.Context, product *domain.Product) error {
	if r.db == nil {
		return nil
	}

	query := `
		UPDATE products
		SET name = :name, brand_id = :brand_id, model = :model, store_id = :store_id, branch_id = :branch_id, price_iqd = :price_iqd, stock_quantity = :stock_quantity, low_stock_threshold = :low_stock_threshold, is_available = :is_available, updated_at = NOW()
		WHERE id = :id AND deleted_at IS NULL
	`
	_, err := r.db.NamedExecContext(ctx, query, product)
	if err != nil {
		return fmt.Errorf("failed to update product: %w", err)
	}
	return nil
}

func (r *postgresProductRepository) SoftDelete(ctx context.Context, id uuid.UUID, merchantID *uuid.UUID) error {
	if r.db == nil {
		return nil
	}

	var query string
	var args []interface{}
	if merchantID != nil {
		query = `UPDATE products SET deleted_at = NOW(), is_available = false WHERE id = $1 AND merchant_id = $2 AND deleted_at IS NULL`
		args = []interface{}{id, *merchantID}
	} else {
		query = `UPDATE products SET deleted_at = NOW(), is_available = false WHERE id = $1 AND deleted_at IS NULL`
		args = []interface{}{id}
	}

	_, err := r.db.ExecContext(ctx, query, args...)
	if err != nil {
		return fmt.Errorf("failed to soft delete product: %w", err)
	}
	return nil
}

