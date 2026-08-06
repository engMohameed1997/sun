package handler

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/pkg/utils"
)

type ProductHandler struct {
	productRepo  repository.ProductRepository
	storeRepo    *repository.StoreRepository
	categoryRepo repository.CategoryRepository
}

func NewProductHandler(productRepo repository.ProductRepository, storeRepo *repository.StoreRepository, categoryRepo repository.CategoryRepository) *ProductHandler {
	return &ProductHandler{productRepo: productRepo, storeRepo: storeRepo, categoryRepo: categoryRepo}
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

	var storeID *uuid.UUID
	if req.StoreID != nil {
		storeID = req.StoreID
	} else {
		// Find store by merchant
		if h.storeRepo != nil {
			store, err := h.storeRepo.GetStoreByMerchantID(c.Request.Context(), h.getMerchantID(c))
			if err == nil && store != nil {
				storeID = &store.ID
			}
		}
	}

	merchantID := h.getMerchantID(c)
	product := &domain.Product{
		ID:             uuid.New(),
		CategoryID:     req.CategoryID,
		MerchantID:     &merchantID,
		StoreID:        storeID,
		BranchID:       req.BranchID,
		SKU:            req.SKU,
		Name:           req.Name,
		BrandID:        req.BrandID,
		Model:          req.Model,
		Type:           req.Type,
		PriceIQD:       req.PriceIQD,
		StockQuantity:  req.StockQuantity,
		Specifications: specs,
		Images:         req.Images,
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
	if h.categoryRepo != nil {
		categories, err := h.categoryRepo.ListAll(c.Request.Context())
		if err != nil {
			utils.InternalServerError(c, err)
			return
		}
		utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة تصنيفات المنظومات الشمسية بنجاح", categories)
		return
	}

	// Fallback
	categories := []domain.Category{
		{ID: 1, Name: "ألواح شمسية", Description: "ألواح طاقة شمسية N-Type / TOPCon High Efficiency"},
		{ID: 2, Name: "عواكس طاقة (انفيرترات)", Description: "انفيرترات هجينة وإضافية سين ويف"},
		{ID: 3, Name: "بطاريات خزن ليثيوم", Description: "بطاريات LiFePO4 دورات شحن 6000+"},
		{ID: 4, Name: "هياكل وقواعد تثبيت", Description: "هياكل تثبيت ألمنيوم ومجلفنة"},
		{ID: 5, Name: "كوابل ومحولات", Description: "كوابل DC شمسية ومحولات ومستلزمات الحماية"},
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة تصنيفات المنظومات الشمسية بنجاح", categories)
}

type CategoryReq struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
}

func (h *ProductHandler) CreateCategory(c *gin.Context) {
	var req CategoryReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التصنيف غير صالحة", err)
		return
	}

	cat := &domain.Category{
		Name:        req.Name,
		Description: req.Description,
	}

	if err := h.categoryRepo.Create(c.Request.Context(), cat); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إضافة التصنيف بنجاح", cat)
}

func (h *ProductHandler) UpdateCategory(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)

	var req CategoryReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التصنيف غير صالحة", err)
		return
	}

	cat, err := h.categoryRepo.GetByID(c.Request.Context(), id)
	if err != nil || cat == nil {
		utils.BadRequestError(c, "التصنيف غير موجود", err)
		return
	}

	cat.Name = req.Name
	cat.Description = req.Description

	if err := h.categoryRepo.Update(c.Request.Context(), cat); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث التصنيف بنجاح", cat)
}

func (h *ProductHandler) DeleteCategory(c *gin.Context) {
	idStr := c.Param("id")
	id, _ := strconv.Atoi(idStr)

	if err := h.categoryRepo.Delete(c.Request.Context(), id); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف التصنيف بنجاح", nil)
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

	var storeID *uuid.UUID
	if req.StoreID != nil {
		storeID = req.StoreID
	} else {
		// Find store by merchant
		if h.storeRepo != nil {
			store, err := h.storeRepo.GetStoreByMerchantID(c.Request.Context(), merchantID)
			if err == nil && store != nil {
				storeID = &store.ID
			}
		}
	}

	product := &domain.Product{
		ID:                uuid.New(),
		CategoryID:        req.CategoryID,
		MerchantID:        &merchantID,
		StoreID:           storeID,
		BranchID:          req.BranchID,
		SKU:               req.SKU,
		Name:              req.Name,
		BrandID:           req.BrandID,
		Model:             req.Model,
		Type:              req.Type,
		PriceIQD:          req.PriceIQD,
		StockQuantity:     req.StockQuantity,
		LowStockThreshold: req.LowStockThreshold,
		Specifications:    specs,
		Images:            req.Images,
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
	if merchantID == uuid.Nil {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المنتج غير صالح", err)
		return
	}

	existing, err := h.productRepo.FindByID(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if existing == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "المنتج غير موجود", "PRODUCT_NOT_FOUND", nil)
		return
	}
	if existing.MerchantID == nil || *existing.MerchantID != merchantID {
		utils.ErrorResponse(c, http.StatusForbidden, "غير مصرح بتعديل هذا المنتج", "FORBIDDEN", nil)
		return
	}

	var req domain.CreateProductRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المنتج غير صالحة", err)
		return
	}

	var storeID *uuid.UUID
	if req.StoreID != nil {
		storeID = req.StoreID
	} else {
		// Find store by merchant
		if h.storeRepo != nil {
			store, err := h.storeRepo.GetStoreByMerchantID(c.Request.Context(), merchantID)
			if err == nil && store != nil {
				storeID = &store.ID
			}
		}
	}

	product := &domain.Product{
		ID:                id,
		CategoryID:        req.CategoryID,
		MerchantID:        &merchantID,
		StoreID:           storeID,
		BranchID:          req.BranchID,
		Name:              req.Name,
		BrandID:           req.BrandID,
		Model:             req.Model,
		PriceIQD:          req.PriceIQD,
		StockQuantity:     req.StockQuantity,
		LowStockThreshold: req.LowStockThreshold,
		Images:            req.Images,
		IsAvailable:       existing.IsAvailable,
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
	if merchantID == uuid.Nil {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}

	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المنتج غير صالح", err)
		return
	}

	existing, err := h.productRepo.FindByID(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if existing == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "المنتج غير موجود", "PRODUCT_NOT_FOUND", nil)
		return
	}
	if existing.MerchantID == nil || *existing.MerchantID != merchantID {
		utils.ErrorResponse(c, http.StatusForbidden, "غير مصرح بحذف هذا المنتج", "FORBIDDEN", nil)
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
