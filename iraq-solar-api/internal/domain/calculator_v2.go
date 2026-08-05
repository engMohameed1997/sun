package domain

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// SolarPhysicsCalculator interface defines the pure physics calculation contract
type SolarPhysicsCalculator interface {
	Calculate(ctx context.Context, input interface{}) (*CalculationResult, error)
}

type CalculationCostEstimate struct {
	MedianTotalIQD float64 `json:"median_total_iqd"`
	MinTotalIQD    float64 `json:"min_total_iqd"`
	MaxTotalIQD    float64 `json:"max_total_iqd"`
	EquipmentIQD   float64 `json:"equipment_iqd"`
	InstallationIQD float64 `json:"installation_iqd"`
}

type CalculationResult struct {
	SystemSizekW            float64                 `json:"system_size_kw,omitempty"`
	RecommendedInverterkW   float64                 `json:"recommended_inverter_kw,omitempty"`
	RecommendedBatterykWh  float64                 `json:"recommended_battery_kwh,omitempty"`
	RequiredPanelCount      int                     `json:"required_panel_count,omitempty"`
	RecommendedPanelWattage int                     `json:"recommended_panel_wattage,omitempty"`
	DailyGenerationkWh      float64                 `json:"daily_generation_kwh,omitempty"`
	AnnualGenerationkWh     float64                 `json:"annual_generation_kwh,omitempty"`
	CO2SavedTonsPerYear     float64                 `json:"co2_saved_tons_per_year,omitempty"`
	RuntimeHours            float64                 `json:"runtime_hours,omitempty"`
	UsableCapacitykWh       float64                 `json:"usable_capacity_kwh,omitempty"`
	RecommendedDoDPercent  float64                 `json:"recommended_dod_percent,omitempty"`
	CableCrossSectionMM2    float64                 `json:"cable_cross_section_mm2,omitempty"`
	StandardCableSizeMM2    float64                 `json:"standard_cable_size_mm2,omitempty"`
	VoltageDropPercent      float64                 `json:"voltage_drop_percent,omitempty"`
	MaxPanelsPerString      int                     `json:"max_panels_per_string,omitempty"`
	MinPanelsPerString      int                     `json:"min_panels_per_string,omitempty"`
	RecommendedPanelsPerStr int                     `json:"recommended_panels_per_string,omitempty"`
	DCBreakerAmps           float64                 `json:"dc_breaker_amps,omitempty"`
	ACBreakerAmps           float64                 `json:"ac_breaker_amps,omitempty"`
	StringFuseAmps          float64                 `json:"string_fuse_amps,omitempty"`
	SeriesBatteryCount      int                     `json:"series_battery_count,omitempty"`
	ParallelBatteryCount    int                     `json:"parallel_battery_count,omitempty"`
	TotalBatteriesNeeded    int                     `json:"total_batteries_needed,omitempty"`
	MaxRoofPanels           int                     `json:"max_roof_panels,omitempty"`
	UsableRoofAreaM2        float64                 `json:"usable_roof_area_m2,omitempty"`
	MonthlySavingsIQD       float64                 `json:"monthly_savings_iqd,omitempty"`
	PaybackPeriodYears      float64                 `json:"payback_period_years,omitempty"`
	EstimatedCost           CalculationCostEstimate `json:"estimated_cost"`
	Assumptions             map[string]string       `json:"assumptions"`
	Warnings                []string                `json:"warnings"`
	Notes                   []string                `json:"notes"`
}

type ScoredProductRecommendation struct {
	ProductID        uuid.UUID `json:"product_id"`
	StoreID          *uuid.UUID `json:"store_id,omitempty"`
	StoreName        string    `json:"store_name"`
	ProductName      string    `json:"product_name"`
	Brand            string    `json:"brand"`
	Model            string    `json:"model"`
	ProductType      string    `json:"product_type"`
	Image            string    `json:"image,omitempty"`
	UnitPriceIQD     float64   `json:"unit_price_iqd"`
	RequiredQuantity int       `json:"required_quantity"`
	TotalPriceIQD    float64   `json:"total_price_iqd"`
	StockAvailable   int       `json:"stock_available"`
	Score            int       `json:"score"` // 0-100 match percentage
	MatchReasons     []string  `json:"match_reasons"`
}

type CategorizedRecommendations struct {
	RecommendedKits      []ScoredProductRecommendation `json:"recommended_kits"`
	RecommendedPanels    []ScoredProductRecommendation `json:"recommended_panels"`
	RecommendedBatteries []ScoredProductRecommendation `json:"recommended_batteries"`
	RecommendedInverters []ScoredProductRecommendation `json:"recommended_inverters"`
	RecommendedCables    []ScoredProductRecommendation `json:"recommended_cables"`
	RecommendedBreakers  []ScoredProductRecommendation `json:"recommended_breakers"`
}

type ResponseMetadata struct {
	CalculatorVersion int       `json:"calculator_version"`
	PricingVersion    int       `json:"pricing_version"`
	DatasetVersion    int       `json:"dataset_version"`
	GeneratedAt       time.Time `json:"generated_at"`
}

type CalculatorStandardResponse struct {
	Calculation     *CalculationResult          `json:"calculation"`
	Recommendations CategorizedRecommendations `json:"recommendations"`
	Metadata        ResponseMetadata            `json:"metadata"`
}
