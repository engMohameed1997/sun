package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

type CalculatorHandler struct {
	calcService *service.SolarCalculatorService
	mgmtRepo    repository.CalculatorManagementRepository
	engine      *service.SolarCalculatorEngine
	solarRepo   repository.GovernorateSolarRepository
	presetRepo  repository.AppliancePresetRepository
}

func NewCalculatorHandler(
	calcService *service.SolarCalculatorService,
	mgmtRepo repository.CalculatorManagementRepository,
	engine *service.SolarCalculatorEngine,
	solarRepo repository.GovernorateSolarRepository,
	presetRepo repository.AppliancePresetRepository,
) *CalculatorHandler {
	return &CalculatorHandler{
		calcService: calcService,
		mgmtRepo:    mgmtRepo,
		engine:      engine,
		solarRepo:   solarRepo,
		presetRepo:  presetRepo,
	}
}

// GetActiveCalculators returns active calculators customized for the authenticated user's role extracted from JWT
func (h *CalculatorHandler) GetActiveCalculators(c *gin.Context) {
	role := string(domain.RoleCustomer)
	if rVal, exists := c.Get("user_role"); exists {
		if rRole, ok := rVal.(domain.Role); ok && string(rRole) != "" {
			role = string(rRole)
		} else if rStr, ok := rVal.(string); ok && rStr != "" {
			role = rStr
		}
	}

	if h.mgmtRepo == nil {
		utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الحاسبات النشطة بنجاح", []interface{}{})
		return
	}

	calcs, err := h.mgmtRepo.GetCalculatorsForRole(c.Request.Context(), role)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	var response []domain.CalculatorPublicResponse
	for _, calc := range calcs {
		sub := ""
		if calc.SubtitleAr != nil {
			sub = *calc.SubtitleAr
		}
		bg := ""
		if calc.BackgroundImageUrl != nil {
			bg = *calc.BackgroundImageUrl
		}
		badge := ""
		if calc.Badge != nil {
			badge = *calc.Badge
		}

		response = append(response, domain.CalculatorPublicResponse{
			ID:                 calc.ID,
			RouteKey:           calc.RouteKey,
			Title:              calc.TitleAr,
			Subtitle:           sub,
			IconKey:            calc.IconKey,
			BackgroundImageUrl: bg,
			Badge:              badge,
			ColorHex:           calc.ColorHex,
			IsFeatured:         calc.IsFeatured,
			SortOrder:          calc.SortOrder,
			Version:            calc.Version,
		})
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الحاسبات النشطة بنجاح", response)
}

// Admin APIs

func (h *CalculatorHandler) ListAdminCalculators(c *gin.Context) {
	if h.mgmtRepo == nil {
		utils.SuccessResponse(c, http.StatusOK, "قائمة الحاسبات", []interface{}{})
		return
	}
	calcs, err := h.mgmtRepo.ListAllAdmin(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة جميع الحاسبات للإدارة بنجاح", calcs)
}

func (h *CalculatorHandler) CreateAdminCalculator(c *gin.Context) {
	var req domain.CreateCalculatorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات إنشاء الحاسبة غير صالحة", err)
		return
	}
	if h.mgmtRepo == nil {
		utils.InternalServerError(c, nil)
		return
	}
	res, err := h.mgmtRepo.Create(c.Request.Context(), req)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء الحاسبة بنجاح", res)
}

func (h *CalculatorHandler) UpdateAdminCalculator(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.BadRequestError(c, "معرف الحاسبة غير صالحة", err)
		return
	}
	var req domain.UpdateCalculatorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات تحديث الحاسبة غير صالحة", err)
		return
	}
	if h.mgmtRepo == nil {
		utils.InternalServerError(c, nil)
		return
	}
	res, err := h.mgmtRepo.Update(c.Request.Context(), id, req)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث بيانات الحاسبة بنجاح", res)
}

func (h *CalculatorHandler) PatchAdminCalculatorStatus(c *gin.Context) {
	idParam := c.Param("id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		utils.BadRequestError(c, "معرف الحاسبة غير صالحة", err)
		return
	}
	var req domain.UpdateCalculatorStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "حالة التفعيل غير صالحة", err)
		return
	}
	if h.mgmtRepo == nil {
		utils.InternalServerError(c, nil)
		return
	}
	if err := h.mgmtRepo.UpdateStatus(c.Request.Context(), id, req.IsActive); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة تفعيل الحاسبة بنجاح", gin.H{"id": id, "is_active": req.IsActive})
}

func (h *CalculatorHandler) GetAppliancePresets(c *gin.Context) {
	if h.presetRepo == nil {
		utils.SuccessResponse(c, http.StatusOK, "قائمة الأجهزة المنزلية", []interface{}{})
		return
	}
	list, err := h.presetRepo.ListActive(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب قائمة الأجهزة المنزلية بنجاح", list)
}

func (h *CalculatorHandler) GetGovernorateSolarData(c *gin.Context) {
	if h.solarRepo == nil {
		utils.SuccessResponse(c, http.StatusOK, "بيانات المحافظات الشمسية", []interface{}{})
		return
	}
	list, err := h.solarRepo.ListAllSolarData(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب بيانات الإشعاع الشمسي للمحافظات بنجاح", list)
}

// Calculation Execution Handlers

func (h *CalculatorHandler) EstimateSystem(c *gin.Context) {
	var req domain.SolarCalculationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب الأحمال الشمسية غير صالحة", err)
		return
	}

	govID := 1 // Baghdad default
	if h.engine != nil {
		res := h.engine.CalculateSystemSizing(c.Request.Context(), req, govID)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب تقدير المنظومة الموصى بها ومطابقة المتاجر بنجاح", res)
		return
	}

	var userID *uuid.UUID
	if val, exists := c.Get("user_id"); exists {
		if uid, ok := val.(uuid.UUID); ok {
			userID = &uid
		}
	}

	recommendation := h.calcService.CalculateSystem(c.Request.Context(), req, userID)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب تقدير المنظومة الشمسية الموصى بها بنجاح", recommendation)
}

func (h *CalculatorHandler) ListUserCalculations(c *gin.Context) {
	val, exists := c.Get("user_id")
	if !exists {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	userID := val.(uuid.UUID)

	calcs, err := h.calcService.GetUserCalculations(c.Request.Context(), userID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب الحسابات المحفوظة بنجاح", calcs)
}

func (h *CalculatorHandler) CalculateROI(c *gin.Context) {
	var req domain.ROICalculationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب العائد والتوفير غير صالحة", err)
		return
	}
	res := h.calcService.CalculateROI(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب العائد على الاستثمار والتوفير بنجاح", res)
}

func (h *CalculatorHandler) CalculateBatteryRuntime(c *gin.Context) {
	var req domain.BatteryRuntimeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب تشغيل البطارية غير صالحة", err)
		return
	}
	if h.engine != nil {
		res := h.engine.CalculateBatteryRuntime(c.Request.Context(), req)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب ساعات تشغيل البطارية ومطابقة المتاجر بنجاح", res)
		return
	}
	res := h.calcService.CalculateBatteryRuntime(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب ساعات تشغيل البطارية بنجاح", res)
}

func (h *CalculatorHandler) CalculateApplianceConsumption(c *gin.Context) {
	var req domain.ApplianceConsumptionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب استهلاك الجهاز غير صالحة", err)
		return
	}
	res := h.calcService.CalculateApplianceConsumption(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب استهلاك الجهاز بنجاح", res)
}

func (h *CalculatorHandler) CalculateRoofCapacity(c *gin.Context) {
	var req domain.RoofCapacityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب مساحة السطح غير صالحة", err)
		return
	}
	if h.engine != nil {
		res := h.engine.CalculateRoofCapacity(c.Request.Context(), req)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب قدرة استيعاب السطح ومطابقة الألواح بنجاح", res)
		return
	}
	res := h.calcService.CalculateRoofCapacity(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب قدرة استيعاب السطح بنجاح", res)
}

func (h *CalculatorHandler) CalculateFullKitCost(c *gin.Context) {
	var req domain.FullKitCostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب تكلفة المنظومة الكاملة غير صالحة", err)
		return
	}
	if h.engine != nil {
		sysReq := domain.SolarCalculationRequest{
			DailyConsumptionkWh: req.SystemSizekW * 5.5,
			SystemVoltage:       48,
		}
		res := h.engine.CalculateSystemSizing(c.Request.Context(), sysReq, 1)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب كلفة المنظومة ومطابقة المتاجر بنجاح", res)
		return
	}
	res := h.calcService.CalculateFullKitCost(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب كلفة المنظومة ومطابقة المنتجات بنجاح", res)
}

func (h *CalculatorHandler) CalculateCableSizing(c *gin.Context) {
	var req domain.CableSizingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب سمك الكابلات غير صالحة", err)
		return
	}
	if h.engine != nil {
		res := h.engine.CalculateCableSizing(c.Request.Context(), req)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب سمك الكابل وهبوط الجهد بنجاح", res)
		return
	}
	res := h.calcService.CalculateCableSizing(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب سمك الكابل وهبوط الجهد بنجاح", res)
}

func (h *CalculatorHandler) CalculateMPPTString(c *gin.Context) {
	var req domain.MPPTStringRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب الـ String و MPPT غير صالحة", err)
		return
	}
	if h.engine != nil {
		res := h.engine.CalculateMPPTString(c.Request.Context(), req, 1)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب عدد الألواح للسلسلة وتأثير الحرارة بنجاح", res)
		return
	}
	res := h.calcService.CalculateMPPTString(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب عدد الألواح للسلسلة وتأثير الحرارة بنجاح", res)
}

func (h *CalculatorHandler) CalculateBreakersFuses(c *gin.Context) {
	var req domain.BreakerFuseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب القواطع والفيوزات غير صالحة", err)
		return
	}
	if h.engine != nil {
		res := h.engine.CalculateBreakersFuses(c.Request.Context(), req)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب أمبيرية القواطع والفيوزات بنجاح", res)
		return
	}
	res := h.calcService.CalculateBreakersFuses(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب أمبيرية القواطع والفيوزات بنجاح", res)
}

func (h *CalculatorHandler) CalculateBatteryBank(c *gin.Context) {
	var req domain.BatteryBankRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب توصيل بنك البطاريات غير صالحة", err)
		return
	}
	if h.engine != nil {
		res := h.engine.CalculateBatteryBank(c.Request.Context(), req)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب عدد وتوصيل البطاريات بنجاح", res)
		return
	}
	res := h.calcService.CalculateBatteryBank(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب عدد وتوصيل البطاريات بنجاح", res)
}

func (h *CalculatorHandler) CalculateSolarProduction(c *gin.Context) {
	var req domain.SolarProductionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب الإنتاجية الشمسية غير صالحة", err)
		return
	}
	if h.engine != nil {
		res := h.engine.CalculateSolarProduction(c.Request.Context(), req, 1)
		utils.SuccessResponse(c, http.StatusOK, "تم حساب الإنتاجية الشمسية المتوقعة للمحافظة بنجاح", res)
		return
	}
	res := h.calcService.CalculateSolarProduction(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب الإنتاجية الشمسية المتوقعة للمحافظة بنجاح", res)
}
