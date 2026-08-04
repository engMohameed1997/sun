package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/iraq-solar/api/internal/config"
	"github.com/iraq-solar/api/internal/database"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/handler"
	"github.com/iraq-solar/api/internal/hub"
	"github.com/iraq-solar/api/internal/middleware"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

func main() {
	log.Println("Starting Iraq Solar Enterprise Backend API...")

	// 1. Load Configurations
	cfg := config.Load()

	// 2. Initialize Database Connection
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Fatal: DB Connection failed: %v", err)
	}
	defer db.Close()
	_ = database.SeedDatabase(db)

	// 3. Initialize Repositories
	userRepo := repository.NewUserRepository(db)
	secRepo := repository.NewAuthSecurityRepository(db)
	storeRepo := repository.NewStoreRepository(db)
	productRepo := repository.NewProductRepository(db)
	categoryRepo := repository.NewCategoryRepository(db)
	brandRepo := repository.NewBrandRepository(db)
	calcRepo := repository.NewSolarCalculationRepository(db)
	orderRepo := repository.NewOrderRepository(db)
	adminRepo := repository.NewAdminRepository(db)
	governorateRepo := repository.NewGovernorateRepository(db)
	bannerRepo := repository.NewBannerRepository(db)
	notificationRepo := repository.NewNotificationRepository(db)
	ticketRepo := repository.NewSupportTicketRepository(db)

	// 4. Initialize WebSocket Hub (RealtimeHub — handles all realtime connections)
	realtimeHub := hub.NewRealtimeHub()
	go realtimeHub.Run()
	log.Println("RealtimeHub started")

	// 5. Initialize Services
	storeService := service.NewStoreService(storeRepo, userRepo)
	authService := service.NewAuthService(cfg.JWTSecret, userRepo, secRepo)
	calcService := service.NewSolarCalculatorService(calcRepo)
	notificationService := service.NewNotificationService(notificationRepo, realtimeHub)
	orderService := service.NewOrderService(orderRepo, productRepo, realtimeHub, notificationService)
	orderService.StartPendingOrdersCleanupCron(context.Background(), 15*time.Minute, 24)
	adminService := service.NewAdminService(adminRepo, governorateRepo, bannerRepo, notificationRepo)
	ticketService := service.NewSupportTicketService(ticketRepo)

	minioService, minioErr := service.NewMinIOService(cfg.MinIOEndpoint, cfg.MinIOAccessKey, cfg.MinIOSecretKey, cfg.MinIOBucket, cfg.MinIOUseSSL)
	if minioErr != nil {
		log.Printf("MinIO initialization notice: %v", minioErr)
	} else if minioService != nil {
		_ = minioService.InitBucket(context.Background())
	}

	// 5. Initialize Handlers
	storeHandler := handler.NewStoreHandler(storeService)
	authHandler := handler.NewAuthHandler(authService)
	calcHandler := handler.NewCalculatorHandler(calcService)
	productHandler := handler.NewProductHandler(productRepo, storeRepo, categoryRepo)
	brandHandler := handler.NewBrandHandler(brandRepo)
	orderHandler := handler.NewOrderHandler(orderService)
	adminHandler := handler.NewAdminHandler(adminService)
	uploadHandler := handler.NewUploadHandler(minioService)
	wsHandler := handler.NewWebSocketHandler(realtimeHub)
	notifHandler := handler.NewNotificationHandler(notificationRepo)
	installerHandler := handler.NewInstallerHandler(userRepo)
	profileHandler := handler.NewProfileHandler(userRepo)
	ticketHandler := handler.NewSupportTicketHandler(ticketService)

	// 6. Setup Gin Router & Global Security Middlewares
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}
	router := gin.Default()

	// Global Security & Tracing Middlewares
	router.Use(middleware.RequestIDMiddleware())
	router.Use(middleware.CORSMiddleware())
	router.Use(middleware.SecurityHeadersMiddleware())
	router.Use(middleware.RateLimiterMiddleware(100))

	// Health Check Endpoint
	router.GET("/health", func(c *gin.Context) {
		dbStatus := "disconnected"
		if db != nil && db.Ping() == nil {
			dbStatus = "connected"
		}

		c.JSON(http.StatusOK, gin.H{
			"status":      "healthy",
			"service":     "iraq-solar-api",
			"version":     "1.0.0",
			"environment": cfg.Environment,
			"database":    dbStatus,
		})
	})

	// API Group v1
	v1 := router.Group("/api/v1")
	{
		// Public Auth Routes (With strict rate limiting)
		authGroup := v1.Group("/auth")
		authGroup.Use(middleware.StrictRateLimiterMiddleware(15))
		{
			authGroup.POST("/register", authHandler.Register)
			authGroup.POST("/login", authHandler.Login)
			authGroup.POST("/refresh", authHandler.Refresh)
			authGroup.POST("/logout", authHandler.Logout)
		}

		// Solar System Sizing & Specialized Calculators
		calcGroup := v1.Group("/calculator")
		{
			calcGroup.POST("/estimate", calcHandler.EstimateSystem)
			calcGroup.POST("/roi", calcHandler.CalculateROI)
			calcGroup.POST("/battery-runtime", calcHandler.CalculateBatteryRuntime)
			calcGroup.POST("/appliance-consumption", calcHandler.CalculateApplianceConsumption)
			calcGroup.POST("/roof-capacity", calcHandler.CalculateRoofCapacity)
			calcGroup.POST("/full-cost", calcHandler.CalculateFullKitCost)

			// Technician Tools Sub-Group
			techGroup := calcGroup.Group("/tech")
			{
				techGroup.POST("/cable-sizing", calcHandler.CalculateCableSizing)
				techGroup.POST("/mppt-string", calcHandler.CalculateMPPTString)
				techGroup.POST("/breakers-fuses", calcHandler.CalculateBreakersFuses)
				techGroup.POST("/battery-bank", calcHandler.CalculateBatteryBank)
				techGroup.POST("/solar-production", calcHandler.CalculateSolarProduction)
			}
		}

		// Categories & Public Store Routes
		v1.GET("/categories", productHandler.ListCategories)
		v1.GET("/brands", brandHandler.ListBrands)
		v1.GET("/governorates", adminHandler.ListGovernorates)
		v1.GET("/governorates/:id/districts", adminHandler.ListDistricts)
		v1.GET("/banners", adminHandler.ListHomeBanners)
		// Stores (Public)
		v1.GET("/stores", storeHandler.ListStores)
		v1.GET("/stores/:id", storeHandler.GetStore)
		v1.GET("/stores/:id/delivery-fees", adminHandler.GetStoreDeliveryFees)

		// Public Installers/Engineers Directory
		v1.GET("/installers", installerHandler.ListInstallers)
		v1.GET("/installers/:id", installerHandler.GetInstallerDetail)

		// Products Catalog Routes
		productGroup := v1.Group("/products")
		{
			productGroup.GET("", productHandler.ListProducts)
		}

		// --- WebSocket Routes (use WSAuthMiddleware — token via query param) ---
		// App users: real-time notifications
		v1.GET("/ws/notifications", middleware.WSAuthMiddleware(authService), wsHandler.HandleAppNotifications)

		// Protected Routes (Requires JWT Auth)
		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware(authService))
		{
			// User Profile & Calculations Management
			protected.GET("/user/profile", profileHandler.GetProfile)
			protected.PUT("/user/profile", profileHandler.UpdateProfile)
			protected.PUT("/user/password", profileHandler.ChangePassword)
			protected.GET("/user/calculations", calcHandler.ListUserCalculations)

			// Support Tickets Routes
			supportGroup := protected.Group("/support/tickets")
			{
				supportGroup.POST("", ticketHandler.CreateTicket)
				supportGroup.GET("", ticketHandler.ListUserTickets)
			}

			// Orders Management Routes
			ordersGroup := protected.Group("/orders")
			{
				ordersGroup.POST("", orderHandler.CreateOrder)
				ordersGroup.GET("", orderHandler.ListUserOrders)
				ordersGroup.GET("/:id", orderHandler.GetOrderDetails)
				ordersGroup.DELETE("/:id", orderHandler.CancelOrder)
			}

			// Cart Endpoints
			protected.GET("/cart", func(c *gin.Context) {
				utils.SuccessResponse(c, http.StatusOK, "تم جلب محتويات السلة", gin.H{"items": []interface{}{}, "total_amount": 0})
			})
			protected.POST("/cart/items", func(c *gin.Context) {
				utils.SuccessResponse(c, http.StatusCreated, "تم إضافة المنتج للسلة بنجاح", gin.H{"status": "added"})
			})

			// Wallet Endpoints
			protected.GET("/wallet/balance", func(c *gin.Context) {
				utils.SuccessResponse(c, http.StatusOK, "تم جلب رصيد المحفظة الإلكترونية", gin.H{"balance_iqd": 1500000.00, "currency": "IQD"})
			})
			protected.POST("/wallet/topup", func(c *gin.Context) {
				utils.SuccessResponse(c, http.StatusOK, "تم شحن المحفظة بنجاح", gin.H{"new_balance_iqd": 2000000.00})
			})

			// Merchant Product Management Routes
			merchantGroup := protected.Group("/merchant/products")
			merchantGroup.Use(middleware.RequirePermission(domain.PermProductsOwn))
			{
				merchantGroup.GET("", productHandler.ListMerchantProducts)
				merchantGroup.POST("", productHandler.CreateMerchantProduct)
				merchantGroup.PUT("/:id", productHandler.UpdateMerchantProduct)
				merchantGroup.DELETE("/:id", productHandler.DeleteMerchantProduct)
			}

			// Admin Product Management Routes
			adminProducts := protected.Group("/products")
			adminProducts.Use(middleware.RequireRole(domain.RoleAdmin, domain.RoleMerchant))
			{
				adminProducts.POST("", productHandler.CreateProduct)
			}

			// Image Upload Route
			protected.POST("/upload/image", uploadHandler.UploadImage)

			// Notifications REST API
			notifGroup := protected.Group("/notifications")
			{
				notifGroup.GET("", notifHandler.ListNotifications)
				notifGroup.GET("/unread-count", notifHandler.UnreadCount)
				notifGroup.PUT("/:id/read", notifHandler.MarkAsRead)
				notifGroup.PUT("/read-all", notifHandler.MarkAllAsRead)
				notifGroup.DELETE("/:id", notifHandler.DeleteNotification)
			}

			// Notifications WebSocket (legacy — kept for admin React dashboard)
			protected.GET("/admin/notifications/ws", wsHandler.HandleAdminOrders)

			// Orders WebSocket — real-time order events for admins & merchants
			protected.GET("/ws/orders", wsHandler.HandleAdminOrders)

			// Admin-only Endpoints (Full control panel API)
			adminOnly := protected.Group("/admin")
			adminOnly.Use(middleware.RequireRole(domain.RoleAdmin))
			{
				// Dashboard & Analytics
				adminOnly.GET("/stats", adminHandler.DashboardStats)
				adminOnly.GET("/stats/revenue", adminHandler.RevenueStats)
				adminOnly.GET("/stats/orders-by-status", adminHandler.OrdersByStatus)
				adminOnly.GET("/stats/top-products", adminHandler.TopProducts)

				// Users
				adminOnly.GET("/users", adminHandler.ListUsers)
				adminOnly.GET("/users/:id", adminHandler.GetUser)
				adminOnly.POST("/users", adminHandler.CreateUser)
				adminOnly.PUT("/users/:id", adminHandler.UpdateUser)
				adminOnly.PUT("/users/:id/status", adminHandler.ToggleUserActive)
				// Stores (Admin Full Control)
				adminOnly.GET("/stores", storeHandler.ListStores)
				adminOnly.POST("/stores", storeHandler.CreateStore)
				adminOnly.GET("/stores/:id", storeHandler.GetStore)
				adminOnly.PUT("/stores/:id", storeHandler.UpdateStore)
				adminOnly.DELETE("/stores/:id", storeHandler.DeleteStore)
				adminOnly.PUT("/stores/:id/verify", storeHandler.VerifyStore)
				
				// Branches
				adminOnly.POST("/stores/:id/branches", storeHandler.CreateBranch)
				adminOnly.PUT("/stores/:id/branches/:branch_id", storeHandler.UpdateBranch)
				adminOnly.DELETE("/stores/:id/branches/:branch_id", storeHandler.DeleteBranch)

				// Delivery Fees (existing logic updated)
				adminOnly.GET("/stores/:id/delivery-fees", adminHandler.GetStoreDeliveryFees)
				adminOnly.PUT("/stores/:id/delivery-fees", adminHandler.UpdateStoreDeliveryFees)

				// Orders — REST (paginated, filtered, with full relations)
				adminOnly.GET("/orders", orderHandler.AdminListOrders)
				adminOnly.GET("/orders/:id", orderHandler.AdminGetOrder)
				adminOnly.PUT("/orders/:id/status", orderHandler.AdminUpdateOrderStatus)

				// Categories
				adminOnly.POST("/categories", productHandler.CreateCategory)
				adminOnly.PUT("/categories/:id", productHandler.UpdateCategory)
				adminOnly.DELETE("/categories/:id", productHandler.DeleteCategory)

				// Brands
				adminOnly.GET("/brands", brandHandler.ListBrands)
				adminOnly.POST("/brands", brandHandler.CreateBrand)
				adminOnly.PUT("/brands/:id", brandHandler.UpdateBrand)
				adminOnly.DELETE("/brands/:id", brandHandler.DeleteBrand)
				
				// Products
				adminOnly.GET("/products", adminHandler.ListProducts)
				adminOnly.POST("/products", productHandler.CreateProduct)
				adminOnly.GET("/products/low-stock", adminHandler.LowStockProducts)
				adminOnly.PUT("/products/:id", adminHandler.UpdateProduct)
				adminOnly.DELETE("/products/:id", adminHandler.DeleteProduct)

				// Governorates
				adminOnly.GET("/governorates", adminHandler.ListGovernorates)
				adminOnly.POST("/governorates", adminHandler.CreateGovernorate)
				adminOnly.PUT("/governorates/:id", adminHandler.UpdateGovernorate)
				adminOnly.PUT("/governorates/:id/status", adminHandler.ToggleGovernorateActive)
				adminOnly.DELETE("/governorates/:id", adminHandler.DeleteGovernorate)

				// Banners
				adminOnly.GET("/banners", adminHandler.ListHomeBanners)
				adminOnly.POST("/banners", adminHandler.CreateHomeBanner)
				adminOnly.DELETE("/banners/:id", adminHandler.DeleteHomeBanner)

				// Audit Logs & Settings
				adminOnly.GET("/audit-logs", adminHandler.ListAuditLogs)
				adminOnly.GET("/settings", adminHandler.GetSettings)
				adminOnly.PUT("/settings", adminHandler.UpdateSetting)
			}
		}
	}

	// 7. HTTP Server Setup with Graceful Shutdown
	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("Server running on port %s...", cfg.Port)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal for Graceful Shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server gracefully...")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server stopped cleanly.")
}
