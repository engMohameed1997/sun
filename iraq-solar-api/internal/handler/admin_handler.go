package handler

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

type AdminHandler struct {
	adminService *service.AdminService
}

func NewAdminHandler(adminService *service.AdminService) *AdminHandler {
	return &AdminHandler{adminService: adminService}
}

func (h *AdminHandler) getAdminID(c *gin.Context) uuid.UUID {
	if val, exists := c.Get("user_id"); exists {
		if uid, ok := val.(uuid.UUID); ok {
			return uid
		}
	}
	return uuid.Nil
}

// ─── Dashboard Stats ───

func (h *AdminHandler) DashboardStats(c *gin.Context) {
	stats, err := h.adminService.DashboardStats(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب إحصائيات لوحة التحكم بنجاح", stats)
}

func (h *AdminHandler) RevenueStats(c *gin.Context) {
	days, _ := strconv.Atoi(c.DefaultQuery("days", "7"))
	stats, err := h.adminService.RevenueStats(c.Request.Context(), days)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب تقرير الإيرادات بنجاح", stats)
}

func (h *AdminHandler) OrdersByStatus(c *gin.Context) {
	stats, err := h.adminService.OrdersByStatus(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب توزيع الطلبات بحسب الحالة بنجاح", stats)
}

func (h *AdminHandler) TopProducts(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "5"))
	products, err := h.adminService.TopProducts(c.Request.Context(), limit)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب أكثر المنتجات مبيعاً بنجاح", products)
}

// ─── Users Management ───

func (h *AdminHandler) ListUsers(c *gin.Context) {
	role := c.Query("role")
	status := c.Query("status")
	governorate := c.Query("governorate")
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	users, total, err := h.adminService.ListUsers(c.Request.Context(), role, status, governorate, search, page, perPage)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة المستخدمين بنجاح", gin.H{
		"users": users,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": utils.CalculateTotalPages(total, perPage),
		},
	})
}

func (h *AdminHandler) GetUser(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المستخدم غير صالح", err)
		return
	}

	user, err := h.adminService.GetUser(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if user == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "المستخدم غير موجود", "USER_NOT_FOUND", nil)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل المستخدم بنجاح", user)
}

type CreateUserByAdminReq struct {
	FullName    string      `json:"full_name" binding:"required,min=3"`
	Email       string      `json:"email" binding:"omitempty,email"`
	Phone       string      `json:"phone" binding:"required"`
	Password    string      `json:"password" binding:"required,min=6"`
	Role        domain.Role `json:"role" binding:"required"`
	Governorate string      `json:"governorate"`
	City        string      `json:"city"`
}

func (h *AdminHandler) CreateUser(c *gin.Context) {
	var req CreateUserByAdminReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المستخدم غير صالحة", err)
		return
	}

	if req.Role == domain.RoleAdmin && strings.TrimSpace(req.Email) == "" {
		utils.ErrorResponse(c, http.StatusBadRequest, "لا يمكن إضافة مدير نظام (Admin) بدون بريد إلكتروني، يُرجى إدخال البريد الإلكتروني", "EMAIL_REQUIRED_FOR_ADMIN", nil)
		return
	}

	adminID := h.getAdminID(c)
	user, err := h.adminService.CreateUserByAdmin(c.Request.Context(), adminID, req.FullName, req.Email, req.Phone, req.Password, req.Role, req.Governorate, req.City)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique constraint") {
			utils.BadRequestError(c, "رقم الهاتف أو البريد الإلكتروني مستخدم بالفعل", err)
		} else {
			utils.BadRequestError(c, "فشل إنشاء حساب المستخدم: "+err.Error(), err)
		}
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء الحساب بنجاح بواسطة الأدمن", user)
}

type UpdateUserReq struct {
	FullName    string      `json:"full_name" binding:"required"`
	Phone       string      `json:"phone"`
	Governorate string      `json:"governorate"`
	City        string      `json:"city"`
	Role        domain.Role `json:"role" binding:"required"`
}

func (h *AdminHandler) UpdateUser(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المستخدم غير صالح", err)
		return
	}

	var req UpdateUserReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "البيانات غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.UpdateUser(c.Request.Context(), adminID, id, req.FullName, req.Phone, req.Governorate, req.City, req.Role); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث بيانات المستخدم بنجاح", gin.H{"id": id})
}

type ToggleActiveReq struct {
	IsActive bool `json:"is_active"`
}

func (h *AdminHandler) ToggleUserActive(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المستخدم غير صالح", err)
		return
	}

	var req ToggleActiveReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "البيانات غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.ToggleUserActive(c.Request.Context(), adminID, id, req.IsActive); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تغيير حالة تفعيل المستخدم بنجاح", gin.H{"id": id, "is_active": req.IsActive})
}

func (h *AdminHandler) DeleteUser(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المستخدم غير صالح", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.DeleteUser(c.Request.Context(), adminID, id); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف المستخدم بنجاح", gin.H{"id": id})
}

// ─── Stores Management ───

func (h *AdminHandler) ListStores(c *gin.Context) {
	status := c.Query("status")
	governorate := c.Query("governorate")
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	stores, total, err := h.adminService.ListUsers(c.Request.Context(), string(domain.RoleMerchant), status, governorate, search, page, perPage)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة المتاجر بنجاح", gin.H{
		"stores": stores,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": utils.CalculateTotalPages(total, perPage),
		},
	})
}

type CreateStoreReq struct {
	Name        string `json:"name" binding:"required,min=3"`
	OwnerName   string `json:"owner_name"`
	Email       string `json:"email" binding:"omitempty,email"`
	Phone       string `json:"phone" binding:"required"`
	Password    string `json:"password" binding:"required,min=6"`
	Governorate string `json:"governorate"`
	City        string `json:"city"`
}

func (h *AdminHandler) CreateStore(c *gin.Context) {
	var req CreateStoreReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المتجر غير صالحة", err)
		return
	}

	fullName := req.Name
	if req.OwnerName != "" {
		fullName = req.Name + " (" + req.OwnerName + ")"
	}

	adminID := h.getAdminID(c)
	user, err := h.adminService.CreateUserByAdmin(
		c.Request.Context(),
		adminID,
		fullName,
		req.Email,
		req.Phone,
		req.Password,
		domain.RoleMerchant,
		req.Governorate,
		req.City,
	)
	if err != nil {
		utils.BadRequestError(c, "فشل إنشاء المتجر", err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء المتجر بنجاح", user)
}

// ─── Orders Management ───

func (h *AdminHandler) ListOrders(c *gin.Context) {
	status := c.Query("status")
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	orders, total, err := h.adminService.ListOrders(c.Request.Context(), status, search, page, perPage)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الطلبات بنجاح", gin.H{
		"orders": orders,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": utils.CalculateTotalPages(total, perPage),
		},
	})
}

func (h *AdminHandler) GetOrderDetail(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	order, items, err := h.adminService.GetOrderDetail(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "الطلب غير موجود", "ORDER_NOT_FOUND", nil)
		return
	}

	order.Items = items
	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل الطلب بنجاح", order)
}

type UpdateOrderStatusReq struct {
	Status string `json:"status" binding:"required"`
}

func (h *AdminHandler) UpdateOrderStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	var req UpdateOrderStatusReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "البيانات غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.UpdateOrderStatus(c.Request.Context(), adminID, id, req.Status); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة الطلب بنجاح", gin.H{"id": id, "status": req.Status})
}

// ─── Products Management ───

func (h *AdminHandler) ListProducts(c *gin.Context) {
	pType := c.Query("type")
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	products, total, err := h.adminService.ListProducts(c.Request.Context(), pType, search, page, perPage)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة المنتجات بنجاح", gin.H{
		"products": products,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": utils.CalculateTotalPages(total, perPage),
		},
	})
}

type UpdateProductReq struct {
	Name          string  `json:"name" binding:"required"`
	Brand         string  `json:"brand" binding:"required"`
	Model         string  `json:"model" binding:"required"`
	PriceUSD      float64 `json:"price_usd" binding:"required,gt=0"`
	StockQuantity int     `json:"stock_quantity" binding:"gte=0"`
	IsAvailable   bool    `json:"is_available"`
}

func (h *AdminHandler) UpdateProduct(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المنتج غير صالح", err)
		return
	}

	var req UpdateProductReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المنتج غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.UpdateProduct(c.Request.Context(), adminID, id, req.Name, req.Brand, req.Model, req.PriceUSD, req.StockQuantity, req.IsAvailable); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث المنتج بنجاح", gin.H{"id": id})
}

func (h *AdminHandler) DeleteProduct(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المنتج غير صالح", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.DeleteProduct(c.Request.Context(), adminID, id); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف المنتج بنجاح", gin.H{"id": id})
}

// ─── Governorates Management ───

func (h *AdminHandler) ListGovernorates(c *gin.Context) {
	governorates, err := h.adminService.ListGovernorates(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة المحافظات بنجاح", governorates)
}

type CreateGovernorateReq struct {
	NameAr string `json:"name_ar" binding:"required"`
	NameEn string `json:"name_en"`
}

func (h *AdminHandler) CreateGovernorate(c *gin.Context) {
	var req CreateGovernorateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "البيانات غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	g, err := h.adminService.CreateGovernorate(c.Request.Context(), adminID, req.NameAr, req.NameEn)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إضافة المحافظة بنجاح", g)
}

func (h *AdminHandler) UpdateGovernorate(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المحافظة غير صالح", err)
		return
	}

	var req CreateGovernorateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "البيانات غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.UpdateGovernorate(c.Request.Context(), adminID, id, req.NameAr, req.NameEn); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث المحافظة بنجاح", gin.H{"id": id})
}

func (h *AdminHandler) ToggleGovernorateActive(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المحافظة غير صالح", err)
		return
	}

	var req ToggleActiveReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "البيانات غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.ToggleGovernorateActive(c.Request.Context(), adminID, id, req.IsActive); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تغيير حالة المحافظة بنجاح", gin.H{"id": id, "is_active": req.IsActive})
}

func (h *AdminHandler) DeleteGovernorate(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف المحافظة غير صالح", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.DeleteGovernorate(c.Request.Context(), adminID, id); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف المحافظة بنجاح", gin.H{"id": id})
}

// ─── Banners Management ───

func (h *AdminHandler) ListHomeBanners(c *gin.Context) {
	banners, err := h.adminService.ListHomeBanners(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب إعلانات الصفحة الرئيسية بنجاح", banners)
}

type CreateHomeBannerReq struct {
	Title        string    `json:"title" binding:"required"`
	Subtitle     string    `json:"subtitle"`
	ImageURL     string    `json:"image_url" binding:"required"`
	LinkURL      string    `json:"link_url"`
	DisplayOrder int       `json:"display_order"`
	IsActive     bool      `json:"is_active"`
	StartsAt     *time.Time `json:"starts_at"`
	EndsAt       *time.Time `json:"ends_at"`
}

func (h *AdminHandler) CreateHomeBanner(c *gin.Context) {
	var req CreateHomeBannerReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الإعلان غير صالحة", err)
		return
	}

	titlePtr := &req.Title
	subtitlePtr := &req.Subtitle
	linkPtr := &req.LinkURL

	adminID := h.getAdminID(c)
	b := &domain.HomeBanner{
		Title:        titlePtr,
		Subtitle:     subtitlePtr,
		ImageURL:     req.ImageURL,
		LinkURL:      linkPtr,
		DisplayOrder: req.DisplayOrder,
		IsActive:     req.IsActive,
		StartsAt:     req.StartsAt,
		EndsAt:       req.EndsAt,
	}

	if err := h.adminService.CreateHomeBanner(c.Request.Context(), adminID, b); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء الإعلان بنجاح", b)
}

func (h *AdminHandler) DeleteHomeBanner(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequestError(c, "معرف الإعلان غير صالح", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.DeleteHomeBanner(c.Request.Context(), adminID, id); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف الإعلان بنجاح", gin.H{"id": id})
}

// ─── Audit Logs & Settings ───

func (h *AdminHandler) ListAuditLogs(c *gin.Context) {
	action := c.Query("action")
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	logs, total, err := h.adminService.ListAuditLogs(c.Request.Context(), action, search, page, perPage)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب سجلات الأمان بنجاح", gin.H{
		"logs": logs,
		"pagination": gin.H{
			"page":        page,
			"per_page":    perPage,
			"total":       total,
			"total_pages": utils.CalculateTotalPages(total, perPage),
		},
	})
}

func (h *AdminHandler) GetSettings(c *gin.Context) {
	settings, err := h.adminService.GetSettings(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب إعدادات النظام بنجاح", settings)
}

type UpdateSettingReq struct {
	Key   string `json:"key" binding:"required"`
	Value string `json:"value" binding:"required"`
}

func (h *AdminHandler) UpdateSetting(c *gin.Context) {
	var req UpdateSettingReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الإعداد غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.UpdateSetting(c.Request.Context(), adminID, req.Key, req.Value); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حفظ الإعداد بنجاح", gin.H{"key": req.Key, "value": req.Value})
}

// ─── Store Verification & Delivery Fees ───

type VerifyStoreReq struct {
	IsVerified bool `json:"is_verified"`
}

func (h *AdminHandler) VerifyStore(c *gin.Context) {
	idStr := c.Param("id")
	storeID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	var req VerifyStoreReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التوثيق غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	if err := h.adminService.VerifyStore(c.Request.Context(), adminID, storeID, req.IsVerified); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	msg := "تم توثيق المتجر بنجاح"
	if !req.IsVerified {
		msg = "تم إلغاء توثيق المتجر بنجاح"
	}
	utils.SuccessResponse(c, http.StatusOK, msg, gin.H{"store_id": storeID, "is_verified": req.IsVerified})
}

func (h *AdminHandler) GetStoreDeliveryFees(c *gin.Context) {
	idStr := c.Param("id")
	merchantID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	fees, err := h.adminService.GetStoreDeliveryFees(c.Request.Context(), merchantID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب أسعار التوصيل بنجاح", fees)
}

type UpdateDeliveryFeesReq struct {
	Fees []domain.UpdateDeliveryFeeRequest `json:"fees" binding:"required,min=1"`
}

func (h *AdminHandler) UpdateStoreDeliveryFees(c *gin.Context) {
	idStr := c.Param("id")
	merchantID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف المتجر غير صالح", err)
		return
	}

	var req UpdateDeliveryFeesReq
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات أسعار التوصيل غير صالحة", err)
		return
	}

	adminID := h.getAdminID(c)
	for _, fee := range req.Fees {
		isActive := true
		if fee.IsActive != nil {
			isActive = *fee.IsActive
		}
		if err := h.adminService.UpsertStoreDeliveryFee(c.Request.Context(), adminID, merchantID, fee.GovernorateID, fee.FeeIQD, fee.EstimatedDays, isActive); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث أسعار التوصيل بنجاح", gin.H{"merchant_id": merchantID})
}

// ─── Low Stock Products ───

func (h *AdminHandler) LowStockProducts(c *gin.Context) {
	products, err := h.adminService.GetLowStockProducts(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب المنتجات القليلة المخزون بنجاح", products)
}

