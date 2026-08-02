package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/pkg/utils"
)

type InstallerHandler struct {
	userRepo repository.UserRepository
}

func NewInstallerHandler(userRepo repository.UserRepository) *InstallerHandler {
	return &InstallerHandler{userRepo: userRepo}
}

// ListInstallers - GET /installers - Public endpoint
func (h *InstallerHandler) ListInstallers(c *gin.Context) {
	governorate := c.Query("governorate")
	search := c.Query("search")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ := strconv.Atoi(c.DefaultQuery("per_page", "20"))

	if page < 1 { page = 1 }
	if perPage < 1 || perPage > 50 { perPage = 20 }

	roles := []string{"installer", "engineer"}
	users, total, err := h.userRepo.ListByRole(c.Request.Context(), roles, governorate, search, page, perPage)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "فشل جلب قائمة الفنيين", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الفنيين والمهندسين بنجاح", gin.H{
		"installers": users,
		"pagination": gin.H{
			"page": page,
			"per_page": perPage,
			"total": total,
			"total_pages": (total + perPage - 1) / perPage,
		},
	})
}

// GetInstallerDetail - GET /installers/:id - Public endpoint
func (h *InstallerHandler) GetInstallerDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "معرّف الفني غير صالح", "BAD_REQUEST", err)
		return
	}

	user, err := h.userRepo.FindByID(c.Request.Context(), id)
	if err != nil || user == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "لم يتم العثور على الفني", "NOT_FOUND", err)
		return
	}

	if user.Role != "installer" && user.Role != "engineer" {
		utils.ErrorResponse(c, http.StatusNotFound, "لم يتم العثور على الفني", "NOT_FOUND", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل الفني بنجاح", user)
}
