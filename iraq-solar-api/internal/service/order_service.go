package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/hub"
	"github.com/iraq-solar/api/internal/repository"
)

type OrderService struct {
	orderRepo           repository.OrderRepository
	productRepo         repository.ProductRepository
	hub                 *hub.RealtimeHub
	notificationService *NotificationService
}

func NewOrderService(
	orderRepo repository.OrderRepository,
	productRepo repository.ProductRepository,
	realtimeHub *hub.RealtimeHub,
	notificationService *NotificationService,
) *OrderService {
	return &OrderService{
		orderRepo:           orderRepo,
		productRepo:         productRepo,
		hub:                 realtimeHub,
		notificationService: notificationService,
	}
}

// CreateOrder creates a new order and broadcasts it to connected admins via WebSocket.
func (s *OrderService) CreateOrder(ctx context.Context, userID uuid.UUID, req domain.CreateOrderRequest) (*domain.Order, error) {
	if len(req.Items) == 0 {
		return nil, errors.New("يجب تضمين منتج واحد على الأقل في الطلب")
	}

	orderID := uuid.New()
	var totalAmount float64
	var orderItems []domain.OrderItem

	for _, itemReq := range req.Items {
		var unitPrice float64 = 115.0 // Default fallback
		itemStoreID := itemReq.StoreID
		itemBranchID := itemReq.BranchID

		if s.productRepo != nil {
			product, err := s.productRepo.FindByID(ctx, itemReq.ProductID)
			if err == nil && product != nil {
				unitPrice = product.PriceIQD
				if itemStoreID == nil {
					itemStoreID = product.StoreID
				}
				if itemBranchID == nil {
					itemBranchID = product.BranchID
				}
			}
		}

		itemTotal := unitPrice * float64(itemReq.Quantity)
		totalAmount += itemTotal

		orderItems = append(orderItems, domain.OrderItem{
			ID:            uuid.New(),
			OrderID:       orderID,
			ProductID:     itemReq.ProductID,
			StoreID:       itemStoreID,
			BranchID:      itemBranchID,
			Quantity:      itemReq.Quantity,
			UnitPriceIQD:  unitPrice,
			TotalPriceIQD: itemTotal,
		})
	}

	paymentMethod := req.PaymentMethod
	if paymentMethod == "" {
		paymentMethod = "cash_on_delivery"
	}

	// Derive store_id & branch_id from first item if not set at order level
	orderStoreID := req.StoreID
	if orderStoreID == nil && len(orderItems) > 0 && orderItems[0].StoreID != nil {
		orderStoreID = orderItems[0].StoreID
	}

	orderBranchID := req.BranchID
	if orderBranchID == nil && len(orderItems) > 0 && orderItems[0].BranchID != nil {
		orderBranchID = orderItems[0].BranchID
	}

	newOrder := &domain.Order{
		ID:              orderID,
		UserID:          userID,
		StoreID:         orderStoreID,
		BranchID:        orderBranchID,
		Status:          domain.StatusPending,
		TotalAmountIQD:  totalAmount,
		ShippingAddress: req.ShippingAddress,
		PaymentMethod:   paymentMethod,
		PaymentStatus:   "unpaid",
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
		Items:           orderItems,
	}

	if s.orderRepo != nil {
		if err := s.orderRepo.Create(ctx, newOrder, orderItems); err != nil {
			return nil, err
		}

		// Broadcast new order to all admins via WebSocket
		if s.hub != nil {
			go func() {
				if full, err := s.orderRepo.FindFullByID(context.Background(), orderID); err == nil && full != nil {
					s.hub.BroadcastToAdmins(hub.MsgOrder, hub.EventOrderCreated, full)
					// If store-specific, also broadcast to the merchant
					if full.StoreID != nil {
						s.hub.BroadcastToMerchant(full.StoreID.String(), hub.MsgOrder, hub.EventOrderCreated, full)
					}
				}
			}()
		}
	}

	return newOrder, nil
}

// GetUserOrders returns all orders for a given user (full with store/branch info).
func (s *OrderService) GetUserOrders(ctx context.Context, userID uuid.UUID) ([]domain.OrderFull, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindFullByUserID(ctx, userID)
	}
	return []domain.OrderFull{}, nil
}

// GetOrderByID returns a full order by ID with all related data (store, branch, items).
func (s *OrderService) GetOrderByID(ctx context.Context, orderID uuid.UUID) (*domain.OrderFull, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindFullByID(ctx, orderID)
	}
	return nil, nil
}

// GetOrderFullByID returns a full order with all related data.
func (s *OrderService) GetOrderFullByID(ctx context.Context, orderID uuid.UUID) (*domain.OrderFull, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindFullByID(ctx, orderID)
	}
	return nil, nil
}

// GetAdminOrders returns a paginated, filtered list of all orders (for admin use).
func (s *OrderService) GetAdminOrders(ctx context.Context, filters domain.AdminOrderFilters) (*domain.AdminOrdersResponse, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindAllAdmin(ctx, filters)
	}
	return &domain.AdminOrdersResponse{Orders: []domain.OrderFull{}, Page: 1, Limit: 20}, nil
}

// UpdateOrderStatus updates the status and broadcasts the change via WebSocket.
func (s *OrderService) UpdateOrderStatus(ctx context.Context, orderID uuid.UUID, status domain.OrderStatus, notes string, changedBy *uuid.UUID) error {
	if s.orderRepo == nil {
		return nil
	}

	// Get order before update for broadcast payload and user notification
	var fromStatus domain.OrderStatus
	var orderUserID uuid.UUID
	if current, err := s.orderRepo.FindByID(ctx, orderID); err == nil && current != nil {
		fromStatus = current.Status
		orderUserID = current.UserID
	}

	if err := s.orderRepo.UpdateStatus(ctx, orderID, status, notes, changedBy); err != nil {
		return err
	}

	// Broadcast status change to admins via WebSocket
	if s.hub != nil {
		changedByStr := ""
		if changedBy != nil {
			changedByStr = changedBy.String()
		}
		payload := domain.OrderStatusChangedPayload{
			OrderID:    orderID,
			FromStatus: fromStatus,
			ToStatus:   status,
			ChangedBy:  changedByStr,
			Notes:      notes,
			UpdatedAt:  time.Now(),
		}
		go s.hub.BroadcastToAdmins(hub.MsgOrder, hub.EventOrderStatusChanged, payload)
		// Also broadcast to the user who owns the order
		go s.hub.BroadcastToUser(orderUserID.String(), hub.MsgOrder, hub.EventOrderStatusChanged, payload)
	}

	// Create notification for the user
	if s.notificationService != nil && orderUserID != uuid.Nil {
		go func() {
			title := "تحديث حالة الطلب 📦"
			body := fmt.Sprintf("تم تغيير حالة طلبك إلى: %s", translateOrderStatus(status))
			if notes != "" {
				body += " — " + notes
			}
			dataMap := map[string]interface{}{
				"order_id":    orderID.String(),
				"from_status": string(fromStatus),
				"to_status":   string(status),
			}
			data, _ := json.Marshal(dataMap)
			_, _ = s.notificationService.Create(context.Background(), orderUserID, domain.NotificationTypeOrderStatus, title, body, data)
		}()
	}

	return nil
}

func translateOrderStatus(status domain.OrderStatus) string {
	switch status {
	case domain.StatusPending:
		return "قيد الانتظار"
	case domain.StatusConfirmed:
		return "تم تأكيد الطلب"
	case domain.StatusProcessing:
		return "قيد التجهيز والمعالجة"
	case domain.StatusReadyForPickup:
		return "جاهز للاستلام من الفرع"
	case domain.StatusDelivered:
		return "تم التوصيل"
	case domain.StatusCompleted:
		return "تم مكتمل / تم التسليم بنجاح"
	case domain.StatusCancelled:
		return "تم إلغاء الطلب"
	default:
		return string(status)
	}
}

// CancelOrder cancels an order and broadcasts the update.
func (s *OrderService) CancelOrder(ctx context.Context, orderID uuid.UUID) error {
	if s.orderRepo != nil {
		// Get order before cancel for user notification
		var orderUserID uuid.UUID
		if current, err := s.orderRepo.FindByID(ctx, orderID); err == nil && current != nil {
			orderUserID = current.UserID
		}

		if err := s.orderRepo.Cancel(ctx, orderID); err != nil {
			return err
		}
		if s.hub != nil {
			payload := domain.OrderStatusChangedPayload{
				OrderID:   orderID,
				ToStatus:  domain.StatusCancelled,
				Notes:     "تم إلغاء الطلب",
				UpdatedAt: time.Now(),
			}
			go s.hub.BroadcastToAdmins(hub.MsgOrder, hub.EventOrderCancelled, payload)
			// Also notify the user
			if orderUserID != uuid.Nil {
				go s.hub.BroadcastToUser(orderUserID.String(), hub.MsgOrder, hub.EventOrderCancelled, payload)
			}
		}

		// Create notification for the user
		if s.notificationService != nil && orderUserID != uuid.Nil {
			go func() {
				dataMap := map[string]interface{}{"order_id": orderID.String()}
				data, _ := json.Marshal(dataMap)
				_, _ = s.notificationService.Create(context.Background(), orderUserID, domain.NotificationTypeOrderStatus, "تم إلغاء الطلب ⚠️", "تم إلغاء طلبك بنجاح", data)
			}()
		}
	}
	return nil
}

// StartPendingOrdersCleanupCron cancels expired pending orders on a schedule.
func (s *OrderService) StartPendingOrdersCleanupCron(ctx context.Context, interval time.Duration, expiryHours int) {
	ticker := time.NewTicker(interval)
	go func() {
		for {
			select {
			case <-ctx.Done():
				ticker.Stop()
				return
			case <-ticker.C:
				if s.orderRepo != nil {
					_, _ = s.orderRepo.CancelExpiredPendingOrders(ctx, expiryHours)
				}
			}
		}
	}()
}
