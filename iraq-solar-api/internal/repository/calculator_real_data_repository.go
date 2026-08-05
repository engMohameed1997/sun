package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type GovernorateSolarRepository interface {
	GetSolarDataByGovernorateID(ctx context.Context, id int) (*domain.GovernorateSolarData, error)
	GetEnergyCostByGovernorateID(ctx context.Context, id int) (*domain.GovernorateEnergyCost, error)
	ListAllSolarData(ctx context.Context) ([]domain.GovernorateSolarData, error)
}

type AppliancePresetRepository interface {
	ListActive(ctx context.Context) ([]domain.AppliancePreset, error)
}

type MarketPriceIndexRepository interface {
	GetLatestIndex(ctx context.Context) (*domain.MarketPriceIndex, error)
	UpdateIndex(ctx context.Context, idx *domain.MarketPriceIndex) error
}

type postgresCalculatorRealDataRepository struct {
	db *sqlx.DB
}

func NewCalculatorRealDataRepository(db *sqlx.DB) (GovernorateSolarRepository, AppliancePresetRepository, MarketPriceIndexRepository) {
	repo := &postgresCalculatorRealDataRepository{db: db}
	return repo, repo, repo
}

func (r *postgresCalculatorRealDataRepository) GetSolarDataByGovernorateID(ctx context.Context, id int) (*domain.GovernorateSolarData, error) {
	if r.db == nil {
		return r.getDefaultSolarData(id), nil
	}

	var data domain.GovernorateSolarData
	query := `
		SELECT s.governorate_id, s.peak_sun_hours, s.optimal_tilt_angle, s.min_winter_temp_c, s.max_summer_temp_c, s.dataset_version, s.created_at, s.updated_at, g.name_ar AS governorate_name_ar
		FROM governorate_solar_data s
		JOIN governorates g ON s.governorate_id = g.id
		WHERE s.governorate_id = $1 LIMIT 1
	`
	err := r.db.GetContext(ctx, &data, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return r.getDefaultSolarData(id), nil
		}
		return nil, fmt.Errorf("failed to get governorate solar data: %w", err)
	}
	return &data, nil
}

func (r *postgresCalculatorRealDataRepository) GetEnergyCostByGovernorateID(ctx context.Context, id int) (*domain.GovernorateEnergyCost, error) {
	if r.db == nil {
		return &domain.GovernorateEnergyCost{GovernorateID: id, GeneratorAmperePriceIQD: 18000, GridTariffPerKwhIQD: 35}, nil
	}

	var data domain.GovernorateEnergyCost
	query := `SELECT governorate_id, generator_ampere_price_iqd, grid_tariff_per_kwh_iqd, updated_at FROM governorate_energy_cost WHERE governorate_id = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &data, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return &domain.GovernorateEnergyCost{GovernorateID: id, GeneratorAmperePriceIQD: 18000, GridTariffPerKwhIQD: 35}, nil
		}
		return nil, fmt.Errorf("failed to get governorate energy cost: %w", err)
	}
	return &data, nil
}

func (r *postgresCalculatorRealDataRepository) ListAllSolarData(ctx context.Context) ([]domain.GovernorateSolarData, error) {
	if r.db == nil {
		return []domain.GovernorateSolarData{*r.getDefaultSolarData(1)}, nil
	}

	var list []domain.GovernorateSolarData
	query := `
		SELECT s.governorate_id, s.peak_sun_hours, s.optimal_tilt_angle, s.min_winter_temp_c, s.max_summer_temp_c, s.dataset_version, s.created_at, s.updated_at, g.name_ar AS governorate_name_ar
		FROM governorate_solar_data s
		JOIN governorates g ON s.governorate_id = g.id
		ORDER BY s.governorate_id ASC
	`
	err := r.db.SelectContext(ctx, &list, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list governorate solar data: %w", err)
	}
	return list, nil
}

func (r *postgresCalculatorRealDataRepository) ListActive(ctx context.Context) ([]domain.AppliancePreset, error) {
	if r.db == nil {
		return nil, nil
	}

	var list []domain.AppliancePreset
	query := `SELECT id, name_ar, name_en, default_wattage, power_factor, surge_multiplier, voltage, phase, frequency, default_daily_hours, category, icon_key, sort_order, is_active, created_at FROM appliance_presets WHERE is_active = true ORDER BY sort_order ASC`
	err := r.db.SelectContext(ctx, &list, query)
	if err != nil {
		return nil, fmt.Errorf("failed to list appliance presets: %w", err)
	}
	return list, nil
}

func (r *postgresCalculatorRealDataRepository) GetLatestIndex(ctx context.Context) (*domain.MarketPriceIndex, error) {
	if r.db == nil {
		return r.getDefaultPriceIndex(), nil
	}

	var idx domain.MarketPriceIndex
	query := `SELECT id, panel_price_per_watt_iqd, min_panel_price_per_watt_iqd, max_panel_price_per_watt_iqd, inverter_price_per_kw_iqd, battery_price_per_kwh_iqd, usd_to_iqd_rate, installation_cost_per_kw_iqd, installation_base_fee_iqd, pricing_version, updated_at FROM market_price_index WHERE id = 1 LIMIT 1`
	err := r.db.GetContext(ctx, &idx, query)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return r.getDefaultPriceIndex(), nil
		}
		return nil, fmt.Errorf("failed to get market price index: %w", err)
	}
	return &idx, nil
}

func (r *postgresCalculatorRealDataRepository) UpdateIndex(ctx context.Context, idx *domain.MarketPriceIndex) error {
	if r.db == nil {
		return nil
	}

	query := `
		UPDATE market_price_index
		SET panel_price_per_watt_iqd = :panel_price_per_watt_iqd,
		    min_panel_price_per_watt_iqd = :min_panel_price_per_watt_iqd,
		    max_panel_price_per_watt_iqd = :max_panel_price_per_watt_iqd,
		    inverter_price_per_kw_iqd = :inverter_price_per_kw_iqd,
		    battery_price_per_kwh_iqd = :battery_price_per_kwh_iqd,
		    usd_to_iqd_rate = :usd_to_iqd_rate,
		    installation_cost_per_kw_iqd = :installation_cost_per_kw_iqd,
		    installation_base_fee_iqd = :installation_base_fee_iqd,
		    pricing_version = pricing_version + 1,
		    updated_at = NOW()
		WHERE id = 1
	`
	_, err := r.db.NamedExecContext(ctx, query, idx)
	if err != nil {
		return fmt.Errorf("failed to update market price index: %w", err)
	}
	return nil
}

func (r *postgresCalculatorRealDataRepository) getDefaultSolarData(id int) *domain.GovernorateSolarData {
	return &domain.GovernorateSolarData{
		GovernorateID:    id,
		PeakSunHours:     5.5,
		OptimalTiltAngle: 33.0,
		MinWinterTempC:   0.0,
		MaxSummerTempC:   48.0,
		DatasetVersion:   1,
	}
}

func (r *postgresCalculatorRealDataRepository) getDefaultPriceIndex() *domain.MarketPriceIndex {
	return &domain.MarketPriceIndex{
		ID:                       1,
		PanelPricePerWattIQD:     300.0,
		MinPanelPricePerWattIQD:  250.0,
		MaxPanelPricePerWattIQD:  380.0,
		InverterPricePerKwIQD:    150000.0,
		BatteryPricePerKwhIQD:   350000.0,
		UsdToIqdRate:             1500.0,
		InstallationCostPerKwIQD: 120000.0,
		InstallationBaseFeeIQD:   225000.0,
		PricingVersion:           1,
	}
}
