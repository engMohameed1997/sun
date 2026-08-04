package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

// OrderRepository defines all persistence operations for orders.
type OrderRepository interface {
	Create(ctx context.Context, order *domain.Order, items []domain.OrderItem) error
	FindByID(ctx context.Context, id uuid.UUID) (*domain.Order, error)
	FindFullByID(ctx context.Context, id uuid.UUID) (*domain.OrderFull, error)
	FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.Order, error)
	FindFullByUserID(ctx context.Context, userID uuid.UUID) ([]domain.OrderFull, error)
	FindAllAdmin(ctx context.Context, filters domain.AdminOrderFilters) (*domain.AdminOrdersResponse, error)
	GetStatusHistory(ctx context.Context, orderID uuid.UUID) ([]domain.OrderStatusHistory, error)
	UpdateStatus(ctx context.Context, id uuid.UUID, status domain.OrderStatus, notes string, changedBy *uuid.UUID) error
	Cancel(ctx context.Context, id uuid.UUID) error
	CancelExpiredPendingOrders(ctx context.Context, expiryHours int) (int64, error)
}

type postgresOrderRepository struct {
	db *sqlx.DB
}

func NewOrderRepository(db *sqlx.DB) OrderRepository {
	return &postgresOrderRepository{db: db}
}

// orderFullSelectSQL is the common SELECT for the v_orders_full view.
const orderFullSelectSQL = `
	SELECT
		id, user_id, store_id, branch_id,
		status, total_amount_iqd, shipping_address,
		payment_method, payment_status,
		created_at, updated_at,
		customer_name, customer_phone,
		customer_governorate, customer_city,
		store_name, store_slug, store_logo_url, store_phone,
		branch_name, branch_address, branch_city, branch_phone,
		branch_governorate_ar, branch_governorate_en
	FROM v_orders_full
`

// ─── Create ────────────────────────────────────────────────────────────────

func (r *postgresOrderRepository) Create(ctx context.Context, order *domain.Order, items []domain.OrderItem) error {
	if r.db == nil {
		return nil
	}

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback()

	// 1. Lock product rows FOR UPDATE and verify stock
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
		// Reserve stock
		reserveQuery := `UPDATE products SET reserved_quantity = reserved_quantity + $1, updated_at = NOW() WHERE id = $2`
		if _, err := tx.ExecContext(ctx, reserveQuery, item.Quantity, item.ProductID); err != nil {
			return fmt.Errorf("failed to reserve product stock: %w", err)
		}
	}

	// 2. Insert order (now includes store_id and branch_id)
	orderQuery := `
		INSERT INTO orders (id, user_id, store_id, branch_id, status, total_amount_iqd, shipping_address, payment_method, payment_status, created_at, updated_at)
		VALUES (:id, :user_id, :store_id, :branch_id, :status, :total_amount_iqd, :shipping_address, :payment_method, :payment_status, :created_at, :updated_at)
	`
	if _, err = tx.NamedExecContext(ctx, orderQuery, order); err != nil {
		return fmt.Errorf("failed to insert order: %w", err)
	}

	// 3. Insert order items (includes store_id and branch_id per item)
	itemQuery := `
		INSERT INTO order_items (id, order_id, product_id, store_id, branch_id, quantity, unit_price_iqd, total_price_iqd)
		VALUES (:id, :order_id, :product_id, :store_id, :branch_id, :quantity, :unit_price_iqd, :total_price_iqd)
	`
	for _, item := range items {
		if _, err = tx.NamedExecContext(ctx, itemQuery, item); err != nil {
			return fmt.Errorf("failed to insert order item: %w", err)
		}
	}

	// 4. Create initial order status history
	historyQuery := `INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, notes) VALUES ($1, NULL, $2, $3, $4)`
	notes := "تم إنشاء الطلب وحجز المخزون"
	if _, err := tx.ExecContext(ctx, historyQuery, order.ID, string(order.Status), order.UserID, notes); err != nil {
		return fmt.Errorf("failed to record order status history: %w", err)
	}

	return tx.Commit()
}

// ─── FindByID (simple) ─────────────────────────────────────────────────────

func (r *postgresOrderRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.Order, error) {
	if r.db == nil {
		return nil, nil
	}
	var order domain.Order
	query := `SELECT id, user_id, store_id, branch_id, status, total_amount_iqd, shipping_address, payment_method, payment_status, created_at, updated_at FROM orders WHERE id = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &order, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get order: %w", err)
	}
	var items []domain.OrderItem
	_ = r.db.SelectContext(ctx, &items, `SELECT id, order_id, product_id, store_id, branch_id, quantity, unit_price_iqd, total_price_iqd FROM order_items WHERE order_id = $1`, id)
	order.Items = items
	return &order, nil
}

// ─── FindFullByID (with all JOINs) ─────────────────────────────────────────

func (r *postgresOrderRepository) FindFullByID(ctx context.Context, id uuid.UUID) (*domain.OrderFull, error) {
	if r.db == nil {
		return nil, nil
	}
	var order domain.OrderFull
	query := orderFullSelectSQL + ` WHERE id = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &order, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get full order: %w", err)
	}

	// Fetch full items with product names
	itemsQuery := `
		SELECT
			oi.id, oi.order_id, oi.product_id, oi.store_id, oi.branch_id,
			oi.quantity, oi.unit_price_iqd, oi.total_price_iqd,
			p.name AS product_name, p.sku AS product_sku,
			COALESCE(p.images[1], NULL) AS product_image
		FROM order_items oi
		LEFT JOIN products p ON oi.product_id = p.id
		WHERE oi.order_id = $1
	`
	var items []domain.OrderItemFull
	_ = r.db.SelectContext(ctx, &items, itemsQuery, id)
	order.Items = items

	// Fetch status history
	order.StatusHistory, _ = r.GetStatusHistory(ctx, id)

	return &order, nil
}

// ─── FindByUserID ──────────────────────────────────────────────────────────

func (r *postgresOrderRepository) FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.Order, error) {
	if r.db == nil {
		return nil, nil
	}
	var orders []domain.Order
	query := `SELECT id, user_id, store_id, branch_id, status, total_amount_iqd, shipping_address, payment_method, payment_status, created_at, updated_at FROM orders WHERE user_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &orders, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to list user orders: %w", err)
	}
	return orders, nil
}

// ─── FindFullByUserID (with all JOINs) ─────────────────────────────────────

func (r *postgresOrderRepository) FindFullByUserID(ctx context.Context, userID uuid.UUID) ([]domain.OrderFull, error) {
	if r.db == nil {
		return []domain.OrderFull{}, nil
	}
	orders := []domain.OrderFull{}
	query := orderFullSelectSQL + ` WHERE user_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &orders, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to list user full orders: %w", err)
	}

	if orders == nil {
		orders = []domain.OrderFull{}
	}

	// Fetch items for each order
	for i := range orders {
		items := []domain.OrderItemFull{}
		itemsQuery := `
			SELECT
				oi.id, oi.order_id, oi.product_id, oi.store_id, oi.branch_id,
				oi.quantity, oi.unit_price_iqd, oi.total_price_iqd,
				p.name AS product_name, p.sku AS product_sku,
				COALESCE(p.images[1], NULL) AS product_image
			FROM order_items oi
			LEFT JOIN products p ON oi.product_id = p.id
			WHERE oi.order_id = $1
			`
		_ = r.db.SelectContext(ctx, &items, itemsQuery, orders[i].ID)
		orders[i].Items = items
	}

	return orders, nil
}

// ─── FindAllAdmin (paginated, filtered) ────────────────────────────────────

func (r *postgresOrderRepository) FindAllAdmin(ctx context.Context, filters domain.AdminOrderFilters) (*domain.AdminOrdersResponse, error) {
	if r.db == nil {
		return &domain.AdminOrdersResponse{Orders: []domain.OrderFull{}, Page: 1, Limit: 20}, nil
	}

	// Defaults
	page := filters.Page
	if page < 1 {
		page = 1
	}
	limit := filters.Limit
	if limit < 1 || limit > 100 {
		limit = 20
	}
	offset := (page - 1) * limit

	// Build WHERE clause dynamically
	conditions := []string{}
	args := []any{}
	argIdx := 1

	if filters.Status != "" {
		conditions = append(conditions, fmt.Sprintf("status = $%d", argIdx))
		args = append(args, filters.Status)
		argIdx++
	}
	if filters.StoreID != "" {
		conditions = append(conditions, fmt.Sprintf("store_id = $%d", argIdx))
		args = append(args, filters.StoreID)
		argIdx++
	}
	if filters.BranchID != "" {
		conditions = append(conditions, fmt.Sprintf("branch_id = $%d", argIdx))
		args = append(args, filters.BranchID)
		argIdx++
	}
	if filters.Search != "" {
		// Search by customer name, phone, or order ID prefix
		searchPattern := "%" + strings.ToLower(filters.Search) + "%"
		conditions = append(conditions, fmt.Sprintf(
			`(LOWER(customer_name) LIKE $%d OR customer_phone LIKE $%d OR LOWER(id::text) LIKE $%d)`,
			argIdx, argIdx+1, argIdx+2,
		))
		args = append(args, searchPattern, searchPattern, searchPattern)
		argIdx += 3
	}
	if filters.FromDate != "" {
		conditions = append(conditions, fmt.Sprintf("created_at >= $%d", argIdx))
		args = append(args, filters.FromDate)
		argIdx++
	}
	if filters.ToDate != "" {
		conditions = append(conditions, fmt.Sprintf("created_at <= $%d", argIdx))
		args = append(args, filters.ToDate)
		argIdx++
	}

	whereClause := ""
	if len(conditions) > 0 {
		whereClause = " WHERE " + strings.Join(conditions, " AND ")
	}

	// Count total
	countQuery := `SELECT COUNT(*) FROM v_orders_full` + whereClause
	var total int
	if err := r.db.QueryRowContext(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, fmt.Errorf("failed to count orders: %w", err)
	}

	// Fetch page
	dataQuery := orderFullSelectSQL + whereClause +
		fmt.Sprintf(` ORDER BY created_at DESC LIMIT $%d OFFSET $%d`, argIdx, argIdx+1)
	args = append(args, limit, offset)

	var orders []domain.OrderFull
	if err := r.db.SelectContext(ctx, &orders, dataQuery, args...); err != nil {
		return nil, fmt.Errorf("failed to list admin orders: %w", err)
	}

	totalPages := (total + limit - 1) / limit

	return &domain.AdminOrdersResponse{
		Orders:     orders,
		Total:      total,
		Page:       page,
		Limit:      limit,
		TotalPages: totalPages,
	}, nil
}

// ─── GetStatusHistory ──────────────────────────────────────────────────────

func (r *postgresOrderRepository) GetStatusHistory(ctx context.Context, orderID uuid.UUID) ([]domain.OrderStatusHistory, error) {
	if r.db == nil {
		return nil, nil
	}
	query := `
		SELECT
			h.id, h.order_id, h.from_status, h.to_status, h.changed_by, h.notes, h.created_at,
			u.full_name AS changed_by_name
		FROM order_status_history h
		LEFT JOIN users u ON h.changed_by = u.id
		WHERE h.order_id = $1
		ORDER BY h.created_at ASC
	`
	var history []domain.OrderStatusHistory
	if err := r.db.SelectContext(ctx, &history, query, orderID); err != nil {
		return nil, fmt.Errorf("failed to fetch status history: %w", err)
	}
	return history, nil
}

// ─── UpdateStatus ──────────────────────────────────────────────────────────

func (r *postgresOrderRepository) UpdateStatus(ctx context.Context, id uuid.UUID, status domain.OrderStatus, notes string, changedBy *uuid.UUID) error {
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
	if err = tx.SelectContext(ctx, &items, "SELECT product_id, quantity FROM order_items WHERE order_id = $1", id); err != nil {
		return fmt.Errorf("failed to fetch order items: %w", err)
	}

	// Update stock based on transition
	if status == domain.StatusCompleted {
		for _, item := range items {
			_, _ = tx.ExecContext(ctx,
				`UPDATE products SET stock_quantity = GREATEST(0, stock_quantity - $1), reserved_quantity = GREATEST(0, reserved_quantity - $1), updated_at = NOW() WHERE id = $2`,
				item.Quantity, item.ProductID)
		}
	} else if status == domain.StatusCancelled {
		for _, item := range items {
			_, _ = tx.ExecContext(ctx,
				`UPDATE products SET reserved_quantity = GREATEST(0, reserved_quantity - $1), updated_at = NOW() WHERE id = $2`,
				item.Quantity, item.ProductID)
		}
	}

	// Update order status
	if _, err = tx.ExecContext(ctx, "UPDATE orders SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2", status, id); err != nil {
		return fmt.Errorf("failed to update order status: %w", err)
	}

	// Record history
	historyNotes := notes
	if historyNotes == "" {
		historyNotes = "تغيير حالة الطلب"
	}
	if _, err = tx.ExecContext(ctx,
		`INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, notes) VALUES ($1, $2, $3, $4, $5)`,
		id, currentStatus, string(status), changedBy, historyNotes,
	); err != nil {
		return fmt.Errorf("failed to record status history: %w", err)
	}

	return tx.Commit()
}

// ─── Cancel ────────────────────────────────────────────────────────────────

func (r *postgresOrderRepository) Cancel(ctx context.Context, id uuid.UUID) error {
	return r.UpdateStatus(ctx, id, domain.StatusCancelled, "إلغاء الطلب", nil)
}

// ─── CancelExpiredPendingOrders ─────────────────────────────────────────────

func (r *postgresOrderRepository) CancelExpiredPendingOrders(ctx context.Context, expiryHours int) (int64, error) {
	if r.db == nil {
		return 0, nil
	}
	var expiredIDs []uuid.UUID
	query := `SELECT id FROM orders WHERE status = 'pending' AND created_at < NOW() - ($1 || ' hours')::interval`
	if err := r.db.SelectContext(ctx, &expiredIDs, query, expiryHours); err != nil {
		return 0, fmt.Errorf("failed to fetch expired pending orders: %w", err)
	}
	var count int64
	for _, id := range expiredIDs {
		if err := r.UpdateStatus(ctx, id, domain.StatusCancelled, "إلغاء تلقائي بسبب انتهاء المهلة", nil); err == nil {
			count++
		}
	}
	return count, nil
}
