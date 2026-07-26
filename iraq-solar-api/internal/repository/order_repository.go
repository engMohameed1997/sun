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

type OrderRepository interface {
	Create(ctx context.Context, order *domain.Order, items []domain.OrderItem) error
	FindByID(ctx context.Context, id uuid.UUID) (*domain.Order, error)
	FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.Order, error)
	UpdateStatus(ctx context.Context, id uuid.UUID, status domain.OrderStatus) error
	Cancel(ctx context.Context, id uuid.UUID) error
}

type postgresOrderRepository struct {
	db *sqlx.DB
}

func NewOrderRepository(db *sqlx.DB) OrderRepository {
	return &postgresOrderRepository{db: db}
}

func (r *postgresOrderRepository) Create(ctx context.Context, order *domain.Order, items []domain.OrderItem) error {
	if r.db == nil {
		return nil
	}

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback()

	orderQuery := `
		INSERT INTO orders (id, user_id, status, total_amount_usd, shipping_address, payment_method, payment_status, created_at, updated_at)
		VALUES (:id, :user_id, :status, :total_amount_usd, :shipping_address, :payment_method, :payment_status, :created_at, :updated_at)
	`
	_, err = tx.NamedExecContext(ctx, orderQuery, order)
	if err != nil {
		return fmt.Errorf("failed to insert order: %w", err)
	}

	itemQuery := `
		INSERT INTO order_items (id, order_id, product_id, quantity, unit_price_usd, total_price_usd)
		VALUES (:id, :order_id, :product_id, :quantity, :unit_price_usd, :total_price_usd)
	`
	for _, item := range items {
		_, err = tx.NamedExecContext(ctx, itemQuery, item)
		if err != nil {
			return fmt.Errorf("failed to insert order item: %w", err)
		}
	}

	return tx.Commit()
}

func (r *postgresOrderRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.Order, error) {
	if r.db == nil {
		return nil, nil
	}

	var order domain.Order
	query := `SELECT id, user_id, status, total_amount_usd, shipping_address, payment_method, payment_status, created_at, updated_at FROM orders WHERE id = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &order, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get order: %w", err)
	}

	var items []domain.OrderItem
	itemsQuery := `SELECT id, order_id, product_id, quantity, unit_price_usd, total_price_usd FROM order_items WHERE order_id = $1`
	_ = r.db.SelectContext(ctx, &items, itemsQuery, id)
	order.Items = items

	return &order, nil
}

func (r *postgresOrderRepository) FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.Order, error) {
	if r.db == nil {
		return nil, nil
	}

	var orders []domain.Order
	query := `SELECT id, user_id, status, total_amount_usd, shipping_address, payment_method, payment_status, created_at, updated_at FROM orders WHERE user_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &orders, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to list user orders: %w", err)
	}
	return orders, nil
}

func (r *postgresOrderRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status domain.OrderStatus) error {
	if r.db == nil {
		return nil
	}

	query := `UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	_, err := r.db.ExecContext(ctx, query, status, id)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}
	return nil
}

func (r *postgresOrderRepository) Cancel(ctx context.Context, id uuid.UUID) error {
	return r.UpdateStatus(ctx, id, domain.StatusCancelled)
}
