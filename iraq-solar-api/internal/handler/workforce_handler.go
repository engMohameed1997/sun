package handler

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

// WorkforceHandler exposes the workforce dispatch REST API for customers,
// technicians and administrators.
type WorkforceHandler struct {
	repo      repository.WorkforceRepository
	workforce *service.WorkforceService
	dispatch  *service.DispatchService
}

// NewWorkforceHandler builds a WorkforceHandler.
func NewWorkforceHandler(
	repo repository.WorkforceRepository,
	workforce *service.WorkforceService,
	dispatch *service.DispatchService,
) *WorkforceHandler {
	return &WorkforceHandler{repo: repo, workforce: workforce, dispatch: dispatch}
}

// --- Shared helpers ---

func currentUserID(c *gin.Context) (uuid.UUID, bool) {
	val, exists := c.Get("user_id")
	if !exists {
		return uuid.Nil, false
	}
	id, ok := val.(uuid.UUID)
	return id, ok
}

func notFoundError(c *gin.Context, message string) {
	utils.ErrorResponse(c, http.StatusNotFound, message, "NOT_FOUND", nil)
}

// marshalStrings converts a string slice into a JSONB-ready payload (never null).
func marshalStrings(values []string) (json.RawMessage, error) {
	if values == nil {
		values = []string{}
	}
	return json.Marshal(values)
}

func parseUUIDParam(c *gin.Context, name string) (uuid.UUID, bool) {
	id, err := uuid.Parse(c.Param(name))
	if err != nil {
		utils.BadRequestError(c, "معرّف غير صالح", err)
		return uuid.Nil, false
	}
	return id, true
}

// currentTechnician resolves the technician profile of the authenticated user.
func (h *WorkforceHandler) currentTechnician(c *gin.Context) (*domain.Technician, bool) {
	userID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return nil, false
	}
	tech, err := h.workforce.GetTechnicianForUser(c.Request.Context(), userID)
	if err != nil {
		if errors.Is(err, service.ErrTechnicianNotFound) {
			notFoundError(c, "لا يوجد ملف فني مرتبط بحسابك")
			return nil, false
		}
		utils.InternalServerError(c, err)
		return nil, false
	}
	return tech, true
}

func parseTechnicianFilters(c *gin.Context) domain.TechnicianFilters {
	f := domain.TechnicianFilters{
		Role:   c.Query("role"),
		Status: c.Query("status"),
		Search: c.Query("search"),
	}
	f.GovernorateID, _ = strconv.Atoi(c.Query("governorate_id"))
	f.Page, _ = strconv.Atoi(c.DefaultQuery("page", "1"))
	f.Limit, _ = strconv.Atoi(c.DefaultQuery("limit", "20"))
	if v := c.Query("is_verified"); v != "" {
		verified := v == "true"
		f.IsVerified = &verified
	}
	return f
}

func toPublicTechnician(t domain.Technician) domain.TechnicianPublic {
	name := t.FullName
	if parts := strings.Fields(strings.TrimSpace(name)); len(parts) > 0 {
		name = parts[0]
	}
	return domain.TechnicianPublic{
		ID:                 t.ID,
		FirstName:          name,
		ProfileImageURL:    t.ProfileImageURL,
		Role:               t.Role,
		Specializations:    t.Specializations,
		ExperienceYears:    t.ExperienceYears,
		Rating:             t.Rating,
		CompletedJobsCount: t.CompletedJobsCount,
		VerificationLevel:  t.VerificationLevel,
		LevelNameAr:        t.LevelNameAr,
		LevelBadgeColor:    t.LevelBadgeColor,
		GovernorateName:    t.GovernorateName,
	}
}

// --- Public endpoints (trust gallery — never exposes phone numbers) ---

// ListPublicTechnicians returns a privacy-safe directory of verified technicians.
func (h *WorkforceHandler) ListPublicTechnicians(c *gin.Context) {
	f := parseTechnicianFilters(c)
	verified := true
	f.IsVerified = &verified

	techs, total, err := h.repo.ListTechnicians(c.Request.Context(), f)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	public := make([]domain.TechnicianPublic, 0, len(techs))
	for _, t := range techs {
		public = append(public, toPublicTechnician(t))
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الفنيين المعتمدين", gin.H{
		"technicians": public,
		"total":       total,
		"page":        f.Page,
		"limit":       f.Limit,
	})
}

// GetPublicTechnician returns a single technician's public profile.
func (h *WorkforceHandler) GetPublicTechnician(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	tech, err := h.repo.GetTechnicianByID(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if tech == nil {
		notFoundError(c, "الفني غير موجود")
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب ملف الفني", toPublicTechnician(*tech))
}

// GetTechnicianPortfolio returns the technician's public work gallery.
func (h *WorkforceHandler) GetTechnicianPortfolio(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	items, err := h.repo.ListPortfolio(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب معرض الأعمال", items)
}

// --- Technician self-service ---

// GetMyTechnicianProfile returns the authenticated technician's own profile bundle.
func (h *WorkforceHandler) GetMyTechnicianProfile(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	ctx := c.Request.Context()

	zones, err := h.repo.ListServiceZones(ctx, tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	availability, err := h.repo.GetAvailability(ctx, tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	docs, err := h.repo.ListDocuments(ctx, tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	portfolio, err := h.repo.ListPortfolio(ctx, tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب ملف الفني", gin.H{
		"technician":   tech,
		"zones":        zones,
		"availability": availability,
		"documents":    docs,
		"portfolio":    portfolio,
	})
}

// UpdateMyAvailability sets live availability status and working hours/days.
func (h *WorkforceHandler) UpdateMyAvailability(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	var req domain.UpdateAvailabilityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التواجد غير صالحة", err)
		return
	}
	if err := h.workforce.UpdateAvailability(c.Request.Context(), tech.ID, req); err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}
	availability, err := h.repo.GetAvailability(c.Request.Context(), tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة التواجد", availability)
}

// UpdateMyServiceZones replaces the technician's coverage governorates.
func (h *WorkforceHandler) UpdateMyServiceZones(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	var req domain.UpdateServiceZonesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات مناطق التغطية غير صالحة", err)
		return
	}
	if err := h.repo.ReplaceServiceZones(c.Request.Context(), tech.ID, req.GovernorateIDs, req.PrimaryGovernorate); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	zones, err := h.repo.ListServiceZones(c.Request.Context(), tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث مناطق التغطية", zones)
}

// AddMyDocument uploads a verification document for review.
func (h *WorkforceHandler) AddMyDocument(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	var req domain.AddDocumentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المستند غير صالحة", err)
		return
	}
	doc := &domain.TechnicianDocument{
		ID:           uuid.New(),
		TechnicianID: tech.ID,
		Type:         req.Type,
		URL:          req.URL,
		Status:       domain.DocStatusPending,
	}
	if err := h.repo.AddDocument(c.Request.Context(), doc); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم رفع المستند وسيتم مراجعته", doc)
}

// AddMyPortfolioItem publishes a project to the technician's gallery.
func (h *WorkforceHandler) AddMyPortfolioItem(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	var req domain.AddPortfolioRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المشروع غير صالحة", err)
		return
	}

	before, err := marshalStrings(req.BeforeImages)
	if err != nil {
		utils.BadRequestError(c, "صور (قبل) غير صالحة", err)
		return
	}
	after, err := marshalStrings(req.AfterImages)
	if err != nil {
		utils.BadRequestError(c, "صور (بعد) غير صالحة", err)
		return
	}

	projectType := req.ProjectType
	if projectType == "" {
		projectType = "installation"
	}

	item := &domain.TechnicianPortfolio{
		ID:               uuid.New(),
		TechnicianID:     tech.ID,
		Title:            req.Title,
		Description:      req.Description,
		BeforeImages:     before,
		AfterImages:      after,
		VideoURL:         req.VideoURL,
		ProjectType:      projectType,
		SystemCapacityKW: req.SystemCapacityKW,
		Governorate:      req.Governorate,
		City:             req.City,
		ExecutionDate:    req.ExecutionDate,
	}
	if err := h.repo.AddPortfolioItem(c.Request.Context(), item); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم إضافة المشروع لمعرض الأعمال", item)
}

// GetMyWallet returns the technician's wallet balance and transactions.
func (h *WorkforceHandler) GetMyWallet(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	summary, err := h.workforce.GetWalletSummary(c.Request.Context(), tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب بيانات المحفظة", summary)
}

// --- Admin: technicians ---

// AdminListTechnicians returns the paginated technician management table.
func (h *WorkforceHandler) AdminListTechnicians(c *gin.Context) {
	f := parseTechnicianFilters(c)
	techs, total, err := h.repo.ListTechnicians(c.Request.Context(), f)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	totalPages := 0
	if f.Limit > 0 {
		totalPages = (total + f.Limit - 1) / f.Limit
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الفنيين", domain.TechniciansResponse{
		Technicians: techs,
		Total:       total,
		Page:        f.Page,
		Limit:       f.Limit,
		TotalPages:  totalPages,
	})
}

// AdminGetTechnician returns the full technician record with related collections.
func (h *WorkforceHandler) AdminGetTechnician(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	ctx := c.Request.Context()

	tech, err := h.repo.GetTechnicianByID(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if tech == nil {
		notFoundError(c, "الفني غير موجود")
		return
	}

	zones, err := h.repo.ListServiceZones(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	docs, err := h.repo.ListDocuments(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	portfolio, err := h.repo.ListPortfolio(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	wallet, err := h.repo.GetWallet(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	availability, err := h.repo.GetAvailability(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب بيانات الفني", gin.H{
		"technician":   tech,
		"zones":        zones,
		"documents":    docs,
		"portfolio":    portfolio,
		"wallet":       wallet,
		"availability": availability,
	})
}

// AdminCreateTechnician registers a new technician profile (and user account if needed).
func (h *WorkforceHandler) AdminCreateTechnician(c *gin.Context) {
	var req domain.CreateTechnicianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الفني غير صالحة", err)
		return
	}
	tech, err := h.workforce.RegisterTechnician(c.Request.Context(), req)
	if err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء ملف الفني بنجاح", tech)
}

// AdminUpdateTechnician edits an existing technician profile.
func (h *WorkforceHandler) AdminUpdateTechnician(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpdateTechnicianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التعديل غير صالحة", err)
		return
	}
	if err := h.repo.UpdateTechnician(c.Request.Context(), id, req); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	tech, err := h.repo.GetTechnicianByID(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث بيانات الفني", tech)
}

// AdminVerifyTechnician sets verification status and level.
func (h *WorkforceHandler) AdminVerifyTechnician(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.VerifyTechnicianRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التوثيق غير صالحة", err)
		return
	}
	if err := h.workforce.VerifyTechnician(c.Request.Context(), id, req); err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة توثيق الفني", gin.H{"technician_id": id})
}

// AdminUpdateRanking pins, hides or manually orders a technician.
func (h *WorkforceHandler) AdminUpdateRanking(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpdateRankingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الترتيب غير صالحة", err)
		return
	}
	if err := h.repo.UpdateRankingFlags(c.Request.Context(), id, req); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	ranking, err := h.repo.GetRanking(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث ترتيب الفني", ranking)
}

// AdminUpdateServiceZones sets the governorates a technician covers.
func (h *WorkforceHandler) AdminUpdateServiceZones(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpdateServiceZonesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات مناطق التغطية غير صالحة", err)
		return
	}
	if err := h.repo.ReplaceServiceZones(c.Request.Context(), id, req.GovernorateIDs, req.PrimaryGovernorate); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	zones, err := h.repo.ListServiceZones(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث مناطق التغطية", zones)
}

// AdminReviewDocument approves or rejects a technician document.
func (h *WorkforceHandler) AdminReviewDocument(c *gin.Context) {
	docID, ok := parseUUIDParam(c, "doc_id")
	if !ok {
		return
	}
	adminID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	var req domain.ReviewDocumentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المراجعة غير صالحة", err)
		return
	}
	if err := h.repo.UpdateDocumentStatus(c.Request.Context(), docID, req.Status, adminID); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة المستند", gin.H{"document_id": docID, "status": req.Status})
}

// AdminGetTechnicianWallet returns a technician's wallet for the finance screen.
func (h *WorkforceHandler) AdminGetTechnicianWallet(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	summary, err := h.workforce.GetWalletSummary(c.Request.Context(), id)
	if err != nil {
		if errors.Is(err, service.ErrTechnicianNotFound) {
			notFoundError(c, "الفني غير موجود")
			return
		}
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب محفظة الفني", summary)
}

// AdminSettleWallet zeroes out the technician's pending payout.
func (h *WorkforceHandler) AdminSettleWallet(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	if err := h.repo.SettleWallet(c.Request.Context(), id); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	wallet, err := h.repo.GetWallet(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تسديد مستحقات الفني", wallet)
}

// --- Admin: technician levels ---

// ListTechnicianLevels returns commission tiers.
func (h *WorkforceHandler) ListTechnicianLevels(c *gin.Context) {
	levels, err := h.repo.ListLevels(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب مستويات الفنيين", levels)
}

// CreateTechnicianLevel adds a new commission tier.
func (h *WorkforceHandler) CreateTechnicianLevel(c *gin.Context) {
	var req domain.UpsertTechnicianLevelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المستوى غير صالحة", err)
		return
	}
	level, err := h.repo.CreateLevel(c.Request.Context(), req)
	if err != nil {
		utils.BadRequestError(c, "تعذر إنشاء المستوى", err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء المستوى", level)
}

// UpdateTechnicianLevel edits a commission tier.
func (h *WorkforceHandler) UpdateTechnicianLevel(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpsertTechnicianLevelRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المستوى غير صالحة", err)
		return
	}
	if err := h.repo.UpdateLevel(c.Request.Context(), id, req); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث المستوى", gin.H{"level_id": id})
}

// --- Admin: fair dispatch analytics ---

// AdminDispatchStats returns per-technician fair-dispatch counters.
func (h *WorkforceHandler) AdminDispatchStats(c *gin.Context) {
	stats, err := h.repo.ListDispatchStats(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب إحصائيات عدالة التوزيع", stats)
}
