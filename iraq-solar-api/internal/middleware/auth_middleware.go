package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
)

func AuthMiddleware(authService *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		claims, user, err := authService.ValidateTokenWithContext(c.Request.Context(), parts[1])
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Set("role", claims.Role)
		if user != nil && user.GovernorateID != nil {
			c.Set("governorate_id", *user.GovernorateID)
		}
		c.Next()
	}
}

// OptionalAuthMiddleware validates JWT token if provided in Authorization header.
// If no Authorization header is present, it proceeds as guest without setting context claims.
// If an Authorization header IS present but invalid, it returns 401 Unauthorized.
func OptionalAuthMiddleware(authService *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		claims, user, err := authService.ValidateTokenWithContext(c.Request.Context(), parts[1])
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Set("role", claims.Role)
		if user != nil && user.GovernorateID != nil {
			c.Set("governorate_id", *user.GovernorateID)
		}
		c.Next()
	}
}

// WSAuthMiddleware authenticates WebSocket connections using the Authorization header.
// Tokens MUST NOT be passed in the URL query string because URLs are logged by servers,
// proxies, browsers, and can be leaked via Referer headers. The WebSocket handshake is an
// HTTP request, so clients that can set headers (e.g., wscat, mobile apps, server clients)
// should send Authorization: Bearer <JWT>.
func WSAuthMiddleware(authService *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required for WebSocket"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization header format"})
			c.Abort()
			return
		}

		tokenStr := parts[1]

		claims, user, err := authService.ValidateTokenWithContext(c.Request.Context(), tokenStr)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Set("role", claims.Role)
		if user != nil && user.GovernorateID != nil {
			c.Set("governorate_id", *user.GovernorateID)
		}
		c.Next()
	}
}

func RequireRole(roles ...domain.Role) gin.HandlerFunc {
	return func(c *gin.Context) {
		roleVal, exists := c.Get("role")
		if !exists {
			c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: No role found in request context"})
			c.Abort()
			return
		}

		userRole := roleVal.(domain.Role)
		for _, allowedRole := range roles {
			if userRole == allowedRole {
				c.Next()
				return
			}
		}

		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: Insufficient permissions"})
		c.Abort()
	}
}

func RequirePermission(perm domain.Permission) gin.HandlerFunc {
	return func(c *gin.Context) {
		roleVal, exists := c.Get("role")
		if !exists {
			c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: No role found in request context"})
			c.Abort()
			return
		}

		userRole := roleVal.(domain.Role)
		if domain.HasPermission(userRole, perm) {
			c.Next()
			return
		}

		c.JSON(http.StatusForbidden, gin.H{"error": "Forbidden: Insufficient permissions"})
		c.Abort()
	}
}
