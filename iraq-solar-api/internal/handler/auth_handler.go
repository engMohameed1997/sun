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
		utils.BadRequestError(c, err.Error(), err)
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

	secContext := domain.LoginSecurityContext{
		IPAddress: c.ClientIP(),
		UserAgent: c.GetHeader("User-Agent"),
	}

	user, token, refreshToken, err := h.authService.LoginUserWithSecurity(c.Request.Context(), req, secContext)
	if err != nil {
		utils.UnauthorizedError(c, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تسجيل الدخول بنجاح", domain.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		User:         *user,
	})
}

func (h *AuthHandler) Refresh(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token"`
	}
	_ = c.ShouldBindJSON(&req)

	refreshTokenStr := req.RefreshToken
	if refreshTokenStr == "" {
		refreshTokenStr = c.GetHeader("X-Refresh-Token")
	}

	if refreshTokenStr == "" {
		utils.BadRequestError(c, "رمز التجديد مطلوب", nil)
		return
	}

	secContext := domain.LoginSecurityContext{
		IPAddress: c.ClientIP(),
		UserAgent: c.GetHeader("User-Agent"),
	}

	newToken, newRefreshToken, err := h.authService.RefreshTokenWithSecurity(c.Request.Context(), refreshTokenStr, secContext)
	if err != nil {
		utils.UnauthorizedError(c, err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تجديد الرمز بنجاح", gin.H{
		"token":         newToken,
		"refresh_token": newRefreshToken,
	})
}

func (h *AuthHandler) Logout(c *gin.Context) {
	var req struct {
		RefreshToken string `json:"refresh_token"`
	}
	_ = c.ShouldBindJSON(&req)

	refreshTokenStr := req.RefreshToken
	if refreshTokenStr == "" {
		refreshTokenStr = c.GetHeader("X-Refresh-Token")
	}

	if refreshTokenStr != "" {
		_ = h.authService.LogoutUser(c.Request.Context(), refreshTokenStr)
	}

	utils.SuccessResponse(c, http.StatusOK, "تم تسجيل الخروج بنجاح", nil)
}
