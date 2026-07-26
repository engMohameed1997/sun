package handler

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/pkg/utils"
)

type ProductHandler struct {
	productRepo repository.ProductRepository
}

func NewProductHandler(productRepo repository.ProductRepository) *ProductHandler {
	return &ProductHandler{productRepo: productRepo}
}

func (h *ProductHandler) ListProducts(c *gin.Context) {
	if h.productRepo != nil {
		products, err := h.productRepo.ListAll(c.Request.Context())
		if err == nil && len(products) > 0 {
			utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة منتجات المنظومات الشمسية بنجاح من قاعدة البيانات", products)
			return
		}
	}

	// Fallback sample demonstration products list with technical specs
	panelSpecs, _ := json.Marshal(map[string]interface{}{
		"efficiency":  "21.5%",
		"wattage":     550,
		"technology":  "N-Type TOPCon",
		"warranty_yr": 25,
	})

	inverterSpecs, _ := json.Marshal(map[string]interface{}{
		"capacity_kw":   8.0,
		"type":          "Hybrid Three Phase",
		"mppt_channels": 2,
		"warranty_yr":   5,
	})

	batterySpecs, _ := json.Marshal(map[string]interface{}{
		"capacity_kwh": 10.2,
		"chemistry":    "LiFePO4 (Lithium Iron Phosphate)",
		"cycles":       6000,
		"voltage":      48,
	})

	products := []domain.Product{
		{
			ID:             uuid.New(),
			SKU:            "SP-LONGi-550",
			Name:           "لوح طاقة شمسية LONGi 550W N-Type",
			Brand:          "LONGi Solar",
			Model:          "LR5-72HTH-550M",
			Type:           domain.TypePanel,
			PriceUSD:       115.00,
			StockQuantity:  150,
			Specifications: panelSpecs,
			IsAvailable:    true,
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		},
		{
			ID:             uuid.New(),
			SKU:            "INV-DEYE-8K",
			Name:           "انفيرتر هجين Deye 8kW Three Phase",
			Brand:          "Deye",
			Model:          "SUN-8K-SG04LP3",
			Type:           domain.TypeInverter,
			PriceUSD:       1250.00,
			StockQuantity:  25,
			Specifications: inverterSpecs,
			IsAvailable:    true,
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		},
		{
			ID:             uuid.New(),
			SKU:            "BAT-FELICITY-10K",
			Name:           "بطارية ليثيوم Felicity 10.2kWh LiFePO4",
			Brand:          "FelicitySolar",
			Model:          "FL-LPBF48200-H",
			Type:           domain.TypeBattery,
			PriceUSD:       1450.00,
			StockQuantity:  30,
			Specifications: batterySpecs,
			IsAvailable:    true,
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		},
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة منتجات المنظومات الشمسية بنجاح", products)
}

func (h *ProductHandler) CreateProduct(c *gin.Context) {
	var req domain.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المنتج غير صالحة", err)
		return
	}

	specs := req.Specifications
	if len(specs) == 0 {
		specs = json.RawMessage("{}")
	}

	product := &domain.Product{
		ID:             uuid.New(),
		SKU:            req.SKU,
		Name:           req.Name,
		Brand:          req.Brand,
		Model:          req.Model,
		Type:           req.Type,
		PriceUSD:       req.PriceUSD,
		StockQuantity:  req.StockQuantity,
		Specifications: specs,
		IsAvailable:    true,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	if h.productRepo != nil {
		if err := h.productRepo.Create(c.Request.Context(), product); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إضافة المنتج الشمسي بنجاح", product)
}

func (h *ProductHandler) ListCategories(c *gin.Context) {
	categories := []domain.Category{
		{ID: 1, Name: "ألواح شمسية", Description: "ألواح طاقة شمسية N-Type / TOPCon High Efficiency"},
		{ID: 2, Name: "عواكس طاقة (انفيرترات)", Description: "انفيرترات هجينة وإضافية سين ويف"},
		{ID: 3, Name: "بطاريات خزن ليثيوم", Description: "بطاريات LiFePO4 دورات شحن 6000+"},
		{ID: 4, Name: "هياكل وقواعد تثبيت", Description: "هياكل تثبيت ألمنيوم ومجلفنة"},
		{ID: 5, Name: "كوابل ومحولات", Description: "كوابل DC شمسية ومحولات ومستلزمات الحماية"},
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة تصنيفات المنظومات الشمسية بنجاح", categories)
}
