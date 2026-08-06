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

	"github.com/iraq-solar/api/internal/cache"
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

	// 2. Initialize Database Connection & Redis Cache
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Fatal: DB Connection failed: %v", err)
	}
	defer db.Close()
	_ = database.SeedDatabase(db)

	redisCache := cache.NewRedisCache(cfg.RedisURL)

	// 3. Initialize Repositories
	userRepo := repository.NewUserRepository(db)
	secRepo := repository.NewAuthSecurityRepository(db)
	storeRepo := repository.NewStoreRepository(db)
	productRepo := repository.NewProductRepository(db)
	categoryRepo := repository.NewCategoryRepository(db)
	brandRepo := repository.NewBrandRepository(db)
	calcRepo := repository.NewSolarCalculationRepository(db)
	calcMgmtRepo := repository.NewCalculatorManagementRepository(db)
	orderRepo := repository.NewOrderRepository(db)
	adminRepo := repository.NewAdminRepository(db)
	governorateRepo := repository.NewGovernorateRepository(db)
	bannerRepo := repository.NewBannerRepository(db)
	notificationRepo := repository.NewNotificationRepository(db)
	ticketRepo := repository.NewSupportTicketRepository(db)
	workforceRepo := repository.NewWorkforceRepository(db)

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
	adminService := service.NewAdminService(adminRepo, governorateRepo, notificationRepo)
	ticketService := service.NewSupportTicketService(ticketRepo)
	bannerService := service.NewBannerService(bannerRepo, redisCache, cfg.RedisBannerCacheTTL)
	workforceService := service.NewWorkforceService(workforceRepo, userRepo, realtimeHub)
	dispatchService := service.NewDispatchService(workforceRepo, workforceService, realtimeHub, notificationService)
	dispatchService.StartDispatchExpiryCron(context.Background(), time.Minute)

	minioService, minioErr := service.NewMinIOService(cfg.MinIOEndpoint, cfg.MinIOPublicEndpoint, cfg.MinIOAccessKey, cfg.MinIOSecretKey, cfg.MinIOBucket, cfg.MinIOUseSSL)
	if minioErr != nil {
		log.Printf("MinIO initialization notice: %v", minioErr)
	} else if minioService != nil {
		_ = minioService.InitBucket(context.Background())
	}

	// Initialize Real Data Repositories & Solar Engine
	solarRepo, presetRepo, indexRepo := repository.NewCalculatorRealDataRepository(db)
	catalogService := service.NewCatalogService(productRepo, storeRepo)
	recService := service.NewRecommendationService(catalogService)
	calcEngine := service.NewSolarCalculatorEngine(solarRepo, indexRepo, presetRepo, recService)

	// 5. Initialize Handlers
	storeHandler := handler.NewStoreHandler(storeService)
	authHandler := handler.NewAuthHandler(authService)
	calcHandler := handler.NewCalculatorHandler(calcService, calcMgmtRepo, calcEngine, solarRepo, presetRepo)
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
	bannerHandler := handler.NewBannerHandler(bannerService)
	workforceHandler := handler.NewWorkforceHandler(workforceRepo, workforceService, dispatchService)

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

	_ = os.MkdirAll("./uploads", 0755)
	router.Static("/uploads", "./uploads")

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
			authGroup.POST("/admin-login", authHandler.Login)
			authGroup.POST("/refresh", authHandler.Refresh)
			authGroup.POST("/logout", authHandler.Logout)
		}

		// Solar System Sizing & Specialized Calculators
		calcGroup := v1.Group("/calculator")
		{
			calcGroup.GET("/appliances", calcHandler.GetAppliancePresets)
			calcGroup.GET("/governorates-solar", calcHandler.GetGovernorateSolarData)
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
		v1.GET("/calculators", middleware.OptionalAuthMiddleware(authService), calcHandler.GetActiveCalculators)

		// Categories & Public Store Routes
		v1.GET("/categories", productHandler.ListCategories)
		v1.GET("/brands", brandHandler.ListBrands)
		v1.GET("/governorates", adminHandler.ListGovernorates)
		v1.GET("/governorates/:id/districts", adminHandler.ListDistricts)
		v1.GET("/banners", middleware.OptionalAuthMiddleware(authService), bannerHandler.GetActiveBanners)
		v1.POST("/banners/:id/track", bannerHandler.TrackBannerEvent)
		// Stores (Public)
		v1.GET("/stores", storeHandler.ListStores)
		v1.GET("/stores/:id", storeHandler.GetStore)
		v1.GET("/stores/:id/delivery-fees", adminHandler.GetStoreDeliveryFees)

		// Public Installers/Engineers Directory
		v1.GET("/installers", installerHandler.ListInstallers)
		v1.GET("/installers/:id", installerHandler.GetInstallerDetail)

		// Public Technicians Directory (trust gallery — no phone numbers exposed)
		v1.GET("/technicians", workforceHandler.ListPublicTechnicians)
		v1.GET("/technicians/:id", workforceHandler.GetPublicTechnician)
		v1.GET("/technicians/:id/portfolio", workforceHandler.GetTechnicianPortfolio)

		// Products Catalog Routes
		productGroup := v1.Group("/products")
		{
			productGroup.GET("", productHandler.ListProducts)
		}

		// --- WebSocket Routes (use WSAuthMiddleware — token via query param) ---
		// App users: real-time notifications
		v1.GET("/ws/notifications", middleware.WSAuthMiddleware(authService), wsHandler.HandleAppNotifications)
		// Orders WebSocket — real-time order events for admins & merchants
		v1.GET("/ws/orders", middleware.WSAuthMiddleware(authService), wsHandler.HandleAdminOrders)
		// Notifications WebSocket (legacy — kept for admin React dashboard)
		v1.GET("/admin/notifications/ws", middleware.WSAuthMiddleware(authService), wsHandler.HandleAdminOrders)

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

			// --- Workforce: Customer Service Orders ---
			serviceOrders := protected.Group("/service-orders")
			{
				serviceOrders.POST("", workforceHandler.CreateServiceOrder)
				serviceOrders.POST("/from-calculator", workforceHandler.CreateServiceOrderFromCalculator)
				serviceOrders.GET("", workforceHandler.ListMyServiceOrders)
				serviceOrders.GET("/:id", workforceHandler.GetMyServiceOrder)
				serviceOrders.POST("/:id/cancel", workforceHandler.CancelServiceOrder)
				serviceOrders.POST("/:id/review", workforceHandler.SubmitOrderReview)
			}

			// --- Workforce: Technician Workspace ---
			technicianGroup := protected.Group("/technician")
			technicianGroup.Use(middleware.RequireRole(domain.RoleInstaller, domain.RoleEngineer, domain.RoleAdmin))
			{
				technicianGroup.GET("/profile", workforceHandler.GetMyTechnicianProfile)
				technicianGroup.PUT("/availability", workforceHandler.UpdateMyAvailability)
				technicianGroup.PUT("/zones", workforceHandler.UpdateMyServiceZones)
				technicianGroup.POST("/documents", workforceHandler.AddMyDocument)
				technicianGroup.POST("/portfolio", workforceHandler.AddMyPortfolioItem)
				technicianGroup.GET("/wallet", workforceHandler.GetMyWallet)

				technicianGroup.GET("/dispatch-queue", workforceHandler.GetMyDispatchQueue)
				technicianGroup.POST("/dispatch/:id/accept", workforceHandler.AcceptDispatch)
				technicianGroup.POST("/dispatch/:id/reject", workforceHandler.RejectDispatch)

				technicianGroup.GET("/assignments", workforceHandler.ListMyAssignments)
				technicianGroup.GET("/orders/:id", workforceHandler.GetMyAssignmentDetail)
				technicianGroup.POST("/orders/:id/status", workforceHandler.UpdateJobStatus)
				technicianGroup.POST("/orders/:id/media", workforceHandler.AddJobMedia)
				technicianGroup.POST("/orders/:id/tasks/:task_id/toggle", workforceHandler.ToggleJobTask)
				technicianGroup.POST("/orders/:id/customer-unavailable", workforceHandler.MarkCustomerUnavailable)
				technicianGroup.POST("/orders/:id/tracking", workforceHandler.UpdateTracking)

				technicianGroup.POST("/leads", workforceHandler.CreateLead)
				technicianGroup.GET("/leads", workforceHandler.ListMyLeads)
			}

			// Merchant Product Management Routes
			merchantGroup := protected.Group("/merchant/products")
			merchantGroup.Use(middleware.RequirePermission(domain.PermProductsOwn))
			{
				merchantGroup.GET("", productHandler.ListMerchantProducts)
				merchantGroup.POST("", productHandler.CreateMerchantProduct)
				merchantGroup.PUT("/:id", productHandler.UpdateMerchantProduct)
				merchantGroup.DELETE("/:id", productHandler.DeleteMerchantProduct)
			}

			// Merchant Banner Management Routes
			merchantBanners := protected.Group("/merchant/banners")
			merchantBanners.Use(middleware.RequireRole(domain.RoleMerchant, domain.RoleAdmin))
			{
				merchantBanners.GET("", bannerHandler.ListAdminBanners)
				merchantBanners.POST("", bannerHandler.CreateBanner)
				merchantBanners.PUT("/:id", bannerHandler.UpdateBanner)
				merchantBanners.DELETE("/:id", bannerHandler.DeleteBanner)
			}

			// Admin Product Management Routes
			adminProducts := protected.Group("/products")
			adminProducts.Use(middleware.RequireRole(domain.RoleAdmin, domain.RoleMerchant))
			{
				adminProducts.POST("", productHandler.CreateProduct)
			}

			// Admin Calculator Management Routes
			adminCalcGroup := protected.Group("/admin/calculators")
			adminCalcGroup.Use(middleware.RequireRole(domain.RoleAdmin))
			{
				adminCalcGroup.GET("", calcHandler.ListAdminCalculators)
				adminCalcGroup.POST("", calcHandler.CreateAdminCalculator)
				adminCalcGroup.PUT("/:id", calcHandler.UpdateAdminCalculator)
				adminCalcGroup.PATCH("/:id/status", calcHandler.PatchAdminCalculatorStatus)
			}

			// Image Upload Routes
			protected.POST("/upload", uploadHandler.UploadImage)
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
				adminOnly.GET("/banners", bannerHandler.ListAdminBanners)
				adminOnly.POST("/banners", bannerHandler.CreateBanner)
				adminOnly.PUT("/banners/:id", bannerHandler.UpdateBanner)
				adminOnly.DELETE("/banners/:id", bannerHandler.DeleteBanner)
				adminOnly.PUT("/banners/reorder", bannerHandler.ReorderBanners)
				adminOnly.GET("/banners/:id/analytics", bannerHandler.GetBannerAnalytics)

				// --- Workforce: Technicians Management ---
				adminOnly.GET("/technicians", workforceHandler.AdminListTechnicians)
				adminOnly.POST("/technicians", workforceHandler.AdminCreateTechnician)
				adminOnly.GET("/technicians/:id", workforceHandler.AdminGetTechnician)
				adminOnly.PUT("/technicians/:id", workforceHandler.AdminUpdateTechnician)
				adminOnly.PUT("/technicians/:id/verify", workforceHandler.AdminVerifyTechnician)
				adminOnly.PUT("/technicians/:id/ranking", workforceHandler.AdminUpdateRanking)
				adminOnly.PUT("/technicians/:id/zones", workforceHandler.AdminUpdateServiceZones)
				adminOnly.PUT("/technicians/:id/documents/:doc_id", workforceHandler.AdminReviewDocument)
				adminOnly.GET("/technicians/:id/wallet", workforceHandler.AdminGetTechnicianWallet)
				adminOnly.POST("/technicians/:id/wallet/settle", workforceHandler.AdminSettleWallet)

				// --- Workforce: Technician Levels ---
				adminOnly.GET("/technician-levels", workforceHandler.ListTechnicianLevels)
				adminOnly.POST("/technician-levels", workforceHandler.CreateTechnicianLevel)
				adminOnly.PUT("/technician-levels/:id", workforceHandler.UpdateTechnicianLevel)

				// --- Workforce: Service Orders & Dispatch ---
				adminOnly.GET("/service-orders", workforceHandler.AdminListServiceOrders)
				adminOnly.GET("/service-orders/:id", workforceHandler.AdminGetServiceOrder)
				adminOnly.GET("/service-orders/:id/dispatch-queue", workforceHandler.AdminGetDispatchQueue)
				adminOnly.PUT("/service-orders/:id/assign", workforceHandler.AdminAssignTechnician)
				adminOnly.POST("/service-orders/:id/redispatch", workforceHandler.AdminRedispatchOrder)
				adminOnly.PUT("/service-orders/:id/status", workforceHandler.AdminUpdateServiceOrderStatus)
				adminOnly.PUT("/service-orders/:id/pricing", workforceHandler.AdminSetPricing)
				adminOnly.PUT("/service-orders/:id/payment-status", workforceHandler.AdminUpdatePaymentStatus)

				// --- Workforce: Dispatch Settings & Analytics ---
				adminOnly.GET("/dispatch-settings", workforceHandler.ListDispatchSettings)
				adminOnly.PUT("/dispatch-settings", workforceHandler.UpsertDispatchSettings)
				adminOnly.GET("/dispatch-stats", workforceHandler.AdminDispatchStats)

				// --- Workforce: Pricing ---
				adminOnly.GET("/service-pricing", workforceHandler.AdminListPricing)
				adminOnly.GET("/service-price-tiers", workforceHandler.AdminListPriceTiers)

				// --- Workforce: Technician Leads ---
				adminOnly.GET("/leads", workforceHandler.AdminListLeads)
				adminOnly.PUT("/leads/:id/approve", workforceHandler.AdminApproveLead)
				adminOnly.PUT("/leads/:id/reject", workforceHandler.AdminRejectLead)

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
