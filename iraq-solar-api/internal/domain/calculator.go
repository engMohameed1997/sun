package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type SolarCalculationRequest struct {
	DailyConsumptionkWh float64 `json:"daily_consumption_kwh" binding:"required,gt=0"`
	PeakSunHours        float64 `json:"peak_sun_hours"` // Defaults to 5.5 for MENA/Iraq if 0
	AutonomyDays        int     `json:"autonomy_days"`   // Backup days (default 1)
	SystemVoltage       int     `json:"system_voltage"`  // 12V, 24V, 48V (default 48V)
	PanelWattage        int     `json:"panel_wattage"`   // e.g. 550W
}

type SystemRecommendation struct {
	RecommendedSystemSizekW  float64 `json:"system_size_kw"`
	RecommendedInverterkW   float64 `json:"recommended_inverter_kw"`
	RecommendedBatterykWh  float64 `json:"recommended_battery_kwh"`
	RequiredPanelCount      int     `json:"required_panel_count"`
	EstimatedCostIQD        float64 `json:"estimated_cost_iqd"`
	DailyGenerationkWh      float64 `json:"daily_generation_kwh"`
	CO2SavedTonsPerYear     float64 `json:"co2_saved_tons_per_year"`
}

type SolarCalculation struct {
	ID                     uuid.UUID       `db:"id" json:"id"`
	UserID                 *uuid.UUID      `db:"user_id" json:"user_id,omitempty"`
	DailyConsumptionkWh    float64         `db:"daily_consumption_kwh" json:"daily_consumption_kwh"`
	PeakSunHours           float64         `db:"peak_sun_hours" json:"peak_sun_hours"`
	SystemSizekW           float64         `db:"system_size_kw" json:"system_size_kw"`
	RecommendedInverterkW  float64         `db:"recommended_inverter_kw" json:"recommended_inverter_kw"`
	RecommendedBatterykWh float64         `db:"recommended_battery_kwh" json:"recommended_battery_kwh"`
	PanelCount             int             `db:"panel_count" json:"panel_count"`
	EstimatedCostIQD       float64         `db:"estimated_cost_iqd" json:"estimated_cost_iqd"`
	Details                json.RawMessage `db:"details" json:"details"`
	CreatedAt              time.Time       `db:"created_at" json:"created_at"`
}

// --- Homeowner Calculators ---

type ROICalculationRequest struct {
	MonthlyGeneratorFeeIQD     float64 `json:"monthly_generator_fee_iqd"`
	MonthlyNationalGridFeeIQD float64 `json:"monthly_national_grid_fee_iqd"`
	SystemCostIQD              float64 `json:"system_cost_iqd" binding:"required,gt=0"`
}

type ROICalculationResponse struct {
	MonthlySavingsIQD  float64 `json:"monthly_savings_iqd"`
	AnnualSavingsIQD   float64 `json:"annual_savings_iqd"`
	PaybackPeriodYears float64 `json:"payback_period_years"`
	FiveYearSavingsIQD float64 `json:"five_year_savings_iqd"`
	TenYearSavingsIQD  float64 `json:"ten_year_savings_iqd"`
}

type BatteryRuntimeRequest struct {
	BatteryCapacitykWh float64 `json:"battery_capacity_kwh" binding:"required,gt=0"`
	BatteryType        string  `json:"battery_type"` // "lithium", "lead_acid", "gel"
	CurrentLoadkW      float64 `json:"current_load_kw" binding:"required,gt=0"`
}

type BatteryRuntimeResponse struct {
	RuntimeHours            float64 `json:"runtime_hours"`
	UsableCapacitykWh       float64 `json:"usable_capacity_kwh"`
	DepthOfDischargePercent float64 `json:"depth_of_discharge_percent"`
}

type ApplianceConsumptionRequest struct {
	ApplianceName string  `json:"appliance_name"`
	Wattage       float64 `json:"wattage" binding:"required,gt=0"`
	Quantity      int     `json:"quantity"`
	DailyHours    float64 `json:"daily_hours" binding:"required,gt=0"`
}

type ApplianceConsumptionResponse struct {
	HourlykWh  float64 `json:"hourly_kwh"`
	DailykWh   float64 `json:"daily_kwh"`
	MonthlykWh float64 `json:"monthly_kwh"`
	Appliance  string  `json:"appliance"`
}

type RoofCapacityRequest struct {
	LengthMeters           float64 `json:"length_meters" binding:"required,gt=0"`
	WidthMeters            float64 `json:"width_meters" binding:"required,gt=0"`
	PanelWattage           int     `json:"panel_wattage"`
	ObstructionPercentage float64 `json:"obstruction_percentage"`
}

type RoofCapacityResponse struct {
	TotalAreaM2   float64 `json:"total_area_m2"`
	UsableAreaM2  float64 `json:"usable_area_m2"`
	MaxPanelCount int     `json:"max_panel_count"`
	MaxCapacitykW float64 `json:"max_capacity_kw"`
}

type FullKitCostRequest struct {
	SystemSizekW        float64 `json:"system_size_kw" binding:"required,gt=0"`
	BatterykWh          float64 `json:"battery_kwh"`
	InverterkW          float64 `json:"inverter_kw"`
	PanelCount          int     `json:"panel_count"`
	IncludeInstallation bool    `json:"include_installation"`
}

type FullKitCostResponse struct {
	EstimatedTotalIQD    float64 `json:"estimated_total_iqd"`
	EquipmentCostIQD     float64 `json:"equipment_cost_iqd"`
	InstallationCostIQD  float64 `json:"installation_cost_iqd"`
	MatchingKitSummary   string  `json:"matching_kit_summary"`
	MarketplaceActionURL string  `json:"marketplace_action_url"`
}

// --- Technician Calculators ---

type CableSizingRequest struct {
	CurrentAmps          float64 `json:"current_amps" binding:"required,gt=0"`
	DistanceMeters       float64 `json:"distance_meters" binding:"required,gt=0"`
	SystemVoltage        float64 `json:"system_voltage" binding:"required,gt=0"`
	AllowableDropPercent float64 `json:"allowable_drop_percent"` // Default 2.5%
	WireMaterial         string  `json:"wire_material"`          // "copper" or "aluminum"
}

type CableSizingResponse struct {
	RecommendedCrossSectionMM2 float64 `json:"recommended_cross_section_mm2"`
	StandardCableSizeMM2       float64 `json:"standard_cable_size_mm2"`
	ActualVoltageDropVolts     float64 `json:"actual_voltage_drop_volts"`
	ActualVoltageDropPercent   float64 `json:"actual_voltage_drop_percent"`
	PowerLossWatts             float64 `json:"power_loss_watts"`
}

type MPPTStringRequest struct {
	PanelVoc          float64 `json:"panel_voc" binding:"required,gt=0"`
	PanelVmp          float64 `json:"panel_vmp" binding:"required,gt=0"`
	PanelTempCoeffVoc float64 `json:"panel_temp_coeff_voc"` // e.g. -0.28 (%/C)
	MinTempC          float64 `json:"min_temp_c"`           // Lowest winter temp (e.g. 0C)
	MaxTempC          float64 `json:"max_temp_c"`           // Highest summer temp (e.g. 50C)
	InverterMaxVoc    float64 `json:"inverter_max_voc" binding:"required,gt=0"`
	InverterMinMPPTV  float64 `json:"inverter_min_mppt_v" binding:"required,gt=0"`
	InverterMaxMPPTV  float64 `json:"inverter_max_mppt_v" binding:"required,gt=0"`
}

type MPPTStringResponse struct {
	MaxPanelsPerString         int     `json:"max_panels_per_string"`
	MinPanelsPerString         int     `json:"min_panels_per_string"`
	RecommendedPanelsPerString int     `json:"recommended_panels_per_string"`
	MaxVocColdEst              float64 `json:"max_voc_cold_est"`
	MinVmpHotEst               float64 `json:"min_vmp_hot_est"`
}

type BreakerFuseRequest struct {
	ArrayIsc           float64 `json:"array_isc" binding:"required,gt=0"`
	InverterOutputAmps float64 `json:"inverter_output_amps" binding:"required,gt=0"`
	SystemVoltage      float64 `json:"system_voltage"`
}

type BreakerFuseResponse struct {
	DCBreakerAmps     float64 `json:"dc_breaker_amps"`
	ACBreakerAmps     float64 `json:"ac_breaker_amps"`
	StringFuseAmps    float64 `json:"string_fuse_amps"`
	SPDRecommendedType string  `json:"spd_recommended_type"`
}

type BatteryBankRequest struct {
	TargetVoltage       float64 `json:"target_voltage" binding:"required,gt=0"`
	TargetCapacitykWh   float64 `json:"target_capacity_kwh" binding:"required,gt=0"`
	SingleBatteryVoltage float64 `json:"single_battery_voltage" binding:"required,gt=0"`
	SingleBatteryAh      float64 `json:"single_battery_ah" binding:"required,gt=0"`
}

type BatteryBankResponse struct {
	TotalBatteriesNeeded int     `json:"total_batteries_needed"`
	SeriesCount          int     `json:"series_count"`
	ParallelCount        int     `json:"parallel_count"`
	ActualCapacitykWh    float64 `json:"actual_capacity_kwh"`
	WiringDiagramNote    string  `json:"wiring_diagram_note"`
}

type SolarProductionRequest struct {
	Province      string  `json:"province"`
	SystemSizekW  float64 `json:"system_size_kw" binding:"required,gt=0"`
	TiltAngle     float64 `json:"tilt_angle"`
}

type SolarProductionResponse struct {
	Province             string  `json:"province"`
	OptimalTiltAngle     float64 `json:"optimal_tilt_angle"`
	DailyAvgkWh          float64 `json:"daily_avg_kwh"`
	MonthlyProductionkWh float64 `json:"monthly_production_kwh"`
	AnnualProductionkWh  float64 `json:"annual_production_kwh"`
}

