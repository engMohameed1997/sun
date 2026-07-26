package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type SolarCalculationRepository interface {
	Create(ctx context.Context, calc *domain.SolarCalculation) error
	FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.SolarCalculation, error)
}

type postgresSolarCalculationRepository struct {
	db *sqlx.DB
}

func NewSolarCalculationRepository(db *sqlx.DB) SolarCalculationRepository {
	return &postgresSolarCalculationRepository{db: db}
}

func (r *postgresSolarCalculationRepository) Create(ctx context.Context, calc *domain.SolarCalculation) error {
	if r.db == nil {
		return nil
	}

	query := `
		INSERT INTO solar_calculations (
			id, user_id, daily_consumption_kwh, peak_sun_hours, system_size_kw,
			recommended_inverter_kw, recommended_battery_kwh, panel_count, estimated_cost_usd, details, created_at
		) VALUES (
			:id, :user_id, :daily_consumption_kwh, :peak_sun_hours, :system_size_kw,
			:recommended_inverter_kw, :recommended_battery_kwh, :panel_count, :estimated_cost_usd, :details, :created_at
		)
	`

	_, err := r.db.NamedExecContext(ctx, query, calc)
	if err != nil {
		return fmt.Errorf("failed to insert solar calculation: %w", err)
	}
	return nil
}

func (r *postgresSolarCalculationRepository) FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.SolarCalculation, error) {
	if r.db == nil {
		return nil, nil
	}

	var calculations []domain.SolarCalculation
	query := `SELECT id, user_id, daily_consumption_kwh, peak_sun_hours, system_size_kw, recommended_inverter_kw, recommended_battery_kwh, panel_count, estimated_cost_usd, details, created_at FROM solar_calculations WHERE user_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &calculations, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to list solar calculations for user: %w", err)
	}
	return calculations, nil
}
