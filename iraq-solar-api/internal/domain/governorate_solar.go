package domain

import "time"

type GovernorateSolarData struct {
	GovernorateID    int       `db:"governorate_id" json:"governorate_id"`
	PeakSunHours     float64   `db:"peak_sun_hours" json:"peak_sun_hours"`
	OptimalTiltAngle float64   `db:"optimal_tilt_angle" json:"optimal_tilt_angle"`
	MinWinterTempC   float64   `db:"min_winter_temp_c" json:"min_winter_temp_c"`
	MaxSummerTempC   float64   `db:"max_summer_temp_c" json:"max_summer_temp_c"`
	DatasetVersion   int       `db:"dataset_version" json:"dataset_version"`
	CreatedAt        time.Time `db:"created_at" json:"created_at"`
	UpdatedAt        time.Time `db:"updated_at" json:"updated_at"`

	// Joined field
	GovernorateNameAr string `db:"governorate_name_ar" json:"governorate_name_ar,omitempty"`
}

type GovernorateEnergyCost struct {
	GovernorateID           int       `db:"governorate_id" json:"governorate_id"`
	GeneratorAmperePriceIQD float64   `db:"generator_ampere_price_iqd" json:"generator_ampere_price_iqd"`
	GridTariffPerKwhIQD     float64   `db:"grid_tariff_per_kwh_iqd" json:"grid_tariff_per_kwh_iqd"`
	UpdatedAt               time.Time `db:"updated_at" json:"updated_at"`
}
