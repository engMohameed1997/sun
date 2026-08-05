package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/service"
	"github.com/iraq-solar/api/pkg/utils"
)

func parseServiceOrderFilters(c *gin.Context) domain.ServiceOrderFilters {
	f := domain.ServiceOrderFilters{
		Status:       c.Query("status"),
		OrderType:    c.Query("order_type"),
		TechnicianID: c.Query("technician_id"),
		Search:       c.Query("search"),
	}
	f.GovernorateID, _ = strconv.Atoi(c.Query("governorate_id"))
	f.Page, _ = strconv.Atoi(c.DefaultQuery("page", "1"))
	f.Limit, _ = strconv.Atoi(c.DefaultQuery("limit", "20"))
	return f
}

// --- Customer: service orders ---

// CreateServiceOrder receives a customer request and starts the dispatch engine.
func (h *WorkforceHandler) CreateServiceOrder(c *gin.Context) {
	userID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	var req domain.CreateServiceOrderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الطلب غير صالحة", err)
		return
	}

	order, err := h.dispatch.CreateServiceOrder(c.Request.Context(), &userID, req, nil)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	view, err := h.workforce.BuildCustomerView(c.Request.Context(), order)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم استلام طلبك، جاري البحث عن فني متوفر...", view)
}

// CreateServiceOrderFromCalculator turns a calculator result into a dispatched service order.
func (h *WorkforceHandler) CreateServiceOrderFromCalculator(c *gin.Context) {
	userID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	var req domain.CreateServiceOrderFromCalculatorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الطلب غير صالحة", err)
		return
	}

	order, err := h.dispatch.CreateServiceOrder(c.Request.Context(), &userID, req.CreateServiceOrderRequest, req.CalculatorResult)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	view, err := h.workforce.BuildCustomerView(c.Request.Context(), order)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم إنشاء طلب الخدمة من نتيجة الحاسبة", view)
}

// ListMyServiceOrders returns the customer's own service order history.
func (h *WorkforceHandler) ListMyServiceOrders(c *gin.Context) {
	userID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	orders, err := h.repo.ListCustomerServiceOrders(c.Request.Context(), userID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	views := make([]domain.CustomerServiceOrderView, 0, len(orders))
	for i := range orders {
		view, err := h.workforce.BuildCustomerView(c.Request.Context(), &orders[i])
		if err != nil {
			utils.InternalServerError(c, err)
			return
		}
		views = append(views, *view)
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب طلبات الخدمة", views)
}

// GetMyServiceOrder returns the privacy-safe tracking view of a single order.
func (h *WorkforceHandler) GetMyServiceOrder(c *gin.Context) {
	userID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	order, err := h.repo.GetServiceOrder(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		notFoundError(c, "الطلب غير موجود")
		return
	}
	if order.CustomerID == nil || *order.CustomerID != userID {
		utils.ForbiddenError(c, "هذا الطلب لا يخصك")
		return
	}

	view, err := h.workforce.BuildCustomerView(c.Request.Context(), order)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل الطلب", view)
}

// SubmitOrderReview stores the customer rating after completion.
func (h *WorkforceHandler) SubmitOrderReview(c *gin.Context) {
	userID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.SubmitReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التقييم غير صالحة", err)
		return
	}

	review, err := h.workforce.SubmitReview(c.Request.Context(), id, userID, req)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrServiceOrderNotFound):
			notFoundError(c, "الطلب غير موجود")
		case errors.Is(err, service.ErrForbiddenAction):
			utils.ForbiddenError(c, "هذا الطلب لا يخصك")
		default:
			utils.InternalServerError(c, err)
		}
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "شكراً لتقييمك", review)
}

// --- Technician: dispatch queue ---

// GetMyDispatchQueue lists live offers waiting for the technician's response.
func (h *WorkforceHandler) GetMyDispatchQueue(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	offers, err := h.repo.ListTechnicianOffers(c.Request.Context(), tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	for i := range offers {
		offers[i].EstimatedPayoutIQD = h.workforce.EstimatePayout(c.Request.Context(), offers[i].OrderType, offers[i].SystemSizeKW)
		offers[i].SelectionReasonAr = service.BuildSelectionReasonText(domain.TechnicianCandidate{
			FullName:           tech.FullName,
			Rating:             tech.Rating,
			CompletedJobsCount: tech.CompletedJobsCount,
			VerificationLevel:  tech.VerificationLevel,
			GovernorateName:    offers[i].GovernorateName,
		})
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب المهام المتاحة", offers)
}

// AcceptDispatch accepts an offer and locks the order to this technician.
func (h *WorkforceHandler) AcceptDispatch(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	dispatchID, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	order, err := h.dispatch.AcceptDispatch(c.Request.Context(), dispatchID, tech.ID)
	if err != nil {
		if errors.Is(err, service.ErrForbiddenAction) {
			utils.ForbiddenError(c, "هذه المهمة ليست موجهة لك")
			return
		}
		utils.BadRequestError(c, err.Error(), err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم قبول المهمة", order)
}

// RejectDispatch declines an offer and passes it to the next technician.
func (h *WorkforceHandler) RejectDispatch(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	dispatchID, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.RejectDispatchRequest
	_ = c.ShouldBindJSON(&req)

	if err := h.dispatch.RejectDispatch(c.Request.Context(), dispatchID, tech.ID, req.Reason); err != nil {
		if errors.Is(err, service.ErrForbiddenAction) {
			utils.ForbiddenError(c, "هذه المهمة ليست موجهة لك")
			return
		}
		utils.BadRequestError(c, err.Error(), err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم رفض المهمة", gin.H{"dispatch_id": dispatchID})
}

// --- Technician: assignments & execution ---

// ListMyAssignments returns accepted jobs with full order details.
func (h *WorkforceHandler) ListMyAssignments(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	assignments, err := h.repo.ListTechnicianAssignments(c.Request.Context(), tech.ID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب المهام المسندة", assignments)
}

// GetMyAssignmentDetail returns a single job with tasks and media.
func (h *WorkforceHandler) GetMyAssignmentDetail(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	orderID, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	ctx := c.Request.Context()

	order, err := h.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		notFoundError(c, "الطلب غير موجود")
		return
	}
	if order.AssignedTechnicianID == nil || *order.AssignedTechnicianID != tech.ID {
		utils.ForbiddenError(c, "هذه المهمة ليست مسندة لك")
		return
	}

	tasks, err := h.repo.ListJobTasks(ctx, orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	media, err := h.repo.ListJobMedia(ctx, orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	pricing, err := h.repo.GetPricing(ctx, orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	timeline, err := h.repo.GetStatusHistory(ctx, orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل المهمة", gin.H{
		"order":    order,
		"tasks":    tasks,
		"media":    media,
		"pricing":  pricing,
		"timeline": timeline,
	})
}

// UpdateJobStatus moves a job through its execution lifecycle.
func (h *WorkforceHandler) UpdateJobStatus(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	orderID, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpdateServiceOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الحالة غير صالحة", err)
		return
	}

	ctx := c.Request.Context()
	order, err := h.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		notFoundError(c, "الطلب غير موجود")
		return
	}
	if order.AssignedTechnicianID == nil || *order.AssignedTechnicianID != tech.ID {
		utils.ForbiddenError(c, "هذه المهمة ليست مسندة لك")
		return
	}

	switch req.Status {
	case domain.SvcStatusOnTheWay, domain.SvcStatusArrived, domain.SvcStatusWorking, domain.SvcStatusWaitingCustomer:
		if err := h.repo.UpdateOrderStatus(ctx, orderID, req.Status, &tech.UserID, req.Notes); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	case domain.SvcStatusCompleted:
		if err := h.workforce.CompleteOrder(ctx, orderID, &tech.UserID); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	default:
		utils.BadRequestError(c, "لا يمكن للفني تعيين هذه الحالة", nil)
		return
	}

	updated, err := h.repo.GetServiceOrder(ctx, orderID)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة المهمة", updated)
}

// ToggleJobTask flips a checklist item.
func (h *WorkforceHandler) ToggleJobTask(c *gin.Context) {
	if _, ok := h.currentTechnician(c); !ok {
		return
	}
	taskID, ok := parseUUIDParam(c, "task_id")
	if !ok {
		return
	}
	if err := h.repo.ToggleJobTask(c.Request.Context(), taskID); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث المهمة", gin.H{"task_id": taskID})
}

// AddJobMedia attaches a photo, note or signature to a job.
func (h *WorkforceHandler) AddJobMedia(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	orderID, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.AddJobMediaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات المرفق غير صالحة", err)
		return
	}

	media := &domain.JobMedia{
		ID:           uuid.New(),
		OrderID:      orderID,
		TechnicianID: &tech.ID,
		Type:         req.Type,
		URL:          req.URL,
		Content:      req.Content,
		Lat:          req.Lat,
		Lng:          req.Lng,
	}
	if err := h.repo.AddJobMedia(c.Request.Context(), media); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم رفع المرفق", media)
}

// MarkCustomerUnavailable records a customer no-show with GPS proof.
func (h *WorkforceHandler) MarkCustomerUnavailable(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	orderID, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.AddJobMediaRequest
	_ = c.ShouldBindJSON(&req)

	if err := h.workforce.MarkCustomerUnavailable(c.Request.Context(), orderID, tech.ID, req); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تسجيل عدم تجاوب الزبون", gin.H{"order_id": orderID})
}

// UpdateTracking stores the technician's latest GPS position for an active job.
func (h *WorkforceHandler) UpdateTracking(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	orderID, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpdateTrackingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الموقع غير صالحة", err)
		return
	}
	status := req.Status
	if status == "" {
		status = domain.TrackingOnTheWay
	}

	point := &domain.TechnicianTracking{
		ID:           uuid.New(),
		OrderID:      orderID,
		TechnicianID: tech.ID,
		Lat:          req.Lat,
		Lng:          req.Lng,
		Status:       status,
	}
	if err := h.repo.AddTrackingPoint(c.Request.Context(), point); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث الموقع", point)
}

// --- Technician: leads ---

// CreateLead submits a private customer the technician found outside the platform.
func (h *WorkforceHandler) CreateLead(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	var req domain.CreateLeadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات العميل غير صالحة", err)
		return
	}

	lead := &domain.TechnicianLead{
		ID:                uuid.New(),
		TechnicianID:      tech.ID,
		CustomerName:      req.CustomerName,
		CustomerPhone:     req.CustomerPhone,
		OrderType:         req.OrderType,
		Description:       req.Description,
		SystemSizeKW:      req.SystemSizeKW,
		GovernorateID:     req.GovernorateID,
		DistrictID:        req.DistrictID,
		Address:           req.Address,
		EstimatedPriceIQD: req.EstimatedPriceIQD,
		Status:            domain.LeadPendingReview,
	}
	if err := h.repo.CreateLead(c.Request.Context(), lead); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusCreated, "تم إرسال الطلب للمراجعة", lead)
}

// ListMyLeads returns the technician's submitted leads.
func (h *WorkforceHandler) ListMyLeads(c *gin.Context) {
	tech, ok := h.currentTechnician(c)
	if !ok {
		return
	}
	leads, err := h.repo.ListLeads(c.Request.Context(), &tech.ID, c.Query("status"))
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب طلباتك الخاصة", leads)
}

// --- Admin: service orders ---

// AdminListServiceOrders returns the paginated service order board.
func (h *WorkforceHandler) AdminListServiceOrders(c *gin.Context) {
	f := parseServiceOrderFilters(c)
	orders, total, err := h.repo.ListServiceOrders(c.Request.Context(), f)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	totalPages := 0
	if f.Limit > 0 {
		totalPages = (total + f.Limit - 1) / f.Limit
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب الطلبات الخدمية", domain.ServiceOrdersResponse{
		Orders:     orders,
		Total:      total,
		Page:       f.Page,
		Limit:      f.Limit,
		TotalPages: totalPages,
	})
}

// AdminGetServiceOrder returns an order with its dispatch queue, timeline and media.
func (h *WorkforceHandler) AdminGetServiceOrder(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	ctx := c.Request.Context()

	order, err := h.repo.GetServiceOrder(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	if order == nil {
		notFoundError(c, "الطلب غير موجود")
		return
	}

	queue, err := h.repo.GetDispatchQueue(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	timeline, err := h.repo.GetStatusHistory(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	tasks, err := h.repo.ListJobTasks(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	media, err := h.repo.ListJobMedia(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	pricing, err := h.repo.GetPricing(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	tracking, err := h.repo.GetLatestTracking(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "تم جلب تفاصيل الطلب", gin.H{
		"order":          order,
		"dispatch_queue": queue,
		"timeline":       timeline,
		"tasks":          tasks,
		"media":          media,
		"pricing":        pricing,
		"tracking":       tracking,
	})
}

// AdminGetDispatchQueue returns the dispatch attempts for a specific order.
func (h *WorkforceHandler) AdminGetDispatchQueue(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	queue, err := h.repo.GetDispatchQueue(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب طابور التوزيع", queue)
}

// AdminAssignTechnician assigns a technician manually, bypassing the dispatch engine.
func (h *WorkforceHandler) AdminAssignTechnician(c *gin.Context) {
	adminID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.ManualAssignRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التعيين غير صالحة", err)
		return
	}

	order, err := h.dispatch.ManualAssign(c.Request.Context(), id, req.TechnicianID, adminID)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrServiceOrderNotFound):
			notFoundError(c, "الطلب غير موجود")
		case errors.Is(err, service.ErrTechnicianNotFound):
			notFoundError(c, "الفني غير موجود")
		default:
			utils.InternalServerError(c, err)
		}
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تعيين الفني يدوياً", order)
}

// AdminRedispatchOrder reruns the dispatch engine for a stuck order.
func (h *WorkforceHandler) AdminRedispatchOrder(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	if err := h.dispatch.RedispatchOrder(c.Request.Context(), id); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	order, err := h.repo.GetServiceOrder(c.Request.Context(), id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم إعادة تشغيل التوزيع", order)
}

// AdminUpdateServiceOrderStatus overrides an order's status.
func (h *WorkforceHandler) AdminUpdateServiceOrderStatus(c *gin.Context) {
	adminID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpdateServiceOrderStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الحالة غير صالحة", err)
		return
	}

	ctx := c.Request.Context()
	if req.Status == domain.SvcStatusCompleted {
		if err := h.workforce.CompleteOrder(ctx, id, &adminID); err != nil {
			utils.InternalServerError(c, err)
			return
		}
	} else if err := h.repo.UpdateOrderStatus(ctx, id, req.Status, &adminID, req.Notes); err != nil {
		utils.InternalServerError(c, err)
		return
	}

	order, err := h.repo.GetServiceOrder(ctx, id)
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة الطلب", order)
}

// --- Admin: dispatch settings ---

// ListDispatchSettings returns the per-service-type dispatch configuration.
func (h *WorkforceHandler) ListDispatchSettings(c *gin.Context) {
	settings, err := h.repo.ListDispatchSettings(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب إعدادات التوزيع", settings)
}

// UpsertDispatchSettings creates or updates the dispatch behaviour for a service type.
func (h *WorkforceHandler) UpsertDispatchSettings(c *gin.Context) {
	var req domain.UpsertDispatchSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الإعدادات غير صالحة", err)
		return
	}
	if err := h.repo.UpsertDispatchSettings(c.Request.Context(), req); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	settings, err := h.repo.ListDispatchSettings(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم حفظ إعدادات التوزيع", settings)
}

// --- Admin: pricing ---

// AdminListPricing returns all pricing rows, optionally filtered by payment status.
func (h *WorkforceHandler) AdminListPricing(c *gin.Context) {
	list, err := h.repo.ListPricing(c.Request.Context(), c.Query("payment_status"))
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب بيانات التسعير", list)
}

// AdminSetPricing sets the base price and commission for an order.
func (h *WorkforceHandler) AdminSetPricing(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.SetPricingRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات التسعير غير صالحة", err)
		return
	}
	pricing, err := h.workforce.SetPricing(c.Request.Context(), id, req)
	if err != nil {
		if errors.Is(err, service.ErrServiceOrderNotFound) {
			notFoundError(c, "الطلب غير موجود")
			return
		}
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم حفظ تسعير الطلب", pricing)
}

// AdminUpdatePaymentStatus advances the payment lifecycle of an order.
func (h *WorkforceHandler) AdminUpdatePaymentStatus(c *gin.Context) {
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.UpdatePaymentStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequestError(c, "بيانات الدفع غير صالحة", err)
		return
	}
	if err := h.repo.UpdatePaymentStatus(c.Request.Context(), id, req.PaymentStatus); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم تحديث حالة الدفع", gin.H{"order_id": id, "payment_status": req.PaymentStatus})
}

// AdminListPriceTiers returns the reference price table per service type.
func (h *WorkforceHandler) AdminListPriceTiers(c *gin.Context) {
	tiers, err := h.repo.ListPriceTiers(c.Request.Context())
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب جدول الأسعار", tiers)
}

// --- Admin: leads ---

// AdminListLeads returns technician-submitted leads awaiting review.
func (h *WorkforceHandler) AdminListLeads(c *gin.Context) {
	leads, err := h.repo.ListLeads(c.Request.Context(), nil, c.Query("status"))
	if err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم جلب طلبات الفنيين", leads)
}

// AdminApproveLead converts a lead into a dispatched service order.
func (h *WorkforceHandler) AdminApproveLead(c *gin.Context) {
	adminID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	var req domain.ApproveLeadRequest
	_ = c.ShouldBindJSON(&req)

	order, err := h.dispatch.ApproveLead(c.Request.Context(), id, adminID, req)
	if err != nil {
		utils.BadRequestError(c, err.Error(), err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم قبول الطلب وتحويله لطلب خدمة", order)
}

// AdminRejectLead declines a technician lead.
func (h *WorkforceHandler) AdminRejectLead(c *gin.Context) {
	adminID, ok := currentUserID(c)
	if !ok {
		utils.UnauthorizedError(c, "غير مصرح")
		return
	}
	id, ok := parseUUIDParam(c, "id")
	if !ok {
		return
	}
	if err := h.repo.UpdateLeadStatus(c.Request.Context(), id, domain.LeadRejected, adminID, nil); err != nil {
		utils.InternalServerError(c, err)
		return
	}
	utils.SuccessResponse(c, http.StatusOK, "تم رفض الطلب", gin.H{"lead_id": id})
}
