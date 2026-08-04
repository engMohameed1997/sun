package service

import (
	"context"
	"encoding/json"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type SolarCalculatorService struct {
	calcRepo repository.SolarCalculationRepository
}

func NewSolarCalculatorService(calcRepo repository.SolarCalculationRepository) *SolarCalculatorService {
	return &SolarCalculatorService{
		calcRepo: calcRepo,
	}
}

func (s *SolarCalculatorService) CalculateSystem(ctx context.Context, req domain.SolarCalculationRequest, userID *uuid.UUID) domain.SystemRecommendation {
	peakSunHours := req.PeakSunHours
	if peakSunHours <= 0 {
		peakSunHours = 5.5 // Standard average for Iraq & MENA region
	}

	autonomyDays := req.AutonomyDays
	if autonomyDays <= 0 {
		autonomyDays = 1 // 1 day backup by default
	}

	panelWattage := req.PanelWattage
	if panelWattage <= 0 {
		panelWattage = 550 // 550W Mono-PERC / N-Type Tier-1 panel
	}

	// 1. Calculate Required Solar Array kW
	systemLossFactor := 1.25 // 25% loss (cables, inverter efficiency, dust, temp coefficient)
	arrayKW := (req.DailyConsumptionkWh / peakSunHours) * systemLossFactor
	arrayKW = math.Round(arrayKW*100) / 100

	// 2. Panel Count
	panelCapacityKW := float64(panelWattage) / 1000.0
	panelCount := int(math.Ceil(arrayKW / panelCapacityKW))
	actualArrayKW := math.Round((float64(panelCount)*panelCapacityKW)*100) / 100

	// 3. Recommended Inverter Size (kW)
	inverterKW := math.Round((actualArrayKW*1.2)*10) / 10
	if inverterKW < 3.0 {
		inverterKW = 3.0
	}

	// 4. Battery Capacity (kWh)
	dodFactor := 1.25 // 80% Depth of Discharge for LiFePO4
	batteryCapacitykWh := math.Round((req.DailyConsumptionkWh*float64(autonomyDays)*dodFactor)*10) / 10

	// 5. Estimated System Cost (IQD)
	costSolarAndInverterIQD := actualArrayKW * 650.0 * 1500.0
	costBatteryStorageIQD := batteryCapacitykWh * 250.0 * 1500.0
	totalCostIQD := math.Round((costSolarAndInverterIQD + costBatteryStorageIQD))

	// 6. Annual Generation & CO2 Savings
	annualGenerationkWh := actualArrayKW * peakSunHours * 365.0
	co2SavedTonsPerYear := math.Round((annualGenerationkWh*0.0007)*100) / 100

	recommendation := domain.SystemRecommendation{
		RecommendedSystemSizekW: actualArrayKW,
		RecommendedInverterkW:  inverterKW,
		RecommendedBatterykWh: batteryCapacitykWh,
		RequiredPanelCount:     panelCount,
		EstimatedCostIQD:       totalCostIQD,
		DailyGenerationkWh:     math.Round((actualArrayKW*peakSunHours)*100) / 100,
		CO2SavedTonsPerYear:    co2SavedTonsPerYear,
	}

	// Save calculation to DB if repository is connected
	if s.calcRepo != nil {
		detailsBytes, _ := json.Marshal(recommendation)
		calcRecord := &domain.SolarCalculation{
			ID:                     uuid.New(),
			UserID:                 userID,
			DailyConsumptionkWh:    req.DailyConsumptionkWh,
			PeakSunHours:           peakSunHours,
			SystemSizekW:           actualArrayKW,
			RecommendedInverterkW:  inverterKW,
			RecommendedBatterykWh: batteryCapacitykWh,
			PanelCount:             panelCount,
			EstimatedCostIQD:       totalCostIQD,
			Details:                detailsBytes,
			CreatedAt:              time.Now(),
		}
		_ = s.calcRepo.Create(ctx, calcRecord)
	}

	return recommendation
}

func (s *SolarCalculatorService) GetUserCalculations(ctx context.Context, userID uuid.UUID) ([]domain.SolarCalculation, error) {
	if s.calcRepo != nil {
		return s.calcRepo.FindByUserID(ctx, userID)
	}
	return []domain.SolarCalculation{}, nil
}


// --- Homeowner Calculators Implementation ---

func (s *SolarCalculatorService) CalculateROI(ctx context.Context, req domain.ROICalculationRequest) domain.ROICalculationResponse {
	monthlySavingsIQD := req.MonthlyGeneratorFeeIQD + req.MonthlyNationalGridFeeIQD
	if monthlySavingsIQD <= 0 {
		monthlySavingsIQD = 225000.0 // Default ~150 USD baseline in IQD
	}

	annualSavingsIQD := monthlySavingsIQD * 12.0
	paybackYears := req.SystemCostIQD / annualSavingsIQD
	paybackYears = math.Round(paybackYears*10) / 10

	fiveYearSavingsIQD := (annualSavingsIQD * 5.0) - req.SystemCostIQD
	tenYearSavingsIQD := (annualSavingsIQD * 10.0) - req.SystemCostIQD

	return domain.ROICalculationResponse{
		MonthlySavingsIQD:  math.Round(monthlySavingsIQD),
		AnnualSavingsIQD:   math.Round(annualSavingsIQD),
		PaybackPeriodYears: paybackYears,
		FiveYearSavingsIQD: math.Round(fiveYearSavingsIQD),
		TenYearSavingsIQD:  math.Round(tenYearSavingsIQD),
	}
}

func (s *SolarCalculatorService) CalculateBatteryRuntime(ctx context.Context, req domain.BatteryRuntimeRequest) domain.BatteryRuntimeResponse {
	dodPercent := 0.90 // 90% for Lithium LiFePO4 by default
	switch req.BatteryType {
	case "lead_acid":
		dodPercent = 0.50
	case "gel":
		dodPercent = 0.60
	}

	usableCapacity := req.BatteryCapacitykWh * dodPercent
	runtimeHours := usableCapacity / req.CurrentLoadkW
	runtimeHours = math.Round(runtimeHours*10) / 10

	return domain.BatteryRuntimeResponse{
		RuntimeHours:            runtimeHours,
		UsableCapacitykWh:       math.Round(usableCapacity*100) / 100,
		DepthOfDischargePercent: dodPercent * 100.0,
	}
}

func (s *SolarCalculatorService) CalculateApplianceConsumption(ctx context.Context, req domain.ApplianceConsumptionRequest) domain.ApplianceConsumptionResponse {
	quantity := req.Quantity
	if quantity <= 0 {
		quantity = 1
	}

	hourlykWh := (req.Wattage * float64(quantity)) / 1000.0
	dailykWh := hourlykWh * req.DailyHours
	monthlykWh := dailykWh * 30.0

	return domain.ApplianceConsumptionResponse{
		HourlykWh:  math.Round(hourlykWh*1000) / 1000,
		DailykWh:   math.Round(dailykWh*100) / 100,
		MonthlykWh: math.Round(monthlykWh*100) / 100,
		Appliance:  req.ApplianceName,
	}
}

func (s *SolarCalculatorService) CalculateRoofCapacity(ctx context.Context, req domain.RoofCapacityRequest) domain.RoofCapacityResponse {
	panelWattage := req.PanelWattage
	if panelWattage <= 0 {
		panelWattage = 550
	}

	panelAreaM2 := 2.58 // Average Tier-1 550W panel dimensions (2.27m x 1.13m)
	totalArea := req.LengthMeters * req.WidthMeters
	usableArea := totalArea * (1.0 - (req.ObstructionPercentage / 100.0))

	maxPanels := int(math.Floor(usableArea / panelAreaM2))
	maxCapacitykW := (float64(maxPanels) * float64(panelWattage)) / 1000.0

	return domain.RoofCapacityResponse{
		TotalAreaM2:   math.Round(totalArea*100) / 100,
		UsableAreaM2:  math.Round(usableArea*100) / 100,
		MaxPanelCount: maxPanels,
		MaxCapacitykW: math.Round(maxCapacitykW*100) / 100,
	}
}

func (s *SolarCalculatorService) CalculateFullKitCost(ctx context.Context, req domain.FullKitCostRequest) domain.FullKitCostResponse {
	equipmentCostIQD := ((req.SystemSizekW * 450.0) + (req.BatterykWh * 220.0)) * 1500.0
	installationCostIQD := 0.0
	if req.IncludeInstallation {
		installationCostIQD = ((req.SystemSizekW * 80.0) + 150.0) * 1500.0
	}
	totalCostIQD := equipmentCostIQD + installationCostIQD

	summary := fmt.Sprintf("منظومة طاقة شمسية متكاملة قدرة %.1f kW مع بطاريات بسعة %.1f kWh", req.SystemSizekW, req.BatterykWh)
	actionURL := fmt.Sprintf("/products?min_kw=%.1f&max_kw=%.1f", req.SystemSizekW*0.9, req.SystemSizekW*1.1)

	return domain.FullKitCostResponse{
		EstimatedTotalIQD:    math.Round(totalCostIQD),
		EquipmentCostIQD:     math.Round(equipmentCostIQD),
		InstallationCostIQD:  math.Round(installationCostIQD),
		MatchingKitSummary:   summary,
		MarketplaceActionURL: actionURL,
	}
}

// --- Technician Calculators Implementation ---

func (s *SolarCalculatorService) CalculateCableSizing(ctx context.Context, req domain.CableSizingRequest) domain.CableSizingResponse {
	allowableDrop := req.AllowableDropPercent
	if allowableDrop <= 0 {
		allowableDrop = 2.5 // 2.5% standard allowable voltage drop
	}

	rho := 0.01724 // Copper resistivity (ohm*mm2/m)
	if req.WireMaterial == "aluminum" {
		rho = 0.0282
	}

	allowableVolts := req.SystemVoltage * (allowableDrop / 100.0)
	calcMM2 := (2.0 * req.DistanceMeters * req.CurrentAmps * rho) / allowableVolts

	// Standard cable sizes in mm2
	standardSizes := []float64{2.5, 4.0, 6.0, 10.0, 16.0, 25.0, 35.0, 50.0, 70.0, 95.0, 120.0}
	selectedSize := standardSizes[len(standardSizes)-1]
	for _, sz := range standardSizes {
		if sz >= calcMM2 {
			selectedSize = sz
			break
		}
	}

	actualDropVolts := (2.0 * req.DistanceMeters * req.CurrentAmps * rho) / selectedSize
	actualDropPercent := (actualDropVolts / req.SystemVoltage) * 100.0
	powerLossWatts := actualDropVolts * req.CurrentAmps

	return domain.CableSizingResponse{
		RecommendedCrossSectionMM2: math.Round(calcMM2*100) / 100,
		StandardCableSizeMM2:       selectedSize,
		ActualVoltageDropVolts:     math.Round(actualDropVolts*100) / 100,
		ActualVoltageDropPercent:   math.Round(actualDropPercent*100) / 100,
		PowerLossWatts:             math.Round(powerLossWatts*100) / 100,
	}
}

func (s *SolarCalculatorService) CalculateMPPTString(ctx context.Context, req domain.MPPTStringRequest) domain.MPPTStringResponse {
	tempCoeff := req.PanelTempCoeffVoc
	if tempCoeff == 0 {
		tempCoeff = -0.28 // Standard -0.28%/C for mono PERC
	}

	minTemp := req.MinTempC // e.g. 0C winter
	maxTemp := req.MaxTempC // e.g. 50C summer

	// Voltage adjusted for temperature
	maxVocCold := req.PanelVoc * (1.0 + (tempCoeff / 100.0) * (minTemp - 25.0))
	minVmpHot := req.PanelVmp * (1.0 + (tempCoeff / 100.0) * (maxTemp - 25.0))

	maxPanels := int(math.Floor(req.InverterMaxVoc / maxVocCold))
	minPanels := int(math.Ceil(req.InverterMinMPPTV / minVmpHot))
	recommendedPanels := (maxPanels + minPanels) / 2

	return domain.MPPTStringResponse{
		MaxPanelsPerString:         maxPanels,
		MinPanelsPerString:         minPanels,
		RecommendedPanelsPerString: recommendedPanels,
		MaxVocColdEst:              math.Round(maxVocCold*10) / 10,
		MinVmpHotEst:               math.Round(minVmpHot*10) / 10,
	}
}

func (s *SolarCalculatorService) CalculateBreakersFuses(ctx context.Context, req domain.BreakerFuseRequest) domain.BreakerFuseResponse {
	dcBreakerAmps := math.Ceil((req.ArrayIsc * 1.25) / 5.0) * 5.0
	acBreakerAmps := math.Ceil((req.InverterOutputAmps * 1.25) / 5.0) * 5.0
	stringFuseAmps := math.Ceil(req.ArrayIsc * 1.56)

	return domain.BreakerFuseResponse{
		DCBreakerAmps:      dcBreakerAmps,
		ACBreakerAmps:      acBreakerAmps,
		StringFuseAmps:     stringFuseAmps,
		SPDRecommendedType: "Type 2 DC 1000V Surge Protective Device (SPD)",
	}
}

func (s *SolarCalculatorService) CalculateBatteryBank(ctx context.Context, req domain.BatteryBankRequest) domain.BatteryBankResponse {
	seriesCount := int(math.Round(req.TargetVoltage / req.SingleBatteryVoltage))
	if seriesCount <= 0 {
		seriesCount = 1
	}

	targetAhTotal := (req.TargetCapacitykWh * 1000.0) / req.TargetVoltage
	parallelCount := int(math.Ceil(targetAhTotal / req.SingleBatteryAh))
	if parallelCount <= 0 {
		parallelCount = 1
	}

	totalBatteries := seriesCount * parallelCount
	actualCapacitykWh := (float64(totalBatteries) * req.SingleBatteryVoltage * req.SingleBatteryAh) / 1000.0

	note := fmt.Sprintf("توصيل %d بطارية على التوالي للحصول على %d V، ثم توصيل %d سلاسل على التوازي", seriesCount, int(req.TargetVoltage), parallelCount)

	return domain.BatteryBankResponse{
		TotalBatteriesNeeded: totalBatteries,
		SeriesCount:          seriesCount,
		ParallelCount:        parallelCount,
		ActualCapacitykWh:    math.Round(actualCapacitykWh*100) / 100,
		WiringDiagramNote:    note,
	}
}

func (s *SolarCalculatorService) CalculateSolarProduction(ctx context.Context, req domain.SolarProductionRequest) domain.SolarProductionResponse {
	peakSunHours := 5.5
	optimalTilt := 32.0 // Default for Iraq

	switch req.Province {
	case "بغداد", "Baghdad":
		peakSunHours = 5.5
		optimalTilt = 33.0
	case "البصرة", "Basra":
		peakSunHours = 5.8
		optimalTilt = 30.0
	case "أربيل", "Erbil", "دهوك", "Duhok":
		peakSunHours = 5.2
		optimalTilt = 36.0
	case "النجف", "Najaf", "كربلاء", "Karbala":
		peakSunHours = 5.6
		optimalTilt = 32.0
	}

	if req.TiltAngle > 0 {
		optimalTilt = req.TiltAngle
	}

	dailyAvg := req.SystemSizekW * peakSunHours * 0.82 // 0.82 derating factor for real conditions
	monthly := dailyAvg * 30.0
	annual := dailyAvg * 365.0

	return domain.SolarProductionResponse{
		Province:             req.Province,
		OptimalTiltAngle:     optimalTilt,
		DailyAvgkWh:          math.Round(dailyAvg*100) / 100,
		MonthlyProductionkWh: math.Round(monthly*100) / 100,
		AnnualProductionkWh:  math.Round(annual*100) / 100,
	}
}

