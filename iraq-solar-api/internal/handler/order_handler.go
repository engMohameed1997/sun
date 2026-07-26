package handler

import (
	"net/http"

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

func (h *OrderHandler) GetOrderDetails(c *gin.Context) {
	idStr := c.Param("id")
	orderID, err := uuid.Parse(idStr)
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

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل الطلب بنجاح", order)
}

func (h *OrderHandler) UpdateOrderStatus(c *gin.Context) {
	idStr := c.Param("id")
	orderID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	var req domain.UpdateOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الحالة غير صالحة", err)
		return
	}

	if err := h.orderService.UpdateOrderStatus(c.Request.Context(), orderID, req.Status); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة الطلب بنجاح", gin.H{"id": orderID, "status": req.Status})
}

func (h *OrderHandler) CancelOrder(c *gin.Context) {
	idStr := c.Param("id")
	orderID, err := uuid.Parse(idStr)
	if err != nil {
		utils.BadRequestError(c, "معرف الطلب غير صالح", err)
		return
	}

	if err := h.orderService.CancelOrder(c.Request.Context(), orderID); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم إلغاء الطلب بنجاح", gin.H{"id": orderID, "status": domain.StatusCancelled})
}
