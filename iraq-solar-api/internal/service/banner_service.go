package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/cache"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type BannerService struct {
	bannerRepo *repository.BannerRepository
	redisCache *cache.RedisCache
	cacheTTL   time.Duration
}

func NewBannerService(bannerRepo *repository.BannerRepository, redisCache *cache.RedisCache, cacheTTLSeconds int) *BannerService {
	ttl := time.Duration(cacheTTLSeconds) * time.Second
	if ttl <= 0 {
		ttl = 5 * time.Minute
	}
	return &BannerService{
		bannerRepo: bannerRepo,
		redisCache: redisCache,
		cacheTTL:   ttl,
	}
}

// ─── Public / Client Banner Retrieval ───

func (s *BannerService) GetActiveBanners(ctx context.Context, params domain.BannerFilterParams) ([]domain.Banner, error) {
	if params.Placement == "" {
		params.Placement = "home"
	}

	// 1. Fetch raw banners from Redis Cache (Option A) or DB Fallback
	cacheKey := fmt.Sprintf("banners:%s:raw", params.Placement)
	if params.StoreID != nil && *params.StoreID != uuid.Nil {
		cacheKey = fmt.Sprintf("banners:%s:%s:raw", params.Placement, params.StoreID.String())
	}

	var rawBanners []domain.Banner
	if s.redisCache != nil && s.redisCache.IsAvailable() {
		cachedStr, err := s.redisCache.Get(ctx, cacheKey)
		if err == nil && cachedStr != "" {
			if err := json.Unmarshal([]byte(cachedStr), &rawBanners); err == nil {
				// Cache hit!
				return s.filterBanners(rawBanners, params), nil
			}
		}
	}

	// Cache Miss or Redis unavailable -> DB Fallback
	var err error
	rawBanners, err = s.bannerRepo.ListRawActiveBannersByPlacement(ctx, params.Placement, params.StoreID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch raw banners: %w", err)
	}

	// Store raw banners in Redis
	if s.redisCache != nil && s.redisCache.IsAvailable() && len(rawBanners) > 0 {
		if bytes, err := json.Marshal(rawBanners); err == nil {
			_ = s.redisCache.Set(ctx, cacheKey, string(bytes), s.cacheTTL)
		}
	}

	// 2. Evaluate schedule & versioned targeting rules in Service layer
	return s.filterBanners(rawBanners, params), nil
}

func (s *BannerService) filterBanners(banners []domain.Banner, params domain.BannerFilterParams) []domain.Banner {
	activeBanners := make([]domain.Banner, 0)
	now := time.Now()

	for _, b := range banners {
		if !b.IsActive {
			continue
		}

		if !s.IsBannerActiveNow(&b, now) {
			continue
		}

		if !s.MatchesTargeting(&b, params.Role, params.GovernorateID) {
			continue
		}

		activeBanners = append(activeBanners, b)
	}
	return activeBanners
}

// ─── Schedule & Recurrence Evaluation ───

func (s *BannerService) IsBannerActiveNow(b *domain.Banner, now time.Time) bool {
	tzName := b.Timezone
	if tzName == "" {
		tzName = "Asia/Baghdad"
	}

	loc, err := time.LoadLocation(tzName)
	if err != nil {
		loc = time.UTC
	}
	localNow := now.In(loc)

	// Check date boundaries
	if b.StartsAt != nil && localNow.Before(*b.StartsAt) {
		return false
	}
	if b.EndsAt != nil && localNow.After(*b.EndsAt) {
		return false
	}

	// Check simple recurrence
	if b.RecurrenceType != "" && b.RecurrenceType != domain.RecurrenceNone {
		if b.RecurrenceEnd != nil && localNow.After(*b.RecurrenceEnd) {
			return false
		}

		if b.RecurrenceTime != nil && *b.RecurrenceTime != "" {
			recHour, recMin, err := parseTimeOfDay(*b.RecurrenceTime)
			if err == nil {
				bannerRecurrenceTime := time.Date(localNow.Year(), localNow.Month(), localNow.Day(), recHour, recMin, 0, 0, loc)
				// Requires current time to be at or after recurrence start time for the recurring day
				if localNow.Before(bannerRecurrenceTime) {
					return false
				}
			}
		}
	}

	return true
}

func parseTimeOfDay(tStr string) (int, int, error) {
	var h, m int
	_, err := fmt.Sscanf(tStr, "%d:%d", &h, &m)
	if err != nil {
		return 0, 0, err
	}
	return h, m, nil
}

// ─── Versioned JSONB Targeting Evaluation ───

func (s *BannerService) MatchesTargeting(b *domain.Banner, userRole string, governorateID int) bool {
	if b.TargetingRules == nil || len(b.TargetingRules) == 0 {
		return true
	}

	rules := b.TargetingRules

	// Role targeting check
	if rolesRaw, exists := rules["roles"]; exists {
		if rolesList, ok := rolesRaw.([]interface{}); ok && len(rolesList) > 0 {
			if userRole == "" {
				userRole = "customer" // Default public role
			}
			matched := false
			for _, r := range rolesList {
				if fmt.Sprintf("%v", r) == userRole {
					matched = true
					break
				}
			}
			if !matched {
				return false
			}
		}
	}

	// Governorate targeting check
	if govRaw, exists := rules["governorate_ids"]; exists {
		if govList, ok := govRaw.([]interface{}); ok && len(govList) > 0 {
			if governorateID > 0 {
				matched := false
				for _, g := range govList {
					var gID int
					switch v := g.(type) {
					case float64:
						gID = int(v)
					case int:
						gID = v
					}
					if gID == governorateID {
						matched = true
						break
					}
				}
				if !matched {
					return false
				}
			}
		}
	}

	return true
}

// ─── Admin / Merchant Banner CRUD ───

func (s *BannerService) CreateBanner(ctx context.Context, creatorID uuid.UUID, creatorRole string, req domain.CreateBannerRequest) (*domain.Banner, error) {
	if err := s.validateCreateRequest(&req); err != nil {
		return nil, err
	}

	var merchantID *uuid.UUID
	if domain.Role(creatorRole) == domain.RoleMerchant {
		merchantID = &creatorID
	} else if req.MerchantID != nil && *req.MerchantID != uuid.Nil {
		merchantID = req.MerchantID
	}

	isActive := true
	if req.IsActive != nil {
		isActive = *req.IsActive
	}

	tz := req.Timezone
	if tz == "" {
		tz = "Asia/Baghdad"
	}

	// Ensure targeting rules includes version: 1
	if req.TargetingRules == nil {
		req.TargetingRules = make(map[string]interface{})
	}
	req.TargetingRules["version"] = 1

	banner := &domain.Banner{
		ID:             uuid.New(),
		ImageURL:       req.ImageURL,
		MobileImageURL: req.MobileImageURL,
		Priority:       req.Priority,
		DisplayOrder:   req.DisplayOrder,
		IsActive:       isActive,
		StartsAt:       req.StartsAt,
		EndsAt:         req.EndsAt,
		ActionType:     domain.ActionType(req.ActionType),
		ActionPayload:  domain.JSONBMap(req.ActionPayload),
		TargetingRules: domain.JSONBMap(req.TargetingRules),
		RecurrenceType: domain.RecurrenceType(req.RecurrenceType),
		RecurrenceTime: req.RecurrenceTime,
		RecurrenceEnd:  req.RecurrenceEnd,
		Timezone:       tz,
		CreatedBy:      &creatorID,
		MerchantID:     merchantID,
	}

	err := s.bannerRepo.CreateBanner(ctx, banner, req.Placements, req.StoreIDs, req.StoreTargets)
	if err != nil {
		return nil, err
	}

	s.invalidateCache(ctx)
	return banner, nil
}

func (s *BannerService) UpdateBanner(ctx context.Context, bannerID, userMerchantID uuid.UUID, userRole string, req domain.UpdateBannerRequest) (*domain.Banner, error) {
	existing, err := s.bannerRepo.GetBannerByID(ctx, bannerID)
	if err != nil || existing == nil {
		return nil, errors.New("banner not found")
	}

	// Service-level merchant ownership verification
	if domain.Role(userRole) == domain.RoleMerchant {
		if existing.MerchantID == nil || *existing.MerchantID != userMerchantID {
			return nil, errors.New("forbidden: merchants can only manage their own banners")
		}
	}

	if req.ImageURL != nil {
		existing.ImageURL = *req.ImageURL
	}
	if req.MobileImageURL != nil {
		existing.MobileImageURL = req.MobileImageURL
	}
	if req.Priority != nil {
		if *req.Priority < 0 || *req.Priority > 100 {
			return nil, errors.New("priority must be between 0 and 100")
		}
		existing.Priority = *req.Priority
	}
	if req.DisplayOrder != nil {
		existing.DisplayOrder = *req.DisplayOrder
	}
	if req.IsActive != nil {
		existing.IsActive = *req.IsActive
	}
	if req.StartsAt != nil {
		existing.StartsAt = req.StartsAt
	}
	if req.EndsAt != nil {
		existing.EndsAt = req.EndsAt
	}
	if req.ActionType != nil {
		existing.ActionType = domain.ActionType(*req.ActionType)
	}
	if req.ActionPayload != nil {
		existing.ActionPayload = domain.JSONBMap(req.ActionPayload)
	}
	if req.TargetingRules != nil {
		req.TargetingRules["version"] = 1
		existing.TargetingRules = domain.JSONBMap(req.TargetingRules)
	}
	if req.RecurrenceType != nil {
		existing.RecurrenceType = domain.RecurrenceType(*req.RecurrenceType)
	}
	if req.RecurrenceTime != nil {
		existing.RecurrenceTime = req.RecurrenceTime
	}
	if req.RecurrenceEnd != nil {
		existing.RecurrenceEnd = req.RecurrenceEnd
	}
	if req.Timezone != nil {
		existing.Timezone = *req.Timezone
	}

	err = s.bannerRepo.UpdateBanner(ctx, existing, req.Placements, req.StoreIDs, req.StoreTargets)
	if err != nil {
		return nil, err
	}

	s.invalidateCache(ctx)
	return existing, nil
}

func (s *BannerService) DeleteBanner(ctx context.Context, bannerID, userMerchantID uuid.UUID, userRole string) error {
	existing, err := s.bannerRepo.GetBannerByID(ctx, bannerID)
	if err != nil || existing == nil {
		return errors.New("banner not found")
	}

	if domain.Role(userRole) == domain.RoleMerchant {
		if existing.MerchantID == nil || *existing.MerchantID != userMerchantID {
			return errors.New("forbidden: merchants can only manage their own banners")
		}
	}

	err = s.bannerRepo.DeleteBanner(ctx, bannerID)
	if err == nil {
		s.invalidateCache(ctx)
	}
	return err
}

func (s *BannerService) ListAdminBanners(ctx context.Context, merchantID *uuid.UUID, placement string, page, perPage int) ([]domain.Banner, int, error) {
	if page <= 0 {
		page = 1
	}
	if perPage <= 0 {
		perPage = 20
	}
	return s.bannerRepo.ListAdminBanners(ctx, merchantID, placement, page, perPage)
}

func (s *BannerService) ReorderBanners(ctx context.Context, bannerIDs []uuid.UUID) error {
	if len(bannerIDs) == 0 {
		return errors.New("banner_ids list cannot be empty")
	}
	err := s.bannerRepo.ReorderBanners(ctx, bannerIDs)
	if err == nil {
		s.invalidateCache(ctx)
	}
	return err
}

// ─── Tracking & Anti-Spam Event Deduplication ───

func (s *BannerService) TrackBannerEvent(ctx context.Context, bannerID uuid.UUID, eventType string, userID *uuid.UUID, deviceID string, metadata map[string]interface{}) error {
	if eventType != string(domain.EventImpression) && eventType != string(domain.EventClick) {
		return errors.New("invalid event_type. Must be 'impression' or 'click'")
	}

	today := time.Now().Format("2006-01-02")
	userKey := "anonymous"
	if userID != nil {
		userKey = userID.String()
	} else if deviceID != "" {
		userKey = deviceID
	}

	// Anti-Spam Deduplication via Redis SetNX (24h TTL)
	dedupKey := fmt.Sprintf("banner:event:%s:%s:%s:%s", bannerID.String(), userKey, eventType, today)
	if s.redisCache != nil && s.redisCache.IsAvailable() {
		isNew, _ := s.redisCache.SetNX(ctx, dedupKey, "1", 24*time.Hour)
		if !isNew && eventType == string(domain.EventImpression) {
			// Skip duplicate impressions within same 24 hours
			return nil
		}
	}

	event := &domain.BannerEvent{
		ID:        uuid.New(),
		BannerID:  bannerID,
		EventType: domain.EventType(eventType),
		UserID:    userID,
		DeviceID:  &deviceID,
		Metadata:  domain.JSONBMap(metadata),
	}

	return s.bannerRepo.RecordEvent(ctx, event)
}

func (s *BannerService) GetBannerAnalytics(ctx context.Context, bannerID uuid.UUID, days int) ([]domain.BannerAnalyticsSummary, error) {
	return s.bannerRepo.GetBannerAnalytics(ctx, bannerID, days)
}

// ─── Cache Invalidation & Internal Helpers ───

func (s *BannerService) invalidateCache(ctx context.Context) {
	if s.redisCache != nil && s.redisCache.IsAvailable() {
		err := s.redisCache.DeletePattern(ctx, "banners:*")
		if err != nil {
			log.Printf("Notice: Redis cache invalidation error: %v", err)
		}
	}
}

func (s *BannerService) validateCreateRequest(req *domain.CreateBannerRequest) error {
	if req.ImageURL == "" {
		return errors.New("image_url is required")
	}
	if len(req.Placements) == 0 {
		return errors.New("at least one placement is required")
	}
	if req.Priority < 0 || req.Priority > 100 {
		return errors.New("priority must be between 0 and 100")
	}
	if req.StartsAt != nil && req.EndsAt != nil && req.StartsAt.After(*req.EndsAt) {
		return errors.New("starts_at must be before ends_at")
	}
	if req.RecurrenceType != "" && req.RecurrenceType != string(domain.RecurrenceNone) {
		if req.RecurrenceTime == nil || *req.RecurrenceTime == "" {
			return errors.New("recurrence_time is required when recurrence_type is set")
		}
	}
	return nil
}
