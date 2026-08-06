package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

// WorkforceRepository is the data-access contract for the workforce dispatch system.
type WorkforceRepository interface {
	// Technicians
	CreateTechnician(ctx context.Context, t *domain.Technician, zones []int) error
	GetTechnicianByID(ctx context.Context, id uuid.UUID) (*domain.Technician, error)
	GetTechnicianByUserID(ctx context.Context, userID uuid.UUID) (*domain.Technician, error)
	ListTechnicians(ctx context.Context, f domain.TechnicianFilters) ([]domain.Technician, int, error)
	UpdateTechnician(ctx context.Context, id uuid.UUID, req domain.UpdateTechnicianRequest) error
	SetTechnicianVerification(ctx context.Context, id uuid.UUID, isVerified bool, level int) error
	SetTechnicianAvailabilityStatus(ctx context.Context, id uuid.UUID, status string) error
	UpdateTechnicianLevel(ctx context.Context, id uuid.UUID) error
	IncrementCompletedJobs(ctx context.Context, id uuid.UUID) error
	RecalculateTechnicianRating(ctx context.Context, id uuid.UUID) error
	RecordDispatchResponse(ctx context.Context, id uuid.UUID, accepted bool, responseMinutes int) error

	// Availability
	GetAvailability(ctx context.Context, technicianID uuid.UUID) (*domain.TechnicianAvailability, error)
	UpsertAvailability(ctx context.Context, technicianID uuid.UUID, req domain.UpdateAvailabilityRequest) error

	// Service zones
	ReplaceServiceZones(ctx context.Context, technicianID uuid.UUID, governorateIDs []int, primary *int) error
	ListServiceZones(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianServiceZone, error)

	// Wallet
	GetWallet(ctx context.Context, technicianID uuid.UUID) (*domain.TechnicianWallet, error)
	CreditWallet(ctx context.Context, technicianID uuid.UUID, payout, commission float64) error
	SettleWallet(ctx context.Context, technicianID uuid.UUID) error

	// Documents
	AddDocument(ctx context.Context, d *domain.TechnicianDocument) error
	ListDocuments(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianDocument, error)
	UpdateDocumentStatus(ctx context.Context, docID uuid.UUID, status domain.DocumentStatus, reviewer uuid.UUID) error

	// Portfolio
	AddPortfolioItem(ctx context.Context, p *domain.TechnicianPortfolio) error
	ListPortfolio(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianPortfolio, error)
	DeletePortfolioItem(ctx context.Context, id uuid.UUID) error

	// Ranking
	GetRanking(ctx context.Context, technicianID uuid.UUID) (*domain.TechnicianRanking, error)
	UpsertRanking(ctx context.Context, technicianID uuid.UUID, score float64) error
	UpdateRankingFlags(ctx context.Context, technicianID uuid.UUID, req domain.UpdateRankingRequest) error

	// Levels
	ListLevels(ctx context.Context) ([]domain.TechnicianLevel, error)
	CreateLevel(ctx context.Context, req domain.UpsertTechnicianLevelRequest) (*domain.TechnicianLevel, error)
	UpdateLevel(ctx context.Context, id uuid.UUID, req domain.UpsertTechnicianLevelRequest) error

	// Service orders
	CreateServiceOrder(ctx context.Context, o *domain.ServiceOrder) error
	NextOrderNumber(ctx context.Context) (string, error)
	GetServiceOrder(ctx context.Context, id uuid.UUID) (*domain.ServiceOrder, error)
	ListServiceOrders(ctx context.Context, f domain.ServiceOrderFilters) ([]domain.ServiceOrder, int, error)
	ListCustomerServiceOrders(ctx context.Context, customerID uuid.UUID) ([]domain.ServiceOrder, error)
	UpdateOrderStatus(ctx context.Context, orderID uuid.UUID, status domain.ServiceOrderStatus, changedBy *uuid.UUID, notes *string) error
	SetOrderTechnician(ctx context.Context, orderID, technicianID uuid.UUID, status domain.ServiceOrderStatus) error
	GetStatusHistory(ctx context.Context, orderID uuid.UUID) ([]domain.ServiceOrderStatusEvent, error)

	// Dispatch
	GetDispatchSettings(ctx context.Context, serviceType string) (*domain.DispatchSettings, error)
	ListDispatchSettings(ctx context.Context) ([]domain.DispatchSettings, error)
	UpsertDispatchSettings(ctx context.Context, req domain.UpsertDispatchSettingsRequest) error
	FindAvailableTechnicians(ctx context.Context, governorateID int, serviceType string) ([]domain.TechnicianCandidate, error)
	AddToDispatchQueue(ctx context.Context, entries []domain.DispatchQueueEntry) error
	GetDispatchQueue(ctx context.Context, orderID uuid.UUID) ([]domain.DispatchQueueEntry, error)
	GetDispatchEntry(ctx context.Context, dispatchID uuid.UUID) (*domain.DispatchQueueEntry, error)
	MarkDispatchSent(ctx context.Context, dispatchID uuid.UUID, timeoutMinutes int) error
	UpdateDispatchStatus(ctx context.Context, dispatchID uuid.UUID, status domain.DispatchStatus) error
	CancelRemainingDispatch(ctx context.Context, orderID, winnerID uuid.UUID) error
	ClearDispatchQueue(ctx context.Context, orderID uuid.UUID) error
	GetNextDispatchCandidate(ctx context.Context, orderID uuid.UUID) (*domain.DispatchQueueEntry, error)
	ListTechnicianOffers(ctx context.Context, technicianID uuid.UUID) ([]domain.DispatchOffer, error)
	ExpireStaleDispatches(ctx context.Context) ([]domain.DispatchQueueEntry, error)

	// Dispatch stats (fair dispatch)
	EnsureDispatchStats(ctx context.Context, technicianID uuid.UUID) error
	RecordDispatchSent(ctx context.Context, technicianID uuid.UUID) error
	RecordOrderCompleted(ctx context.Context, technicianID uuid.UUID, payout float64) error
	UpdateFairnessBoost(ctx context.Context, technicianID uuid.UUID, boost float64) error
	ListDispatchStats(ctx context.Context) ([]domain.TechnicianDispatchStats, error)

	// Assignments
	CreateAssignment(ctx context.Context, a *domain.OrderAssignment) error
	ListAssignmentsForOrder(ctx context.Context, orderID uuid.UUID) ([]domain.OrderAssignment, error)
	ListTechnicianAssignments(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianAssignment, error)
	UpdateAssignmentStatus(ctx context.Context, orderID, technicianID uuid.UUID, status domain.AssignmentStatus) error

	// Job execution
	CreateJobTasks(ctx context.Context, orderID uuid.UUID, titles []string) error
	ListJobTasks(ctx context.Context, orderID uuid.UUID) ([]domain.JobTask, error)
	ToggleJobTask(ctx context.Context, taskID uuid.UUID) error
	AddJobMedia(ctx context.Context, m *domain.JobMedia) error
	ListJobMedia(ctx context.Context, orderID uuid.UUID) ([]domain.JobMedia, error)

	// Tracking
	AddTrackingPoint(ctx context.Context, t *domain.TechnicianTracking) error
	GetLatestTracking(ctx context.Context, orderID uuid.UUID) (*domain.TechnicianTracking, error)

	// Reviews
	CreateReview(ctx context.Context, r *domain.CustomerReview) error
	GetReview(ctx context.Context, orderID uuid.UUID) (*domain.CustomerReview, error)

	// Pricing
	UpsertPricing(ctx context.Context, p *domain.ServicePricing) error
	GetPricing(ctx context.Context, orderID uuid.UUID) (*domain.ServicePricing, error)
	ListPricing(ctx context.Context, status string) ([]domain.ServicePricing, error)
	UpdatePaymentStatus(ctx context.Context, orderID uuid.UUID, status domain.ServicePaymentStatus) error
	ListWalletTransactions(ctx context.Context, technicianID uuid.UUID) ([]domain.ServicePricing, error)
	GetPriceTier(ctx context.Context, serviceType string) (*domain.ServicePriceTier, error)
	ListPriceTiers(ctx context.Context) ([]domain.ServicePriceTier, error)

	// Leads
	CreateLead(ctx context.Context, l *domain.TechnicianLead) error
	ListLeads(ctx context.Context, technicianID *uuid.UUID, status string) ([]domain.TechnicianLead, error)
	GetLead(ctx context.Context, id uuid.UUID) (*domain.TechnicianLead, error)
	UpdateLeadStatus(ctx context.Context, id uuid.UUID, status domain.LeadStatus, reviewer uuid.UUID, convertedOrderID *uuid.UUID) error
}

type postgresWorkforceRepository struct {
	db *sqlx.DB
}

// NewWorkforceRepository builds a Postgres-backed WorkforceRepository.
func NewWorkforceRepository(db *sqlx.DB) WorkforceRepository {
	return &postgresWorkforceRepository{db: db}
}

const technicianSelectColumns = `
	COALESCE(t.id, u.id) AS id,
	u.id AS user_id,
	COALESCE(NULLIF(u.full_name, ''), t.full_name, '') AS full_name,
	COALESCE(t.profile_image_url, '') AS profile_image_url,
	COALESCE(NULLIF(u.phone, ''), t.phone_private, '') AS phone_private,
	COALESCE(t.phone_public, NULLIF(u.phone, ''), '') AS phone_public,
	COALESCE(NULLIF(u.role, ''), t.role, 'technician') AS role,
	COALESCE(t.specializations, '[]'::jsonb) AS specializations,
	COALESCE(u.governorate_id, t.governorate_id, 0) AS governorate_id,
	COALESCE(u.district_id, t.district_id, 0) AS district_id,
	COALESCE(t.experience_years, 0) AS experience_years,
	COALESCE(t.bio, '') AS bio,
	COALESCE(t.is_verified, false) AS is_verified,
	COALESCE(t.is_active, u.is_active, true) AS is_active,
	COALESCE(t.availability_status, 'offline') AS availability_status,
	COALESCE(t.rating, 0) AS rating,
	COALESCE(t.completed_jobs_count, 0) AS completed_jobs_count,
	COALESCE(t.acceptance_rate, 100) AS acceptance_rate,
	COALESCE(t.avg_response_minutes, 0) AS avg_response_minutes,
	COALESCE(t.verification_level, 0) AS verification_level,
	COALESCE(t.complaint_count, 0) AS complaint_count,
	t.level_id,
	COALESCE(t.created_at, u.created_at) AS created_at,
	COALESCE(t.updated_at, u.updated_at) AS updated_at,
	COALESCE(l.name, '') AS level_name,
	COALESCE(l.name_ar, '') AS level_name_ar,
	COALESCE(l.badge_color, '') AS level_badge_color,
	COALESCE(l.commission_rate, 0) AS commission_rate,
	COALESCE(g_user.name_ar, g.name_ar, u.governorate, '') AS governorate_name,
	COALESCE(r.priority_score, 0) AS priority_score,
	COALESCE(r.is_featured, false) AS is_featured,
	COALESCE(r.is_hidden, false) AS is_hidden`

const technicianFromClause = `
	FROM users u
	LEFT JOIN technicians t ON t.user_id = u.id
	LEFT JOIN technician_levels l ON l.id = t.level_id
	LEFT JOIN governorates g ON g.id = t.governorate_id
	LEFT JOIN governorates g_user ON g_user.id = u.governorate_id
	LEFT JOIN technician_ranking r ON r.technician_id = t.id`

// --- Technicians ---

func (r *postgresWorkforceRepository) CreateTechnician(ctx context.Context, t *domain.Technician, zones []int) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	query := `
		INSERT INTO technicians (
			id, user_id, full_name, profile_image_url, phone_private, phone_public, role,
			specializations, governorate_id, district_id, experience_years, bio,
			availability_status, level_id
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13,
			(SELECT id FROM technician_levels ORDER BY sort_order LIMIT 1)
		)`
	if _, err = tx.ExecContext(ctx, query,
		t.ID, t.UserID, t.FullName, t.ProfileImageURL, t.PhonePrivate, t.PhonePublic, t.Role,
		t.Specializations, t.GovernorateID, t.DistrictID, t.ExperienceYears, t.Bio,
		t.AvailabilityStatus,
	); err != nil {
		return fmt.Errorf("insert technician: %w", err)
	}

	if _, err = tx.ExecContext(ctx,
		`INSERT INTO technician_availability (technician_id, status) VALUES ($1, 'offline')
		 ON CONFLICT (technician_id) DO NOTHING`, t.ID); err != nil {
		return fmt.Errorf("init availability: %w", err)
	}
	if _, err = tx.ExecContext(ctx,
		`INSERT INTO technician_wallet (technician_id) VALUES ($1) ON CONFLICT (technician_id) DO NOTHING`, t.ID); err != nil {
		return fmt.Errorf("init wallet: %w", err)
	}
	if _, err = tx.ExecContext(ctx,
		`INSERT INTO technician_ranking (technician_id) VALUES ($1) ON CONFLICT (technician_id) DO NOTHING`, t.ID); err != nil {
		return fmt.Errorf("init ranking: %w", err)
	}
	if _, err = tx.ExecContext(ctx,
		`INSERT INTO technician_dispatch_stats (technician_id) VALUES ($1) ON CONFLICT (technician_id) DO NOTHING`, t.ID); err != nil {
		return fmt.Errorf("init dispatch stats: %w", err)
	}

	for i, gid := range zones {
		if _, err = tx.ExecContext(ctx,
			`INSERT INTO technician_service_zones (technician_id, governorate_id, is_primary)
			 VALUES ($1, $2, $3) ON CONFLICT (technician_id, governorate_id) DO NOTHING`,
			t.ID, gid, i == 0); err != nil {
			return fmt.Errorf("insert service zone: %w", err)
		}
	}

	return tx.Commit()
}

func (r *postgresWorkforceRepository) GetTechnicianByID(ctx context.Context, id uuid.UUID) (*domain.Technician, error) {
	var t domain.Technician
	query := `SELECT ` + technicianSelectColumns + technicianFromClause + ` WHERE (t.id = $1 OR u.id = $1)`
	if err := r.db.GetContext(ctx, &t, query, id); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get technician: %w", err)
	}
	return &t, nil
}

func (r *postgresWorkforceRepository) GetTechnicianByUserID(ctx context.Context, userID uuid.UUID) (*domain.Technician, error) {
	var t domain.Technician
	query := `SELECT ` + technicianSelectColumns + technicianFromClause + ` WHERE (u.id = $1 OR t.user_id = $1)`
	if err := r.db.GetContext(ctx, &t, query, userID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get technician by user: %w", err)
	}
	return &t, nil
}

func (r *postgresWorkforceRepository) ListTechnicians(ctx context.Context, f domain.TechnicianFilters) ([]domain.Technician, int, error) {
	where := []string{"1=1"}
	args := []interface{}{}
	idx := 1

	if f.Role != "" {
		where = append(where, fmt.Sprintf("(t.role = $%d OR u.role = $%d)", idx, idx))
		args = append(args, f.Role)
		idx++
	} else {
		where = append(where, "(t.role IN ('installer', 'engineer', 'technician', 'worker') OR u.role IN ('installer', 'engineer', 'technician', 'worker'))")
	}
	if f.GovernorateID > 0 {
		where = append(where, fmt.Sprintf(
			"(t.governorate_id = $%d OR u.governorate_id = $%d OR EXISTS (SELECT 1 FROM technician_service_zones z WHERE z.technician_id = t.id AND z.governorate_id = $%d))", idx, idx, idx))
		args = append(args, f.GovernorateID)
		idx++
	}
	if f.Status != "" {
		where = append(where, fmt.Sprintf("t.availability_status = $%d", idx))
		args = append(args, f.Status)
		idx++
	}
	if f.IsVerified != nil {
		where = append(where, fmt.Sprintf("t.is_verified = $%d", idx))
		args = append(args, *f.IsVerified)
		idx++
	}
	if f.Search != "" {
		where = append(where, fmt.Sprintf("(t.full_name ILIKE $%d OR t.phone_public ILIKE $%d OR t.phone_private ILIKE $%d OR u.full_name ILIKE $%d OR u.phone ILIKE $%d OR g.name_ar ILIKE $%d OR g_user.name_ar ILIKE $%d OR u.governorate ILIKE $%d)", idx, idx, idx, idx, idx, idx, idx, idx))
		args = append(args, "%"+f.Search+"%")
		idx++
	}

	clause := strings.Join(where, " AND ")

	var total int
	countQuery := `SELECT COUNT(*)` + technicianFromClause + ` WHERE ` + clause
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("count technicians: %w", err)
	}

	if f.Page < 1 {
		f.Page = 1
	}
	if f.Limit < 1 || f.Limit > 200 {
		f.Limit = 20
	}
	offset := (f.Page - 1) * f.Limit

	query := `SELECT ` + technicianSelectColumns + technicianFromClause + ` WHERE ` + clause +
		fmt.Sprintf(` ORDER BY COALESCE(r.is_featured, false) DESC, COALESCE(r.priority_score, 0) DESC, t.created_at DESC LIMIT $%d OFFSET $%d`, idx, idx+1)
	args = append(args, f.Limit, offset)

	list := []domain.Technician{}
	if err := r.db.SelectContext(ctx, &list, query, args...); err != nil {
		return nil, 0, fmt.Errorf("list technicians: %w", err)
	}
	return list, total, nil
}

func (r *postgresWorkforceRepository) UpdateTechnician(ctx context.Context, id uuid.UUID, req domain.UpdateTechnicianRequest) error {
	sets := []string{"updated_at = NOW()"}
	args := []interface{}{}
	idx := 1

	addSet := func(col string, val interface{}) {
		sets = append(sets, fmt.Sprintf("%s = $%d", col, idx))
		args = append(args, val)
		idx++
	}

	if req.FullName != nil {
		addSet("full_name", *req.FullName)
	}
	if req.ProfileImageURL != nil {
		addSet("profile_image_url", *req.ProfileImageURL)
	}
	if req.PhonePublic != nil {
		addSet("phone_public", *req.PhonePublic)
	}
	if req.Role != nil {
		addSet("role", *req.Role)
	}
	if req.Specializations != nil {
		raw, err := json.Marshal(req.Specializations)
		if err != nil {
			return fmt.Errorf("marshal specializations: %w", err)
		}
		addSet("specializations", raw)
	}
	if req.GovernorateID != nil {
		addSet("governorate_id", *req.GovernorateID)
	}
	if req.DistrictID != nil {
		addSet("district_id", *req.DistrictID)
	}
	if req.ExperienceYears != nil {
		addSet("experience_years", *req.ExperienceYears)
	}
	if req.Bio != nil {
		addSet("bio", *req.Bio)
	}
	if req.IsActive != nil {
		addSet("is_active", *req.IsActive)
	}
	if req.LevelID != nil {
		addSet("level_id", *req.LevelID)
	}

	if len(sets) == 1 {
		return nil
	}

	query := fmt.Sprintf(`UPDATE technicians SET %s WHERE id = $%d`, strings.Join(sets, ", "), idx)
	args = append(args, id)
	if _, err := r.db.ExecContext(ctx, query, args...); err != nil {
		return fmt.Errorf("update technician: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) SetTechnicianVerification(ctx context.Context, id uuid.UUID, isVerified bool, level int) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE technicians SET is_verified = $1, verification_level = $2, updated_at = NOW() WHERE id = $3`,
		isVerified, level, id)
	if err != nil {
		return fmt.Errorf("verify technician: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) SetTechnicianAvailabilityStatus(ctx context.Context, id uuid.UUID, status string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE technicians SET availability_status = $1, updated_at = NOW() WHERE id = $2`, status, id)
	if err != nil {
		return fmt.Errorf("set availability status: %w", err)
	}
	return nil
}

// UpdateTechnicianLevel promotes/demotes a technician based on jobs count and rating.
func (r *postgresWorkforceRepository) UpdateTechnicianLevel(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE technicians t
		SET level_id = (
			SELECT l.id FROM technician_levels l
			WHERE t.completed_jobs_count >= l.min_jobs AND t.rating >= l.min_rating
			ORDER BY l.sort_order DESC
			LIMIT 1
		), updated_at = NOW()
		WHERE t.id = $1`
	if _, err := r.db.ExecContext(ctx, query, id); err != nil {
		return fmt.Errorf("update technician level: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) IncrementCompletedJobs(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE technicians SET completed_jobs_count = completed_jobs_count + 1, updated_at = NOW() WHERE id = $1`, id)
	if err != nil {
		return fmt.Errorf("increment completed jobs: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) RecalculateTechnicianRating(ctx context.Context, id uuid.UUID) error {
	query := `
		UPDATE technicians SET rating = COALESCE((
			SELECT ROUND(AVG((quality_rating + punctuality_rating + speed_rating)::numeric / 3), 2)
			FROM customer_reviews WHERE technician_id = $1
		), 0), updated_at = NOW()
		WHERE id = $1`
	if _, err := r.db.ExecContext(ctx, query, id); err != nil {
		return fmt.Errorf("recalculate rating: %w", err)
	}
	return nil
}

// RecordDispatchResponse updates acceptance rate and average response time.
func (r *postgresWorkforceRepository) RecordDispatchResponse(ctx context.Context, id uuid.UUID, accepted bool, responseMinutes int) error {
	query := `
		UPDATE technicians t SET
			acceptance_rate = COALESCE((
				SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'accepted') /
				       NULLIF(COUNT(*) FILTER (WHERE status IN ('accepted','rejected','expired')), 0), 2)
				FROM dispatch_queue WHERE technician_id = $1
			), 100.00),
			avg_response_minutes = CASE
				WHEN $2 THEN GREATEST(0, (t.avg_response_minutes + $3) / 2)
				ELSE t.avg_response_minutes
			END,
			updated_at = NOW()
		WHERE t.id = $1`
	if _, err := r.db.ExecContext(ctx, query, id, accepted, responseMinutes); err != nil {
		return fmt.Errorf("record dispatch response: %w", err)
	}
	return nil
}

// --- Availability ---

func (r *postgresWorkforceRepository) GetAvailability(ctx context.Context, technicianID uuid.UUID) (*domain.TechnicianAvailability, error) {
	var a domain.TechnicianAvailability
	query := `
		SELECT id, technician_id, status, available_from::text, available_until::text,
		       working_days, current_lat, current_lng, last_status_change_at, updated_at
		FROM technician_availability WHERE technician_id = $1`
	if err := r.db.GetContext(ctx, &a, query, technicianID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get availability: %w", err)
	}
	return &a, nil
}

func (r *postgresWorkforceRepository) UpsertAvailability(ctx context.Context, technicianID uuid.UUID, req domain.UpdateAvailabilityRequest) error {
	days := req.WorkingDays
	if days == nil {
		days = []string{"sat", "sun", "mon", "tue", "wed", "thu"}
	}
	raw, err := json.Marshal(days)
	if err != nil {
		return fmt.Errorf("marshal working days: %w", err)
	}

	query := `
		INSERT INTO technician_availability (technician_id, status, available_from, available_until, working_days, last_status_change_at, updated_at)
		VALUES ($1, $2, $3::time, $4::time, $5, NOW(), NOW())
		ON CONFLICT (technician_id) DO UPDATE SET
			status = EXCLUDED.status,
			available_from = EXCLUDED.available_from,
			available_until = EXCLUDED.available_until,
			working_days = EXCLUDED.working_days,
			last_status_change_at = CASE WHEN technician_availability.status <> EXCLUDED.status THEN NOW() ELSE technician_availability.last_status_change_at END,
			updated_at = NOW()`
	if _, err := r.db.ExecContext(ctx, query, technicianID, req.Status, req.AvailableFrom, req.AvailableUntil, raw); err != nil {
		return fmt.Errorf("upsert availability: %w", err)
	}
	return r.SetTechnicianAvailabilityStatus(ctx, technicianID, req.Status)
}

// --- Service zones ---

func (r *postgresWorkforceRepository) ReplaceServiceZones(ctx context.Context, technicianID uuid.UUID, governorateIDs []int, primary *int) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.ExecContext(ctx, `DELETE FROM technician_service_zones WHERE technician_id = $1`, technicianID); err != nil {
		return fmt.Errorf("clear zones: %w", err)
	}
	for i, gid := range governorateIDs {
		isPrimary := (primary != nil && *primary == gid) || (primary == nil && i == 0)
		if _, err := tx.ExecContext(ctx,
			`INSERT INTO technician_service_zones (technician_id, governorate_id, is_primary) VALUES ($1, $2, $3)`,
			technicianID, gid, isPrimary); err != nil {
			return fmt.Errorf("insert zone: %w", err)
		}
	}
	return tx.Commit()
}

func (r *postgresWorkforceRepository) ListServiceZones(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianServiceZone, error) {
	list := []domain.TechnicianServiceZone{}
	query := `
		SELECT z.id, z.technician_id, z.governorate_id, z.is_primary, z.created_at,
		       g.name_ar AS governorate_name_ar
		FROM technician_service_zones z
		LEFT JOIN governorates g ON g.id = z.governorate_id
		WHERE z.technician_id = $1
		ORDER BY z.is_primary DESC, g.name_ar`
	if err := r.db.SelectContext(ctx, &list, query, technicianID); err != nil {
		return nil, fmt.Errorf("list zones: %w", err)
	}
	return list, nil
}

// --- Wallet ---

func (r *postgresWorkforceRepository) GetWallet(ctx context.Context, technicianID uuid.UUID) (*domain.TechnicianWallet, error) {
	var w domain.TechnicianWallet
	query := `SELECT * FROM technician_wallet WHERE technician_id = $1`
	if err := r.db.GetContext(ctx, &w, query, technicianID); err != nil {
		if err == sql.ErrNoRows {
			if _, insErr := r.db.ExecContext(ctx,
				`INSERT INTO technician_wallet (technician_id) VALUES ($1) ON CONFLICT DO NOTHING`, technicianID); insErr != nil {
				return nil, fmt.Errorf("init wallet: %w", insErr)
			}
			if err2 := r.db.GetContext(ctx, &w, query, technicianID); err2 != nil {
				return nil, fmt.Errorf("get wallet: %w", err2)
			}
			return &w, nil
		}
		return nil, fmt.Errorf("get wallet: %w", err)
	}
	return &w, nil
}

func (r *postgresWorkforceRepository) CreditWallet(ctx context.Context, technicianID uuid.UUID, payout, commission float64) error {
	query := `
		INSERT INTO technician_wallet (technician_id, balance_iqd, total_earned_iqd, total_commission_iqd, pending_payout_iqd)
		VALUES ($1, $2, $2, $3, $2)
		ON CONFLICT (technician_id) DO UPDATE SET
			balance_iqd = technician_wallet.balance_iqd + EXCLUDED.balance_iqd,
			total_earned_iqd = technician_wallet.total_earned_iqd + EXCLUDED.total_earned_iqd,
			total_commission_iqd = technician_wallet.total_commission_iqd + EXCLUDED.total_commission_iqd,
			pending_payout_iqd = technician_wallet.pending_payout_iqd + EXCLUDED.pending_payout_iqd,
			updated_at = NOW()`
	if _, err := r.db.ExecContext(ctx, query, technicianID, payout, commission); err != nil {
		return fmt.Errorf("credit wallet: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) SettleWallet(ctx context.Context, technicianID uuid.UUID) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.ExecContext(ctx, `
		UPDATE technician_wallet
		SET balance_iqd = 0, pending_payout_iqd = 0, last_settlement_at = NOW(), updated_at = NOW()
		WHERE technician_id = $1`, technicianID); err != nil {
		return fmt.Errorf("settle wallet: %w", err)
	}

	if _, err := tx.ExecContext(ctx, `
		UPDATE service_pricing sp SET payment_status = 'settled', settled_at = NOW()
		FROM service_orders so
		WHERE sp.order_id = so.id AND so.assigned_technician_id = $1
		  AND sp.payment_status IN ('unpaid', 'pending', 'paid_to_technician')`, technicianID); err != nil {
		return fmt.Errorf("settle pricing rows: %w", err)
	}

	return tx.Commit()
}

// --- Documents ---

func (r *postgresWorkforceRepository) AddDocument(ctx context.Context, d *domain.TechnicianDocument) error {
	query := `
		INSERT INTO technician_documents (id, technician_id, type, url, status)
		VALUES ($1, $2, $3, $4, 'pending')`
	if _, err := r.db.ExecContext(ctx, query, d.ID, d.TechnicianID, d.Type, d.URL); err != nil {
		return fmt.Errorf("add document: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) ListDocuments(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianDocument, error) {
	list := []domain.TechnicianDocument{}
	query := `SELECT * FROM technician_documents WHERE technician_id = $1 ORDER BY created_at DESC`
	if err := r.db.SelectContext(ctx, &list, query, technicianID); err != nil {
		return nil, fmt.Errorf("list documents: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) UpdateDocumentStatus(ctx context.Context, docID uuid.UUID, status domain.DocumentStatus, reviewer uuid.UUID) error {
	query := `UPDATE technician_documents SET status = $1, reviewed_by = $2, reviewed_at = NOW() WHERE id = $3`
	if _, err := r.db.ExecContext(ctx, query, status, reviewer, docID); err != nil {
		return fmt.Errorf("update document status: %w", err)
	}
	return nil
}

// --- Portfolio ---

func (r *postgresWorkforceRepository) AddPortfolioItem(ctx context.Context, p *domain.TechnicianPortfolio) error {
	query := `
		INSERT INTO technician_portfolio (
			id, technician_id, title, description, before_images, after_images, video_url,
			project_type, system_capacity_kw, governorate, city, execution_date
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.TechnicianID, p.Title, p.Description, p.BeforeImages, p.AfterImages, p.VideoURL,
		p.ProjectType, p.SystemCapacityKW, p.Governorate, p.City, p.ExecutionDate)
	if err != nil {
		return fmt.Errorf("add portfolio: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) ListPortfolio(ctx context.Context, technicianID uuid.UUID) ([]domain.TechnicianPortfolio, error) {
	list := []domain.TechnicianPortfolio{}
	query := `SELECT * FROM technician_portfolio WHERE technician_id = $1 ORDER BY created_at DESC`
	if err := r.db.SelectContext(ctx, &list, query, technicianID); err != nil {
		return nil, fmt.Errorf("list portfolio: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) DeletePortfolioItem(ctx context.Context, id uuid.UUID) error {
	if _, err := r.db.ExecContext(ctx, `DELETE FROM technician_portfolio WHERE id = $1`, id); err != nil {
		return fmt.Errorf("delete portfolio: %w", err)
	}
	return nil
}

// --- Ranking ---

func (r *postgresWorkforceRepository) GetRanking(ctx context.Context, technicianID uuid.UUID) (*domain.TechnicianRanking, error) {
	var rk domain.TechnicianRanking
	if err := r.db.GetContext(ctx, &rk, `SELECT * FROM technician_ranking WHERE technician_id = $1`, technicianID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get ranking: %w", err)
	}
	return &rk, nil
}

func (r *postgresWorkforceRepository) UpsertRanking(ctx context.Context, technicianID uuid.UUID, score float64) error {
	query := `
		INSERT INTO technician_ranking (technician_id, priority_score, last_recalculated_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (technician_id) DO UPDATE SET
			priority_score = EXCLUDED.priority_score,
			last_recalculated_at = NOW()`
	if _, err := r.db.ExecContext(ctx, query, technicianID, score); err != nil {
		return fmt.Errorf("upsert ranking: %w", err)
	}
	return nil
}

func (r *postgresWorkforceRepository) UpdateRankingFlags(ctx context.Context, technicianID uuid.UUID, req domain.UpdateRankingRequest) error {
	query := `
		INSERT INTO technician_ranking (technician_id, manual_order, is_featured, is_hidden)
		VALUES ($1, COALESCE($2, 0), COALESCE($3, false), COALESCE($4, false))
		ON CONFLICT (technician_id) DO UPDATE SET
			manual_order = COALESCE($2, technician_ranking.manual_order),
			is_featured = COALESCE($3, technician_ranking.is_featured),
			is_hidden = COALESCE($4, technician_ranking.is_hidden)`
	if _, err := r.db.ExecContext(ctx, query, technicianID, req.ManualOrder, req.IsFeatured, req.IsHidden); err != nil {
		return fmt.Errorf("update ranking flags: %w", err)
	}
	return nil
}

// --- Levels ---

func (r *postgresWorkforceRepository) ListLevels(ctx context.Context) ([]domain.TechnicianLevel, error) {
	list := []domain.TechnicianLevel{}
	if err := r.db.SelectContext(ctx, &list, `SELECT * FROM technician_levels ORDER BY sort_order`); err != nil {
		return nil, fmt.Errorf("list levels: %w", err)
	}
	return list, nil
}

func (r *postgresWorkforceRepository) CreateLevel(ctx context.Context, req domain.UpsertTechnicianLevelRequest) (*domain.TechnicianLevel, error) {
	var l domain.TechnicianLevel
	query := `
		INSERT INTO technician_levels (name, name_ar, min_jobs, min_rating, commission_rate, badge_color, sort_order)
		VALUES ($1, $2, $3, $4, $5, COALESCE(NULLIF($6, ''), '#CD7F32'), $7)
		RETURNING *`
	err := r.db.GetContext(ctx, &l, query, req.Name, req.NameAr, req.MinJobs, req.MinRating, req.CommissionRate, req.BadgeColor, req.SortOrder)
	if err != nil {
		return nil, fmt.Errorf("create level: %w", err)
	}
	return &l, nil
}

func (r *postgresWorkforceRepository) UpdateLevel(ctx context.Context, id uuid.UUID, req domain.UpsertTechnicianLevelRequest) error {
	query := `
		UPDATE technician_levels SET
			name = $1, name_ar = $2, min_jobs = $3, min_rating = $4,
			commission_rate = $5, badge_color = COALESCE(NULLIF($6, ''), badge_color), sort_order = $7
		WHERE id = $8`
	_, err := r.db.ExecContext(ctx, query, req.Name, req.NameAr, req.MinJobs, req.MinRating, req.CommissionRate, req.BadgeColor, req.SortOrder, id)
	if err != nil {
		return fmt.Errorf("update level: %w", err)
	}
	return nil
}
