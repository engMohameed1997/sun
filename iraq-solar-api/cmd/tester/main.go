package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"

	"github.com/gin-gonic/gin"

	"github.com/iraq-solar/api/internal/config"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/handler"
	"github.com/iraq-solar/api/internal/middleware"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/internal/service"
)

type TestResult struct {
	Endpoint   string `json:"endpoint"`
	Method     string `json:"method"`
	StatusCode int    `json:"status_code"`
	Passed     bool   `json:"passed"`
	Message    string `json:"message"`
}

func setupTestRouter() (*gin.Engine, *service.AuthService) {
	gin.SetMode(gin.TestMode)
	router := gin.Default()

	cfg := config.Load()

	userRepo := repository.NewUserRepository(nil)
	productRepo := repository.NewProductRepository(nil)
	calcRepo := repository.NewSolarCalculationRepository(nil)

	authService := service.NewAuthService(cfg.JWTSecret, userRepo)
	calcService := service.NewSolarCalculatorService(calcRepo)

	authHandler := handler.NewAuthHandler(authService)
	calcHandler := handler.NewCalculatorHandler(calcService)
	productHandler := handler.NewProductHandler(productRepo, nil, nil)

	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "iraq-solar-api"})
	})

	v1 := router.Group("/api/v1")
	{
		v1.POST("/auth/register", authHandler.Register)
		v1.POST("/auth/login", authHandler.Login)
		v1.POST("/calculator/estimate", calcHandler.EstimateSystem)
		v1.GET("/products", productHandler.ListProducts)

		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware(authService))
		{
			protected.GET("/user/profile", func(c *gin.Context) {
				userID, _ := c.Get("user_id")
				email, _ := c.Get("email")
				role, _ := c.Get("role")
				c.JSON(http.StatusOK, gin.H{
					"success": true,
					"user_id": userID,
					"email":   email,
					"role":    role,
				})
			})

			adminOnly := protected.Group("/admin")
			adminOnly.Use(middleware.RequireRole(domain.RoleAdmin))
			{
				adminOnly.GET("/stats", func(c *gin.Context) {
					c.JSON(http.StatusOK, gin.H{
						"success":           true,
						"total_orders":      142,
						"total_revenue_iqd": 185400000.00,
					})
				})
			}
		}
	}

	return router, authService
}

func main() {
	fmt.Println("============ 🚀 بدء فحص واختبار جميع الـ Endpoints ============")
	router, authService := setupTestRouter()

	results := []TestResult{}

	// 1. Test Health Endpoint
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/health", nil)
	router.ServeHTTP(w, req)
	results = append(results, TestResult{
		Endpoint:   "/health",
		Method:     "GET",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusOK,
		Message:    "فحص حالة السيرفر والصحة العامة",
	})

	// 2. Test User Registration Endpoint
	regBody, _ := json.Marshal(domain.RegisterRequest{
		FullName:    "أحمد علي - مهندس طاقة",
		Email:       "ahmed.engineer@iraqsolar.iq",
		Phone:       "+9647712345678",
		Password:    "SecurePass123!",
		Governorate: "Baghdad",
		City:        "Mansour",
	})
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(regBody))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	var regResponse struct {
		Success bool `json:"success"`
		Data    struct {
			Token string      `json:"token"`
			User  domain.User `json:"user"`
		} `json:"data"`
	}
	json.Unmarshal(w.Body.Bytes(), &regResponse)

	userToken := regResponse.Data.Token
	results = append(results, TestResult{
		Endpoint:   "/api/v1/auth/register",
		Method:     "POST",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusCreated && userToken != "",
		Message:    "تسجيل حساب جديد وتوليد JWT Token بنجاح",
	})

	// 3. Test User Login Endpoint
	loginBody, _ := json.Marshal(domain.LoginRequest{
		Email:    "ahmed.engineer@iraqsolar.iq",
		Password: "SecurePass123!",
	})
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(loginBody))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	json.Unmarshal(w.Body.Bytes(), &regResponse)
	if userToken == "" {
		userToken = regResponse.Data.Token
	}
	results = append(results, TestResult{
		Endpoint:   "/api/v1/auth/login",
		Method:     "POST",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusOK && regResponse.Data.Token != "",
		Message:    "تسجيل الدخول واستلام رمز JWT المعتمَد",
	})

	// 4. Test Authenticated User Profile (With Token)
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/api/v1/user/profile", nil)
	req.Header.Set("Authorization", "Bearer "+userToken)
	router.ServeHTTP(w, req)
	results = append(results, TestResult{
		Endpoint:   "/api/v1/user/profile",
		Method:     "GET [With Token]",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusOK,
		Message:    "وصول ناجح للملف الشخصي باستخدام Bearer Token",
	})

	// 5. Test Authenticated User Profile (WITHOUT Token - Should fail 401)
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/api/v1/user/profile", nil)
	router.ServeHTTP(w, req)
	results = append(results, TestResult{
		Endpoint:   "/api/v1/user/profile",
		Method:     "GET [No Token]",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusUnauthorized,
		Message:    "رفض الوصول 401 Unauthorized عند عدم إرسال التوكن",
	})

	// 6. Test Solar Calculator Endpoint
	calcBody, _ := json.Marshal(domain.SolarCalculationRequest{
		DailyConsumptionkWh: 30.0,
		PeakSunHours:        5.5,
		AutonomyDays:        1,
		PanelWattage:        550,
	})
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("POST", "/api/v1/calculator/estimate", bytes.NewBuffer(calcBody))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)
	results = append(results, TestResult{
		Endpoint:   "/api/v1/calculator/estimate",
		Method:     "POST",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusOK,
		Message:    "حساب تقدير قدرة وسعة المنظومة الشمسية والبطاريات",
	})

	// 7. Test Products Catalog Endpoint
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/api/v1/products", nil)
	router.ServeHTTP(w, req)
	results = append(results, TestResult{
		Endpoint:   "/api/v1/products",
		Method:     "GET",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusOK,
		Message:    "عرض كتالوج الألواح والانفيرترات والبطاريات الشمسية",
	})

	// 8. Test Admin Stats Endpoint (Normal Customer Role - Should fail 403)
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/api/v1/admin/stats", nil)
	req.Header.Set("Authorization", "Bearer "+userToken)
	router.ServeHTTP(w, req)
	results = append(results, TestResult{
		Endpoint:   "/api/v1/admin/stats",
		Method:     "GET [Customer Token]",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusForbidden,
		Message:    "حماية مسارات الأدمن وتطبيق RBAC بظهور 403 Forbidden",
	})

	// 9. Test Admin Stats Endpoint (With Generated Admin Token)
	adminUser := &domain.User{
		ID:    domain.User{}.ID,
		Email: "admin@iraqsolar.iq",
		Role:  domain.RoleAdmin,
	}
	adminToken, _, _ := authService.GenerateToken(adminUser)
	w = httptest.NewRecorder()
	req, _ = http.NewRequest("GET", "/api/v1/admin/stats", nil)
	req.Header.Set("Authorization", "Bearer "+adminToken)
	router.ServeHTTP(w, req)
	results = append(results, TestResult{
		Endpoint:   "/api/v1/admin/stats",
		Method:     "GET [Admin Token]",
		StatusCode: w.Code,
		Passed:     w.Code == http.StatusOK,
		Message:    "وصول ناجح لمسار الأدمن باستخدام توكن بصلاحيات Admin",
	})

	// Print Results Summary Table
	fmt.Println("\n--------------------------------------------------------------------------------")
	fmt.Printf("%-35s | %-18s | %-6s | %-8s\n", "Endpoint", "Method/Context", "Status", "Result")
	fmt.Println("--------------------------------------------------------------------------------")
	allPassed := true
	for _, res := range results {
		statusStr := "PASSED ✅"
		if !res.Passed {
			statusStr = "FAILED ❌"
			allPassed = false
		}
		fmt.Printf("%-35s | %-18s | %-6d | %-8s\n", res.Endpoint, res.Method, res.StatusCode, statusStr)
		fmt.Printf("   💬 التفاصيل: %s\n", res.Message)
	}
	fmt.Println("--------------------------------------------------------------------------------")

	if allPassed {
		fmt.Println("🎉 اكتمل فحص جميع الـ Endpoints بنجاح 100%! النظام جاهز للإنتاج.")
	} else {
		fmt.Println("⚠️ هناك بعض نقاط النهاية التي تحتاج لمراجعة.")
		os.Exit(1)
	}
}

// Suppress unused imports warning
var _ = io.EOF
