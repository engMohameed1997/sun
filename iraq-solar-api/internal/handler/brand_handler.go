package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/pkg/utils"
)

type BrandHandler struct {
	brandRepo repository.BrandRepository
}

func NewBrandHandler(brandRepo repository.BrandRepository) *BrandHandler {
	return &BrandHandler{brandRepo: brandRepo}
}

func (h *BrandHandler) ListBrands(c *gin.Context) {
	onlyActive := c.Query("active") == "true"
	if h.brandRepo == nil {
		utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الماركات بنجاح", []domain.Brand{})
		return
	}
	brands, err := h.brandRepo.ListAll(c.Request.Context(), onlyActive)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الماركات بنجاح", brands)
}

func (h *BrandHandler) CreateBrand(c *gin.Context) {
	var req domain.CreateBrandRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الماركة غير صالحة", err)
		return
	}

	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	brand := &domain.Brand{
		ID:       uuid.New(),
		Name:     req.Name,
		LogoURL:  req.LogoURL,
		IsActive: isActive,
	}

	if err := h.brandRepo.Create(c.Request.Context(), brand); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إضافة الماركة بنجاح", brand)
}

func (h *BrandHandler) UpdateBrand(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الماركة غير صالح", err)
		return
	}

	var req domain.UpdateBrandRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الماركة غير صالحة", err)
		return
	}

	if err := h.brandRepo.Update(c.Request.Context(), id, req); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث الماركة بنجاح", gin.H{"id": id})
}

func (h *BrandHandler) DeleteBrand(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الماركة غير صالح", err)
		return
	}

	if err := h.brandRepo.Delete(c.Request.Context(), id); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف الماركة بنجاح", gin.H{"id": id})
}
