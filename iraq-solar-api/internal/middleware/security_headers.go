package middleware

import (
	"github.com/gin-gonic/gin"
)

// SecurityHeadersMiddleware adds essential HTTP security headers to protect against common web vulnerabilities
func SecurityHeadersMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Prevent clickjacking
		c.Writer.Header().Set("X-Frame-Options", "DENY")
		// Prevent MIME-sniffing
		c.Writer.Header().Set("X-Content-Type-Options", "nosniff")
		// Enable XSS protection filter in modern browsers
		c.Writer.Header().Set("X-XSS-Protection", "1; mode=block")
		// Control referrer header sending
		c.Writer.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		// Content Security Policy
		c.Writer.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;")
		// Force HTTPS if behind SSL proxy
		c.Writer.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")

		c.Next()
	}
}
