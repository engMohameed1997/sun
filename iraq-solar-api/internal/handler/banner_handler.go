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

type BannerHandler struct {
	bannerService *service.BannerService
}

func NewBannerHandler(bannerService *service.BannerService) *BannerHandler {
	return &BannerHandler{bannerService: bannerService}
}

// ─── Public Endpoints ───

// GetActiveBanners GET /api/v1/banners
func (h *BannerHandler) GetActiveBanners(c *gin.Context) {
	placement := c.DefaultQuery("placement", "home")
	role := h.getUserRole(c)

	var storeIDPtr *uuid.UUID
	if storeStr := c.Query("store_id"); storeStr != "" {
		if sID, err := uuid.Parse(storeStr); err == nil {
			storeIDPtr = &sID
		}
	}

	var catIDPtr *uuid.UUID
	if catStr := c.Query("category_id"); catStr != "" {
		if cID, err := uuid.Parse(catStr); err == nil {
			catIDPtr = &cID
		}
	}

	var prodIDPtr *uuid.UUID
	if prodStr := c.Query("product_id"); prodStr != "" {
		if pID, err := uuid.Parse(prodStr); err == nil {
			prodIDPtr = &pID
		}
	}

	govID := h.getUserGovernorateID(c)

	params := domain.BannerFilterParams{
		Placement:     placement,
		StoreID:       storeIDPtr,
		CategoryID:    catIDPtr,
		ProductID:     prodIDPtr,
		Role:          role,
		GovernorateID: govID,
	}

	banners, err := h.bannerService.GetActiveBanners(c.Request.Context(), params)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب الإعلانات بنجاح", banners)
}

// TrackBannerEvent POST /api/v1/banners/:id/track
func (h *BannerHandler) TrackBannerEvent(c *gin.Context) {
	bannerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الإعلان غير صالح", err)
		return
	}

	var req domain.TrackBannerEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات تتبع الإعلان غير صالحة", err)
		return
	}

	userID := h.getUserID(c)
	err = h.bannerService.TrackBannerEvent(c.Request.Context(), bannerID, req.EventType, userID, req.DeviceID, req.Metadata)
	if err != nil {
		utils.BadRequestError(c, "فشل تسجيل التفاعل مع الإعلان", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تسجيل التفاعل بنجاح", gin.H{"status": "recorded"})
}

// ─── Admin / Merchant Management Endpoints ───

// ListAdminBanners GET /api/v1/admin/banners
func (h *BannerHandler) ListAdminBanners(c *gin.Context) {
	placement := c.Query("placement")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	var merchantIDPtr *uuid.UUID
	userRole := h.getUserRole(c)
	if domain.Role(userRole) == domain.RoleMerchant {
		if mID := h.getUserID(c); mID != nil {
			merchantIDPtr = mID
		}
	} else if mStr := c.Query("merchant_id"); mStr != "" {
		if mID, err := uuid.Parse(mStr); err == nil {
			merchantIDPtr = &mID
		}
	}

	banners, total, err := h.bannerService.ListAdminBanners(c.Request.Context(), merchantIDPtr, placement, page, perPage)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الإعلانات بنجاح", gin.H{
		"banners": banners,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": utils.CalculateTotalPages(total, perPage),
		},
	})
}

// CreateBanner POST /api/v1/admin/banners
func (h *BannerHandler) CreateBanner(c *gin.Context) {
	var req domain.CreateBannerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات إنشاء الإعلان غير صالحة", err)
		return
	}

	creatorID := h.getUserID(c)
	if creatorID == nil {
		utils.UnauthorizedError(c, "يرجى تسجيل الدخول أولاً")
		return
	}
	userRole := h.getUserRole(c)

	banner, err := h.bannerService.CreateBanner(c.Request.Context(), *creatorID, userRole, req)
	if err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء الإعلان بنجاح", banner)
}

// UpdateBanner PUT /api/v1/admin/banners/:id
func (h *BannerHandler) UpdateBanner(c *gin.Context) {
	bannerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الإعلان غير صالح", err)
		return
	}

	var req domain.UpdateBannerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات تحديث الإعلان غير صالحة", err)
		return
	}

	userID := h.getUserID(c)
	if userID == nil {
		utils.UnauthorizedError(c, "يرجى تسجيل الدخول أولاً")
		return
	}
	userRole := h.getUserRole(c)

	banner, err := h.bannerService.UpdateBanner(c.Request.Context(), bannerID, *userID, userRole, req)
	if err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث الإعلان بنجاح", banner)
}

// DeleteBanner DELETE /api/v1/admin/banners/:id
func (h *BannerHandler) DeleteBanner(c *gin.Context) {
	bannerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الإعلان غير صالح", err)
		return
	}

	userID := h.getUserID(c)
	if userID == nil {
		utils.UnauthorizedError(c, "يرجى تسجيل الدخول أولاً")
		return
	}
	userRole := h.getUserRole(c)

	err = h.bannerService.DeleteBanner(c.Request.Context(), bannerID, *userID, userRole)
	if err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف الإعلان بنجاح", gin.H{"id": bannerID})
}

// ReorderBanners PUT /api/v1/admin/banners/reorder
func (h *BannerHandler) ReorderBanners(c *gin.Context) {
	var req domain.ReorderBannersRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "قائمة ترتيب الإعلانات غير صالحة", err)
		return
	}

	err := h.bannerService.ReorderBanners(c.Request.Context(), req.BannerIDs)
	if err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث ترتيب الإعلانات بنجاح", gin.H{"status": "reordered"})
}

// GetBannerAnalytics GET /api/v1/admin/banners/:id/analytics
func (h *BannerHandler) GetBannerAnalytics(c *gin.Context) {
	bannerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الإعلان غير صالح", err)
		return
	}

	days, _ := strconv.Atoi(c.DefaultQuery("days", "30"))
	analytics, err := h.bannerService.GetBannerAnalytics(c.Request.Context(), bannerID, days)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تحليلات الإعلان بنجاح", analytics)
}

// ─── Helpers ───

func (h *BannerHandler) getUserID(c *gin.Context) *uuid.UUID {
	if val, exists := c.Get("user_id"); exists {
		if id, ok := val.(uuid.UUID); ok {
			return &id
		}
	}
	return nil
}

func (h *BannerHandler) getUserRole(c *gin.Context) string {
	if val, exists := c.Get("role"); exists {
		if r, ok := val.(domain.Role); ok {
			return string(r)
		}
		if rStr, ok := val.(string); ok && rStr != "" {
			return rStr
		}
	}
	if val, exists := c.Get("user_role"); exists {
		if rStr, ok := val.(string); ok && rStr != "" {
			return rStr
		}
	}
	return "customer"
}

func (h *BannerHandler) getUserGovernorateID(c *gin.Context) int {
	if val, exists := c.Get("governorate_id"); exists {
		if govID, ok := val.(int); ok {
			return govID
		}
	}
	return 0
}
