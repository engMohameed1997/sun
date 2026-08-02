package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/pkg/utils"
)

type ProfileHandler struct {
	userRepo repository.UserRepository
}

func NewProfileHandler(userRepo repository.UserRepository) *ProfileHandler {
	return &ProfileHandler{userRepo: userRepo}
}

// GetProfile - GET /user/profile
func (h *ProfileHandler) GetProfile(c *gin.Context) {
	userID, ok := c.Get("user_id")
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}
	uid, ok := userID.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	user, err := h.userRepo.FindByID(c.Request.Context(), uid)
	if err != nil || user == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "لم يتم العثور على المستخدم", "NOT_FOUND", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب الملف الشخصي بنجاح", gin.H{
		"id":          user.ID,
		"full_name":   user.FullName,
		"email":       user.Email,
		"phone":       user.Phone,
		"role":        user.Role,
		"governorate": user.Governorate,
		"city":        user.City,
		"is_active":   user.IsActive,
		"is_verified": user.IsVerified,
		"created_at":  user.CreatedAt,
	})
}

// UpdateProfile - PUT /user/profile
func (h *ProfileHandler) UpdateProfile(c *gin.Context) {
	userIDVal, ok := c.Get("user_id")
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}
	userID, ok := userIDVal.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	var req struct {
		FullName    string `json:"full_name"`
		Phone       string `json:"phone"`
		Governorate string `json:"governorate"`
		City        string `json:"city"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "بيانات غير صالحة", "BAD_REQUEST", err)
		return
	}

	user, err := h.userRepo.FindByID(c.Request.Context(), userID)
	if err != nil || user == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "لم يتم العثور على المستخدم", "NOT_FOUND", err)
		return
	}

	if req.FullName != "" {
		user.FullName = req.FullName
	}
	if req.Phone != "" {
		user.Phone = req.Phone
	}
	if req.Governorate != "" {
		user.Governorate = req.Governorate
	}
	if req.City != "" {
		user.City = req.City
	}
	user.UpdatedAt = time.Now()

	if err := h.userRepo.Update(c.Request.Context(), user); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "فشل تحديث الملف الشخصي", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تحديث الملف الشخصي بنجاح", gin.H{
		"id":          user.ID,
		"full_name":   user.FullName,
		"email":       user.Email,
		"phone":       user.Phone,
		"role":        user.Role,
		"governorate": user.Governorate,
		"city":        user.City,
	})
}

// ChangePassword - PUT /user/password
func (h *ProfileHandler) ChangePassword(c *gin.Context) {
	userIDVal, ok := c.Get("user_id")
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}
	userID, ok := userIDVal.(uuid.UUID)
	if !ok {
		utils.ErrorResponse(c, http.StatusUnauthorized, "غير مصرح", "UNAUTHORIZED", nil)
		return
	}

	var req struct {
		OldPassword string `json:"old_password" binding:"required"`
		NewPassword string `json:"new_password" binding:"required,min=6"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "يرجى إدخال كلمة المرور القديمة والجديدة (6 أحرف على الأقل)", "BAD_REQUEST", err)
		return
	}

	user, err := h.userRepo.FindByID(c.Request.Context(), userID)
	if err != nil || user == nil {
		utils.ErrorResponse(c, http.StatusNotFound, "لم يتم العثور على المستخدم", "NOT_FOUND", err)
		return
	}

	// Verify old password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.OldPassword)); err != nil {
		utils.ErrorResponse(c, http.StatusBadRequest, "كلمة المرور الحالية غير صحيحة", "BAD_REQUEST", err)
		return
	}

	// Hash new password
	newHash, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "فشل تشفير كلمة المرور الجديدة", "INTERNAL_ERROR", err)
		return
	}

	if err := h.userRepo.UpdatePassword(c.Request.Context(), userID, string(newHash)); err != nil {
		utils.ErrorResponse(c, http.StatusInternalServerError, "فشل تحديث كلمة المرور", "INTERNAL_ERROR", err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تغيير كلمة المرور بنجاح", nil)
}
