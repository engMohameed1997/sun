package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/hub"
	"github.com/iraq-solar/api/internal/repository"
)

var (
	// ErrTechnicianNotFound is returned when no technician profile matches the lookup.
	ErrTechnicianNotFound = errors.New("technician not found")
	// ErrServiceOrderNotFound is returned when no service order matches the lookup.
	ErrServiceOrderNotFound = errors.New("service order not found")
	// ErrForbiddenAction is returned when the actor is not allowed to touch the resource.
	ErrForbiddenAction = errors.New("forbidden action")
)

// WorkforceService holds the technician-side business logic: profiles, verification,
// availability, ranking scores, wallets and order completion/pricing.
type WorkforceService struct {
	repo     repository.WorkforceRepository
	userRepo repository.UserRepository
	hub      *hub.RealtimeHub
}

// NewWorkforceService builds a WorkforceService.
func NewWorkforceService(repo repository.WorkforceRepository, userRepo repository.UserRepository, realtimeHub *hub.RealtimeHub) *WorkforceService {
	return &WorkforceService{repo: repo, userRepo: userRepo, hub: realtimeHub}
}

// Repo exposes the underlying repository for handlers that only need reads.
func (s *WorkforceService) Repo() repository.WorkforceRepository { return s.repo }

// --- Technician lifecycle ---

// RegisterTechnician creates a technician profile, optionally creating the backing user account,
// and initializes wallet / ranking / availability / dispatch stats rows.
func (s *WorkforceService) RegisterTechnician(ctx context.Context, req domain.CreateTechnicianRequest) (*domain.Technician, error) {
	userID := uuid.Nil

	if req.UserID != nil {
		userID = *req.UserID
		existing, err := s.userRepo.FindByID(ctx, userID)
		if err != nil || existing == nil {
			return nil, errors.New("المستخدم غير موجود")
		}
		if req.FullName == "" { req.FullName = existing.FullName }
		if req.Phone == "" { req.Phone = existing.Phone }
		if req.GovernorateID == nil { req.GovernorateID = existing.GovernorateID }
		if req.DistrictID == nil { req.DistrictID = existing.DistrictID }
	} else {
		if strings.TrimSpace(req.Phone) == "" || strings.TrimSpace(req.Password) == "" {
			return nil, errors.New("phone and password are required when no user_id is provided")
		}
		existing, err := s.userRepo.FindByPhone(ctx, req.Phone)
		if err != nil {
			return nil, err
		}
		if existing != nil {
			userID = existing.ID
			if req.FullName == "" { req.FullName = existing.FullName }
			if req.GovernorateID == nil { req.GovernorateID = existing.GovernorateID }
			if req.DistrictID == nil { req.DistrictID = existing.DistrictID }
		} else {
			hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
			if err != nil {
				return nil, fmt.Errorf("hash password: %w", err)
			}
			role := domain.RoleInstaller
			if req.Role == domain.TechRoleEngineer {
				role = domain.RoleEngineer
			}
			now := time.Now()
			user := &domain.User{
				ID:            uuid.New(),
				FullName:      req.FullName,
				Phone:         req.Phone,
				PasswordHash:  string(hash),
				Role:          role,
				GovernorateID: req.GovernorateID,
				DistrictID:    req.DistrictID,
				IsActive:      true,
				CreatedAt:     now,
				UpdatedAt:     now,
			}
			if err := s.userRepo.Create(ctx, user); err != nil {
				return nil, err
			}
			userID = user.ID
		}
	}

	specs := req.Specializations
	if specs == nil {
		specs = []string{}
	}
	rawSpecs, err := json.Marshal(specs)
	if err != nil {
		return nil, fmt.Errorf("marshal specializations: %w", err)
	}

	tech := &domain.Technician{
		ID:                 uuid.New(),
		UserID:             userID,
		FullName:           req.FullName,
		ProfileImageURL:    req.ProfileImageURL,
		PhonePublic:        req.PhonePublic,
		Role:               req.Role,
		Specializations:    rawSpecs,
		GovernorateID:      req.GovernorateID,
		DistrictID:         req.DistrictID,
		ExperienceYears:    req.ExperienceYears,
		Bio:                req.Bio,
		AvailabilityStatus: domain.AvailabilityOffline,
	}
	if req.Phone != "" {
		phone := req.Phone
		tech.PhonePrivate = &phone
	}

	zones := req.ServiceZones
	if len(zones) == 0 && req.GovernorateID != nil {
		zones = []int{*req.GovernorateID}
	}

	if err := s.repo.CreateTechnician(ctx, tech, zones); err != nil {
		return nil, err
	}

	if _, err := s.RecalculateRanking(ctx, tech.ID); err != nil {
		return nil, err
	}

	return s.repo.GetTechnicianByID(ctx, tech.ID)
}

// VerifyTechnician toggles verification state and level (admin action).
func (s *WorkforceService) VerifyTechnician(ctx context.Context, id uuid.UUID, req domain.VerifyTechnicianRequest) error {
	if req.VerificationLevel < 0 || req.VerificationLevel > 3 {
		return errors.New("verification_level must be between 0 and 3")
	}
	if err := s.repo.SetTechnicianVerification(ctx, id, req.IsVerified, req.VerificationLevel); err != nil {
		return err
	}
	_, err := s.RecalculateRanking(ctx, id)
	return err
}

// UpdateAvailability lets a technician set live status and working hours.
func (s *WorkforceService) UpdateAvailability(ctx context.Context, technicianID uuid.UUID, req domain.UpdateAvailabilityRequest) error {
	switch req.Status {
	case "available", "busy", "offline", "vacation":
	default:
		return errors.New("invalid availability status")
	}
	if err := s.repo.UpsertAvailability(ctx, technicianID, req); err != nil {
		return err
	}
	tech, _ := s.repo.GetTechnicianByID(ctx, technicianID)
	fullName := ""
	if tech != nil {
		fullName = tech.FullName
	}
	if s.hub != nil {
		go s.hub.BroadcastToAdmins(hub.MsgWorkforce, hub.EventTechnicianAvailabilityChanged, map[string]any{
			"technician_id":       technicianID,
			"full_name":           fullName,
			"availability_status": req.Status,
			"updated_at":          time.Now(),
		})
	}
	return nil
}

// GetTechnicianForUser resolves the technician profile bound to an authenticated user.
func (s *WorkforceService) GetTechnicianForUser(ctx context.Context, userID uuid.UUID) (*domain.Technician, error) {
	tech, err := s.repo.GetTechnicianByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if tech == nil {
		return nil, ErrTechnicianNotFound
	}
	return tech, nil
}

// --- Scoring ---

// CalculateQualityScore implements the weighted quality ranking algorithm (0-100).
//
//	35% rating ⋅ 20% proximity ⋅ 15% completed jobs ⋅ 10% response speed
//	 5% acceptance rate ⋅ 10% verification level ⋅ 5% clean record
func CalculateQualityScore(c domain.TechnicianCandidate) float64 {
	ratingScore := (c.Rating / 5.0) * 100
	if c.Rating == 0 {
		// New technicians are not punished to zero — verification carries them.
		ratingScore = 60
	}

	proximityScore := 60.0
	if c.IsPrimaryZone {
		proximityScore = 100.0
	}

	jobsScore := math.Min(float64(c.CompletedJobsCount)/50.0, 1.0) * 100

	responseScore := 100.0
	switch {
	case c.AvgResponseMinutes <= 0:
		responseScore = 70
	case c.AvgResponseMinutes <= 2:
		responseScore = 100
	case c.AvgResponseMinutes <= 5:
		responseScore = 85
	case c.AvgResponseMinutes <= 10:
		responseScore = 65
	default:
		responseScore = 40
	}

	acceptanceScore := math.Max(0, math.Min(c.AcceptanceRate, 100))
	verificationScore := (float64(c.VerificationLevel) / 3.0) * 100
	recordScore := math.Max(0, 100-float64(c.ComplaintCount)*20)

	total := ratingScore*0.35 +
		proximityScore*0.20 +
		jobsScore*0.15 +
		responseScore*0.10 +
		acceptanceScore*0.05 +
		verificationScore*0.10 +
		recordScore*0.05

	return round2(math.Max(0, math.Min(total, 100)))
}

// CalculateFairnessScore rewards technicians who have been idle or are still proving
// themselves, and dampens technicians already saturated with work this month.
func CalculateFairnessScore(c domain.TechnicianCandidate, avgOrdersInZone, avgEarningsInZone float64) float64 {
	score := 50.0

	switch {
	case c.DaysSinceLastOrder >= 14:
		score += 25
	case c.DaysSinceLastOrder >= 7:
		score += 15
	case c.DaysSinceLastOrder >= 3:
		score += 5
	}

	if c.IsNewTechnician && c.NewTechOrdersCount < 10 {
		score += 20
	}

	if avgOrdersInZone > 0 {
		ratio := float64(c.OrdersThisMonth) / avgOrdersInZone
		switch {
		case ratio > 1.5:
			score -= 20
		case ratio > 1.2:
			score -= 10
		case ratio < 0.5:
			score += 10
		}
	}

	if avgEarningsInZone > 0 && c.EarningsThisMonth < avgEarningsInZone*0.5 {
		score += 10
	}

	return round2(math.Max(0, math.Min(score, 100)))
}

// CalculateFairnessBoost is the additive nudge persisted on technician_dispatch_stats.
func CalculateFairnessBoost(c domain.TechnicianCandidate, avgOrdersInZone float64) float64 {
	boost := 0.0

	switch {
	case c.DaysSinceLastOrder >= 14:
		boost += 15
	case c.DaysSinceLastOrder >= 7:
		boost += 8
	}

	if c.IsNewTechnician && c.NewTechOrdersCount < 10 {
		boost += 20
	}

	if avgOrdersInZone > 0 {
		if float64(c.OrdersThisMonth) > avgOrdersInZone*1.5 {
			boost -= 10
		} else if float64(c.OrdersThisMonth) < avgOrdersInZone*0.5 {
			boost += 5
		}
	}

	return round2(boost)
}

// ScoreCandidates computes quality + fairness + final scores for a candidate pool.
func ScoreCandidates(candidates []domain.TechnicianCandidate) []domain.TechnicianCandidate {
	if len(candidates) == 0 {
		return candidates
	}

	totalOrders, totalEarnings := 0.0, 0.0
	for _, c := range candidates {
		totalOrders += float64(c.OrdersThisMonth)
		totalEarnings += c.EarningsThisMonth
	}
	avgOrders := totalOrders / float64(len(candidates))
	avgEarnings := totalEarnings / float64(len(candidates))

	scored := make([]domain.TechnicianCandidate, len(candidates))
	for i, c := range candidates {
		c.QualityScore = CalculateQualityScore(c)
		c.FairnessScore = CalculateFairnessScore(c, avgOrders, avgEarnings)
		boost := CalculateFairnessBoost(c, avgOrders)
		c.FinalScore = round2(math.Max(0, c.QualityScore*0.7+c.FairnessScore*0.3+boost))
		scored[i] = c
	}
	return scored
}

// RecalculateRanking recomputes and persists the technician's quality-based priority score.
func (s *WorkforceService) RecalculateRanking(ctx context.Context, technicianID uuid.UUID) (float64, error) {
	tech, err := s.repo.GetTechnicianByID(ctx, technicianID)
	if err != nil {
		return 0, err
	}
	if tech == nil {
		return 0, ErrTechnicianNotFound
	}

	candidate := domain.TechnicianCandidate{
		TechnicianID:       tech.ID,
		FullName:           tech.FullName,
		Rating:             tech.Rating,
		CompletedJobsCount: tech.CompletedJobsCount,
		AcceptanceRate:     tech.AcceptanceRate,
		AvgResponseMinutes: tech.AvgResponseMinutes,
		VerificationLevel:  tech.VerificationLevel,
		ComplaintCount:     tech.ComplaintCount,
		IsPrimaryZone:      true,
	}
	score := CalculateQualityScore(candidate)

	if err := s.repo.UpsertRanking(ctx, technicianID, score); err != nil {
		return 0, err
	}
	return score, nil
}

// --- Wallet & pricing ---

// CalculatePricing derives base price and commission for an order using price tiers
// and the assigned technician's level commission rate.
func (s *WorkforceService) CalculatePricing(ctx context.Context, order *domain.ServiceOrder, basePriceOverride *float64) (*domain.ServicePricing, error) {
	tier, err := s.repo.GetPriceTier(ctx, string(order.OrderType))
	if err != nil {
		return nil, err
	}

	basePrice := 0.0
	commissionPercent := 15.0

	if tier != nil {
		basePrice = tier.DefaultPriceIQD
		commissionPercent = tier.CommissionPercent
		if order.SystemSizeKW != nil && tier.PricePerKWIQD > 0 {
			basePrice += *order.SystemSizeKW * tier.PricePerKWIQD
		}
		if tier.MaxPriceIQD > 0 {
			basePrice = math.Min(basePrice, tier.MaxPriceIQD)
		}
		basePrice = math.Max(basePrice, tier.MinPriceIQD)
	}

	if basePriceOverride != nil {
		basePrice = *basePriceOverride
	}

	if order.AssignedTechnicianID != nil {
		tech, err := s.repo.GetTechnicianByID(ctx, *order.AssignedTechnicianID)
		if err != nil {
			return nil, err
		}
		if tech != nil && tech.CommissionRate != nil {
			commissionPercent = *tech.CommissionRate
		}
	}

	commission := round2(basePrice * commissionPercent / 100.0)
	pricing := &domain.ServicePricing{
		ID:                        uuid.New(),
		OrderID:                   order.ID,
		BasePriceIQD:              round2(basePrice),
		PlatformCommissionPercent: commissionPercent,
		PlatformCommissionIQD:     commission,
		TechnicianPayoutIQD:       round2(basePrice - commission),
		PaymentStatus:             domain.PayUnpaid,
	}
	return pricing, nil
}

// EstimatePayout returns the approximate technician payout shown before accepting a dispatch.
func (s *WorkforceService) EstimatePayout(ctx context.Context, orderType domain.ServiceOrderType, sizeKW *float64) float64 {
	tier, err := s.repo.GetPriceTier(ctx, string(orderType))
	if err != nil || tier == nil {
		return 0
	}
	base := tier.DefaultPriceIQD
	if sizeKW != nil && tier.PricePerKWIQD > 0 {
		base += *sizeKW * tier.PricePerKWIQD
	}
	if tier.MaxPriceIQD > 0 {
		base = math.Min(base, tier.MaxPriceIQD)
	}
	base = math.Max(base, tier.MinPriceIQD)
	return round2(base * (100 - tier.CommissionPercent) / 100.0)
}

// SetPricing stores (or overrides) the pricing row for an order.
func (s *WorkforceService) SetPricing(ctx context.Context, orderID uuid.UUID, req domain.SetPricingRequest) (*domain.ServicePricing, error) {
	order, err := s.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		return nil, err
	}
	if order == nil {
		return nil, ErrServiceOrderNotFound
	}

	pricing, err := s.CalculatePricing(ctx, order, &req.BasePriceIQD)
	if err != nil {
		return nil, err
	}
	if req.PlatformCommissionPercent != nil {
		pricing.PlatformCommissionPercent = *req.PlatformCommissionPercent
		pricing.PlatformCommissionIQD = round2(pricing.BasePriceIQD * pricing.PlatformCommissionPercent / 100.0)
		pricing.TechnicianPayoutIQD = round2(pricing.BasePriceIQD - pricing.PlatformCommissionIQD)
	}

	if err := s.repo.UpsertPricing(ctx, pricing); err != nil {
		return nil, err
	}
	return pricing, nil
}

// CompleteOrder closes a job: pricing, wallet credit, stats, level review.
func (s *WorkforceService) CompleteOrder(ctx context.Context, orderID uuid.UUID, actor *uuid.UUID) error {
	order, err := s.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		return err
	}
	if order == nil {
		return ErrServiceOrderNotFound
	}
	if order.AssignedTechnicianID == nil {
		return errors.New("order has no assigned technician")
	}

	pricing, err := s.repo.GetPricing(ctx, orderID)
	if err != nil {
		return err
	}
	if pricing == nil {
		pricing, err = s.CalculatePricing(ctx, order, nil)
		if err != nil {
			return err
		}
		if err := s.repo.UpsertPricing(ctx, pricing); err != nil {
			return err
		}
	}

	techID := *order.AssignedTechnicianID

	if err := s.repo.UpdateOrderStatus(ctx, orderID, domain.SvcStatusCompleted, actor, strPtr("تم إنجاز الطلب")); err != nil {
		return err
	}
	if err := s.repo.UpdateAssignmentStatus(ctx, orderID, techID, domain.AssignmentCompleted); err != nil {
		return err
	}
	if err := s.repo.CreditWallet(ctx, techID, pricing.TechnicianPayoutIQD, pricing.PlatformCommissionIQD); err != nil {
		return err
	}
	if err := s.repo.UpdatePaymentStatus(ctx, orderID, domain.PayPending); err != nil {
		return err
	}
	if err := s.repo.IncrementCompletedJobs(ctx, techID); err != nil {
		return err
	}
	if err := s.repo.RecordOrderCompleted(ctx, techID, pricing.TechnicianPayoutIQD); err != nil {
		return err
	}
	if err := s.repo.UpdateTechnicianLevel(ctx, techID); err != nil {
		return err
	}
	if err := s.repo.SetTechnicianAvailabilityStatus(ctx, techID, "available"); err != nil {
		return err
	}
	_, err = s.RecalculateRanking(ctx, techID)
	return err
}

// MarkCustomerUnavailable records a customer no-show with GPS/photo proof.
func (s *WorkforceService) MarkCustomerUnavailable(ctx context.Context, orderID, technicianID uuid.UUID, req domain.AddJobMediaRequest) error {
	media := &domain.JobMedia{
		ID:           uuid.New(),
		OrderID:      orderID,
		TechnicianID: &technicianID,
		Type:         "gps_proof",
		URL:          req.URL,
		Content:      req.Content,
		Lat:          req.Lat,
		Lng:          req.Lng,
	}
	if err := s.repo.AddJobMedia(ctx, media); err != nil {
		return err
	}
	return s.repo.UpdateOrderStatus(ctx, orderID, domain.SvcStatusWaitingCustomer, nil, strPtr("الزبون غير متجاوب"))
}

// SubmitReview stores a customer review and refreshes technician rating and ranking.
func (s *WorkforceService) SubmitReview(ctx context.Context, orderID uuid.UUID, customerID uuid.UUID, req domain.SubmitReviewRequest) (*domain.CustomerReview, error) {
	order, err := s.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		return nil, err
	}
	if order == nil {
		return nil, ErrServiceOrderNotFound
	}
	if order.CustomerID == nil || *order.CustomerID != customerID {
		return nil, ErrForbiddenAction
	}
	if order.AssignedTechnicianID == nil {
		return nil, errors.New("order has no assigned technician")
	}

	review := &domain.CustomerReview{
		ID:                uuid.New(),
		OrderID:           orderID,
		CustomerID:        &customerID,
		TechnicianID:      *order.AssignedTechnicianID,
		QualityRating:     req.QualityRating,
		PunctualityRating: req.PunctualityRating,
		SpeedRating:       req.SpeedRating,
		Comment:           req.Comment,
	}
	if err := s.repo.CreateReview(ctx, review); err != nil {
		return nil, err
	}
	if err := s.repo.RecalculateTechnicianRating(ctx, review.TechnicianID); err != nil {
		return nil, err
	}
	if err := s.repo.UpdateTechnicianLevel(ctx, review.TechnicianID); err != nil {
		return nil, err
	}
	if _, err := s.RecalculateRanking(ctx, review.TechnicianID); err != nil {
		return nil, err
	}
	return review, nil
}

// GetWalletSummary returns the wallet plus its per-order transaction history.
func (s *WorkforceService) GetWalletSummary(ctx context.Context, technicianID uuid.UUID) (*domain.WalletSummary, error) {
	wallet, err := s.repo.GetWallet(ctx, technicianID)
	if err != nil {
		return nil, err
	}
	if wallet == nil {
		return nil, ErrTechnicianNotFound
	}
	txs, err := s.repo.ListWalletTransactions(ctx, technicianID)
	if err != nil {
		return nil, err
	}
	return &domain.WalletSummary{Wallet: *wallet, Transactions: txs}, nil
}

// BuildCustomerView converts an order into the privacy-safe customer projection.
func (s *WorkforceService) BuildCustomerView(ctx context.Context, order *domain.ServiceOrder) (*domain.CustomerServiceOrderView, error) {
	view := &domain.CustomerServiceOrderView{
		ID:                   order.ID,
		OrderNumber:          order.OrderNumber,
		OrderType:            order.OrderType,
		Description:          order.Description,
		SystemSizeKW:         order.SystemSizeKW,
		Address:              order.Address,
		GovernorateName:      order.GovernorateName,
		PreferredDate:        order.PreferredDate,
		Status:               order.Status,
		StatusLabelAr:        domain.ServiceOrderStatusLabels[order.Status],
		AssignedTechnicianID: order.AssignedTechnicianID,
		CreatedAt:            order.CreatedAt,
		CompletedAt:          order.CompletedAt,
	}

	timeline, err := s.repo.GetStatusHistory(ctx, order.ID)
	if err != nil {
		return nil, err
	}
	view.Timeline = timeline

	if order.AssignedTechnicianID != nil {
		tech, err := s.repo.GetTechnicianByID(ctx, *order.AssignedTechnicianID)
		if err != nil {
			return nil, err
		}
		if tech != nil {
			view.Technician = &domain.AssignedTechnicianSummary{
				ID:                 tech.ID,
				FirstName:          firstName(tech.FullName),
				ProfileImageURL:    tech.ProfileImageURL,
				Rating:             tech.Rating,
				CompletedJobsCount: tech.CompletedJobsCount,
				LevelNameAr:        tech.LevelNameAr,
				LevelBadgeColor:    tech.LevelBadgeColor,
			}
		}
		tracking, err := s.repo.GetLatestTracking(ctx, order.ID)
		if err != nil {
			return nil, err
		}
		view.Tracking = tracking
	}

	pricing, err := s.repo.GetPricing(ctx, order.ID)
	if err != nil {
		return nil, err
	}
	view.Pricing = pricing

	return view, nil
}

// --- Helpers ---

func round2(v float64) float64 {
	return math.Round(v*100) / 100
}

func strPtr(s string) *string { return &s }

func firstName(full string) string {
	parts := strings.Fields(strings.TrimSpace(full))
	if len(parts) == 0 {
		return full
	}
	return parts[0]
}
