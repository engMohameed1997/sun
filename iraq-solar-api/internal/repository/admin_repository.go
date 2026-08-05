package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type RevenueDataPoint struct {
	Date    string  `db:"date" json:"date"`
	Revenue float64 `db:"revenue" json:"revenue"`
}

type StatusCount struct {
	Status string `db:"status" json:"status"`
	Count  int    `db:"count" json:"count"`
}

type TopProduct struct {
	ID      uuid.UUID `db:"id" json:"id"`
	Name    string    `db:"name" json:"name"`
	Sales   int       `db:"sales" json:"sales"`
	Revenue float64   `db:"revenue" json:"revenue"`
}

type OrderWithUser struct {
	ID              uuid.UUID          `db:"id" json:"id"`
	UserID          uuid.UUID          `db:"user_id" json:"user_id"`
	Status          string             `db:"status" json:"status"`
	TotalAmountIQD  float64            `db:"total_amount_iqd" json:"total_amount_iqd"`
	ShippingAddress string             `db:"shipping_address" json:"shipping_address"`
	PaymentMethod   string             `db:"payment_method" json:"payment_method"`
	PaymentStatus   string             `db:"payment_status" json:"payment_status"`
	CreatedAt       time.Time          `db:"created_at" json:"created_at"`
	UpdatedAt       time.Time          `db:"updated_at" json:"updated_at"`
	CustomerName    string             `db:"customer_name" json:"customer_name"`
	CustomerPhone   string             `db:"customer_phone" json:"customer_phone"`
	Items           []domain.OrderItem `json:"items,omitempty"`
}

type AuditLog struct {
	ID         uuid.UUID       `db:"id" json:"id"`
	UserID     *uuid.UUID      `db:"user_id" json:"user_id"`
	Action     string          `db:"action" json:"action"`
	EntityName string          `db:"entity_name" json:"entity_name"`
	EntityID   string          `db:"entity_id" json:"entity_id"`
	Payload    json.RawMessage `db:"payload" json:"payload"`
	CreatedAt  time.Time       `db:"created_at" json:"created_at"`
}

type DashboardStatsResult struct {
	TotalOrders       int     `json:"total_orders"`
	TotalRevenue      float64 `json:"total_revenue_iqd"`
	TotalUsers        int     `json:"total_users"`
	TotalProducts     int     `json:"total_products"`
	PendingOrders     int     `json:"pending_orders"`
	NewUsersThisMonth int     `json:"new_users_this_month"`
	TotalStores       int     `json:"total_stores"`
	ActiveInstallers  int     `json:"active_installers"`
}

type AdminRepository struct {
	db       *sqlx.DB
	mu       sync.RWMutex
	memUsers []domain.User
}

func NewAdminRepository(db *sqlx.DB) *AdminRepository {
	return &AdminRepository{
		db:       db,
		memUsers: make([]domain.User, 0),
	}
}

// ─── Users & Stores Management ───

func (r *AdminRepository) ListUsers(ctx context.Context, role, status, governorate, search string, page, perPage int) ([]domain.User, int, error) {
	if r.db == nil {
		r.mu.RLock()
		defer r.mu.RUnlock()

		filtered := make([]domain.User, 0)
		for _, u := range r.memUsers {
			if role != "" && string(u.Role) != role {
				continue
			}
			if status == "active" && !u.IsActive {
				continue
			}
			if status == "inactive" && u.IsActive {
				continue
			}
			if governorate != "" && u.Governorate != governorate {
				continue
			}
			if search != "" && !strings.Contains(strings.ToLower(u.FullName), strings.ToLower(search)) && !strings.Contains(strings.ToLower(u.Phone), strings.ToLower(search)) {
				continue
			}
			filtered = append(filtered, u)
		}
		return filtered, len(filtered), nil
	}

	offset := (page - 1) * perPage
	where := []string{"deleted_at IS NULL"}
	args := []interface{}{}
	argIdx := 1

	if role != "" {
		where = append(where, fmt.Sprintf("role = $%d", argIdx))
		args = append(args, role)
		argIdx++
	}
	if status == "active" {
		where = append(where, fmt.Sprintf("is_active = $%d", argIdx))
		args = append(args, true)
		argIdx++
	} else if status == "inactive" {
		where = append(where, fmt.Sprintf("is_active = $%d", argIdx))
		args = append(args, false)
		argIdx++
	}
	if governorate != "" {
		where = append(where, fmt.Sprintf("governorate = $%d", argIdx))
		args = append(args, governorate)
		argIdx++
	}
	if search != "" {
		where = append(where, fmt.Sprintf("(full_name ILIKE $%d OR phone ILIKE $%d)", argIdx, argIdx))
		args = append(args, "%"+search+"%")
		argIdx++
	}

	whereClause := strings.Join(where, " AND ")

	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM users WHERE %s", whereClause)
	var total int
	r.db.GetContext(ctx, &total, countQuery, args...)

	query := fmt.Sprintf(`SELECT id, full_name, COALESCE(phone, '') AS phone, role, COALESCE(governorate, '') AS governorate, COALESCE(city, '') AS city, is_active, created_at, updated_at 
		FROM users WHERE %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)
	args = append(args, perPage, offset)

	var users []domain.User
	err := r.db.SelectContext(ctx, &users, query, args...)
	return users, total, err
}

func (r *AdminRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	r.mu.RLock()
	for _, u := range r.memUsers {
		if u.ID == id {
			r.mu.RUnlock()
			return &u, nil
		}
	}
	r.mu.RUnlock()

	if r.db == nil {
		return nil, nil
	}
	var user domain.User
	err := r.db.GetContext(ctx, &user, `SELECT id, full_name, COALESCE(phone, '') AS phone, role, COALESCE(governorate, '') AS governorate, COALESCE(city, '') AS city, is_active, created_at, updated_at 
		FROM users WHERE id = $1 AND deleted_at IS NULL`, id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &user, err
}

func (r *AdminRepository) CreateUserByAdmin(ctx context.Context, user *domain.User) error {
	r.mu.Lock()
	r.memUsers = append([]domain.User{*user}, r.memUsers...)
	r.mu.Unlock()

	if r.db == nil {
		return nil
	}
	query := `INSERT INTO users (id, full_name, phone, password_hash, role, governorate, city, is_active, created_at, updated_at)
		VALUES ($1, $2, NULLIF($3, ''), $4, $5, $6, $7, $8, $9, $10)`
	_, err := r.db.ExecContext(ctx, query, user.ID, user.FullName, user.Phone,
		user.PasswordHash, user.Role, user.Governorate, user.City, user.IsActive, user.CreatedAt, user.UpdatedAt)
	return err
}

func (r *AdminRepository) UpdateUser(ctx context.Context, id uuid.UUID, fullName, phone, governorate, city string, role domain.Role) error {
	r.mu.Lock()
	for i, u := range r.memUsers {
		if u.ID == id {
			r.memUsers[i].FullName = fullName
			r.memUsers[i].Phone = phone
			r.memUsers[i].Governorate = governorate
			r.memUsers[i].City = city
			r.memUsers[i].Role = role
			break
		}
	}
	r.mu.Unlock()

	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, `UPDATE users SET full_name=$1, phone=$2, governorate=$3, city=$4, role=$5, updated_at=NOW() WHERE id=$6`,
		fullName, phone, governorate, city, role, id)
	return err
}

func (r *AdminRepository) ToggleUserActive(ctx context.Context, id uuid.UUID, isActive bool) error {
	r.mu.Lock()
	for i, u := range r.memUsers {
		if u.ID == id {
			r.memUsers[i].IsActive = isActive
			break
		}
	}
	r.mu.Unlock()

	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE users SET is_active=$1, updated_at=NOW() WHERE id=$2", isActive, id)
	return err
}

func (r *AdminRepository) SoftDeleteUser(ctx context.Context, id uuid.UUID) error {
	r.mu.Lock()
	newMem := make([]domain.User, 0)
	for _, u := range r.memUsers {
		if u.ID != id {
			newMem = append(newMem, u)
		}
	}
	r.memUsers = newMem
	r.mu.Unlock()

	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE users SET deleted_at=NOW(), is_active=false WHERE id=$1", id)
	return err
}

// ─── Dashboard Stats ───

func (r *AdminRepository) DashboardStats(ctx context.Context) (*DashboardStatsResult, error) {
	r.mu.RLock()
	totalStores := 0
	for _, u := range r.memUsers {
		if u.Role == domain.RoleMerchant && u.IsActive {
			totalStores++
		}
	}
	r.mu.RUnlock()

	if r.db == nil {
		return &DashboardStatsResult{
			TotalOrders:       0,
			TotalRevenue:      0.0,
			TotalUsers:        len(r.memUsers),
			TotalProducts:     0,
			PendingOrders:     0,
			NewUsersThisMonth: 0,
			TotalStores:       totalStores,
			ActiveInstallers:  0,
		}, nil
	}

	stats := &DashboardStatsResult{}
	r.db.GetContext(ctx, &stats.TotalOrders, "SELECT COUNT(*) FROM orders")
	r.db.GetContext(ctx, &stats.TotalRevenue, "SELECT COALESCE(SUM(total_amount_iqd),0) FROM orders WHERE status IN ('completed','confirmed','processing')")
	r.db.GetContext(ctx, &stats.TotalUsers, "SELECT COUNT(*) FROM users WHERE deleted_at IS NULL")
	r.db.GetContext(ctx, &stats.TotalProducts, "SELECT COUNT(*) FROM products")
	r.db.GetContext(ctx, &stats.PendingOrders, "SELECT COUNT(*) FROM orders WHERE status='pending'")
	r.db.GetContext(ctx, &stats.NewUsersThisMonth, "SELECT COUNT(*) FROM users WHERE created_at >= date_trunc('month', CURRENT_DATE) AND deleted_at IS NULL")
	r.db.GetContext(ctx, &stats.TotalStores, "SELECT COUNT(*) FROM users WHERE role='merchant' AND deleted_at IS NULL AND is_active=true")
	r.db.GetContext(ctx, &stats.ActiveInstallers, "SELECT COUNT(*) FROM users WHERE role IN ('installer','engineer') AND deleted_at IS NULL AND is_active=true")
	return stats, nil
}

func (r *AdminRepository) RevenueByPeriod(ctx context.Context, days int) ([]RevenueDataPoint, error) {
	if r.db == nil {
		return []RevenueDataPoint{
			{Date: "2026-07-20", Revenue: 15400},
			{Date: "2026-07-21", Revenue: 22100},
			{Date: "2026-07-22", Revenue: 18900},
			{Date: "2026-07-23", Revenue: 31000},
			{Date: "2026-07-24", Revenue: 27500},
			{Date: "2026-07-25", Revenue: 34200},
			{Date: "2026-07-26", Revenue: 36300},
		}, nil
	}
	query := `SELECT TO_CHAR(created_at::date, 'YYYY-MM-DD') as date, COALESCE(SUM(total_amount_iqd),0) as revenue
		FROM orders WHERE created_at >= NOW() - INTERVAL '1 day' * $1 AND status != 'cancelled'
		GROUP BY created_at::date ORDER BY created_at::date ASC`
	var data []RevenueDataPoint
	err := r.db.SelectContext(ctx, &data, query, days)
	return data, err
}

func (r *AdminRepository) OrdersByStatus(ctx context.Context) ([]StatusCount, error) {
	if r.db == nil {
		return []StatusCount{
			{Status: "pending", Count: 12},
			{Status: "confirmed", Count: 45},
			{Status: "processing", Count: 28},
			{Status: "completed", Count: 52},
			{Status: "cancelled", Count: 5},
		}, nil
	}
	var data []StatusCount
	err := r.db.SelectContext(ctx, &data, "SELECT status, COUNT(*) as count FROM orders GROUP BY status ORDER BY count DESC")
	return data, err
}

func (r *AdminRepository) TopProducts(ctx context.Context, limit int) ([]TopProduct, error) {
	if r.db == nil {
		return []TopProduct{
			{ID: uuid.New(), Name: "لوح طاقة شمسية LONGi 550W", Sales: 150, Revenue: 17250},
			{ID: uuid.New(), Name: "انفيرتر هجين Deye 8kW", Sales: 25, Revenue: 31250},
			{ID: uuid.New(), Name: "بطارية ليثيوم Felicity 10.2kWh", Sales: 30, Revenue: 43500},
		}, nil
	}
	query := `SELECT p.id, p.name, COALESCE(SUM(oi.quantity),0) as sales, COALESCE(SUM(oi.total_price_iqd),0) as revenue
		FROM products p LEFT JOIN order_items oi ON p.id = oi.product_id
		GROUP BY p.id, p.name ORDER BY sales DESC LIMIT $1`
	var data []TopProduct
	err := r.db.SelectContext(ctx, &data, query, limit)
	return data, err
}

// ─── Orders Management ───

func (r *AdminRepository) ListAllOrders(ctx context.Context, status, search string, page, perPage int) ([]OrderWithUser, int, error) {
	if r.db == nil {
		return []OrderWithUser{}, 0, nil
	}
	offset := (page - 1) * perPage
	where := []string{"1=1"}
	args := []interface{}{}
	argIdx := 1

	if status != "" {
		where = append(where, fmt.Sprintf("o.status = $%d", argIdx))
		args = append(args, status)
		argIdx++
	}
	if search != "" {
		where = append(where, fmt.Sprintf("(u.full_name ILIKE $%d OR o.id::text ILIKE $%d)", argIdx, argIdx))
		args = append(args, "%"+search+"%")
		argIdx++
	}

	whereClause := strings.Join(where, " AND ")
	var total int
	r.db.GetContext(ctx, &total, fmt.Sprintf("SELECT COUNT(*) FROM orders o JOIN users u ON o.user_id=u.id WHERE %s", whereClause), args...)

	query := fmt.Sprintf(`SELECT o.id, o.user_id, o.status, o.total_amount_iqd, o.shipping_address, o.payment_method, 
		o.payment_status, o.created_at, o.updated_at, u.full_name as customer_name, u.phone as customer_phone
		FROM orders o JOIN users u ON o.user_id=u.id WHERE %s ORDER BY o.created_at DESC LIMIT $%d OFFSET $%d`,
		whereClause, argIdx, argIdx+1)
	args = append(args, perPage, offset)

	var orders []OrderWithUser
	err := r.db.SelectContext(ctx, &orders, query, args...)
	return orders, total, err
}

func (r *AdminRepository) GetOrderDetail(ctx context.Context, id uuid.UUID) (*OrderWithUser, []domain.OrderItem, error) {
	if r.db == nil {
		return nil, nil, nil
	}
	var order OrderWithUser
	err := r.db.GetContext(ctx, &order, `SELECT o.id, o.user_id, o.status, o.total_amount_iqd, o.shipping_address, o.payment_method,
		o.payment_status, o.created_at, o.updated_at, u.full_name as customer_name, u.phone as customer_phone
		FROM orders o JOIN users u ON o.user_id=u.id WHERE o.id=$1`, id)
	if err != nil {
		return nil, nil, err
	}

	var items []domain.OrderItem
	r.db.SelectContext(ctx, &items, "SELECT * FROM order_items WHERE order_id=$1", id)
	return &order, items, nil
}

func (r *AdminRepository) UpdateOrderStatus(ctx context.Context, id uuid.UUID, status string) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE orders SET status=$1, updated_at=NOW() WHERE id=$2", status, id)
	return err
}

// ─── Products Management ───

func (r *AdminRepository) ListAllProducts(ctx context.Context, pType, search string, page, perPage int) ([]domain.Product, int, error) {
	if r.db == nil {
		return []domain.Product{}, 0, nil
	}
	offset := (page - 1) * perPage
	where := []string{"p.deleted_at IS NULL"}
	args := []interface{}{}
	argIdx := 1

	if pType != "" {
		where = append(where, fmt.Sprintf("p.type = $%d", argIdx))
		args = append(args, pType)
		argIdx++
	}
	if search != "" {
		where = append(where, fmt.Sprintf("(p.name ILIKE $%d OR p.sku ILIKE $%d OR p.model ILIKE $%d)", argIdx, argIdx, argIdx))
		args = append(args, "%"+search+"%")
		argIdx++
	}

	whereClause := strings.Join(where, " AND ")
	var total int
	r.db.GetContext(ctx, &total, fmt.Sprintf("SELECT COUNT(*) FROM products p WHERE %s", whereClause), args...)

	query := fmt.Sprintf(`SELECT p.id, p.category_id, p.merchant_id, p.store_id, p.branch_id, p.sku, p.name, p.brand_id, b.name AS brand_name, p.model, p.type, p.price_iqd, p.stock_quantity, p.reserved_quantity, p.low_stock_threshold, p.specifications, p.images, p.is_available, p.created_at, p.updated_at, p.deleted_at
		FROM products p LEFT JOIN brands b ON p.brand_id = b.id WHERE %s ORDER BY p.created_at DESC LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)
	args = append(args, perPage, offset)

	var products []domain.Product
	err := r.db.SelectContext(ctx, &products, query, args...)
	return products, total, err
}

func (r *AdminRepository) UpdateProduct(ctx context.Context, p *domain.Product) error {
	if r.db == nil {
		return nil
	}
	query := `UPDATE products SET 
		name = $1, 
		model = $2, 
		price_iqd = $3, 
		stock_quantity = $4, 
		low_stock_threshold = $5,
		is_available = $6, 
		images = $7, 
		specifications = $8,
		category_id = COALESCE($9, category_id),
		brand_id = COALESCE($10, brand_id),
		store_id = COALESCE($11, store_id),
		branch_id = COALESCE($12, branch_id),
		updated_at = NOW() 
		WHERE id = $13 AND deleted_at IS NULL`
	_, err := r.db.ExecContext(ctx, query,
		p.Name, p.Model, p.PriceIQD, p.StockQuantity, p.LowStockThreshold, p.IsAvailable, p.Images, p.Specifications, p.CategoryID, p.BrandID, p.StoreID, p.BranchID, p.ID)
	return err
}

func (r *AdminRepository) DeleteProduct(ctx context.Context, id uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "DELETE FROM products WHERE id=$1", id)
	return err
}

// ─── Audit Logs ───

func (r *AdminRepository) GetAuditLogs(ctx context.Context, action, search string, page, perPage int) ([]AuditLog, int, error) {
	if r.db == nil {
		return []AuditLog{}, 0, nil
	}
	offset := (page - 1) * perPage
	where := []string{"1=1"}
	args := []interface{}{}
	argIdx := 1

	if action != "" {
		where = append(where, fmt.Sprintf("action = $%d", argIdx))
		args = append(args, action)
		argIdx++
	}

	whereClause := strings.Join(where, " AND ")
	var total int
	r.db.GetContext(ctx, &total, fmt.Sprintf("SELECT COUNT(*) FROM audit_logs WHERE %s", whereClause), args...)

	query := fmt.Sprintf("SELECT * FROM audit_logs WHERE %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d", whereClause, argIdx, argIdx+1)
	args = append(args, perPage, offset)

	var logs []AuditLog
	err := r.db.SelectContext(ctx, &logs, query, args...)
	return logs, total, err
}

func (r *AdminRepository) CreateAuditLog(ctx context.Context, userID *uuid.UUID, action, entityName, entityID string, payload interface{}) error {
	if r.db == nil {
		return nil
	}

	sanitizedPayload := sanitizePayload(payload)
	payloadJSON, _ := json.Marshal(sanitizedPayload)
	_, err := r.db.ExecContext(ctx, `INSERT INTO audit_logs (user_id, action, entity_name, entity_id, payload) VALUES ($1,$2,$3,$4,$5)`,
		userID, action, entityName, entityID, payloadJSON)
	return err
}

func sanitizePayload(payload interface{}) interface{} {
	if payload == nil {
		return nil
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return payload
	}
	var temp map[string]interface{}
	if err := json.Unmarshal(data, &temp); err != nil {
		return payload
	}

	sanitized := make(map[string]interface{})
	for k, v := range temp {
		lk := strings.ToLower(k)
		if strings.Contains(lk, "password") || strings.Contains(lk, "token") || strings.Contains(lk, "secret") || strings.Contains(lk, "api_key") {
			sanitized[k] = "[REDACTED]"
		} else {
			sanitized[k] = v
		}
	}
	return sanitized
}

// ─── Store Verification & Delivery Fees ───

func (r *AdminRepository) VerifyStore(ctx context.Context, storeID uuid.UUID, adminID uuid.UUID, isVerified bool) error {
	r.mu.Lock()
	for i, u := range r.memUsers {
		if u.ID == storeID {
			r.memUsers[i].IsVerified = isVerified
			if isVerified {
				now := time.Now()
				r.memUsers[i].VerifiedAt = &now
				r.memUsers[i].VerifiedBy = &adminID
			} else {
				r.memUsers[i].VerifiedAt = nil
				r.memUsers[i].VerifiedBy = nil
			}
			break
		}
	}
	r.mu.Unlock()

	if r.db == nil {
		return nil
	}

	if isVerified {
		query := `UPDATE users SET is_verified = true, verified_at = NOW(), verified_by = $1, updated_at = NOW() WHERE id = $2 AND role = 'merchant'`
		_, err := r.db.ExecContext(ctx, query, adminID, storeID)
		return err
	}
	query := `UPDATE users SET is_verified = false, verified_at = NULL, verified_by = NULL, updated_at = NOW() WHERE id = $1 AND role = 'merchant'`
	_, err := r.db.ExecContext(ctx, query, storeID)
	return err
}

func (r *AdminRepository) GetStoreDeliveryFees(ctx context.Context, storeID uuid.UUID) ([]domain.DeliveryFee, error) {
	if r.db == nil {
		return []domain.DeliveryFee{}, nil
	}
	var fees []domain.DeliveryFee
	query := `
		SELECT df.id, df.merchant_id, df.store_id, df.governorate_id, df.fee_iqd, df.estimated_days, df.is_active,
		       g.name_ar AS governorate_name_ar, g.name_en AS governorate_name_en
		FROM delivery_fees df
		JOIN governorates g ON df.governorate_id = g.id
		WHERE df.store_id = $1
		ORDER BY g.id ASC
	`
	err := r.db.SelectContext(ctx, &fees, query, storeID)
	return fees, err
}

func (r *AdminRepository) UpsertStoreDeliveryFee(ctx context.Context, merchantID uuid.UUID, storeID uuid.UUID, govID int, feeIQD float64, days int, isActive bool) error {
	if r.db == nil {
		return nil
	}
	query := `
		INSERT INTO delivery_fees (merchant_id, store_id, governorate_id, fee_iqd, estimated_days, is_active)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (store_id, governorate_id)
		DO UPDATE SET fee_iqd = EXCLUDED.fee_iqd, estimated_days = EXCLUDED.estimated_days, is_active = EXCLUDED.is_active
	`
	_, err := r.db.ExecContext(ctx, query, merchantID, storeID, govID, feeIQD, days, isActive)
	return err
}

// ─── Merchant Products & Low Stock ───

func (r *AdminRepository) ListMerchantProducts(ctx context.Context, merchantID uuid.UUID, pType, search string, page, perPage int) ([]domain.Product, int, error) {
	if r.db == nil {
		return []domain.Product{}, 0, nil
	}
	offset := (page - 1) * perPage
	where := []string{"p.merchant_id = $1", "p.deleted_at IS NULL"}
	args := []interface{}{merchantID}
	argIdx := 2

	if pType != "" {
		where = append(where, fmt.Sprintf("p.type = $%d", argIdx))
		args = append(args, pType)
		argIdx++
	}
	if search != "" {
		where = append(where, fmt.Sprintf("(p.name ILIKE $%d OR p.sku ILIKE $%d OR p.model ILIKE $%d)", argIdx, argIdx, argIdx))
		args = append(args, "%"+search+"%")
		argIdx++
	}

	whereClause := strings.Join(where, " AND ")
	var total int
	r.db.GetContext(ctx, &total, fmt.Sprintf("SELECT COUNT(*) FROM products p WHERE %s", whereClause), args...)

	query := fmt.Sprintf(`SELECT p.id, p.category_id, p.merchant_id, p.store_id, p.branch_id, p.sku, p.name, p.brand_id, b.name AS brand_name, p.model, p.type, p.price_iqd, p.stock_quantity, p.reserved_quantity, p.low_stock_threshold, p.specifications, p.images, p.is_available, p.created_at, p.updated_at, p.deleted_at
		FROM products p LEFT JOIN brands b ON p.brand_id = b.id WHERE %s ORDER BY p.created_at DESC LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)
	args = append(args, perPage, offset)

	var products []domain.Product
	err := r.db.SelectContext(ctx, &products, query, args...)
	return products, total, err
}

func (r *AdminRepository) GetLowStockProducts(ctx context.Context) ([]domain.Product, error) {
	if r.db == nil {
		return []domain.Product{}, nil
	}
	query := `SELECT p.id, p.category_id, p.merchant_id, p.store_id, p.branch_id, p.sku, p.name, p.brand_id, b.name AS brand_name, p.model, p.type, p.price_iqd, p.stock_quantity, p.reserved_quantity, p.low_stock_threshold, p.specifications, p.images, p.is_available, p.created_at, p.updated_at, p.deleted_at
		FROM products p LEFT JOIN brands b ON p.brand_id = b.id WHERE (p.stock_quantity - p.reserved_quantity) <= p.low_stock_threshold AND p.deleted_at IS NULL ORDER BY (p.stock_quantity - p.reserved_quantity) ASC`
	var products []domain.Product
	err := r.db.SelectContext(ctx, &products, query)
	return products, err
}

func (r *AdminRepository) GetOrderHistory(ctx context.Context, orderID uuid.UUID) ([]domain.OrderStatusHistory, error) {
	if r.db == nil {
		return []domain.OrderStatusHistory{}, nil
	}
	var history []domain.OrderStatusHistory
	query := `SELECT id, order_id, from_status, to_status, changed_by, notes, created_at FROM order_status_history WHERE order_id = $1 ORDER BY created_at ASC`
	err := r.db.SelectContext(ctx, &history, query, orderID)
	return history, err
}

func (r *AdminRepository) RecordOrderStatusHistory(ctx context.Context, orderID uuid.UUID, fromStatus, toStatus string, changedBy *uuid.UUID, notes string) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO order_status_history (order_id, from_status, to_status, changed_by, notes) VALUES ($1, $2, $3, $4, $5)`
	_, err := r.db.ExecContext(ctx, query, orderID, fromStatus, toStatus, changedBy, notes)
	return err
}

// ─── System Settings ───

func (r *AdminRepository) GetSettings(ctx context.Context) ([]domain.SystemSetting, error) {
	if r.db == nil {
		return []domain.SystemSetting{}, nil
	}
	var settings []domain.SystemSetting
	err := r.db.SelectContext(ctx, &settings, "SELECT key, value, updated_at FROM system_settings ORDER BY key")
	return settings, err
}

func (r *AdminRepository) UpsertSetting(ctx context.Context, key, value string) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, `INSERT INTO system_settings (key, value, updated_at) VALUES ($1,$2,NOW()) 
		ON CONFLICT (key) DO UPDATE SET value=EXCLUDED.value, updated_at=NOW()`, key, value)
	return err
}
