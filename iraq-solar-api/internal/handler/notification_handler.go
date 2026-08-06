package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/pkg/utils"
)

type NotificationHandler struct {
	repo *repository.NotificationRepository
}

func NewNotificationHandler(repo *repository.NotificationRepository) *NotificationHandler {
	return &NotificationHandler{repo: repo}
}

func getUserIDFromContext(c *gin.Context) (uuid.UUID, bool) {
	userIDVal, ok := c.Get("user_id")
	if !ok {
		return uuid.Nil, false
	}
	switch v := userIDVal.(type) {
	case uuid.UUID:
		return v, true
	case string:
		u, err := uuid.Parse(v)
		if err == nil {
			return u, true
		}
	}
	return uuid.Nil, false
}

func (h *NotificationHandler) ListNotifications(c *gin.Context) {
	userID, ok := getUserIDFromContext(c)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	if page < 1 {
		page = 1
	}

	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "10"))
	if perPage < 1 {
		perPage = 10
	}

	notifications, total, err := h.repo.ListByRecipient(c.Request.Context(), userID, page, perPage)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "حدث خطأ أثناء جلب الإشعارات", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب الإشعارات بنجاح", gin.H{
		"notifications": notifications,
		"total":         total,
		"page":          page,
		"per_page":      perPage,
	})
}

func (h *NotificationHandler) UnreadCount(c *gin.Context) {
	userID, ok := getUserIDFromContext(c)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	count, err := h.repo.CountUnread(c.Request.Context(), userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "حدث خطأ أثناء جلب عدد الإشعارات غير المقروءة", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب العدد بنجاح", gin.H{
		"unread_count": count,
		"count":        count,
	})
}

func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	userID, ok := getUserIDFromContext(c)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "معرف الإشعار غير صالح", "BAD_REQUEST", err)
		return
	}

	err = h.repo.MarkAsRead(c.Request.Context(), id, userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "حدث خطأ أثناء تحديث الإشعار", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث الإشعار كـ مقروء", nil)
}

func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
	userID, ok := getUserIDFromContext(c)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	err := h.repo.MarkAllAsRead(c.Request.Context(), userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "حدث خطأ أثناء تحديث الإشعارات", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم قراءة جميع الإشعارات بنجاح", nil)
}

func (h *NotificationHandler) DeleteNotification(c *gin.Context) {
	userID, ok := getUserIDFromContext(c)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "معرف الإشعار غير صالح", "BAD_REQUEST", err)
		return
	}

	err = h.repo.Delete(c.Request.Context(), id, userID)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "حدث خطأ أثناء حذف الإشعار", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم حذف الإشعار بنجاح", nil)
}
