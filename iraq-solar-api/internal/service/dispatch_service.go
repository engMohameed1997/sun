package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/hub"
	"github.com/iraq-solar/api/internal/repository"
)

// parallelScoreWindow is the score gap under which candidates are considered
// equally matched and are allowed to compete in parallel (fastest accept wins).
const parallelScoreWindow = 5.0

// largeInstallationKW is the threshold above which installations are dispatched
// sequentially in hybrid mode (big jobs deserve a deliberate single offer).
const largeInstallationKW = 10.0

// DispatchService is the dispatch engine: it turns a service order into a ranked
// technician queue, sends offers, and resolves accept / reject / expiry outcomes.
type DispatchService struct {
	repo      repository.WorkforceRepository
	workforce *WorkforceService
	hub       *hub.RealtimeHub
	notifier  *NotificationService
}

// NewDispatchService builds a DispatchService.
func NewDispatchService(
	repo repository.WorkforceRepository,
	workforce *WorkforceService,
	realtimeHub *hub.RealtimeHub,
	notifier *NotificationService,
) *DispatchService {
	return &DispatchService{repo: repo, workforce: workforce, hub: realtimeHub, notifier: notifier}
}

// --- Order creation ---

// CreateServiceOrder persists a customer service order and kicks off dispatching.
func (s *DispatchService) CreateServiceOrder(ctx context.Context, customerID *uuid.UUID, req domain.CreateServiceOrderRequest, calcResult json.RawMessage) (*domain.ServiceOrder, error) {
	orderNumber, err := s.repo.NextOrderNumber(ctx)
	if err != nil {
		return nil, err
	}

	priority := req.Priority
	if priority == "" {
		priority = "normal"
	}

	order := &domain.ServiceOrder{
		ID:               uuid.New(),
		OrderNumber:      orderNumber,
		CustomerID:       customerID,
		OrderType:        req.OrderType,
		Description:      req.Description,
		SystemSizeKW:     req.SystemSizeKW,
		GovernorateID:    req.GovernorateID,
		DistrictID:       req.DistrictID,
		Address:          req.Address,
		Lat:              req.Lat,
		Lng:              req.Lng,
		PreferredDate:    req.PreferredDate,
		Status:           domain.SvcStatusNew,
		Priority:         priority,
		CalculatorResult: calcResult,
		DispatchMode:     domain.DispatchSequential,
	}

	if err := s.repo.CreateServiceOrder(ctx, order); err != nil {
		return nil, err
	}

	if err := s.ProcessDispatch(ctx, order.ID, nil); err != nil {
		log.Printf("[dispatch] order %s: %v", order.OrderNumber, err)
	}

	return s.repo.GetServiceOrder(ctx, order.ID)
}

// --- Dispatch engine ---

// ProcessDispatch ranks eligible technicians and sends out offers according to the
// configured dispatch mode for the service type.
// preferredTechnician (optional) is placed first in the queue — used for converted leads.
func (s *DispatchService) ProcessDispatch(ctx context.Context, orderID uuid.UUID, preferredTechnician *uuid.UUID) error {
	order, err := s.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		return err
	}
	if order == nil {
		return ErrServiceOrderNotFound
	}
	if order.GovernorateID == nil {
		return errors.New("order has no governorate — cannot dispatch")
	}

	// 1. Settings for this service type
	settings, err := s.repo.GetDispatchSettings(ctx, string(order.OrderType))
	if err != nil {
		return err
	}
	if settings == nil {
		settings = &domain.DispatchSettings{
			DispatchMode:            domain.DispatchSequential,
			ResponseTimeoutMinutes:  10,
			ParallelCandidatesCount: 3,
			MinimumScore:            0,
			AutoAssignEnabled:       true,
		}
	}
	if !settings.AutoAssignEnabled {
		return s.repo.UpdateOrderStatus(ctx, orderID, domain.SvcStatusNew, nil, strPtr("التوزيع التلقائي معطل — بانتظار تعيين يدوي"))
	}

	// 2. Filter eligible technicians
	candidates, err := s.repo.FindAvailableTechnicians(ctx, *order.GovernorateID, string(order.OrderType))
	if err != nil {
		return err
	}

	// 3 + 4. Score and sort
	candidates = ScoreCandidates(candidates)
	eligible := make([]domain.TechnicianCandidate, 0, len(candidates))
	for _, c := range candidates {
		if c.FinalScore >= settings.MinimumScore {
			eligible = append(eligible, c)
		}
	}
	sort.SliceStable(eligible, func(i, j int) bool { return eligible[i].FinalScore > eligible[j].FinalScore })

	if preferredTechnician != nil {
		for i, c := range eligible {
			if c.TechnicianID == *preferredTechnician && i > 0 {
				eligible[0], eligible[i] = eligible[i], eligible[0]
				break
			}
		}
	}

	if len(eligible) == 0 {
		if err := s.repo.UpdateOrderStatus(ctx, orderID, domain.SvcStatusNoTechnicianAvailable, nil,
			strPtr("لا يوجد فني متوفر يغطي هذه المنطقة حالياً")); err != nil {
			return err
		}
		s.broadcastAdmins(hub.EventServiceOrderUnassigned, map[string]any{
			"order_id":     order.ID,
			"order_number": order.OrderNumber,
			"message":      "لا يوجد فني متوفر — يتطلب تعيين يدوي",
		})
		return nil
	}

	// 7. Resolve effective mode (hybrid decision)
	mode := s.resolveDispatchMode(settings, order, eligible)

	// 5. Build the queue with selection reasons
	entries := make([]domain.DispatchQueueEntry, 0, len(eligible))
	for i, c := range eligible {
		reason, err := json.Marshal(buildSelectionReason(c))
		if err != nil {
			return fmt.Errorf("marshal selection reason: %w", err)
		}
		entries = append(entries, domain.DispatchQueueEntry{
			ID:              uuid.New(),
			ServiceOrderID:  order.ID,
			TechnicianID:    c.TechnicianID,
			PriorityScore:   c.FinalScore,
			DispatchMode:    mode,
			Position:        i + 1,
			Status:          domain.DispatchQueued,
			SelectionReason: reason,
		})
		if err := s.repo.UpdateFairnessBoost(ctx, c.TechnicianID, c.FinalScore-c.QualityScore*0.7-c.FairnessScore*0.3); err != nil {
			return err
		}
	}

	if err := s.repo.AddToDispatchQueue(ctx, entries); err != nil {
		return err
	}

	// 9. Mark the order as dispatching
	if err := s.repo.UpdateOrderStatus(ctx, orderID, domain.SvcStatusDispatching, nil, strPtr("جاري البحث عن فني متوفر")); err != nil {
		return err
	}

	// 8. Send offers
	targets := 1
	if mode == domain.DispatchParallel {
		targets = settings.ParallelCandidatesCount
		// 6. Fair competition — widen the window to include equally-scored technicians.
		top := eligible[0].FinalScore
		for i := targets; i < len(eligible); i++ {
			if top-eligible[i].FinalScore <= parallelScoreWindow {
				targets = i + 1
			} else {
				break
			}
		}
	}
	if targets > len(entries) {
		targets = len(entries)
	}

	for i := 0; i < targets; i++ {
		if err := s.sendOffer(ctx, order, entries[i], eligible[i], settings.ResponseTimeoutMinutes); err != nil {
			log.Printf("[dispatch] send offer failed for %s: %v", entries[i].TechnicianID, err)
		}
	}

	return nil
}

// resolveDispatchMode turns a hybrid configuration into a concrete mode.
func (s *DispatchService) resolveDispatchMode(settings *domain.DispatchSettings, order *domain.ServiceOrder, eligible []domain.TechnicianCandidate) domain.DispatchMode {
	if settings.DispatchMode != domain.DispatchHybrid {
		return settings.DispatchMode
	}
	if order.OrderType == domain.ServiceTypeInstallation {
		if order.SystemSizeKW != nil && *order.SystemSizeKW > largeInstallationKW {
			return domain.DispatchSequential
		}
	}
	if len(eligible) > 1 && eligible[0].FinalScore-eligible[1].FinalScore <= parallelScoreWindow {
		return domain.DispatchParallel
	}
	return domain.DispatchSequential
}

// sendOffer marks a queue entry as sent, updates fair-dispatch stats and notifies the technician.
func (s *DispatchService) sendOffer(ctx context.Context, order *domain.ServiceOrder, entry domain.DispatchQueueEntry, candidate domain.TechnicianCandidate, timeoutMinutes int) error {
	if err := s.repo.MarkDispatchSent(ctx, entry.ID, timeoutMinutes); err != nil {
		return err
	}
	if err := s.repo.RecordDispatchSent(ctx, entry.TechnicianID); err != nil {
		return err
	}

	tech, err := s.repo.GetTechnicianByID(ctx, entry.TechnicianID)
	if err != nil || tech == nil {
		return err
	}

	expiresAt := time.Now().Add(time.Duration(timeoutMinutes) * time.Minute)
	reasonAr := BuildSelectionReasonText(candidate)
	payload := domain.DispatchNotificationPayload{
		DispatchID:        entry.ID,
		OrderID:           order.ID,
		OrderNumber:       order.OrderNumber,
		OrderType:         order.OrderType,
		GovernorateName:   order.GovernorateName,
		EstimatedPayout:   s.workforce.EstimatePayout(ctx, order.OrderType, order.SystemSizeKW),
		SelectionReasonAr: reasonAr,
		ExpiresAt:         &expiresAt,
	}

	if s.hub != nil {
		go s.hub.BroadcastToUser(tech.UserID.String(), hub.MsgDispatch, hub.EventNewDispatch, payload)
	}
	if s.notifier != nil {
		raw, _ := json.Marshal(payload)
		if _, err := s.notifier.Create(ctx, tech.UserID, domain.NotificationTypeNewOrder,
			"مهمة جديدة متاحة", reasonAr, raw); err != nil {
			log.Printf("[dispatch] notify technician failed: %v", err)
		}
	}

	return nil
}

// --- Technician responses ---

// AcceptDispatch assigns the order to the accepting technician and cancels the rest of the queue.
func (s *DispatchService) AcceptDispatch(ctx context.Context, dispatchID, technicianID uuid.UUID) (*domain.ServiceOrder, error) {
	entry, err := s.repo.GetDispatchEntry(ctx, dispatchID)
	if err != nil {
		return nil, err
	}
	if entry == nil {
		return nil, errors.New("dispatch offer not found")
	}
	if entry.TechnicianID != technicianID {
		return nil, ErrForbiddenAction
	}
	if entry.Status != domain.DispatchSent && entry.Status != domain.DispatchQueued {
		return nil, errors.New("هذه المهمة لم تعد متاحة")
	}
	if entry.ExpiresAt != nil && entry.ExpiresAt.Before(time.Now()) {
		_ = s.repo.UpdateDispatchStatus(ctx, dispatchID, domain.DispatchExpired)
		return nil, errors.New("انتهت مهلة الرد على هذه المهمة")
	}

	order, err := s.repo.GetServiceOrder(ctx, entry.ServiceOrderID)
	if err != nil {
		return nil, err
	}
	if order == nil {
		return nil, ErrServiceOrderNotFound
	}
	if order.AssignedTechnicianID != nil {
		return nil, errors.New("تم إسناد هذه المهمة لفني آخر")
	}

	if err := s.repo.UpdateDispatchStatus(ctx, dispatchID, domain.DispatchAccepted); err != nil {
		return nil, err
	}
	if err := s.repo.CancelRemainingDispatch(ctx, order.ID, dispatchID); err != nil {
		return nil, err
	}

	now := time.Now()
	assignment := &domain.OrderAssignment{
		ID:           uuid.New(),
		OrderID:      order.ID,
		TechnicianID: technicianID,
		AssignedBy:   "dispatch_engine",
		Status:       domain.AssignmentAccepted,
		AcceptedAt:   &now,
	}
	if err := s.repo.CreateAssignment(ctx, assignment); err != nil {
		return nil, err
	}
	if err := s.repo.SetOrderTechnician(ctx, order.ID, technicianID, domain.SvcStatusAssigned); err != nil {
		return nil, err
	}
	if err := s.repo.UpdateOrderStatus(ctx, order.ID, domain.SvcStatusAssigned, nil, strPtr("تم تعيين فني معتمد")); err != nil {
		return nil, err
	}
	if err := s.repo.SetTechnicianAvailabilityStatus(ctx, technicianID, "busy"); err != nil {
		return nil, err
	}

	responseMinutes := 0
	if entry.SentAt != nil {
		responseMinutes = int(math.Round(now.Sub(*entry.SentAt).Minutes()))
	}
	if err := s.repo.RecordDispatchResponse(ctx, technicianID, true, responseMinutes); err != nil {
		return nil, err
	}
	if _, err := s.workforce.RecalculateRanking(ctx, technicianID); err != nil {
		return nil, err
	}

	if err := s.ensureDefaultTasks(ctx, order); err != nil {
		return nil, err
	}

	s.notifyCustomerAssigned(ctx, order, technicianID)
	s.broadcastAdmins(hub.EventServiceOrderStatusChanged, map[string]any{
		"order_id":      order.ID,
		"order_number":  order.OrderNumber,
		"status":        domain.SvcStatusAssigned,
		"technician_id": technicianID,
	})

	return s.repo.GetServiceOrder(ctx, order.ID)
}

// RejectDispatch declines an offer and moves the queue forward (sequential mode).
func (s *DispatchService) RejectDispatch(ctx context.Context, dispatchID, technicianID uuid.UUID, reason *string) error {
	entry, err := s.repo.GetDispatchEntry(ctx, dispatchID)
	if err != nil {
		return err
	}
	if entry == nil {
		return errors.New("dispatch offer not found")
	}
	if entry.TechnicianID != technicianID {
		return ErrForbiddenAction
	}

	if err := s.repo.UpdateDispatchStatus(ctx, dispatchID, domain.DispatchRejected); err != nil {
		return err
	}
	if err := s.repo.RecordDispatchResponse(ctx, technicianID, false, 0); err != nil {
		return err
	}
	if _, err := s.workforce.RecalculateRanking(ctx, technicianID); err != nil {
		return err
	}

	return s.advanceQueue(ctx, entry.ServiceOrderID)
}

// ExpireDispatch marks a single offer as expired and advances the queue.
func (s *DispatchService) ExpireDispatch(ctx context.Context, dispatchID uuid.UUID) error {
	entry, err := s.repo.GetDispatchEntry(ctx, dispatchID)
	if err != nil {
		return err
	}
	if entry == nil {
		return nil
	}
	if err := s.repo.UpdateDispatchStatus(ctx, dispatchID, domain.DispatchExpired); err != nil {
		return err
	}
	if err := s.repo.RecordDispatchResponse(ctx, entry.TechnicianID, false, 0); err != nil {
		return err
	}
	return s.advanceQueue(ctx, entry.ServiceOrderID)
}

// advanceQueue sends the offer to the next queued technician, or flags the order
// as unassignable when the queue is exhausted.
func (s *DispatchService) advanceQueue(ctx context.Context, orderID uuid.UUID) error {
	order, err := s.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		return err
	}
	if order == nil || order.AssignedTechnicianID != nil {
		return nil
	}

	// Another offer is still in flight (parallel mode) — nothing to do yet.
	queue, err := s.repo.GetDispatchQueue(ctx, orderID)
	if err != nil {
		return err
	}
	for _, e := range queue {
		if e.Status == domain.DispatchSent {
			return nil
		}
	}

	next, err := s.repo.GetNextDispatchCandidate(ctx, orderID)
	if err != nil {
		return err
	}
	if next == nil {
		if err := s.repo.UpdateOrderStatus(ctx, orderID, domain.SvcStatusNoTechnicianAvailable, nil,
			strPtr("جميع الفنيين رفضوا أو لم يستجيبوا")); err != nil {
			return err
		}
		s.broadcastAdmins(hub.EventServiceOrderUnassigned, map[string]any{
			"order_id":     order.ID,
			"order_number": order.OrderNumber,
			"message":      "انتهى طابور التوزيع بدون قبول — يتطلب تعيين يدوي",
		})
		return nil
	}

	settings, err := s.repo.GetDispatchSettings(ctx, string(order.OrderType))
	if err != nil {
		return err
	}
	timeout := 10
	if settings != nil {
		timeout = settings.ResponseTimeoutMinutes
	}

	candidate, err := s.candidateFromQueueEntry(ctx, *next)
	if err != nil {
		return err
	}
	return s.sendOffer(ctx, order, *next, candidate, timeout)
}

// candidateFromQueueEntry rebuilds a scoring snapshot from a persisted queue entry.
func (s *DispatchService) candidateFromQueueEntry(ctx context.Context, entry domain.DispatchQueueEntry) (domain.TechnicianCandidate, error) {
	tech, err := s.repo.GetTechnicianByID(ctx, entry.TechnicianID)
	if err != nil {
		return domain.TechnicianCandidate{}, err
	}
	c := domain.TechnicianCandidate{TechnicianID: entry.TechnicianID, FinalScore: entry.PriorityScore}
	if tech != nil {
		c.FullName = tech.FullName
		c.Rating = tech.Rating
		c.CompletedJobsCount = tech.CompletedJobsCount
		c.VerificationLevel = tech.VerificationLevel
		c.GovernorateName = tech.GovernorateName
	}
	return c, nil
}

// StartDispatchExpiryCron periodically expires stale offers and advances queues.
func (s *DispatchService) StartDispatchExpiryCron(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				expired, err := s.repo.ExpireStaleDispatches(ctx)
				if err != nil {
					log.Printf("[dispatch] expiry sweep failed: %v", err)
					continue
				}
				seen := map[uuid.UUID]bool{}
				for _, e := range expired {
					if err := s.repo.RecordDispatchResponse(ctx, e.TechnicianID, false, 0); err != nil {
						log.Printf("[dispatch] record expiry failed: %v", err)
					}
					if !seen[e.ServiceOrderID] {
						seen[e.ServiceOrderID] = true
						if err := s.advanceQueue(ctx, e.ServiceOrderID); err != nil {
							log.Printf("[dispatch] advance queue failed: %v", err)
						}
					}
				}
			}
		}
	}()
}

// --- Admin actions ---

// ManualAssign bypasses the dispatch engine and assigns a technician directly.
func (s *DispatchService) ManualAssign(ctx context.Context, orderID, technicianID, adminID uuid.UUID) (*domain.ServiceOrder, error) {
	order, err := s.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		return nil, err
	}
	if order == nil {
		return nil, ErrServiceOrderNotFound
	}
	tech, err := s.repo.GetTechnicianByID(ctx, technicianID)
	if err != nil {
		return nil, err
	}
	if tech == nil {
		return nil, ErrTechnicianNotFound
	}

	if err := s.repo.CancelRemainingDispatch(ctx, orderID, uuid.Nil); err != nil {
		return nil, err
	}

	now := time.Now()
	assignment := &domain.OrderAssignment{
		ID:              uuid.New(),
		OrderID:         orderID,
		TechnicianID:    technicianID,
		AssignedBy:      "admin",
		AssignedByAdmin: &adminID,
		Status:          domain.AssignmentAccepted,
		AcceptedAt:      &now,
	}
	if err := s.repo.CreateAssignment(ctx, assignment); err != nil {
		return nil, err
	}
	if err := s.repo.SetOrderTechnician(ctx, orderID, technicianID, domain.SvcStatusAssigned); err != nil {
		return nil, err
	}
	if err := s.repo.UpdateOrderStatus(ctx, orderID, domain.SvcStatusAssigned, &adminID, strPtr("تم التعيين يدوياً من الإدارة")); err != nil {
		return nil, err
	}
	if err := s.repo.SetTechnicianAvailabilityStatus(ctx, technicianID, "busy"); err != nil {
		return nil, err
	}
	if err := s.ensureDefaultTasks(ctx, order); err != nil {
		return nil, err
	}

	if s.hub != nil {
		go s.hub.BroadcastToUser(tech.UserID.String(), hub.MsgDispatch, hub.EventNewDispatch, map[string]any{
			"order_id":     order.ID,
			"order_number": order.OrderNumber,
			"message":      "تم تعيينك على مهمة جديدة من الإدارة",
		})
	}
	s.notifyCustomerAssigned(ctx, order, technicianID)

	return s.repo.GetServiceOrder(ctx, orderID)
}

// RedispatchOrder clears the previous attempt and reruns the dispatch engine.
func (s *DispatchService) RedispatchOrder(ctx context.Context, orderID uuid.UUID) error {
	if err := s.repo.CancelRemainingDispatch(ctx, orderID, uuid.Nil); err != nil {
		return err
	}
	return s.ProcessDispatch(ctx, orderID, nil)
}

// --- Leads ---

// ApproveLead converts a technician-sourced lead into a real service order and
// re-dispatches it with the originating technician given first priority.
func (s *DispatchService) ApproveLead(ctx context.Context, leadID, adminID uuid.UUID, req domain.ApproveLeadRequest) (*domain.ServiceOrder, error) {
	lead, err := s.repo.GetLead(ctx, leadID)
	if err != nil {
		return nil, err
	}
	if lead == nil {
		return nil, errors.New("lead not found")
	}
	if lead.Status != domain.LeadPendingReview {
		return nil, errors.New("تمت مراجعة هذا الطلب مسبقاً")
	}

	orderNumber, err := s.repo.NextOrderNumber(ctx)
	if err != nil {
		return nil, err
	}

	order := &domain.ServiceOrder{
		ID:            uuid.New(),
		OrderNumber:   orderNumber,
		OrderType:     lead.OrderType,
		Description:   lead.Description,
		SystemSizeKW:  lead.SystemSizeKW,
		GovernorateID: lead.GovernorateID,
		DistrictID:    lead.DistrictID,
		Address:       lead.Address,
		Status:        domain.SvcStatusNew,
		Priority:      "normal",
		DispatchMode:  domain.DispatchSequential,
	}
	if err := s.repo.CreateServiceOrder(ctx, order); err != nil {
		return nil, err
	}

	basePrice := lead.EstimatedPriceIQD
	if req.BasePriceIQD != nil {
		basePrice = req.BasePriceIQD
	}
	if basePrice != nil {
		if _, err := s.workforce.SetPricing(ctx, order.ID, domain.SetPricingRequest{BasePriceIQD: *basePrice}); err != nil {
			return nil, err
		}
	}

	if err := s.repo.UpdateLeadStatus(ctx, leadID, domain.LeadConverted, adminID, &order.ID); err != nil {
		return nil, err
	}

	techID := lead.TechnicianID
	if err := s.ProcessDispatch(ctx, order.ID, &techID); err != nil {
		log.Printf("[dispatch] lead %s dispatch failed: %v", leadID, err)
	}

	return s.repo.GetServiceOrder(ctx, order.ID)
}

// --- Helpers ---

func (s *DispatchService) ensureDefaultTasks(ctx context.Context, order *domain.ServiceOrder) error {
	existing, err := s.repo.ListJobTasks(ctx, order.ID)
	if err != nil {
		return err
	}
	if len(existing) > 0 {
		return nil
	}
	return s.repo.CreateJobTasks(ctx, order.ID, defaultTasksFor(order.OrderType))
}

func defaultTasksFor(t domain.ServiceOrderType) []string {
	switch t {
	case domain.ServiceTypeInstallation:
		return []string{
			"معاينة الموقع وتأكيد المواصفات",
			"تثبيت الهياكل والألواح",
			"تركيب الانفرتر والبطاريات",
			"التمديدات الكهربائية والحماية",
			"الفحص والتشغيل التجريبي",
			"تسليم المنظومة وتوثيق الصور",
		}
	case domain.ServiceTypeMaintenance:
		return []string{"فحص المنظومة", "تنظيف الألواح", "فحص البطاريات والانفرتر", "تقرير الصيانة"}
	case domain.ServiceTypeInspection:
		return []string{"معاينة الموقع", "قياس الأحمال", "توثيق الصور", "رفع التوصيات"}
	case domain.ServiceTypeRepair:
		return []string{"تشخيص العطل", "تنفيذ الإصلاح", "اختبار التشغيل", "توثيق الصور"}
	default:
		return []string{"تقديم الاستشارة", "توثيق التوصيات"}
	}
}

func (s *DispatchService) notifyCustomerAssigned(ctx context.Context, order *domain.ServiceOrder, technicianID uuid.UUID) {
	if s.notifier == nil || order.CustomerID == nil {
		return
	}
	tech, err := s.repo.GetTechnicianByID(ctx, technicianID)
	if err != nil || tech == nil {
		return
	}
	summary := domain.AssignedTechnicianSummary{
		FirstName:          firstName(tech.FullName),
		ProfileImageURL:    tech.ProfileImageURL,
		Rating:             tech.Rating,
		CompletedJobsCount: tech.CompletedJobsCount,
		LevelNameAr:        tech.LevelNameAr,
		LevelBadgeColor:    tech.LevelBadgeColor,
	}
	raw, _ := json.Marshal(map[string]any{"order_id": order.ID, "technician": summary})
	body := fmt.Sprintf("الفني %s ⋅ تقييم %.1f ⋅ %d مشروع منجز", summary.FirstName, summary.Rating, summary.CompletedJobsCount)
	if _, err := s.notifier.Create(ctx, *order.CustomerID, domain.NotificationTypeOrderStatus,
		"تم تعيين فني معتمد لطلبك", body, raw); err != nil {
		log.Printf("[dispatch] notify customer failed: %v", err)
	}
}

func (s *DispatchService) broadcastAdmins(event string, payload any) {
	if s.hub == nil {
		return
	}
	go s.hub.BroadcastToAdmins(hub.MsgDispatch, event, payload)
}

// buildSelectionReason produces the structured explanation stored on the queue entry.
func buildSelectionReason(c domain.TechnicianCandidate) map[string]any {
	zone := "service_zone"
	if c.IsPrimaryZone {
		zone = "primary_zone"
	}
	reason := map[string]any{
		"zone":                  zone,
		"rating":                c.Rating,
		"completed_jobs":        c.CompletedJobsCount,
		"verification_level":    c.VerificationLevel,
		"acceptance_rate":       c.AcceptanceRate,
		"quality_score":         c.QualityScore,
		"fairness_score":        c.FairnessScore,
		"final_score":           c.FinalScore,
		"days_since_last_order": c.DaysSinceLastOrder,
		"is_new_technician":     c.IsNewTechnician,
	}
	if c.GovernorateName != nil {
		reason["governorate"] = *c.GovernorateName
	}
	return reason
}

// BuildSelectionReasonText renders the Arabic "why you were selected" line for technicians.
func BuildSelectionReasonText(c domain.TechnicianCandidate) string {
	parts := []string{}

	if c.GovernorateName != nil && *c.GovernorateName != "" {
		parts = append(parts, fmt.Sprintf("تغطي محافظة %s", *c.GovernorateName))
	}
	if c.Rating > 0 {
		parts = append(parts, fmt.Sprintf("تقييمك %.1f", c.Rating))
	}
	if c.CompletedJobsCount > 0 {
		parts = append(parts, fmt.Sprintf("%d عملية مكتملة", c.CompletedJobsCount))
	}
	if c.VerificationLevel >= 3 {
		parts = append(parts, "موثق بالكامل")
	}
	if c.DaysSinceLastOrder >= 7 && c.DaysSinceLastOrder < 900 {
		parts = append(parts, fmt.Sprintf("لم تستلم طلباً منذ %d أيام", c.DaysSinceLastOrder))
	}
	if c.IsNewTechnician && c.NewTechOrdersCount < 10 {
		parts = append(parts, "مرحلة الإثبات — نريد إعطاءك فرصة")
	}

	if len(parts) == 0 {
		return "تم اختيارك لتغطيتك هذه المنطقة"
	}
	return "تم اختيارك لأن: " + strings.Join(parts, " ⋅ ")
}
