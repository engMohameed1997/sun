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
		INSERT INTO products (id, category_id, sku, name, brand, model, type, price_usd, stock_quantity, specifications, is_available, created_at, updated_at)
		VALUES (:id, :category_id, :sku, :name, :brand, :model, :type, :price_usd, :stock_quantity, :specifications, :is_available, :created_at, :updated_at)
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
	query := `SELECT id, category_id, sku, name, brand, model, type, price_usd, stock_quantity, specifications, is_available, created_at, updated_at FROM products WHERE is_available = true ORDER BY created_at DESC`
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
	query := `SELECT id, category_id, sku, name, brand, model, type, price_usd, stock_quantity, specifications, is_available, created_at, updated_at FROM products WHERE id = $1 LIMIT 1`
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
	query := `SELECT id, category_id, sku, name, brand, model, type, price_usd, stock_quantity, specifications, is_available, created_at, updated_at FROM products WHERE type = $1 AND is_available = true`
	err := r.db.SelectContext(ctx, &products, query, pType)
	if err != nil {
		return nil, fmt.Errorf("failed to get products by type: %w", err)
	}
	return products, nil
}
