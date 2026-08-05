package service

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type SolarCalculatorEngine struct {
	solarRepo repository.GovernorateSolarRepository
	costRepo  repository.GovernorateSolarRepository
	indexRepo repository.MarketPriceIndexRepository
	presetRepo repository.AppliancePresetRepository
	recService *RecommendationService
}

func NewSolarCalculatorEngine(
	solarRepo repository.GovernorateSolarRepository,
	indexRepo repository.MarketPriceIndexRepository,
	presetRepo repository.AppliancePresetRepository,
	recService *RecommendationService,
) *SolarCalculatorEngine {
	return &SolarCalculatorEngine{
		solarRepo:  solarRepo,
		costRepo:   solarRepo,
		indexRepo:  indexRepo,
		presetRepo: presetRepo,
		recService: recService,
	}
}

// 1. System Sizing Calculator
func (e *SolarCalculatorEngine) CalculateSystemSizing(ctx context.Context, req domain.SolarCalculationRequest, govID int) *domain.CalculatorStandardResponse {
	psh := req.PeakSunHours
	solarData, _ := e.solarRepo.GetSolarDataByGovernorateID(ctx, govID)
	if psh <= 0 && solarData != nil {
		psh = solarData.PeakSunHours
	}
	if psh <= 0 {
		psh = 5.5
	}

	autonomyDays := req.AutonomyDays
	if autonomyDays <= 0 {
		autonomyDays = 1
	}

	panelWattage := req.PanelWattage
	if panelWattage <= 0 {
		panelWattage = 575 // Modern 575W N-Type benchmark
	}

	systemLossFactor := 1.25
	arrayKW := (req.DailyConsumptionkWh / psh) * systemLossFactor
	arrayKW = math.Round(arrayKW*100) / 100

	panelCapacityKW := float64(panelWattage) / 1000.0
	panelCount := int(math.Ceil(arrayKW / panelCapacityKW))
	actualArrayKW := math.Round((float64(panelCount)*panelCapacityKW)*100) / 100

	inverterKW := math.Round((actualArrayKW*1.2)*10) / 10
	if inverterKW < 3.0 {
		inverterKW = 3.0
	}

	dodFactor := 1.25 // 80% recommended DoD for LiFePO4
	batteryCapacitykWh := math.Round((req.DailyConsumptionkWh*float64(autonomyDays)*dodFactor)*10) / 10

	priceIndex, _ := e.indexRepo.GetLatestIndex(ctx)
	if priceIndex == nil {
		priceIndex = &domain.MarketPriceIndex{
			PanelPricePerWattIQD: 300, MinPanelPricePerWattIQD: 250, MaxPanelPricePerWattIQD: 380,
			InverterPricePerKwIQD: 150000, BatteryPricePerKwhIQD: 350000, InstallationCostPerKwIQD: 120000, InstallationBaseFeeIQD: 225000, PricingVersion: 1,
		}
	}

	equipCost := (actualArrayKW * 1000.0 * priceIndex.PanelPricePerWattIQD) + (inverterKW * priceIndex.InverterPricePerKwIQD) + (batteryCapacitykWh * priceIndex.BatteryPricePerKwhIQD)
	minEquipCost := (actualArrayKW * 1000.0 * priceIndex.MinPanelPricePerWattIQD) + (inverterKW * priceIndex.InverterPricePerKwIQD * 0.85) + (batteryCapacitykWh * priceIndex.BatteryPricePerKwhIQD * 0.85)
	maxEquipCost := (actualArrayKW * 1000.0 * priceIndex.MaxPanelPricePerWattIQD) + (inverterKW * priceIndex.InverterPricePerKwIQD * 1.15) + (batteryCapacitykWh * priceIndex.BatteryPricePerKwhIQD * 1.15)

	installCost := (actualArrayKW * priceIndex.InstallationCostPerKwIQD) + priceIndex.InstallationBaseFeeIQD

	dailyGen := math.Round((actualArrayKW*psh)*100) / 100
	annualGen := actualArrayKW * psh * 365.0
	co2Saved := math.Round((annualGen*0.0007)*100) / 100

	calcResult := &domain.CalculationResult{
		SystemSizekW:            actualArrayKW,
		RecommendedInverterkW:   inverterKW,
		RecommendedBatterykWh:  batteryCapacitykWh,
		RequiredPanelCount:      panelCount,
		RecommendedPanelWattage: panelWattage,
		DailyGenerationkWh:      dailyGen,
		AnnualGenerationkWh:     math.Round(annualGen),
		CO2SavedTonsPerYear:     co2Saved,
		EstimatedCost: domain.CalculationCostEstimate{
			MedianTotalIQD: math.Round(equipCost + installCost),
			MinTotalIQD:    math.Round(minEquipCost + installCost),
			MaxTotalIQD:    math.Round(maxEquipCost + installCost),
			EquipmentIQD:   math.Round(equipCost),
			InstallationIQD: math.Round(installCost),
		},
		Assumptions: map[string]string{
			"peak_sun_hours": fmt.Sprintf("%.1f hrs/day", psh),
			"system_loss":     "25% (cable, temp, inverter loss)",
			"recommended_dod": "80% DoD LiFePO4 Battery",
		},
		Warnings: []string{},
		Notes: []string{
			"تم إجراء الحساب الفيزيائي وتوليد نطاق الأسعار بناءً على المؤشرات الحالية بالسوق",
		},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	datasetVer := 1
	if solarData != nil {
		datasetVer = solarData.DatasetVersion
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    priceIndex.PricingVersion,
			DatasetVersion:    datasetVer,
			GeneratedAt:       time.Now(),
		},
	}
}

// 2. Roof Capacity Calculator
func (e *SolarCalculatorEngine) CalculateRoofCapacity(ctx context.Context, req domain.RoofCapacityRequest) *domain.CalculatorStandardResponse {
	panelWattage := req.PanelWattage
	if panelWattage <= 0 {
		panelWattage = 575
	}
	panelAreaM2 := 2.58
	totalArea := req.LengthMeters * req.WidthMeters
	usableArea := totalArea * (1.0 - (req.ObstructionPercentage / 100.0))

	maxPanels := int(math.Floor(usableArea / panelAreaM2))
	maxCapacitykW := (float64(maxPanels) * float64(panelWattage)) / 1000.0

	priceIndex, _ := e.indexRepo.GetLatestIndex(ctx)
	if priceIndex == nil {
		priceIndex = &domain.MarketPriceIndex{PanelPricePerWattIQD: 300, PricingVersion: 1}
	}

	panelCostIQD := maxCapacitykW * 1000.0 * priceIndex.PanelPricePerWattIQD

	calcResult := &domain.CalculationResult{
		MaxRoofPanels:           maxPanels,
		UsableRoofAreaM2:        math.Round(usableArea*100) / 100,
		SystemSizekW:            math.Round(maxCapacitykW*100) / 100,
		RequiredPanelCount:      maxPanels,
		RecommendedPanelWattage: panelWattage,
		EstimatedCost: domain.CalculationCostEstimate{
			MedianTotalIQD: math.Round(panelCostIQD),
			MinTotalIQD:    math.Round(panelCostIQD * 0.85),
			MaxTotalIQD:    math.Round(panelCostIQD * 1.15),
			EquipmentIQD:   math.Round(panelCostIQD),
		},
		Assumptions: map[string]string{
			"panel_area": fmt.Sprintf("%.2f m²", panelAreaM2),
			"obstruction": fmt.Sprintf("%.0f%%", req.ObstructionPercentage),
		},
		Warnings: []string{},
		Notes:    []string{"حساب أقصى سعة استيعابية للسطح متوافقة مع أبعاد الألواح التجارية"},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    priceIndex.PricingVersion,
			DatasetVersion:    1,
			GeneratedAt:       time.Now(),
		},
	}
}

// 3. Battery Runtime Calculator
func (e *SolarCalculatorEngine) CalculateBatteryRuntime(ctx context.Context, req domain.BatteryRuntimeRequest) *domain.CalculatorStandardResponse {
	dodPercent := 0.80 // 80% recommended DoD for longevity
	switch req.BatteryType {
	case "lead_acid":
		dodPercent = 0.50
	case "gel":
		dodPercent = 0.60
	case "lithium":
		dodPercent = 0.90
	}

	usableCapacity := req.BatteryCapacitykWh * dodPercent
	runtimeHours := usableCapacity / req.CurrentLoadkW
	runtimeHours = math.Round(runtimeHours*10) / 10

	calcResult := &domain.CalculationResult{
		RecommendedBatterykWh: req.BatteryCapacitykWh,
		UsableCapacitykWh:     math.Round(usableCapacity*100) / 100,
		RuntimeHours:          runtimeHours,
		RecommendedDoDPercent: dodPercent * 100.0,
		TotalBatteriesNeeded:  1,
		Assumptions: map[string]string{
			"battery_type": req.BatteryType,
			"usable_dod":   fmt.Sprintf("%.0f%%", dodPercent*100.0),
		},
		Notes: []string{"تم حساب ساعات التشغيل الفعلية بالمحافظة على عمر البطارية"},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    1,
			DatasetVersion:    1,
			GeneratedAt:       time.Now(),
		},
	}
}

// 4. Cable Sizing Calculator
func (e *SolarCalculatorEngine) CalculateCableSizing(ctx context.Context, req domain.CableSizingRequest) *domain.CalculatorStandardResponse {
	allowableDrop := req.AllowableDropPercent
	if allowableDrop <= 0 {
		allowableDrop = 2.5
	}
	rho := 0.01724
	if req.WireMaterial == "aluminum" {
		rho = 0.0282
	}

	allowableVolts := req.SystemVoltage * (allowableDrop / 100.0)
	calcMM2 := (2.0 * req.DistanceMeters * req.CurrentAmps * rho) / allowableVolts

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

	calcResult := &domain.CalculationResult{
		CableCrossSectionMM2: math.Round(calcMM2*100) / 100,
		StandardCableSizeMM2: selectedSize,
		VoltageDropPercent:   math.Round(actualDropPercent*100) / 100,
		Assumptions: map[string]string{
			"material": req.WireMaterial,
			"distance": fmt.Sprintf("%.1f m", req.DistanceMeters),
		},
		Notes: []string{"مقاس كابل نقي مطابق للحد المسموح به لهبوط الجهد"},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    1,
			DatasetVersion:    1,
			GeneratedAt:       time.Now(),
		},
	}
}

// 5. MPPT String Calculator
func (e *SolarCalculatorEngine) CalculateMPPTString(ctx context.Context, req domain.MPPTStringRequest, govID int) *domain.CalculatorStandardResponse {
	tempCoeff := req.PanelTempCoeffVoc
	if tempCoeff == 0 {
		tempCoeff = -0.28
	}

	minTemp := req.MinTempC
	maxTemp := req.MaxTempC

	if minTemp == 0 && maxTemp == 0 {
		solarData, _ := e.solarRepo.GetSolarDataByGovernorateID(ctx, govID)
		if solarData != nil {
			minTemp = solarData.MinWinterTempC
			maxTemp = solarData.MaxSummerTempC
		}
	}

	maxVocCold := req.PanelVoc * (1.0 + (tempCoeff / 100.0)*(minTemp-25.0))
	minVmpHot := req.PanelVmp * (1.0 + (tempCoeff / 100.0)*(maxTemp-25.0))

	maxPanels := int(math.Floor(req.InverterMaxVoc / maxVocCold))
	minPanels := int(math.Ceil(req.InverterMinMPPTV / minVmpHot))
	recommendedPanels := (maxPanels + minPanels) / 2

	calcResult := &domain.CalculationResult{
		MaxPanelsPerString:      maxPanels,
		MinPanelsPerString:      minPanels,
		RecommendedPanelsPerStr: recommendedPanels,
		Assumptions: map[string]string{
			"min_winter_temp": fmt.Sprintf("%.1f °C", minTemp),
			"max_summer_temp": fmt.Sprintf("%.1f °C", maxTemp),
		},
		Notes: []string{"تم مراعاة أقصى زيادة في الجهد خلال أشهر الشتاء لتجنب تلف المحول"},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    1,
			DatasetVersion:    1,
			GeneratedAt:       time.Now(),
		},
	}
}

// 6. Breakers & Fuses Calculator
func (e *SolarCalculatorEngine) CalculateBreakersFuses(ctx context.Context, req domain.BreakerFuseRequest) *domain.CalculatorStandardResponse {
	dcBreakerAmps := math.Ceil((req.ArrayIsc * 1.25) / 5.0) * 5.0
	acBreakerAmps := math.Ceil((req.InverterOutputAmps * 1.25) / 5.0) * 5.0
	stringFuseAmps := math.Ceil(req.ArrayIsc * 1.56)

	calcResult := &domain.CalculationResult{
		DCBreakerAmps:  dcBreakerAmps,
		ACBreakerAmps:  acBreakerAmps,
		StringFuseAmps: stringFuseAmps,
		Notes:          []string{"تم تطبيق معامل الأمان 1.25 لضمان عدم الاستجابة الكاذبة للقواطع"},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    1,
			DatasetVersion:    1,
			GeneratedAt:       time.Now(),
		},
	}
}

// 7. Battery Bank Calculator
func (e *SolarCalculatorEngine) CalculateBatteryBank(ctx context.Context, req domain.BatteryBankRequest) *domain.CalculatorStandardResponse {
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

	calcResult := &domain.CalculationResult{
		SeriesBatteryCount:   seriesCount,
		ParallelBatteryCount: parallelCount,
		TotalBatteriesNeeded: totalBatteries,
		UsableCapacitykWh:    math.Round(actualCapacitykWh*100) / 100,
		Notes:                []string{fmt.Sprintf("توصيل %d بطارية توالي للحصول على %.0f V، وثم %d سلاسل توازي", seriesCount, req.TargetVoltage, parallelCount)},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    1,
			DatasetVersion:    1,
			GeneratedAt:       time.Now(),
		},
	}
}

// 8. Solar Production Calculator
func (e *SolarCalculatorEngine) CalculateSolarProduction(ctx context.Context, req domain.SolarProductionRequest, govID int) *domain.CalculatorStandardResponse {
	solarData, _ := e.solarRepo.GetSolarDataByGovernorateID(ctx, govID)
	psh := 5.5
	tilt := 33.0
	if solarData != nil {
		psh = solarData.PeakSunHours
		tilt = solarData.OptimalTiltAngle
	}

	dailyAvg := req.SystemSizekW * psh * 0.82
	annual := dailyAvg * 365.0

	calcResult := &domain.CalculationResult{
		DailyGenerationkWh:  math.Round(dailyAvg*100) / 100,
		AnnualGenerationkWh: math.Round(annual),
		SystemSizekW:        req.SystemSizekW,
		Assumptions: map[string]string{
			"province_psh": fmt.Sprintf("%.2f kWh/m²/day", psh),
			"optimal_tilt": fmt.Sprintf("%.1f°", tilt),
		},
		Notes: []string{"تم الأخذ بعين الاعتبار معامل الكفاءة الميداني 0.82 لتأثير الأتربة والحرارة العالية"},
	}

	recs := domain.CategorizedRecommendations{}
	if e.recService != nil {
		recs = e.recService.GenerateRecommendations(ctx, calcResult)
	}

	return &domain.CalculatorStandardResponse{
		Calculation:     calcResult,
		Recommendations: recs,
		Metadata: domain.ResponseMetadata{
			CalculatorVersion: 2,
			PricingVersion:    1,
			DatasetVersion:    1,
			GeneratedAt:       time.Now(),
		},
	}
}
