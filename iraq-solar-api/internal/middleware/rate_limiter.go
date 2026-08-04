package middleware

import (
	"errors"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/iraq-solar/api/pkg/utils"
)

type ipVisitor struct {
	lastSeen time.Time
	tokens   float64
}

type RateLimiter struct {
	mu           sync.Mutex
	visitors     map[string]*ipVisitor
	rate         float64 // tokens per second
	capacity     float64 // max tokens
	cleanupEvery time.Duration
}

func NewRateLimiter(reqPerMin int) *RateLimiter {
	rate := float64(reqPerMin) / 60.0
	limiter := &RateLimiter{
		visitors:     make(map[string]*ipVisitor),
		rate:         rate,
		capacity:     float64(reqPerMin),
		cleanupEvery: 3 * time.Minute,
	}

	go limiter.cleanupLoop()
	return limiter
}

func (rl *RateLimiter) allow(ip string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	v, exists := rl.visitors[ip]
	if !exists {
		rl.visitors[ip] = &ipVisitor{
			lastSeen: now,
			tokens:   rl.capacity - 1,
		}
		return true
	}

	elapsed := now.Sub(v.lastSeen).Seconds()
	v.lastSeen = now
	v.tokens += elapsed * rl.rate
	if v.tokens > rl.capacity {
		v.tokens = rl.capacity
	}

	if v.tokens >= 1.0 {
		v.tokens -= 1.0
		return true
	}

	return false
}

func (rl *RateLimiter) cleanupLoop() {
	ticker := time.NewTicker(rl.cleanupEvery)
	for range ticker.C {
		rl.mu.Lock()
		now := time.Now()
		for ip, v := range rl.visitors {
			if now.Sub(v.lastSeen) > 5*time.Minute {
				delete(rl.visitors, ip)
			}
		}
		rl.mu.Unlock()
	}
}

// RateLimiterMiddleware limits requests per IP address
func RateLimiterMiddleware(reqPerMin int) gin.HandlerFunc {
	limiter := NewRateLimiter(reqPerMin)

	return func(c *gin.Context) {
		ip := c.ClientIP()
		if !limiter.allow(ip) {
			utils.ErrorResponse(c, http.StatusTooManyRequests, "تجاوزت الحد المسموح به من الطلبات، يرجى الانتظار قليلاً والتحقق مجدداً", "RATE_LIMIT_EXCEEDED", errors.New("rate limit reached"))
			c.Abort()
			return
		}
		c.Next()
	}
}

// StrictRateLimiterMiddleware provides tighter rate limits for sensitive routes (Login / Register / Refresh)
func StrictRateLimiterMiddleware(reqPerMin int) gin.HandlerFunc {
	limiter := NewRateLimiter(reqPerMin)

	return func(c *gin.Context) {
		ip := c.ClientIP()
		if !limiter.allow(ip) {
			utils.ErrorResponse(c, http.StatusTooManyRequests, "تم تجاوز الحد الأقصى لمحاولات الدخول/التسجيل. يرجى الانتظار دقيقة والتحقق مجدداً", "AUTH_RATE_LIMIT_EXCEEDED", errors.New("auth rate limit exceeded"))
			c.Abort()
			return
		}
		c.Next()
	}
}
