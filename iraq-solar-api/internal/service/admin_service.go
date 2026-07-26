package service

import (
	"context"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type AdminService struct {
	adminRepo       *repository.AdminRepository
	governorateRepo *repository.GovernorateRepository
	bannerRepo      *repository.BannerRepository
	notificationRepo *repository.NotificationRepository
}

func NewAdminService(
	adminRepo *repository.AdminRepository,
	governorateRepo *repository.GovernorateRepository,
	bannerRepo *repository.BannerRepository,
	notificationRepo *repository.NotificationRepository,
) *AdminService {
	return &AdminService{
		adminRepo:       adminRepo,
		governorateRepo: governorateRepo,
		bannerRepo:      bannerRepo,
		notificationRepo: notificationRepo,
	}
}

// ─── Dashboard & Analytics ───

func (s *AdminService) DashboardStats(ctx context.Context) (*repository.DashboardStatsResult, error) {
	return s.adminRepo.DashboardStats(ctx)
}

func (s *AdminService) RevenueStats(ctx context.Context, days int) ([]repository.RevenueDataPoint, error) {
	if days <= 0 {
		days = 7
	}
	return s.adminRepo.RevenueByPeriod(ctx, days)
}

func (s *AdminService) OrdersByStatus(ctx context.Context) ([]repository.StatusCount, error) {
	return s.adminRepo.OrdersByStatus(ctx)
}

func (s *AdminService) TopProducts(ctx context.Context, limit int) ([]repository.TopProduct, error) {
	if limit <= 0 {
		limit = 5
	}
	return s.adminRepo.TopProducts(ctx, limit)
}

// ─── Users Management ───

func (s *AdminService) ListUsers(ctx context.Context, role, status, governorate, search string, page, perPage int) ([]domain.User, int, error) {
	return s.adminRepo.ListUsers(ctx, role, status, governorate, search, page, perPage)
}

func (s *AdminService) GetUser(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	return s.adminRepo.GetUserByID(ctx, id)
}

func (s *AdminService) CreateUserByAdmin(ctx context.Context, adminID uuid.UUID, fullName, email, phone, password string, role domain.Role, governorate, city string) (*domain.User, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	userID := uuid.New()

	user := &domain.User{
		ID:           userID,
		FullName:     fullName,
		Email:        email,
		Phone:        phone,
		PasswordHash: string(hashedPassword),
		Role:         role,
		Governorate:  governorate,
		City:         city,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.adminRepo.CreateUserByAdmin(ctx, user); err != nil {
		return nil, err
	}

	_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "CREATE_USER", "user", user.ID.String(), map[string]interface{}{
		"role": user.Role,
		"name": user.FullName,
	})

	return user, nil
}

func (s *AdminService) UpdateUser(ctx context.Context, adminID uuid.UUID, id uuid.UUID, fullName, phone, governorate, city string, role domain.Role) error {
	err := s.adminRepo.UpdateUser(ctx, id, fullName, phone, governorate, city, role)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "UPDATE_USER", "user", id.String(), map[string]interface{}{
			"role": role,
			"name": fullName,
		})
	}
	return err
}

func (s *AdminService) ToggleUserActive(ctx context.Context, adminID uuid.UUID, id uuid.UUID, isActive bool) error {
	err := s.adminRepo.ToggleUserActive(ctx, id, isActive)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "TOGGLE_USER_ACTIVE", "user", id.String(), map[string]interface{}{
			"is_active": isActive,
		})
	}
	return err
}

func (s *AdminService) DeleteUser(ctx context.Context, adminID uuid.UUID, id uuid.UUID) error {
	err := s.adminRepo.SoftDeleteUser(ctx, id)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "DELETE_USER", "user", id.String(), nil)
	}
	return err
}

// ─── Orders Management ───

func (s *AdminService) ListOrders(ctx context.Context, status, search string, page, perPage int) ([]repository.OrderWithUser, int, error) {
	return s.adminRepo.ListAllOrders(ctx, status, search, page, perPage)
}

func (s *AdminService) GetOrderDetail(ctx context.Context, id uuid.UUID) (*repository.OrderWithUser, []domain.OrderItem, error) {
	return s.adminRepo.GetOrderDetail(ctx, id)
}

func (s *AdminService) UpdateOrderStatus(ctx context.Context, adminID uuid.UUID, id uuid.UUID, status string) error {
	err := s.adminRepo.UpdateOrderStatus(ctx, id, status)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "UPDATE_ORDER_STATUS", "order", id.String(), map[string]interface{}{
			"new_status": status,
		})
	}
	return err
}

// ─── Products Management ───

func (s *AdminService) ListProducts(ctx context.Context, pType, search string, page, perPage int) ([]domain.Product, int, error) {
	return s.adminRepo.ListAllProducts(ctx, pType, search, page, perPage)
}

func (s *AdminService) UpdateProduct(ctx context.Context, adminID uuid.UUID, id uuid.UUID, name, brand, model string, priceUSD float64, stockQty int, isAvailable bool) error {
	err := s.adminRepo.UpdateProduct(ctx, id, name, brand, model, priceUSD, stockQty, isAvailable)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "UPDATE_PRODUCT", "product", id.String(), map[string]interface{}{
			"name":  name,
			"price": priceUSD,
			"stock": stockQty,
		})
	}
	return err
}

func (s *AdminService) DeleteProduct(ctx context.Context, adminID uuid.UUID, id uuid.UUID) error {
	err := s.adminRepo.DeleteProduct(ctx, id)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "DELETE_PRODUCT", "product", id.String(), nil)
	}
	return err
}

// ─── Governorates Management ───

func (s *AdminService) ListGovernorates(ctx context.Context) ([]domain.Governorate, error) {
	return s.governorateRepo.List(ctx)
}

func (s *AdminService) CreateGovernorate(ctx context.Context, adminID uuid.UUID, nameAr, nameEn string) (*domain.Governorate, error) {
	g := &domain.Governorate{
		NameAr:   nameAr,
		NameEn:   nameEn,
		IsActive: true,
	}
	err := s.governorateRepo.Create(ctx, g)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "CREATE_GOVERNORATE", "governorate", string(rune(g.ID)), map[string]interface{}{
			"name_ar": nameAr,
		})
	}
	return g, err
}

func (s *AdminService) UpdateGovernorate(ctx context.Context, adminID uuid.UUID, id int, nameAr, nameEn string) error {
	return s.governorateRepo.Update(ctx, id, nameAr, nameEn)
}

func (s *AdminService) ToggleGovernorateActive(ctx context.Context, adminID uuid.UUID, id int, isActive bool) error {
	return s.governorateRepo.ToggleActive(ctx, id, isActive)
}

func (s *AdminService) DeleteGovernorate(ctx context.Context, adminID uuid.UUID, id int) error {
	return s.governorateRepo.Delete(ctx, id)
}

// ─── Banners Management ───

func (s *AdminService) ListHomeBanners(ctx context.Context) ([]domain.HomeBanner, error) {
	return s.bannerRepo.ListHomeBanners(ctx)
}

func (s *AdminService) CreateHomeBanner(ctx context.Context, adminID uuid.UUID, b *domain.HomeBanner) error {
	b.ID = uuid.New()
	err := s.bannerRepo.CreateHomeBanner(ctx, b)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "CREATE_HOME_BANNER", "banner", b.ID.String(), map[string]interface{}{
			"title": b.Title,
		})
	}
	return err
}

func (s *AdminService) UpdateHomeBanner(ctx context.Context, adminID uuid.UUID, id uuid.UUID, title, subtitle, imageURL, linkURL string, displayOrder int, isActive bool) error {
	return s.bannerRepo.UpdateHomeBanner(ctx, id, title, subtitle, imageURL, linkURL, displayOrder, isActive)
}

func (s *AdminService) DeleteHomeBanner(ctx context.Context, adminID uuid.UUID, id uuid.UUID) error {
	return s.bannerRepo.DeleteHomeBanner(ctx, id)
}

func (s *AdminService) ListStoreBanners(ctx context.Context, merchantID uuid.UUID) ([]domain.StoreBanner, error) {
	return s.bannerRepo.ListStoreBanners(ctx, merchantID)
}

func (s *AdminService) CreateStoreBanner(ctx context.Context, b *domain.StoreBanner) error {
	b.ID = uuid.New()
	return s.bannerRepo.CreateStoreBanner(ctx, b)
}

func (s *AdminService) DeleteStoreBanner(ctx context.Context, id uuid.UUID) error {
	return s.bannerRepo.DeleteStoreBanner(ctx, id)
}

// ─── Audit Logs & Settings ───

func (s *AdminService) ListAuditLogs(ctx context.Context, action, search string, page, perPage int) ([]repository.AuditLog, int, error) {
	return s.adminRepo.GetAuditLogs(ctx, action, search, page, perPage)
}

func (s *AdminService) GetSettings(ctx context.Context) ([]domain.SystemSetting, error) {
	return s.adminRepo.GetSettings(ctx)
}

func (s *AdminService) UpdateSetting(ctx context.Context, adminID uuid.UUID, key, value string) error {
	err := s.adminRepo.UpsertSetting(ctx, key, value)
	if err == nil {
		_ = s.adminRepo.CreateAuditLog(ctx, &adminID, "UPDATE_SETTING", "setting", key, map[string]interface{}{
			"value": value,
		})
	}
	return err
}
