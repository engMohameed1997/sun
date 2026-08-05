package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/jmoiron/sqlx"
)

type BannerRepository struct {
	db *sqlx.DB
}

func NewBannerRepository(db *sqlx.DB) *BannerRepository {
	return &BannerRepository{db: db}
}

func (r *BannerRepository) CreateBanner(ctx context.Context, b *domain.Banner, placements []string, storeIDs []uuid.UUID, storeTargets []domain.BannerStoreTarget) error {
	if r.db == nil {
		return nil
	}

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}

	query := `
		INSERT INTO banners (
			id, image_url, mobile_image_url, priority, display_order, is_active,
			starts_at, ends_at, action_type, action_payload, targeting_rules,
			recurrence_type, recurrence_time, recurrence_end, timezone, created_by, merchant_id
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, $9, $10, $11,
			$12, $13, $14, $15, $16, $17
		) RETURNING created_at, updated_at`

	err = tx.QueryRowContext(
		ctx, query,
		b.ID, b.ImageURL, b.MobileImageURL, b.Priority, b.DisplayOrder, b.IsActive,
		b.StartsAt, b.EndsAt, b.ActionType, b.ActionPayload, b.TargetingRules,
		b.RecurrenceType, b.RecurrenceTime, b.RecurrenceEnd, b.Timezone, b.CreatedBy, b.MerchantID,
	).Scan(&b.CreatedAt, &b.UpdatedAt)

	if err != nil {
		return fmt.Errorf("failed to insert banner: %w", err)
	}

	// Insert placements
	for _, p := range placements {
		if p != "" {
			_, err = tx.ExecContext(ctx, "INSERT INTO banner_placements (banner_id, placement) VALUES ($1, $2) ON CONFLICT DO NOTHING", b.ID, p)
			if err != nil {
				return fmt.Errorf("failed to insert banner placement %s: %w", p, err)
			}
		}
	}

	// Insert store & branch assignments
	if len(storeTargets) > 0 {
		for _, st := range storeTargets {
			if (st.StoreID != nil && *st.StoreID != uuid.Nil) || (st.BranchID != nil && *st.BranchID != uuid.Nil) {
				_, err = tx.ExecContext(ctx, "INSERT INTO banner_stores (banner_id, store_id, branch_id) VALUES ($1, $2, $3)", b.ID, st.StoreID, st.BranchID)
				if err != nil {
					return fmt.Errorf("failed to insert banner store target: %w", err)
				}
			}
		}
	} else {
		for _, sid := range storeIDs {
			if sid != uuid.Nil {
				_, err = tx.ExecContext(ctx, "INSERT INTO banner_stores (banner_id, store_id) VALUES ($1, $2)", b.ID, sid)
				if err != nil {
					return fmt.Errorf("failed to insert banner store %s: %w", sid.String(), err)
				}
			}
		}
	}

	b.Placements = placements
	b.StoreIDs = storeIDs
	b.StoreTargets = storeTargets
	return tx.Commit()
}

func (r *BannerRepository) UpdateBanner(ctx context.Context, b *domain.Banner, placements []string, storeIDs []uuid.UUID, storeTargets []domain.BannerStoreTarget) error {
	if r.db == nil {
		return nil
	}

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	query := `
		UPDATE banners SET
			image_url = $1, mobile_image_url = $2, priority = $3, display_order = $4, is_active = $5,
			starts_at = $6, ends_at = $7, action_type = $8, action_payload = $9, targeting_rules = $10,
			recurrence_type = $11, recurrence_time = $12, recurrence_end = $13, timezone = $14,
			updated_at = NOW()
		WHERE id = $15`

	res, err := tx.ExecContext(
		ctx, query,
		b.ImageURL, b.MobileImageURL, b.Priority, b.DisplayOrder, b.IsActive,
		b.StartsAt, b.EndsAt, b.ActionType, b.ActionPayload, b.TargetingRules,
		b.RecurrenceType, b.RecurrenceTime, b.RecurrenceEnd, b.Timezone, b.ID,
	)
	if err != nil {
		return fmt.Errorf("failed to update banner: %w", err)
	}

	rows, _ := res.RowsAffected()
	if rows == 0 {
		return errors.New("banner not found")
	}

	if placements != nil {
		_, err = tx.ExecContext(ctx, "DELETE FROM banner_placements WHERE banner_id = $1", b.ID)
		if err != nil {
			return err
		}
		for _, p := range placements {
			if p != "" {
				_, err = tx.ExecContext(ctx, "INSERT INTO banner_placements (banner_id, placement) VALUES ($1, $2) ON CONFLICT DO NOTHING", b.ID, p)
				if err != nil {
					return err
				}
			}
		}
		b.Placements = placements
	}

	if storeTargets != nil || storeIDs != nil {
		_, err = tx.ExecContext(ctx, "DELETE FROM banner_stores WHERE banner_id = $1", b.ID)
		if err != nil {
			return err
		}
		if len(storeTargets) > 0 {
			for _, st := range storeTargets {
				if (st.StoreID != nil && *st.StoreID != uuid.Nil) || (st.BranchID != nil && *st.BranchID != uuid.Nil) {
					_, err = tx.ExecContext(ctx, "INSERT INTO banner_stores (banner_id, store_id, branch_id) VALUES ($1, $2, $3)", b.ID, st.StoreID, st.BranchID)
					if err != nil {
						return err
					}
				}
			}
		} else if storeIDs != nil {
			for _, sid := range storeIDs {
				if sid != uuid.Nil {
					_, err = tx.ExecContext(ctx, "INSERT INTO banner_stores (banner_id, store_id) VALUES ($1, $2)", b.ID, sid)
					if err != nil {
						return err
					}
				}
			}
		}
		b.StoreIDs = storeIDs
		b.StoreTargets = storeTargets
	}

	return tx.Commit()
}

func (r *BannerRepository) DeleteBanner(ctx context.Context, id uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "DELETE FROM banners WHERE id = $1", id)
	return err
}

func (r *BannerRepository) populateBannerRelations(ctx context.Context, b *domain.Banner) {
	if r.db == nil || b == nil {
		return
	}
	var placements []string
	_ = r.db.SelectContext(ctx, &placements, "SELECT placement FROM banner_placements WHERE banner_id = $1", b.ID)
	b.Placements = placements

	var storeIDs []uuid.UUID
	_ = r.db.SelectContext(ctx, &storeIDs, "SELECT DISTINCT store_id FROM banner_stores WHERE banner_id = $1 AND store_id IS NOT NULL", b.ID)
	b.StoreIDs = storeIDs

	var branchIDs []uuid.UUID
	_ = r.db.SelectContext(ctx, &branchIDs, "SELECT DISTINCT branch_id FROM banner_stores WHERE banner_id = $1 AND branch_id IS NOT NULL", b.ID)
	b.BranchIDs = branchIDs

	var targets []domain.BannerStoreTarget
	_ = r.db.SelectContext(ctx, &targets, "SELECT store_id, branch_id FROM banner_stores WHERE banner_id = $1", b.ID)
	b.StoreTargets = targets
}

func (r *BannerRepository) GetBannerByID(ctx context.Context, id uuid.UUID) (*domain.Banner, error) {
	if r.db == nil {
		return nil, nil
	}

	var b domain.Banner
	err := r.db.GetContext(ctx, &b, "SELECT * FROM banners WHERE id = $1", id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	r.populateBannerRelations(ctx, &b)
	return &b, nil
}

func (r *BannerRepository) ListRawActiveBannersByPlacement(ctx context.Context, placement string, storeID *uuid.UUID) ([]domain.Banner, error) {
	if r.db == nil {
		return []domain.Banner{}, nil
	}

	query := `
		SELECT DISTINCT b.*
		FROM banners b
		INNER JOIN banner_placements bp ON b.id = bp.banner_id
		LEFT JOIN banner_stores bs ON b.id = bs.banner_id
		WHERE b.is_active = true AND bp.placement = $1`

	args := []interface{}{placement}

	if storeID != nil && *storeID != uuid.Nil {
		query += ` AND (bs.store_id IS NULL OR bs.store_id = $2)`
		args = append(args, *storeID)
	}

	query += ` ORDER BY b.priority DESC, b.display_order ASC, b.created_at DESC`

	var banners []domain.Banner
	err := r.db.SelectContext(ctx, &banners, query, args...)
	if err != nil {
		return nil, err
	}

	for i := range banners {
		r.populateBannerRelations(ctx, &banners[i])
	}

	return banners, nil
}

func (r *BannerRepository) ListAdminBanners(ctx context.Context, merchantID *uuid.UUID, placement string, page, perPage int) ([]domain.Banner, int, error) {
	if r.db == nil {
		return []domain.Banner{}, 0, nil
	}

	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argIdx := 1

	if merchantID != nil {
		whereClause += fmt.Sprintf(" AND b.merchant_id = $%d", argIdx)
		args = append(args, *merchantID)
		argIdx++
	}

	if placement != "" {
		whereClause += fmt.Sprintf(" AND EXISTS (SELECT 1 FROM banner_placements bp WHERE bp.banner_id = b.id AND bp.placement = $%d)", argIdx)
		args = append(args, placement)
		argIdx++
	}

	countQuery := fmt.Sprintf("SELECT COUNT(DISTINCT b.id) FROM banners b %s", whereClause)
	var total int
	err := r.db.GetContext(ctx, &total, countQuery, args...)
	if err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * perPage
	query := fmt.Sprintf(`
		SELECT b.* FROM banners b
		%s
		ORDER BY b.priority DESC, b.display_order ASC, b.created_at DESC
		LIMIT $%d OFFSET $%d`, whereClause, argIdx, argIdx+1)

	args = append(args, perPage, offset)

	var banners []domain.Banner
	err = r.db.SelectContext(ctx, &banners, query, args...)
	if err != nil {
		return nil, 0, err
	}

	for i := range banners {
		r.populateBannerRelations(ctx, &banners[i])
	}

	return banners, total, nil
}

func (r *BannerRepository) ReorderBanners(ctx context.Context, bannerIDs []uuid.UUID) error {
	if r.db == nil {
		return nil
	}

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	for idx, id := range bannerIDs {
		_, err = tx.ExecContext(ctx, "UPDATE banners SET display_order = $1, updated_at = NOW() WHERE id = $2", idx+1, id)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

func (r *BannerRepository) RecordEvent(ctx context.Context, event *domain.BannerEvent) error {
	if r.db == nil {
		return nil
	}

	if event.ID == uuid.Nil {
		event.ID = uuid.New()
	}

	query := `INSERT INTO banner_events (id, banner_id, event_type, user_id, device_id, metadata) VALUES ($1, $2, $3, $4, $5, $6)`
	_, err := r.db.ExecContext(ctx, query, event.ID, event.BannerID, event.EventType, event.UserID, event.DeviceID, event.Metadata)
	if err != nil {
		return err
	}

	// Update summary table
	today := time.Now().Format("2006-01-02")
	isImpression := event.EventType == domain.EventImpression

	var isUnique bool
	if event.UserID != nil || event.DeviceID != nil {
		// Check uniqueness for today
		var count int
		checkQuery := `
			SELECT COUNT(*) FROM banner_events 
			WHERE banner_id = $1 AND event_type = $2 AND DATE(created_at) = $3
			AND (
				(user_id IS NOT NULL AND user_id = $4) OR 
				(device_id IS NOT NULL AND device_id = $5)
			) AND id != $6`
		_ = r.db.GetContext(ctx, &count, checkQuery, event.BannerID, event.EventType, today, event.UserID, event.DeviceID, event.ID)
		isUnique = count == 0
	}

	summaryQuery := `
		INSERT INTO banner_analytics_summary (banner_id, date, impressions, clicks, unique_views, unique_clicks)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (banner_id, date) DO UPDATE SET
			impressions = banner_analytics_summary.impressions + EXCLUDED.impressions,
			clicks = banner_analytics_summary.clicks + EXCLUDED.clicks,
			unique_views = banner_analytics_summary.unique_views + EXCLUDED.unique_views,
			unique_clicks = banner_analytics_summary.unique_clicks + EXCLUDED.unique_clicks,
			updated_at = NOW()`

	impInc, clkInc, uViewInc, uClkInc := 0, 0, 0, 0
	if isImpression {
		impInc = 1
		if isUnique {
			uViewInc = 1
		}
	} else {
		clkInc = 1
		if isUnique {
			uClkInc = 1
		}
	}

	_, _ = r.db.ExecContext(ctx, summaryQuery, event.BannerID, today, impInc, clkInc, uViewInc, uClkInc)
	return nil
}

func (r *BannerRepository) GetBannerAnalytics(ctx context.Context, bannerID uuid.UUID, days int) ([]domain.BannerAnalyticsSummary, error) {
	if r.db == nil {
		return []domain.BannerAnalyticsSummary{}, nil
	}

	if days <= 0 {
		days = 30
	}

	startDate := time.Now().AddDate(0, 0, -days).Format("2006-01-02")
	query := `
		SELECT banner_id, date::text as date, impressions, clicks, unique_views, unique_clicks
		FROM banner_analytics_summary
		WHERE banner_id = $1 AND date >= $2
		ORDER BY date DESC`

	var list []domain.BannerAnalyticsSummary
	err := r.db.SelectContext(ctx, &list, query, bannerID, startDate)
	if err != nil {
		return nil, err
	}

	for i := range list {
		if list[i].Impressions > 0 {
			list[i].CTR = float64(list[i].Clicks) / float64(list[i].Impressions) * 100
		}
	}

	return list, nil
}
