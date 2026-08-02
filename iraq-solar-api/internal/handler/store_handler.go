package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

type StoreHandler struct {
	storeService *service.StoreService
}

func NewStoreHandler(storeService *service.StoreService) *StoreHandler {
	return &StoreHandler{
		storeService: storeService,
	}
}

// ─── ADMIN & PUBLIC STORES ──────────────────────────────────────────────

func (h *StoreHandler) CreateStore(c *gin.Context) {
	var req domain.CreateStoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المتجر غير صالحة", err)
		return
	}

	store, err := h.storeService.CreateStore(c.Request.Context(), req)
	if err != nil {
		utils.BadRequestError(c, "فشل إنشاء المتجر", err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء المتجر بنجاح", store)
}

func (h *StoreHandler) ListStores(c *gin.Context) {
	search := c.Query("search")
	var isVerified *bool
	if v := c.Query("is_verified"); v != "" {
		b, _ := strconv.ParseBool(v)
		isVerified = &b
	}
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	stores, total, err := h.storeService.ListStores(c.Request.Context(), search, isVerified, page, perPage)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب المتاجر بنجاح", gin.H{
		"stores": stores,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": utils.CalculateTotalPages(total, perPage),
		},
	})
}

func (h *StoreHandler) GetStore(c *gin.Context) {
	idStr := c.Param("id")
	storeID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	store, err := h.storeService.GetStoreByID(c.Request.Context(), storeID)
	if err != nil {
		utils.BadRequestError(c, "لم يتم العثور على المتجر", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل المتجر", store)
}

func (h *StoreHandler) UpdateStore(c *gin.Context) {
	idStr := c.Param("id")
	storeID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	var req domain.UpdateStoreRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التحديث غير صالحة", err)
		return
	}

	if err := h.storeService.UpdateStore(c.Request.Context(), storeID, req); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث المتجر بنجاح", nil)
}

func (h *StoreHandler) DeleteStore(c *gin.Context) {
	idStr := c.Param("id")
	storeID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	if err := h.storeService.DeleteStore(c.Request.Context(), storeID); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف المتجر بنجاح", nil)
}

func (h *StoreHandler) VerifyStore(c *gin.Context) {
	idStr := c.Param("id")
	storeID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	var req struct {
		IsVerified bool `json:"is_verified"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التوثيق غير صالحة", err)
		return
	}

	if err := h.storeService.VerifyStore(c.Request.Context(), storeID, req.IsVerified); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	msg := "تم توثيق المتجر بنجاح"
	if !req.IsVerified {
		msg = "تم إلغاء توثيق المتجر بنجاح"
	}
	utils.SuccessResponse(c, http.StatusOK, msg, nil)
}

// ─── BRANCHES ──────────────────────────────────────────────────────────

func (h *StoreHandler) CreateBranch(c *gin.Context) {
	idStr := c.Param("id")
	storeID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	var req domain.CreateBranchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الفرع غير صالحة", err)
		return
	}

	branch, err := h.storeService.CreateBranch(c.Request.Context(), storeID, req)
	if err != nil {
		utils.BadRequestError(c, "فشل إضافة الفرع", err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إضافة الفرع بنجاح", branch)
}

func (h *StoreHandler) UpdateBranch(c *gin.Context) {
	branchIDStr := c.Param("branch_id")
	branchID, err := uuid.Parse(branchIDStr)
	if err != nil {
		utils.BadRequestError(c, "معرف الفرع غير صالح", err)
		return
	}

	var req domain.UpdateBranchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التحديث غير صالحة", err)
		return
	}

	if err := h.storeService.UpdateBranch(c.Request.Context(), branchID, req); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث الفرع بنجاح", nil)
}

func (h *StoreHandler) DeleteBranch(c *gin.Context) {
	branchIDStr := c.Param("branch_id")
	branchID, err := uuid.Parse(branchIDStr)
	if err != nil {
		utils.BadRequestError(c, "معرف الفرع غير صالح", err)
		return
	}

	if err := h.storeService.DeleteBranch(c.Request.Context(), branchID); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف الفرع بنجاح", nil)
}
