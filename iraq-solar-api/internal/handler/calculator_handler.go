package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

type CalculatorHandler struct {
	calcService *service.SolarCalculatorService
}

func NewCalculatorHandler(calcService *service.SolarCalculatorService) *CalculatorHandler {
	return &CalculatorHandler{calcService: calcService}
}

func (h *CalculatorHandler) EstimateSystem(c *gin.Context) {
	var req domain.SolarCalculationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب الأحمال الشمسية غير صالحة", err)
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
	res := h.calcService.CalculateRoofCapacity(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب قدرة استيعاب السطح بنجاح", res)
}

func (h *CalculatorHandler) CalculateFullKitCost(c *gin.Context) {
	var req domain.FullKitCostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب تكلفة المنظومة الكاملة غير صالحة", err)
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
	res := h.calcService.CalculateCableSizing(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب سمك الكابل وهبوط الجهد بنجاح", res)
}

func (h *CalculatorHandler) CalculateMPPTString(c *gin.Context) {
	var req domain.MPPTStringRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب الـ String و MPPT غير صالحة", err)
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
	res := h.calcService.CalculateBreakersFuses(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب أمبيرية القواطع والفيوزات بنجاح", res)
}

func (h *CalculatorHandler) CalculateBatteryBank(c *gin.Context) {
	var req domain.BatteryBankRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات حساب توصيل بنك البطاريات غير صالحة", err)
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
	res := h.calcService.CalculateSolarProduction(c.Request.Context(), req)
	utils.SuccessResponse(c, http.StatusOK, "تم حساب الإنتاجية الشمسية المتوقعة للمحافظة بنجاح", res)
}

