package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

type SupportTicketHandler struct {
	service *service.SupportTicketService
}

func NewSupportTicketHandler(service *service.SupportTicketService) *SupportTicketHandler {
	return &SupportTicketHandler{service: service}
}

func (h *SupportTicketHandler) CreateTicket(c *gin.Context) {
	var req domain.CreateTicketRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التذكرة غير صالحة", err)
		return
	}

	val, exists := c.Get("user_id")
	if !exists {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	userID := val.(uuid.UUID)

	ticket, err := h.service.CreateTicket(c.Request.Context(), userID, req)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم إرسال تذكرة الدعم الفني بنجاح", ticket)
}

func (h *SupportTicketHandler) ListUserTickets(c *gin.Context) {
	val, exists := c.Get("user_id")
	if !exists {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	userID := val.(uuid.UUID)

	tickets, err := h.service.GetUserTickets(c.Request.Context(), userID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تذاكر المستخدم بنجاح", tickets)
}
