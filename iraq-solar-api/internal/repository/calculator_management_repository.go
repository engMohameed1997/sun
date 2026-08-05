package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type CalculatorManagementRepository interface {
	GetCalculatorsForRole(ctx context.Context, role string) ([]domain.Calculator, error)
	ListAllAdmin(ctx context.Context) ([]domain.CalculatorAdminResponse, error)
	GetByID(ctx context.Context, id uuid.UUID) (*domain.CalculatorAdminResponse, error)
	Create(ctx context.Context, req domain.CreateCalculatorRequest) (*domain.CalculatorAdminResponse, error)
	Update(ctx context.Context, id uuid.UUID, req domain.UpdateCalculatorRequest) (*domain.CalculatorAdminResponse, error)
	UpdateStatus(ctx context.Context, id uuid.UUID, isActive bool) error
}

type postgresCalculatorManagementRepository struct {
	db *sqlx.DB
}

func NewCalculatorManagementRepository(db *sqlx.DB) CalculatorManagementRepository {
	return &postgresCalculatorManagementRepository{db: db}
}

func (r *postgresCalculatorManagementRepository) GetCalculatorsForRole(ctx context.Context, role string) ([]domain.Calculator, error) {
	if r.db == nil {
		return nil, nil
	}

	var calcs []domain.Calculator
	query := `
		SELECT DISTINCT c.id, c.route_key, c.title_ar, c.title_en, c.subtitle_ar, c.subtitle_en,
		       c.icon_key, c.background_image_url, c.badge, c.color_hex, c.is_featured, c.sort_order,
		       c.is_active, c.version, c.created_at, c.updated_at
		FROM calculators c
		JOIN calculator_roles cr ON c.id = cr.calculator_id
		WHERE cr.role = $1 AND c.is_active = true
		ORDER BY c.is_featured DESC, c.sort_order ASC
	`
	err := r.db.SelectContext(ctx, &calcs, query, role)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch calculators for role %s: %w", role, err)
	}
	return calcs, nil
}

func (r *postgresCalculatorManagementRepository) ListAllAdmin(ctx context.Context) ([]domain.CalculatorAdminResponse, error) {
	if r.db == nil {
		return nil, nil
	}

	var calcs []domain.Calculator
	query := `SELECT id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, background_image_url, badge, color_hex, is_featured, sort_order, is_active, version, created_at, updated_at FROM calculators ORDER BY sort_order ASC`
	err := r.db.SelectContext(ctx, &calcs, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list admin calculators: %w", err)
	}

	var res []domain.CalculatorAdminResponse
	for _, c := range calcs {
		roles, _ := r.getRolesForCalculator(ctx, c.ID)
		res = append(res, mapAdminResponse(c, roles))
	}
	return res, nil
}

func (r *postgresCalculatorManagementRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.CalculatorAdminResponse, error) {
	if r.db == nil {
		return nil, nil
	}

	var c domain.Calculator
	query := `SELECT id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, background_image_url, badge, color_hex, is_featured, sort_order, is_active, version, created_at, updated_at FROM calculators WHERE id = $1`
	err := r.db.GetContext(ctx, &c, query, id)
	if err != nil {
		return nil, fmt.Errorf("calculator not found: %w", err)
	}

	roles, _ := r.getRolesForCalculator(ctx, c.ID)
	resp := mapAdminResponse(c, roles)
	return &resp, nil
}

func (r *postgresCalculatorManagementRepository) Create(ctx context.Context, req domain.CreateCalculatorRequest) (*domain.CalculatorAdminResponse, error) {
	if r.db == nil {
		return nil, fmt.Errorf("db not initialized")
	}

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	newID := uuid.New()
	query := `
		INSERT INTO calculators (id, route_key, title_ar, title_en, subtitle_ar, subtitle_en, icon_key, background_image_url, badge, color_hex, is_featured, sort_order)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`
	_, err = tx.ExecContext(ctx, query, newID, req.RouteKey, req.TitleAr, req.TitleEn, req.SubtitleAr, req.SubtitleEn, req.IconKey, req.BackgroundImageUrl, req.Badge, req.ColorHex, req.IsFeatured, req.SortOrder)
	if err != nil {
		return nil, fmt.Errorf("failed to create calculator: %w", err)
	}

	for _, role := range req.AllowedRoles {
		_, err = tx.ExecContext(ctx, `INSERT INTO calculator_roles (calculator_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING`, newID, role)
		if err != nil {
			return nil, fmt.Errorf("failed to insert calculator role: %w", err)
		}
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return r.GetByID(ctx, newID)
}

func (r *postgresCalculatorManagementRepository) Update(ctx context.Context, id uuid.UUID, req domain.UpdateCalculatorRequest) (*domain.CalculatorAdminResponse, error) {
	if r.db == nil {
		return nil, fmt.Errorf("db not initialized")
	}

	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	query := `
		UPDATE calculators
		SET title_ar = $1, title_en = $2, subtitle_ar = $3, subtitle_en = $4, icon_key = $5,
		    background_image_url = $6, badge = $7, color_hex = $8, is_featured = $9, sort_order = $10,
		    version = version + 1, updated_at = CURRENT_TIMESTAMP
		WHERE id = $11
	`
	_, err = tx.ExecContext(ctx, query, req.TitleAr, req.TitleEn, req.SubtitleAr, req.SubtitleEn, req.IconKey, req.BackgroundImageUrl, req.Badge, req.ColorHex, req.IsFeatured, req.SortOrder, id)
	if err != nil {
		return nil, fmt.Errorf("failed to update calculator: %w", err)
	}

	_, err = tx.ExecContext(ctx, `DELETE FROM calculator_roles WHERE calculator_id = $1`, id)
	if err != nil {
		return nil, fmt.Errorf("failed to clear old roles: %w", err)
	}

	for _, role := range req.AllowedRoles {
		_, err = tx.ExecContext(ctx, `INSERT INTO calculator_roles (calculator_id, role) VALUES ($1, $2) ON CONFLICT DO NOTHING`, id, role)
		if err != nil {
			return nil, fmt.Errorf("failed to re-insert calculator role: %w", err)
		}
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	return r.GetByID(ctx, id)
}

func (r *postgresCalculatorManagementRepository) UpdateStatus(ctx context.Context, id uuid.UUID, isActive bool) error {
	if r.db == nil {
		return nil
	}
	query := `UPDATE calculators SET is_active = $1, version = version + 1, updated_at = CURRENT_TIMESTAMP WHERE id = $2`
	_, err := r.db.ExecContext(ctx, query, isActive, id)
	return err
}

func (r *postgresCalculatorManagementRepository) getRolesForCalculator(ctx context.Context, calcID uuid.UUID) ([]string, error) {
	var roles []string
	query := `SELECT role FROM calculator_roles WHERE calculator_id = $1`
	err := r.db.SelectContext(ctx, &roles, query, calcID)
	return roles, err
}

func mapAdminResponse(c domain.Calculator, roles []string) domain.CalculatorAdminResponse {
	sub := ""
	if c.SubtitleAr != nil {
		sub = *c.SubtitleAr
	}
	bg := ""
	if c.BackgroundImageUrl != nil {
		bg = *c.BackgroundImageUrl
	}
	badge := ""
	if c.Badge != nil {
		badge = *c.Badge
	}

	return domain.CalculatorAdminResponse{
		CalculatorPublicResponse: domain.CalculatorPublicResponse{
			ID:                 c.ID,
			RouteKey:           c.RouteKey,
			Title:              c.TitleAr,
			Subtitle:           sub,
			IconKey:            c.IconKey,
			BackgroundImageUrl: bg,
			Badge:              badge,
			ColorHex:           c.ColorHex,
			IsFeatured:         c.IsFeatured,
			SortOrder:          c.SortOrder,
			Version:            c.Version,
		},
		AllowedRoles: roles,
		IsActive:     c.IsActive,
		CreatedAt:    c.CreatedAt,
		UpdatedAt:    c.UpdatedAt,
	}
}
