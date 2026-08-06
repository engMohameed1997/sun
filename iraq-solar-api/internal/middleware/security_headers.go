package middleware

import (
	"github.com/gin-gonic/gin"
)

// SecurityHeadersMiddleware adds essential HTTP security headers to protect against common web vulnerabilities
func SecurityHeadersMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Prevent clickjacking (legacy browsers)
		c.Writer.Header().Set("X-Frame-Options", "DENY")
		// Prevent MIME-sniffing
		c.Writer.Header().Set("X-Content-Type-Options", "nosniff")
		// Control referrer header sending: only send origin on cross-origin requests
		c.Writer.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		// Content Security Policy: restrict sources and disable unsafe inline scripts
		c.Writer.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data: blob:; font-src 'self'; connect-src 'self' ws: wss:; frame-ancestors 'none'; form-action 'self'; base-uri 'self';")
		// Disable the deprecated X-XSS-Protection header; it can introduce vulnerabilities in modern browsers
		c.Writer.Header().Set("X-XSS-Protection", "0")
		// Force HTTPS if the request is already over TLS
		if c.Request.TLS != nil || c.GetHeader("X-Forwarded-Proto") == "https" {
			c.Writer.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
		}

		c.Next()
	}
}
