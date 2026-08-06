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

type OrderHandler struct {
	orderService *service.OrderService
}

func NewOrderHandler(orderService *service.OrderService) *OrderHandler {
	return &OrderHandler{orderService: orderService}
}

// CreateOrder handles POST /orders — creates a new order for the authenticated user.
func (h *OrderHandler) CreateOrder(c *gin.Context) {
	var req domain.CreateOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الطلب غير صالحة", err)
		return
	}

	userIDVal, exists := c.Get("user_id")
	if !exists {
		utils.UnauthorizedError(c, "يرجى تسجيل الدخول لتقديم الطلب")
		return
	}
	userID := userIDVal.(uuid.UUID)

	order, err := h.orderService.CreateOrder(c.Request.Context(), userID, req)
	if err != nil {
		utils.BadRequestError(c, "فشل إنشاء الطلب", err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء طلب الشراء بنجاح", order)
}

// ListUserOrders handles GET /orders — returns all orders for the authenticated user.
func (h *OrderHandler) ListUserOrders(c *gin.Context) {
	userIDVal, exists := c.Get("user_id")
	if !exists {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	userID := userIDVal.(uuid.UUID)

	orders, err := h.orderService.GetUserOrders(c.Request.Context(), userID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب طلبات المستخدم بنجاح", orders)
}

// GetOrderDetails handles GET /orders/:id — returns a single order's details.
// Only the order owner or an admin may view the order.
func (h *OrderHandler) GetOrderDetails(c *gin.Context) {
	orderID, err := parseOrderID(c)
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	order, err := h.orderService.GetOrderByID(c.Request.Context(), orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "الطلب غير موجود", "ORDER_NOT_FOUND", nil)
		return
	}

	if !isOwnerOrAdmin(c, order.UserID) {
		utils.ErrorResponse(c, http.StatusForbidden, "غير مصرح بالوصول لهذا الطلب", "FORBIDDEN", nil)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل الطلب بنجاح", order)
}

// UpdateOrderStatus handles PUT /orders/:id/status (user-facing).
func (h *OrderHandler) UpdateOrderStatus(c *gin.Context) {
	orderID, err := parseOrderID(c)
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	var req domain.UpdateOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الحالة غير صالحة", err)
		return
	}

	// Extract changer identity
	var changedBy *uuid.UUID
	if userIDVal, ok := c.Get("user_id"); ok {
		uid := userIDVal.(uuid.UUID)
		changedBy = &uid
	}

	if err := h.orderService.UpdateOrderStatus(c.Request.Context(), orderID, req.Status, req.Notes, changedBy); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة الطلب بنجاح", gin.H{"id": orderID, "status": req.Status})
}

// CancelOrder handles DELETE /orders/:id — cancels the order.
// Only the order owner or an admin may cancel the order.
func (h *OrderHandler) CancelOrder(c *gin.Context) {
	orderID, err := parseOrderID(c)
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	order, err := h.orderService.GetOrderByID(c.Request.Context(), orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "الطلب غير موجود", "ORDER_NOT_FOUND", nil)
		return
	}

	if !isOwnerOrAdmin(c, order.UserID) {
		utils.ErrorResponse(c, http.StatusForbidden, "غير مصرح بإلغاء هذا الطلب", "FORBIDDEN", nil)
		return
	}

	if err := h.orderService.CancelOrder(c.Request.Context(), orderID); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم إلغاء الطلب بنجاح", gin.H{"id": orderID, "status": domain.StatusCancelled})
}

// ─── Admin Endpoints ────────────────────────────────────────────────────────

// AdminListOrders handles GET /admin/orders — paginated, filtered orders list for admins.
// Query params: page, limit, status, search, store_id, branch_id, from_date, to_date
func (h *OrderHandler) AdminListOrders(c *gin.Context) {
	filters := domain.AdminOrderFilters{
		Status:   c.Query("status"),
		Search:   c.Query("search"),
		StoreID:  c.Query("store_id"),
		BranchID: c.Query("branch_id"),
		FromDate: c.Query("from_date"),
		ToDate:   c.Query("to_date"),
	}

	if p, err := strconv.Atoi(c.DefaultQuery("page", "1")); err == nil {
		filters.Page = p
	}
	if l, err := strconv.Atoi(c.DefaultQuery("limit", "20")); err == nil {
		filters.Limit = l
	}

	result, err := h.orderService.GetAdminOrders(c.Request.Context(), filters)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب الطلبات بنجاح", result)
}

// AdminGetOrder handles GET /admin/orders/:id — full order details with relations + history.
func (h *OrderHandler) AdminGetOrder(c *gin.Context) {
	orderID, err := parseOrderID(c)
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	order, err := h.orderService.GetOrderFullByID(c.Request.Context(), orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "الطلب غير موجود", "ORDER_NOT_FOUND", nil)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل الطلب بنجاح", order)
}

// AdminUpdateOrderStatus handles PUT /admin/orders/:id/status — with notes and who changed it.
func (h *OrderHandler) AdminUpdateOrderStatus(c *gin.Context) {
	orderID, err := parseOrderID(c)
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	var req domain.UpdateOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الحالة غير صالحة", err)
		return
	}

	var changedBy *uuid.UUID
	if userIDVal, ok := c.Get("user_id"); ok {
		uid := userIDVal.(uuid.UUID)
		changedBy = &uid
	}

	if err := h.orderService.UpdateOrderStatus(c.Request.Context(), orderID, req.Status, req.Notes, changedBy); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة الطلب بنجاح", gin.H{
		"id":     orderID,
		"status": req.Status,
		"notes":  req.Notes,
	})
}

// ─── Helpers ────────────────────────────────────────────────────────────────

func parseOrderID(c *gin.Context) (uuid.UUID, error) {
	return uuid.Parse(c.Param("id"))
}

func isOwnerOrAdmin(c *gin.Context, ownerID uuid.UUID) bool {
	if ownerID == uuid.Nil {
		return false
	}

	userIDVal, ok := c.Get("user_id")
	if !ok {
		return false
	}
	userID, ok := userIDVal.(uuid.UUID)
	if !ok {
		return false
	}
	if userID == ownerID {
		return true
	}

	roleVal, ok := c.Get("role")
	if !ok {
		return false
	}
	role, ok := roleVal.(domain.Role)
	if !ok {
		return false
	}
	return role == domain.RoleAdmin
}
