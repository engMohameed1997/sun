package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req domain.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التسجيل غير صالحة", err)
		return
	}

	user, token, refreshToken, err := h.authService.RegisterUser(c.Request.Context(), req)
	if err != nil {
		utils.BadRequestError(c, "فشل تسجيل المستخدم", err)
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "تم تسجيل حساب المستخدم بنجاح", domain.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		User:         *user,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req domain.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الدخول غير صالحة", err)
		return
	}

	user, token, refreshToken, err := h.authService.LoginUser(c.Request.Context(), req)
	if err != nil {
		utils.UnauthorizedError(c, "بيانات الدخول غير صحيحة")
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تسجيل الدخول بنجاح", domain.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		User:         *user,
	})
}
