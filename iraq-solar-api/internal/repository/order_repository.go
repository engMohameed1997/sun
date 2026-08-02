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
	CancelExpiredPendingOrders(ctx context.Context, expiryHours int) (int64, error)
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

	// 1. Lock product rows FOR UPDATE and verify stock reservation availability
	for _, item := range items {
		var stockQty, reservedQty int
		var isAvailable bool
		lockQuery := `SELECT stock_quantity, reserved_quantity, is_available FROM products WHERE id = $1 AND deleted_at IS NULL FOR UPDATE`
		err := tx.QueryRowContext(ctx, lockQuery, item.ProductID).Scan(&stockQty, &reservedQty, &isAvailable)
		if err != nil {
			return fmt.Errorf("failed to lock product %s: %w", item.ProductID, err)
		}

		if !isAvailable {
			return fmt.Errorf("المنتج غير متاح حالياً للطلب")
		}

		availableQty := stockQty - reservedQty
		if availableQty < item.Quantity {
			return fmt.Errorf("الكمية المتاحة في المخزون (%d) لا تكفي للكمية المطلوبة (%d)", availableQty, item.Quantity)
		}

		// 2. Increment reserved_quantity
		reserveQuery := `UPDATE products SET reserved_quantity = reserved_quantity + $1, updated_at = NOW() WHERE id = $2`
		if _, err := tx.ExecContext(ctx, reserveQuery, item.Quantity, item.ProductID); err != nil {
			return fmt.Errorf("failed to reserve product stock: %w", err)
		}
	}

	// 3. Insert order
	orderQuery := `
		INSERT INTO orders (id, user_id, status, total_amount_usd, shipping_address, payment_method, payment_status, created_at, updated_at)
		VALUES (:id, :user_id, :status, :total_amount_usd, :shipping_address, :payment_method, :payment_status, :created_at, :updated_at)
	`
	_, err = tx.NamedExecContext(ctx, orderQuery, order)
	if err != nil {
		return fmt.Errorf("failed to insert order: %w", err)
	}

	// 4. Insert order items
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

	// 5. Create initial order status history
	historyQuery := `INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, notes) VALUES ($1, NULL, $2, $3, $4)`
	notes := "تم إنشاء الطلب وحجز المخزون"
	if _, err := tx.ExecContext(ctx, historyQuery, order.ID, string(order.Status), order.UserID, notes); err != nil {
		return fmt.Errorf("failed to record order status history: %w", err)
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

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	var currentStatus string
	err = tx.QueryRowContext(ctx, "SELECT status FROM orders WHERE id = $1 FOR UPDATE", id).Scan(&currentStatus)
	if err != nil {
		return fmt.Errorf("order not found: %w", err)
	}

	if currentStatus == string(status) {
		return nil
	}

	// Fetch order items to update stock reservation
	var items []domain.OrderItem
	err = tx.SelectContext(ctx, &items, "SELECT product_id, quantity FROM order_items WHERE order_id = $1", id)
	if err != nil {
		return fmt.Errorf("failed to fetch order items: %w", err)
	}

	// Update stock based on transition
	if status == domain.StatusCompleted {
		for _, item := range items {
			// Deduct from actual stock_quantity and release reserved_quantity
			_, _ = tx.ExecContext(ctx, `UPDATE products SET stock_quantity = GREATEST(0, stock_quantity - $1), reserved_quantity = GREATEST(0, reserved_quantity - $1), updated_at = NOW() WHERE id = $2`, item.Quantity, item.ProductID)
		}
	} else if status == domain.StatusCancelled {
		for _, item := range items {
			// Release reserved_quantity
			_, _ = tx.ExecContext(ctx, `UPDATE products SET reserved_quantity = GREATEST(0, reserved_quantity - $1), updated_at = NOW() WHERE id = $2`, item.Quantity, item.ProductID)
		}
	}

	// Update order status
	_, err = tx.ExecContext(ctx, "UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", status, id)
	if err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}

	// Insert status history
	_, err = tx.ExecContext(ctx, `INSERT INTO order_status_history (order_id, from_status, to_status, notes) VALUES ($1, $2, $3, $4)`, id, currentStatus, string(status), "تغيير حالة الطلب")
	if err != nil {
		return fmt.Errorf("failed to record status history: %w", err)
	}

	return tx.Commit()
}

func (r *postgresOrderRepository) Cancel(ctx context.Context, id uuid.UUID) error {
	return r.UpdateStatus(ctx, id, domain.StatusCancelled)
}

func (r *postgresOrderRepository) CancelExpiredPendingOrders(ctx context.Context, expiryHours int) (int64, error) {
	if r.db == nil {
		return 0, nil
	}

	var expiredIDs []uuid.UUID
	query := `
		SELECT id FROM orders
		WHERE status = 'pending' AND created_at < NOW() - ($1 || ' hours')::interval
	`
	err := r.db.SelectContext(ctx, &expiredIDs, query, expiryHours)
	if err != nil {
		return 0, fmt.Errorf("failed to fetch expired pending orders: %w", err)
	}

	var count int64
	for _, id := range expiredIDs {
		if err := r.UpdateStatus(ctx, id, domain.StatusCancelled); err == nil {
			count++
		}
	}

	return count, nil
}

