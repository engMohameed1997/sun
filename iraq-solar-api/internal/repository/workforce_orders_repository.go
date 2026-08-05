package repository

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
)

const serviceOrderSelectColumns = `
	o.id, o.order_number, o.customer_id, o.order_type, o.description, o.system_size_kw,
	o.governorate_id, o.district_id, o.address, o.lat, o.lng, o.preferred_date, o.status,
	o.priority, o.calculator_result, o.assigned_technician_id, o.dispatch_mode,
	o.created_at, o.updated_at, o.completed_at,
	u.full_name AS customer_name, u.phone AS customer_phone,
	g.name_ar AS governorate_name, d.name_ar AS district_name,
	t.full_name AS technician_name`

const serviceOrderFromClause = `
	FROM service_orders o
	LEFT JOIN users u ON u.id = o.customer_id
	LEFT JOIN governorates g ON g.id = o.governorate_id
	LEFT JOIN districts d ON d.id = o.district_id
	LEFT JOIN technicians t ON t.id = o.assigned_technician_id`

// --- Service orders ---

func (r *postgresWorkforceRepository) NextOrderNumber(ctx context.Context) (string, error) {
	var seq int
	year := time.Now().Year()
	query := `SELECT COUNT(*) + 1 FROM service_orders WHERE EXTRACT(YEAR FROM created_at) = $1`
	if err := r.db.GetContext(ctx, &seq, query, year); err != nil {
		return "", fmt.Errorf("next order number: %w", err)
	}
	return fmt.Sprintf("SRV-%d-%04d", year, seq), nil
}

func (r *postgresWorkforceRepository) CreateServiceOrder(ctx context.Context, o *domain.ServiceOrder) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	query := `
		INSERT INTO service_orders (
			id, order_number, customer_id, order_type, description, system_size_kw,
			governorate_id, district_id, address, lat, lng, preferred_date,
			status, priority, calculator_result, dispatch_mode
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16)`
	if _, err := tx.ExecContext(ctx, query,
		o.ID, o.OrderNumber, o.CustomerID, o.OrderType, o.Description, o.SystemSizeKW,
		o.GovernorateID, o.DistrictID, o.Address, o.Lat, o.Lng, o.PreferredDate,
		o.Status, o.Priority, o.CalculatorResult, o.DispatchMode); err != nil {
		return fmt.Errorf("insert service order: %w", err)
	}

	if _, err := tx.ExecContext(ctx,
		`INSERT INTO service_order_status_history (order_id, status, changed_by, notes)
		 VALUES ($1, $2, $3, 'تم استلام الطلب')`,
		o.ID, o.Status, o.CustomerID); err != nil {
		return fmt.Errorf("insert initial history: %w", err)
	}

	return tx.Commit()
}

func (r *postgresWorkforceRepository) GetServiceOrder(ctx context.Context, id uuid.UUID) (*domain.ServiceOrder, error) {
	var o domain.ServiceOrder
	query := `SELECT ` + serviceOrderSelectColumns + serviceOrderFromClause + ` WHERE o.id = $1`
	if err := r.db.GetContext(ctx, &o, query, id); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get service order: %w", err)
	}
	return &o, nil
}

func (r *postgresWorkforceRepository) ListServiceOrders(ctx context.Context, f domain.ServiceOrderFilters) ([]domain.ServiceOrder, int, error) {
	where := []string{"1=1"}
	args := []interface{}{}
	idx := 1

	if f.Status != "" {
		where = append(where, fmt.Sprintf("o.status = $%d", idx))
		args = append(args, f.Status)
		idx++
	}
	if f.OrderType != "" {
		where = append(where, fmt.Sprintf("o.order_type = $%d", idx))
		args = append(args, f.OrderType)
		idx++
	}
	if f.GovernorateID > 0 {
		where = append(where, fmt.Sprintf("o.governorate_id = $%d", idx))
		args = append(args, f.GovernorateID)
		idx++
	}
	if f.TechnicianID != "" {
		where = append(where, fmt.Sprintf("o.assigned_technician_id = $%d", idx))
		args = append(args, f.TechnicianID)
		idx++
	}
	if f.Search != "" {
		where = append(where, fmt.Sprintf("(o.order_number ILIKE $%d OR u.full_name ILIKE $%d OR u.phone ILIKE $%d)", idx, idx, idx))
		args = append(args, "%"+f.Search+"%")
		idx++
	}

	clause := strings.Join(where, " AND ")

	var total int
	if err := r.db.GetContext(ctx, &total, `SELECT COUNT(*)`+serviceOrderFromClause+` WHERE `+clause, args...); err != nil {
		return nil, 0, fmt.Errorf("count service orders: %w", err)
	}

	if f.Page < 1 {
		f.Page = 1
	}
	if f.Limit < 1 || f.Limit > 200 {
		f.Limit = 20
	}
	offset := (f.Page - 1) * f.Limit

	query := `SELECT ` + serviceOrderSelectColumns + serviceOrderFromClause + ` WHERE ` + clause +
		fmt.Sprintf(` ORDER BY o.created_at DESC LIMIT $%d OFFSET $%d`, idx, idx+1)
	args = append(args, f.Limit, offset)

	list := []domain.ServiceOrder{}
	if err := r.db.SelectContext(ctx, &list, query, args...); err != nil {
		return nil, 0, fmt.Errorf("list service orders: %w", err)
	}
	return list, total, nil
}

func (r *postgresWorkforceRepository) ListCustomerServiceOrders(ctx context.Context, customerID uuid.UUID) ([]domain.ServiceOrder, error) {
	list := []domain.ServiceOrder{}
	query := `SELECT ` + serviceOrderSelectColumns + serviceOrderFromClause + ` WHERE o.customer_id = $1 ORDER BY o.created_at DESC`
	if err := r.db.SelectContext(ctx, &list, query, customerID); err != nil {
		return nil, fmt.Errorf("list customer service orders: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) UpdateOrderStatus(ctx context.Context, orderID uuid.UUID, status domain.ServiceOrderStatus, changedBy *uuid.UUID, notes *string) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	query := `
		UPDATE service_orders SET
			status = $1,
			completed_at = CASE WHEN $1 = 'completed' THEN NOW() ELSE completed_at END,
			updated_at = NOW()
		WHERE id = $2`
	if _, err := tx.ExecContext(ctx, query, status, orderID); err != nil {
		return fmt.Errorf("update order status: %w", err)
	}

	if _, err := tx.ExecContext(ctx,
		`INSERT INTO service_order_status_history (order_id, status, changed_by, notes) VALUES ($1, $2, $3, $4)`,
		orderID, status, changedBy, notes); err != nil {
		return fmt.Errorf("insert status history: %w", err)
	}

	return tx.Commit()
}

func (r *postgresWorkforceRepository) SetOrderTechnician(ctx context.Context, orderID, technicianID uuid.UUID, status domain.ServiceOrderStatus) error {
	query := `UPDATE service_orders SET assigned_technician_id = $1, status = $2, updated_at = NOW() WHERE id = $3`
	if _, err := r.db.ExecContext(ctx, query, technicianID, status, orderID); err != nil {
		return fmt.Errorf("set order technician: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) GetStatusHistory(ctx context.Context, orderID uuid.UUID) ([]domain.ServiceOrderStatusEvent, error) {
	list := []domain.ServiceOrderStatusEvent{}
	query := `SELECT id, order_id, status, changed_by, notes, created_at
	          FROM service_order_status_history WHERE order_id = $1 ORDER BY created_at`
	if err := r.db.SelectContext(ctx, &list, query, orderID); err != nil {
		return nil, fmt.Errorf("get status history: %w", err)
	}
	return list, nil
}

// --- Dispatch settings ---

func (r *postgresWorkforceRepository) GetDispatchSettings(ctx context.Context, serviceType string) (*domain.DispatchSettings, error) {
	var s domain.DispatchSettings
	if err := r.db.GetContext(ctx, &s, `SELECT * FROM dispatch_settings WHERE service_type = $1`, serviceType); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get dispatch settings: %w", err)
	}
	return &s, nil
}

func (r *postgresWorkforceRepository) ListDispatchSettings(ctx context.Context) ([]domain.DispatchSettings, error) {
	list := []domain.DispatchSettings{}
	if err := r.db.SelectContext(ctx, &list, `SELECT * FROM dispatch_settings ORDER BY service_type`); err != nil {
		return nil, fmt.Errorf("list dispatch settings: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) UpsertDispatchSettings(ctx context.Context, req domain.UpsertDispatchSettingsRequest) error {
	query := `
		INSERT INTO dispatch_settings (service_type, dispatch_mode, response_timeout_minutes, parallel_candidates_count, minimum_score, auto_assign_enabled)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (service_type) DO UPDATE SET
			dispatch_mode = EXCLUDED.dispatch_mode,
			response_timeout_minutes = EXCLUDED.response_timeout_minutes,
			parallel_candidates_count = EXCLUDED.parallel_candidates_count,
			minimum_score = EXCLUDED.minimum_score,
			auto_assign_enabled = EXCLUDED.auto_assign_enabled,
			updated_at = NOW()`
	_, err := r.db.ExecContext(ctx, query, req.ServiceType, req.DispatchMode, req.ResponseTimeoutMinutes,
		req.ParallelCandidatesCount, req.MinimumScore, req.AutoAssignEnabled)
	if err != nil {
		return fmt.Errorf("upsert dispatch settings: %w", err)
	}
	return nil
}

// FindAvailableTechnicians returns eligible candidates for a governorate + service type,
// filtered by availability, working days/hours, specialization and account state.
func (r *postgresWorkforceRepository) FindAvailableTechnicians(ctx context.Context, governorateID int, serviceType string) ([]domain.TechnicianCandidate, error) {
	query := `
		SELECT
			t.id AS technician_id, t.full_name, t.rating, t.completed_jobs_count,
			t.acceptance_rate, t.avg_response_minutes, t.verification_level, t.complaint_count,
			COALESCE(z.is_primary, false) AS is_primary_zone,
			g.name_ar AS governorate_name,
			COALESCE(ds.orders_received_this_month, 0) AS orders_this_month,
			COALESCE(ds.total_earnings_this_month, 0) AS earnings_this_month,
			COALESCE(ds.days_since_last_order, 999) AS days_since_last_order,
			COALESCE(ds.is_new_technician, true) AS is_new_technician,
			COALESCE(ds.new_technician_orders_count, 0) AS new_tech_orders_count
		FROM technicians t
		JOIN technician_service_zones z ON z.technician_id = t.id AND z.governorate_id = $1
		LEFT JOIN governorates g ON g.id = z.governorate_id
		LEFT JOIN technician_availability a ON a.technician_id = t.id
		LEFT JOIN technician_dispatch_stats ds ON ds.technician_id = t.id
		LEFT JOIN technician_ranking rk ON rk.technician_id = t.id
		WHERE t.is_active = true
		  AND t.availability_status = 'available'
		  AND COALESCE(a.status, 'offline') = 'available'
		  AND COALESCE(rk.is_hidden, false) = false
		  AND (
		    a.working_days IS NULL
		    OR a.working_days @> to_jsonb(ARRAY[lower(to_char(NOW(), 'Dy'))])
		  )
		  AND (
		    a.available_from IS NULL OR a.available_until IS NULL
		    OR (NOW()::time BETWEEN a.available_from AND a.available_until)
		  )
		  AND (
		    jsonb_array_length(t.specializations) = 0
		    OR t.specializations @> to_jsonb(ARRAY[$2::text])
		  )`
	list := []domain.TechnicianCandidate{}
	if err := r.db.SelectContext(ctx, &list, query, governorateID, serviceType); err != nil {
		return nil, fmt.Errorf("find available technicians: %w", err)
	}
	return list, nil
}

// --- Dispatch queue ---

func (r *postgresWorkforceRepository) AddToDispatchQueue(ctx context.Context, entries []domain.DispatchQueueEntry) error {
	if len(entries) == 0 {
		return nil
	}
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	query := `
		INSERT INTO dispatch_queue (id, service_order_id, technician_id, priority_score, dispatch_mode, position, status, selection_reason)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (service_order_id, technician_id) DO NOTHING`
	for _, e := range entries {
		if _, err := tx.ExecContext(ctx, query,
			e.ID, e.ServiceOrderID, e.TechnicianID, e.PriorityScore, e.DispatchMode, e.Position, e.Status, e.SelectionReason); err != nil {
			return fmt.Errorf("insert dispatch entry: %w", err)
		}
	}
	return tx.Commit()
}

func (r *postgresWorkforceRepository) GetDispatchQueue(ctx context.Context, orderID uuid.UUID) ([]domain.DispatchQueueEntry, error) {
	list := []domain.DispatchQueueEntry{}
	query := `
		SELECT q.id, q.service_order_id, q.technician_id, q.priority_score, q.dispatch_mode,
		       q.position, q.status, q.selection_reason, q.sent_at, q.responded_at, q.expires_at, q.created_at,
		       t.full_name AS technician_name
		FROM dispatch_queue q
		LEFT JOIN technicians t ON t.id = q.technician_id
		WHERE q.service_order_id = $1
		ORDER BY q.position`
	if err := r.db.SelectContext(ctx, &list, query, orderID); err != nil {
		return nil, fmt.Errorf("get dispatch queue: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) GetDispatchEntry(ctx context.Context, dispatchID uuid.UUID) (*domain.DispatchQueueEntry, error) {
	var e domain.DispatchQueueEntry
	query := `
		SELECT q.id, q.service_order_id, q.technician_id, q.priority_score, q.dispatch_mode,
		       q.position, q.status, q.selection_reason, q.sent_at, q.responded_at, q.expires_at, q.created_at,
		       t.full_name AS technician_name
		FROM dispatch_queue q
		LEFT JOIN technicians t ON t.id = q.technician_id
		WHERE q.id = $1`
	if err := r.db.GetContext(ctx, &e, query, dispatchID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get dispatch entry: %w", err)
	}
	return &e, nil
}

func (r *postgresWorkforceRepository) MarkDispatchSent(ctx context.Context, dispatchID uuid.UUID, timeoutMinutes int) error {
	query := `
		UPDATE dispatch_queue
		SET status = 'sent', sent_at = NOW(), expires_at = NOW() + make_interval(mins => $1)
		WHERE id = $2 AND status = 'queued'`
	if _, err := r.db.ExecContext(ctx, query, timeoutMinutes, dispatchID); err != nil {
		return fmt.Errorf("mark dispatch sent: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) UpdateDispatchStatus(ctx context.Context, dispatchID uuid.UUID, status domain.DispatchStatus) error {
	query := `UPDATE dispatch_queue SET status = $1, responded_at = NOW() WHERE id = $2`
	if _, err := r.db.ExecContext(ctx, query, status, dispatchID); err != nil {
		return fmt.Errorf("update dispatch status: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) CancelRemainingDispatch(ctx context.Context, orderID, winnerID uuid.UUID) error {
	query := `
		UPDATE dispatch_queue SET status = 'cancelled', responded_at = NOW()
		WHERE service_order_id = $1 AND id <> $2 AND status IN ('queued', 'sent')`
	if _, err := r.db.ExecContext(ctx, query, orderID, winnerID); err != nil {
		return fmt.Errorf("cancel remaining dispatch: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) GetNextDispatchCandidate(ctx context.Context, orderID uuid.UUID) (*domain.DispatchQueueEntry, error) {
	var e domain.DispatchQueueEntry
	query := `
		SELECT q.id, q.service_order_id, q.technician_id, q.priority_score, q.dispatch_mode,
		       q.position, q.status, q.selection_reason, q.sent_at, q.responded_at, q.expires_at, q.created_at,
		       t.full_name AS technician_name
		FROM dispatch_queue q
		LEFT JOIN technicians t ON t.id = q.technician_id
		WHERE q.service_order_id = $1 AND q.status = 'queued'
		ORDER BY q.position
		LIMIT 1`
	if err := r.db.GetContext(ctx, &e, query, orderID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get next dispatch candidate: %w", err)
	}
	return &e, nil
}

func (r *postgresWorkforceRepository) ListTechnicianOffers(ctx context.Context, technicianID uuid.UUID) ([]domain.DispatchOffer, error) {
	list := []domain.DispatchOffer{}
	query := `
		SELECT q.id AS dispatch_id, o.id AS order_id, o.order_number, o.order_type, o.system_size_kw,
		       g.name_ar AS governorate_name, d.name_ar AS district_name, o.priority, o.preferred_date,
		       q.expires_at, q.selection_reason, q.status, q.created_at
		FROM dispatch_queue q
		JOIN service_orders o ON o.id = q.service_order_id
		LEFT JOIN governorates g ON g.id = o.governorate_id
		LEFT JOIN districts d ON d.id = o.district_id
		WHERE q.technician_id = $1
		  AND q.status = 'sent'
		  AND (q.expires_at IS NULL OR q.expires_at > NOW())
		  AND o.status IN ('dispatching', 'new')
		ORDER BY q.sent_at DESC`
	if err := r.db.SelectContext(ctx, &list, query, technicianID); err != nil {
		return nil, fmt.Errorf("list technician offers: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) ExpireStaleDispatches(ctx context.Context) ([]domain.DispatchQueueEntry, error) {
	list := []domain.DispatchQueueEntry{}
	query := `
		UPDATE dispatch_queue
		SET status = 'expired', responded_at = NOW()
		WHERE status = 'sent' AND expires_at IS NOT NULL AND expires_at <= NOW()
		RETURNING id, service_order_id, technician_id, priority_score, dispatch_mode,
		          position, status, selection_reason, sent_at, responded_at, expires_at, created_at`
	if err := r.db.SelectContext(ctx, &list, query); err != nil {
		return nil, fmt.Errorf("expire stale dispatches: %w", err)
	}
	return list, nil
}

// --- Dispatch stats ---

func (r *postgresWorkforceRepository) EnsureDispatchStats(ctx context.Context, technicianID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO technician_dispatch_stats (technician_id) VALUES ($1) ON CONFLICT (technician_id) DO NOTHING`, technicianID)
	if err != nil {
		return fmt.Errorf("ensure dispatch stats: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) RecordDispatchSent(ctx context.Context, technicianID uuid.UUID) error {
	query := `
		INSERT INTO technician_dispatch_stats (
			technician_id, orders_received_this_month, orders_received_this_week,
			total_orders_received, new_technician_orders_count, last_order_received_at, days_since_last_order
		) VALUES ($1, 1, 1, 1, 1, NOW(), 0)
		ON CONFLICT (technician_id) DO UPDATE SET
			orders_received_this_month = technician_dispatch_stats.orders_received_this_month + 1,
			orders_received_this_week = technician_dispatch_stats.orders_received_this_week + 1,
			total_orders_received = technician_dispatch_stats.total_orders_received + 1,
			new_technician_orders_count = technician_dispatch_stats.new_technician_orders_count + 1,
			is_new_technician = (technician_dispatch_stats.new_technician_orders_count + 1) < 10,
			last_order_received_at = NOW(),
			days_since_last_order = 0,
			updated_at = NOW()`
	if _, err := r.db.ExecContext(ctx, query, technicianID); err != nil {
		return fmt.Errorf("record dispatch sent: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) RecordOrderCompleted(ctx context.Context, technicianID uuid.UUID, payout float64) error {
	query := `
		INSERT INTO technician_dispatch_stats (technician_id, total_earnings_this_month, last_order_completed_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (technician_id) DO UPDATE SET
			total_earnings_this_month = technician_dispatch_stats.total_earnings_this_month + EXCLUDED.total_earnings_this_month,
			last_order_completed_at = NOW(),
			updated_at = NOW()`
	if _, err := r.db.ExecContext(ctx, query, technicianID, payout); err != nil {
		return fmt.Errorf("record order completed: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) UpdateFairnessBoost(ctx context.Context, technicianID uuid.UUID, boost float64) error {
	query := `
		INSERT INTO technician_dispatch_stats (technician_id, fairness_boost, last_boost_calculated_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (technician_id) DO UPDATE SET
			fairness_boost = EXCLUDED.fairness_boost,
			days_since_last_order = COALESCE(
				EXTRACT(DAY FROM NOW() - technician_dispatch_stats.last_order_received_at)::int, 999),
			last_boost_calculated_at = NOW(),
			updated_at = NOW()`
	if _, err := r.db.ExecContext(ctx, query, technicianID, boost); err != nil {
		return fmt.Errorf("update fairness boost: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) ListDispatchStats(ctx context.Context) ([]domain.TechnicianDispatchStats, error) {
	list := []domain.TechnicianDispatchStats{}
	query := `
		SELECT s.*, t.full_name AS technician_name
		FROM technician_dispatch_stats s
		JOIN technicians t ON t.id = s.technician_id
		ORDER BY s.orders_received_this_month DESC`
	if err := r.db.SelectContext(ctx, &list, query); err != nil {
		return nil, fmt.Errorf("list dispatch stats: %w", err)
	}
	return list, nil
}

// --- Assignments ---

func (r *postgresWorkforceRepository) CreateAssignment(ctx context.Context, a *domain.OrderAssignment) error {
	query := `
		INSERT INTO order_assignments (id, order_id, technician_id, assigned_by, assigned_by_admin, status, accepted_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`
	_, err := r.db.ExecContext(ctx, query, a.ID, a.OrderID, a.TechnicianID, a.AssignedBy, a.AssignedByAdmin, a.Status, a.AcceptedAt)
	if err != nil {
		return fmt.Errorf("create assignment: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) ListAssignmentsForOrder(ctx context.Context, orderID uuid.UUID) ([]domain.OrderAssignment, error) {
	list := []domain.OrderAssignment{}
	if err := r.db.SelectContext(ctx, &list, `SELECT * FROM order_assignments WHERE order_id = $1 ORDER BY assigned_at DESC`, orderID); err != nil {
		return nil, fmt.Errorf("list assignments: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) ListTechnicianAssignments(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianAssignment, error) {
	assignments := []domain.OrderAssignment{}
	query := `
		SELECT a.* FROM order_assignments a
		JOIN service_orders o ON o.id = a.order_id
		WHERE a.technician_id = $1 AND a.status IN ('accepted', 'completed')
		ORDER BY a.assigned_at DESC`
	if err := r.db.SelectContext(ctx, &assignments, query, technicianID); err != nil {
		return nil, fmt.Errorf("list technician assignments: %w", err)
	}

	result := make([]domain.TechnicianAssignment, 0, len(assignments))
	for _, a := range assignments {
		order, err := r.GetServiceOrder(ctx, a.OrderID)
		if err != nil {
			return nil, err
		}
		if order == nil {
			continue
		}
		result = append(result, domain.TechnicianAssignment{OrderAssignment: a, Order: *order})
	}
	return result, nil
}

func (r *postgresWorkforceRepository) UpdateAssignmentStatus(ctx context.Context, orderID, technicianID uuid.UUID, status domain.AssignmentStatus) error {
	query := `
		UPDATE order_assignments SET
			status = $1,
			completion_time = CASE WHEN $1 = 'completed' THEN NOW() ELSE completion_time END,
			rejected_at = CASE WHEN $1 = 'rejected' THEN NOW() ELSE rejected_at END
		WHERE order_id = $2 AND technician_id = $3`
	if _, err := r.db.ExecContext(ctx, query, status, orderID, technicianID); err != nil {
		return fmt.Errorf("update assignment status: %w", err)
	}
	return nil
}

// --- Job execution ---

func (r *postgresWorkforceRepository) CreateJobTasks(ctx context.Context, orderID uuid.UUID, titles []string) error {
	if len(titles) == 0 {
		return nil
	}
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	for i, title := range titles {
		if _, err := tx.ExecContext(ctx,
			`INSERT INTO job_tasks (order_id, title, sort_order) VALUES ($1, $2, $3)`, orderID, title, i+1); err != nil {
			return fmt.Errorf("insert job task: %w", err)
		}
	}
	return tx.Commit()
}

func (r *postgresWorkforceRepository) ListJobTasks(ctx context.Context, orderID uuid.UUID) ([]domain.JobTask, error) {
	list := []domain.JobTask{}
	if err := r.db.SelectContext(ctx, &list, `SELECT * FROM job_tasks WHERE order_id = $1 ORDER BY sort_order`, orderID); err != nil {
		return nil, fmt.Errorf("list job tasks: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) ToggleJobTask(ctx context.Context, taskID uuid.UUID) error {
	query := `
		UPDATE job_tasks SET
			is_completed = NOT is_completed,
			completed_at = CASE WHEN NOT is_completed THEN NOW() ELSE NULL END
		WHERE id = $1`
	if _, err := r.db.ExecContext(ctx, query, taskID); err != nil {
		return fmt.Errorf("toggle job task: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) AddJobMedia(ctx context.Context, m *domain.JobMedia) error {
	query := `
		INSERT INTO job_media (id, order_id, technician_id, type, url, content, lat, lng)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`
	_, err := r.db.ExecContext(ctx, query, m.ID, m.OrderID, m.TechnicianID, m.Type, m.URL, m.Content, m.Lat, m.Lng)
	if err != nil {
		return fmt.Errorf("add job media: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) ListJobMedia(ctx context.Context, orderID uuid.UUID) ([]domain.JobMedia, error) {
	list := []domain.JobMedia{}
	if err := r.db.SelectContext(ctx, &list, `SELECT * FROM job_media WHERE order_id = $1 ORDER BY created_at DESC`, orderID); err != nil {
		return nil, fmt.Errorf("list job media: %w", err)
	}
	return list, nil
}

// --- Tracking ---

func (r *postgresWorkforceRepository) AddTrackingPoint(ctx context.Context, t *domain.TechnicianTracking) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	// Privacy: keep only the latest point per order.
	if _, err := tx.ExecContext(ctx, `DELETE FROM technician_tracking WHERE order_id = $1`, t.OrderID); err != nil {
		return fmt.Errorf("clear tracking: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		`INSERT INTO technician_tracking (id, order_id, technician_id, lat, lng, status) VALUES ($1, $2, $3, $4, $5, $6)`,
		t.ID, t.OrderID, t.TechnicianID, t.Lat, t.Lng, t.Status); err != nil {
		return fmt.Errorf("insert tracking: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		`UPDATE technician_availability SET current_lat = $1, current_lng = $2, updated_at = NOW() WHERE technician_id = $3`,
		t.Lat, t.Lng, t.TechnicianID); err != nil {
		return fmt.Errorf("update live location: %w", err)
	}
	return tx.Commit()
}

func (r *postgresWorkforceRepository) GetLatestTracking(ctx context.Context, orderID uuid.UUID) (*domain.TechnicianTracking, error) {
	var t domain.TechnicianTracking
	query := `SELECT * FROM technician_tracking WHERE order_id = $1 ORDER BY created_at DESC LIMIT 1`
	if err := r.db.GetContext(ctx, &t, query, orderID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get latest tracking: %w", err)
	}
	return &t, nil
}

// --- Reviews ---

func (r *postgresWorkforceRepository) CreateReview(ctx context.Context, rv *domain.CustomerReview) error {
	query := `
		INSERT INTO customer_reviews (id, order_id, customer_id, technician_id, quality_rating, punctuality_rating, speed_rating, comment)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (order_id) DO NOTHING`
	_, err := r.db.ExecContext(ctx, query, rv.ID, rv.OrderID, rv.CustomerID, rv.TechnicianID,
		rv.QualityRating, rv.PunctualityRating, rv.SpeedRating, rv.Comment)
	if err != nil {
		return fmt.Errorf("create review: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) GetReview(ctx context.Context, orderID uuid.UUID) (*domain.CustomerReview, error) {
	var rv domain.CustomerReview
	if err := r.db.GetContext(ctx, &rv, `SELECT * FROM customer_reviews WHERE order_id = $1`, orderID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get review: %w", err)
	}
	return &rv, nil
}

// --- Pricing ---

func (r *postgresWorkforceRepository) UpsertPricing(ctx context.Context, p *domain.ServicePricing) error {
	query := `
		INSERT INTO service_pricing (id, order_id, base_price_iqd, platform_commission_percent, platform_commission_iqd, technician_payout_iqd, payment_status)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (order_id) DO UPDATE SET
			base_price_iqd = EXCLUDED.base_price_iqd,
			platform_commission_percent = EXCLUDED.platform_commission_percent,
			platform_commission_iqd = EXCLUDED.platform_commission_iqd,
			technician_payout_iqd = EXCLUDED.technician_payout_iqd`
	_, err := r.db.ExecContext(ctx, query, p.ID, p.OrderID, p.BasePriceIQD, p.PlatformCommissionPercent,
		p.PlatformCommissionIQD, p.TechnicianPayoutIQD, p.PaymentStatus)
	if err != nil {
		return fmt.Errorf("upsert pricing: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) GetPricing(ctx context.Context, orderID uuid.UUID) (*domain.ServicePricing, error) {
	var p domain.ServicePricing
	query := `
		SELECT sp.*, so.order_number, t.full_name AS technician_name
		FROM service_pricing sp
		JOIN service_orders so ON so.id = sp.order_id
		LEFT JOIN technicians t ON t.id = so.assigned_technician_id
		WHERE sp.order_id = $1`
	if err := r.db.GetContext(ctx, &p, query, orderID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get pricing: %w", err)
	}
	return &p, nil
}

func (r *postgresWorkforceRepository) ListPricing(ctx context.Context, status string) ([]domain.ServicePricing, error) {
	list := []domain.ServicePricing{}
	query := `
		SELECT sp.*, so.order_number, t.full_name AS technician_name
		FROM service_pricing sp
		JOIN service_orders so ON so.id = sp.order_id
		LEFT JOIN technicians t ON t.id = so.assigned_technician_id
		WHERE ($1 = '' OR sp.payment_status = $1)
		ORDER BY sp.created_at DESC`
	if err := r.db.SelectContext(ctx, &list, query, status); err != nil {
		return nil, fmt.Errorf("list pricing: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) UpdatePaymentStatus(ctx context.Context, orderID uuid.UUID, status domain.ServicePaymentStatus) error {
	query := `
		UPDATE service_pricing SET
			payment_status = $1,
			settled_at = CASE WHEN $1 = 'settled' THEN NOW() ELSE settled_at END
		WHERE order_id = $2`
	if _, err := r.db.ExecContext(ctx, query, status, orderID); err != nil {
		return fmt.Errorf("update payment status: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) ListWalletTransactions(ctx context.Context, technicianID uuid.UUID) ([]domain.ServicePricing, error) {
	list := []domain.ServicePricing{}
	query := `
		SELECT sp.*, so.order_number, t.full_name AS technician_name
		FROM service_pricing sp
		JOIN service_orders so ON so.id = sp.order_id
		LEFT JOIN technicians t ON t.id = so.assigned_technician_id
		WHERE so.assigned_technician_id = $1
		ORDER BY sp.created_at DESC`
	if err := r.db.SelectContext(ctx, &list, query, technicianID); err != nil {
		return nil, fmt.Errorf("list wallet transactions: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) GetPriceTier(ctx context.Context, serviceType string) (*domain.ServicePriceTier, error) {
	var t domain.ServicePriceTier
	if err := r.db.GetContext(ctx, &t, `SELECT * FROM service_price_tiers WHERE service_type = $1`, serviceType); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get price tier: %w", err)
	}
	return &t, nil
}

func (r *postgresWorkforceRepository) ListPriceTiers(ctx context.Context) ([]domain.ServicePriceTier, error) {
	list := []domain.ServicePriceTier{}
	if err := r.db.SelectContext(ctx, &list, `SELECT * FROM service_price_tiers ORDER BY service_type`); err != nil {
		return nil, fmt.Errorf("list price tiers: %w", err)
	}
	return list, nil
}

// --- Leads ---

func (r *postgresWorkforceRepository) CreateLead(ctx context.Context, l *domain.TechnicianLead) error {
	query := `
		INSERT INTO technician_leads (
			id, technician_id, customer_name, customer_phone, order_type, description,
			system_size_kw, governorate_id, district_id, address, estimated_price_iqd, status
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'pending_review')`
	_, err := r.db.ExecContext(ctx, query, l.ID, l.TechnicianID, l.CustomerName, l.CustomerPhone,
		l.OrderType, l.Description, l.SystemSizeKW, l.GovernorateID, l.DistrictID, l.Address, l.EstimatedPriceIQD)
	if err != nil {
		return fmt.Errorf("create lead: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) ListLeads(ctx context.Context, technicianID *uuid.UUID, status string) ([]domain.TechnicianLead, error) {
	list := []domain.TechnicianLead{}
	query := `
		SELECT l.*, t.full_name AS technician_name
		FROM technician_leads l
		JOIN technicians t ON t.id = l.technician_id
		WHERE ($1::uuid IS NULL OR l.technician_id = $1::uuid)
		  AND ($2 = '' OR l.status = $2)
		ORDER BY l.created_at DESC`
	if err := r.db.SelectContext(ctx, &list, query, technicianID, status); err != nil {
		return nil, fmt.Errorf("list leads: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) GetLead(ctx context.Context, id uuid.UUID) (*domain.TechnicianLead, error) {
	var l domain.TechnicianLead
	query := `
		SELECT l.*, t.full_name AS technician_name
		FROM technician_leads l
		JOIN technicians t ON t.id = l.technician_id
		WHERE l.id = $1`
	if err := r.db.GetContext(ctx, &l, query, id); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get lead: %w", err)
	}
	return &l, nil
}

func (r *postgresWorkforceRepository) UpdateLeadStatus(ctx context.Context, id uuid.UUID, status domain.LeadStatus, reviewer uuid.UUID, convertedOrderID *uuid.UUID) error {
	query := `
		UPDATE technician_leads SET
			status = $1, reviewed_by = $2, reviewed_at = NOW(),
			converted_order_id = COALESCE($3, converted_order_id)
		WHERE id = $4`
	if _, err := r.db.ExecContext(ctx, query, status, reviewer, convertedOrderID, id); err != nil {
		return fmt.Errorf("update lead status: %w", err)
	}
	return nil
}
