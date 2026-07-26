package service

import (
	"context"
	"testing"

	"github.com/iraq-solar/api/internal/domain"
)

func TestSolarCalculatorService(t *testing.T) {
	calcService := NewSolarCalculatorService(nil)

	t.Run("Standard Household Calculation (25 kWh/day)", func(t *testing.T) {
		req := domain.SolarCalculationRequest{
			DailyConsumptionkWh: 25.0,
			PeakSunHours:        5.5,
			AutonomyDays:        1,
			PanelWattage:        550,
		}

		res := calcService.CalculateSystem(context.Background(), req, nil)

		if res.RecommendedSystemSizekW <= 0 {
			t.Errorf("expected system size > 0, got %f", res.RecommendedSystemSizekW)
		}
		if res.RequiredPanelCount <= 0 {
			t.Errorf("expected panel count > 0, got %d", res.RequiredPanelCount)
		}
		if res.RecommendedInverterkW <= 0 {
			t.Errorf("expected inverter rating > 0, got %f", res.RecommendedInverterkW)
		}
		if res.RecommendedBatterykWh <= 0 {
			t.Errorf("expected battery capacity > 0, got %f", res.RecommendedBatterykWh)
		}
		if res.EstimatedCostIQD <= 0 {
			t.Errorf("expected estimated cost > 0, got %f", res.EstimatedCostIQD)
		}

		t.Logf("Calculated system: Size=%.2fkW, Panels=%d, Inverter=%.1fkW, Battery=%.1fkWh, Cost=%.0f د.ع",
			res.RecommendedSystemSizekW, res.RequiredPanelCount, res.RecommendedInverterkW, res.RecommendedBatterykWh, res.EstimatedCostIQD)
	})

	t.Run("ROI & Payback Calculation", func(t *testing.T) {
		req := domain.ROICalculationRequest{
			MonthlyGeneratorFeeIQD: 225000.0,
			SystemCostIQD:          4500000.0,
		}
		res := calcService.CalculateROI(context.Background(), req)
		if res.MonthlySavingsIQD != 225000.0 {
			t.Errorf("expected 225000.0 monthly savings, got %f", res.MonthlySavingsIQD)
		}
		if res.PaybackPeriodYears <= 0 {
			t.Errorf("expected payback period > 0, got %f", res.PaybackPeriodYears)
		}
	})

	t.Run("Battery Runtime Calculation", func(t *testing.T) {
		req := domain.BatteryRuntimeRequest{
			BatteryCapacitykWh: 10.0,
			BatteryType:        "lithium",
			CurrentLoadkW:      2.0,
		}
		res := calcService.CalculateBatteryRuntime(context.Background(), req)
		if res.RuntimeHours <= 0 {
			t.Errorf("expected runtime > 0, got %f", res.RuntimeHours)
		}
		if res.UsableCapacitykWh != 9.0 { // 90% DoD
			t.Errorf("expected 9.0 kWh usable, got %f", res.UsableCapacitykWh)
		}
	})

	t.Run("Cable Sizing & Voltage Drop", func(t *testing.T) {
		req := domain.CableSizingRequest{
			CurrentAmps:    25.0,
			DistanceMeters: 15.0,
			SystemVoltage:  48.0,
			WireMaterial:   "copper",
		}
		res := calcService.CalculateCableSizing(context.Background(), req)
		if res.StandardCableSizeMM2 <= 0 {
			t.Errorf("expected valid cable size, got %f", res.StandardCableSizeMM2)
		}
		if res.ActualVoltageDropPercent > 2.5 {
			t.Errorf("expected drop <= 2.5%%, got %f%%", res.ActualVoltageDropPercent)
		}
	})

	t.Run("MPPT String Sizing", func(t *testing.T) {
		req := domain.MPPTStringRequest{
			PanelVoc:       49.5,
			PanelVmp:       41.2,
			MinTempC:       0,
			MaxTempC:       50,
			InverterMaxVoc: 500,
			InverterMinMPPTV: 120,
			InverterMaxMPPTV: 450,
		}
		res := calcService.CalculateMPPTString(context.Background(), req)
		if res.MaxPanelsPerString <= 0 || res.MinPanelsPerString <= 0 {
			t.Errorf("expected positive panel limits, got max=%d min=%d", res.MaxPanelsPerString, res.MinPanelsPerString)
		}
	})

	t.Run("Battery Bank Configuration", func(t *testing.T) {
		req := domain.BatteryBankRequest{
			TargetVoltage:        48.0,
			TargetCapacitykWh:    9.6,
			SingleBatteryVoltage: 12.0,
			SingleBatteryAh:      200.0,
		}
		res := calcService.CalculateBatteryBank(context.Background(), req)
		if res.SeriesCount != 4 {
			t.Errorf("expected 4 batteries in series for 48V from 12V, got %d", res.SeriesCount)
		}
		if res.TotalBatteriesNeeded <= 0 {
			t.Errorf("expected total batteries > 0, got %d", res.TotalBatteriesNeeded)
		}
	})
}

