package domain

import "time"

type MarketPriceIndex struct {
	ID                       int       `db:"id" json:"id"`
	PanelPricePerWattIQD     float64   `db:"panel_price_per_watt_iqd" json:"panel_price_per_watt_iqd"`
	MinPanelPricePerWattIQD  float64   `db:"min_panel_price_per_watt_iqd" json:"min_panel_price_per_watt_iqd"`
	MaxPanelPricePerWattIQD  float64   `db:"max_panel_price_per_watt_iqd" json:"max_panel_price_per_watt_iqd"`
	InverterPricePerKwIQD    float64   `db:"inverter_price_per_kw_iqd" json:"inverter_price_per_kw_iqd"`
	BatteryPricePerKwhIQD   float64   `db:"battery_price_per_kwh_iqd" json:"battery_price_per_kwh_iqd"`
	UsdToIqdRate             float64   `db:"usd_to_iqd_rate" json:"usd_to_iqd_rate"`
	InstallationCostPerKwIQD float64   `db:"installation_cost_per_kw_iqd" json:"installation_cost_per_kw_iqd"`
	InstallationBaseFeeIQD   float64   `db:"installation_base_fee_iqd" json:"installation_base_fee_iqd"`
	PricingVersion           int       `db:"pricing_version" json:"pricing_version"`
	UpdatedAt                time.Time `db:"updated_at" json:"updated_at"`
}
