package service

import (
	"context"
	"math"
	"sort"

	"github.com/iraq-solar/api/internal/domain"
)

type RecommendationService struct {
	catalogService *CatalogService
}

func NewRecommendationService(catalogService *CatalogService) *RecommendationService {
	return &RecommendationService{
		catalogService: catalogService,
	}
}

func (s *RecommendationService) GenerateRecommendations(ctx context.Context, calc *domain.CalculationResult) domain.CategorizedRecommendations {
	recs := domain.CategorizedRecommendations{
		RecommendedKits:      []domain.ScoredProductRecommendation{},
		RecommendedPanels:    []domain.ScoredProductRecommendation{},
		RecommendedBatteries: []domain.ScoredProductRecommendation{},
		RecommendedInverters: []domain.ScoredProductRecommendation{},
		RecommendedCables:    []domain.ScoredProductRecommendation{},
		RecommendedBreakers:  []domain.ScoredProductRecommendation{},
	}

	if s.catalogService == nil || calc == nil {
		return recs
	}

	storeMap, _ := s.catalogService.GetStoreMap(ctx)

	// 1. Panels
	if calc.RequiredPanelCount > 0 {
		panels, _ := s.catalogService.GetAvailableProductsByType(ctx, domain.TypePanel)
		for _, p := range panels {
			rec := s.scorePanel(p, calc, storeMap)
			if rec != nil {
				recs.RecommendedPanels = append(recs.RecommendedPanels, *rec)
			}
		}
		sort.Slice(recs.RecommendedPanels, func(i, j int) bool {
			return recs.RecommendedPanels[i].Score > recs.RecommendedPanels[j].Score
		})
		if len(recs.RecommendedPanels) > 10 {
			recs.RecommendedPanels = recs.RecommendedPanels[:10]
		}
	}

	// 2. Inverters
	if calc.RecommendedInverterkW > 0 {
		inverters, _ := s.catalogService.GetAvailableProductsByType(ctx, domain.TypeInverter)
		for _, p := range inverters {
			rec := s.scoreInverter(p, calc, storeMap)
			if rec != nil {
				recs.RecommendedInverters = append(recs.RecommendedInverters, *rec)
			}
		}
		sort.Slice(recs.RecommendedInverters, func(i, j int) bool {
			return recs.RecommendedInverters[i].Score > recs.RecommendedInverters[j].Score
		})
		if len(recs.RecommendedInverters) > 10 {
			recs.RecommendedInverters = recs.RecommendedInverters[:10]
		}
	}

	// 3. Batteries
	if calc.RecommendedBatterykWh > 0 || calc.TotalBatteriesNeeded > 0 {
		batteries, _ := s.catalogService.GetAvailableProductsByType(ctx, domain.TypeBattery)
		for _, p := range batteries {
			rec := s.scoreBattery(p, calc, storeMap)
			if rec != nil {
				recs.RecommendedBatteries = append(recs.RecommendedBatteries, *rec)
			}
		}
		sort.Slice(recs.RecommendedBatteries, func(i, j int) bool {
			return recs.RecommendedBatteries[i].Score > recs.RecommendedBatteries[j].Score
		})
		if len(recs.RecommendedBatteries) > 10 {
			recs.RecommendedBatteries = recs.RecommendedBatteries[:10]
		}
	}

	// 4. Cables
	if calc.StandardCableSizeMM2 > 0 {
		cables, _ := s.catalogService.GetAvailableProductsByType(ctx, domain.TypeCable)
		for _, p := range cables {
			rec := s.scoreCable(p, calc, storeMap)
			if rec != nil {
				recs.RecommendedCables = append(recs.RecommendedCables, *rec)
			}
		}
		sort.Slice(recs.RecommendedCables, func(i, j int) bool {
			return recs.RecommendedCables[i].Score > recs.RecommendedCables[j].Score
		})
		if len(recs.RecommendedCables) > 10 {
			recs.RecommendedCables = recs.RecommendedCables[:10]
		}
	}

	// 5. Breakers / Accessories
	if calc.DCBreakerAmps > 0 || calc.ACBreakerAmps > 0 {
		accessories, _ := s.catalogService.GetAvailableProductsByType(ctx, domain.TypeAccessory)
		for _, p := range accessories {
			rec := s.scoreAccessory(p, calc, storeMap)
			if rec != nil {
				recs.RecommendedBreakers = append(recs.RecommendedBreakers, *rec)
			}
		}
		sort.Slice(recs.RecommendedBreakers, func(i, j int) bool {
			return recs.RecommendedBreakers[i].Score > recs.RecommendedBreakers[j].Score
		})
		if len(recs.RecommendedBreakers) > 10 {
			recs.RecommendedBreakers = recs.RecommendedBreakers[:10]
		}
	}

	return recs
}

func (s *RecommendationService) scorePanel(p domain.Product, calc *domain.CalculationResult, storeMap map[string]domain.Store) *domain.ScoredProductRecommendation {
	qty := calc.RequiredPanelCount
	if qty <= 0 {
		qty = 1
	}

	storeName := "متجر معتمد"
	if p.StoreID != nil {
		if st, ok := storeMap[p.StoreID.String()]; ok {
			storeName = st.Name
		}
	}

	img := ""
	if len(p.Images) > 0 {
		img = p.Images[0]
	}

	score := 85
	reasons := []string{"لوح شمسي عالي الكفاءة"}

	if p.PriceIQD > 0 {
		reasons = append(reasons, "سعر تنافسي بالدينار العراقي")
		score += 5
	}
	if p.AvailableQuantity() >= qty {
		reasons = append(reasons, "متوفر بالكمية المطلوبة")
		score += 5
	} else {
		score -= 10
	}

	totalPrice := p.PriceIQD * float64(qty)

	return &domain.ScoredProductRecommendation{
		ProductID:        p.ID,
		StoreID:          p.StoreID,
		StoreName:        storeName,
		ProductName:      p.Name,
		Brand:            p.BrandName,
		Model:            p.Model,
		ProductType:      string(p.Type),
		Image:            img,
		UnitPriceIQD:     p.PriceIQD,
		RequiredQuantity: qty,
		TotalPriceIQD:    totalPrice,
		StockAvailable:   p.AvailableQuantity(),
		Score:            int(math.Min(100, float64(score))),
		MatchReasons:     reasons,
	}
}

func (s *RecommendationService) scoreInverter(p domain.Product, calc *domain.CalculationResult, storeMap map[string]domain.Store) *domain.ScoredProductRecommendation {
	qty := 1
	storeName := "متجر معتمد"
	if p.StoreID != nil {
		if st, ok := storeMap[p.StoreID.String()]; ok {
			storeName = st.Name
		}
	}
	img := ""
	if len(p.Images) > 0 {
		img = p.Images[0]
	}

	score := 88
	reasons := []string{"قدرة انفرتر مطابقة للمنظومة"}

	if p.AvailableQuantity() >= qty {
		reasons = append(reasons, "متوفر للشراء الفوري")
		score += 7
	}

	return &domain.ScoredProductRecommendation{
		ProductID:        p.ID,
		StoreID:          p.StoreID,
		StoreName:        storeName,
		ProductName:      p.Name,
		Brand:            p.BrandName,
		Model:            p.Model,
		ProductType:      string(p.Type),
		Image:            img,
		UnitPriceIQD:     p.PriceIQD,
		RequiredQuantity: qty,
		TotalPriceIQD:    p.PriceIQD * float64(qty),
		StockAvailable:   p.AvailableQuantity(),
		Score:            int(math.Min(100, float64(score))),
		MatchReasons:     reasons,
	}
}

func (s *RecommendationService) scoreBattery(p domain.Product, calc *domain.CalculationResult, storeMap map[string]domain.Store) *domain.ScoredProductRecommendation {
	qty := calc.TotalBatteriesNeeded
	if qty <= 0 {
		qty = 1
	}
	storeName := "متجر معتمد"
	if p.StoreID != nil {
		if st, ok := storeMap[p.StoreID.String()]; ok {
			storeName = st.Name
		}
	}
	img := ""
	if len(p.Images) > 0 {
		img = p.Images[0]
	}

	score := 86
	reasons := []string{"بطارية طاقة شمسية مطابقة"}

	if p.AvailableQuantity() >= qty {
		reasons = append(reasons, "كمية متوفرة بالكامل بالمتجر")
		score += 8
	}

	return &domain.ScoredProductRecommendation{
		ProductID:        p.ID,
		StoreID:          p.StoreID,
		StoreName:        storeName,
		ProductName:      p.Name,
		Brand:            p.BrandName,
		Model:            p.Model,
		ProductType:      string(p.Type),
		Image:            img,
		UnitPriceIQD:     p.PriceIQD,
		RequiredQuantity: qty,
		TotalPriceIQD:    p.PriceIQD * float64(qty),
		StockAvailable:   p.AvailableQuantity(),
		Score:            int(math.Min(100, float64(score))),
		MatchReasons:     reasons,
	}
}

func (s *RecommendationService) scoreCable(p domain.Product, calc *domain.CalculationResult, storeMap map[string]domain.Store) *domain.ScoredProductRecommendation {
	qty := 25 // Default 25 meters distance benchmark
	storeName := "متجر معتمد"
	if p.StoreID != nil {
		if st, ok := storeMap[p.StoreID.String()]; ok {
			storeName = st.Name
		}
	}
	img := ""
	if len(p.Images) > 0 {
		img = p.Images[0]
	}

	return &domain.ScoredProductRecommendation{
		ProductID:        p.ID,
		StoreID:          p.StoreID,
		StoreName:        storeName,
		ProductName:      p.Name,
		Brand:            p.BrandName,
		Model:            p.Model,
		ProductType:      string(p.Type),
		Image:            img,
		UnitPriceIQD:     p.PriceIQD,
		RequiredQuantity: qty,
		TotalPriceIQD:    p.PriceIQD * float64(qty),
		StockAvailable:   p.AvailableQuantity(),
		Score:            90,
		MatchReasons:     []string{"مقاس كابل نقي مطابق لهبوط الجهد"},
	}
}

func (s *RecommendationService) scoreAccessory(p domain.Product, calc *domain.CalculationResult, storeMap map[string]domain.Store) *domain.ScoredProductRecommendation {
	qty := 1
	storeName := "متجر معتمد"
	if p.StoreID != nil {
		if st, ok := storeMap[p.StoreID.String()]; ok {
			storeName = st.Name
		}
	}
	img := ""
	if len(p.Images) > 0 {
		img = p.Images[0]
	}

	return &domain.ScoredProductRecommendation{
		ProductID:        p.ID,
		StoreID:          p.StoreID,
		StoreName:        storeName,
		ProductName:      p.Name,
		Brand:            p.BrandName,
		Model:            p.Model,
		ProductType:      string(p.Type),
		Image:            img,
		UnitPriceIQD:     p.PriceIQD,
		RequiredQuantity: qty,
		TotalPriceIQD:    p.PriceIQD * float64(qty),
		StockAvailable:   p.AvailableQuantity(),
		Score:            85,
		MatchReasons:     []string{"جهاز حماية DC/AC مطابق"},
	}
}

func mathMin(a, b int) int {
	if a < b {
		return a
	}
	return b
}
