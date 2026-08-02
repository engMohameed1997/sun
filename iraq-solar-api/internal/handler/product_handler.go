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
		if err == nil {
			if products == nil {
				products = []domain.Product{}
			}
			utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة منتجات المنظومات الشمسية بنجاح من قاعدة البيانات", products)
			return
		}
	}
	utils.SuccessResponse(c, http.StatusOK, "لا توجد منتجات حالياً", []domain.Product{})
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

func (h *ProductHandler) getMerchantID(c *gin.Context) uuid.UUID {
	if val, exists := c.Get("user_id"); exists {
		if uid, ok := val.(uuid.UUID); ok {
			return uid
		}
	}
	return uuid.Nil
}

func (h *ProductHandler) ListMerchantProducts(c *gin.Context) {
	merchantID := h.getMerchantID(c)
	if h.productRepo != nil {
		products, err := h.productRepo.ListByMerchant(c.Request.Context(), merchantID)
		if err == nil {
			utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة منتجات التاجر بنجاح", products)
			return
		}
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة منتجات التاجر بنجاح", []domain.Product{})
}

func (h *ProductHandler) CreateMerchantProduct(c *gin.Context) {
	merchantID := h.getMerchantID(c)
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
		ID:                uuid.New(),
		MerchantID:        &merchantID,
		SKU:               req.SKU,
		Name:              req.Name,
		Brand:             req.Brand,
		Model:             req.Model,
		Type:              req.Type,
		PriceUSD:          req.PriceUSD,
		StockQuantity:     req.StockQuantity,
		LowStockThreshold: req.LowStockThreshold,
		Specifications:    specs,
		IsAvailable:       true,
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
	}

	if h.productRepo != nil {
		if err := h.productRepo.Create(c.Request.Context(), product); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إضافة المنتج الخاص بالتاجر بنجاح", product)
}

func (h *ProductHandler) UpdateMerchantProduct(c *gin.Context) {
	merchantID := h.getMerchantID(c)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المنتج غير صالح", err)
		return
	}

	var req domain.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المنتج غير صالحة", err)
		return
	}

	product := &domain.Product{
		ID:                id,
		MerchantID:        &merchantID,
		Name:              req.Name,
		Brand:             req.Brand,
		Model:             req.Model,
		PriceUSD:          req.PriceUSD,
		StockQuantity:     req.StockQuantity,
		LowStockThreshold: req.LowStockThreshold,
		IsAvailable:       true,
		UpdatedAt:         time.Now(),
	}

	if h.productRepo != nil {
		if err := h.productRepo.Update(c.Request.Context(), product); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث المنتج بنجاح", product)
}

func (h *ProductHandler) DeleteMerchantProduct(c *gin.Context) {
	merchantID := h.getMerchantID(c)
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المنتج غير صالح", err)
		return
	}

	if h.productRepo != nil {
		if err := h.productRepo.SoftDelete(c.Request.Context(), id, &merchantID); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	}

	utils.SuccessResponse(c, http.StatusOK, "تم إخفاء/حذف المنتج بنجاح", gin.H{"id": id})
}
