package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/hub"
	"github.com/iraq-solar/api/internal/repository"
)

type OrderService struct {
	orderRepo   repository.OrderRepository
	productRepo repository.ProductRepository
	hub         *hub.OrderHub
}

func NewOrderService(
	orderRepo repository.OrderRepository,
	productRepo repository.ProductRepository,
	orderHub *hub.OrderHub,
) *OrderService {
	return &OrderService{
		orderRepo:   orderRepo,
		productRepo: productRepo,
		hub:         orderHub,
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

		if s.productRepo != nil {
			product, err := s.productRepo.FindByID(ctx, itemReq.ProductID)
			if err == nil && product != nil {
				unitPrice = product.PriceIQD
			}
		}

		itemTotal := unitPrice * float64(itemReq.Quantity)
		totalAmount += itemTotal

		orderItems = append(orderItems, domain.OrderItem{
			ID:            uuid.New(),
			OrderID:       orderID,
			ProductID:     itemReq.ProductID,
			StoreID:       itemReq.StoreID,
			BranchID:      itemReq.BranchID,
			Quantity:      itemReq.Quantity,
			UnitPriceIQD:  unitPrice,
			TotalPriceIQD: itemTotal,
		})
	}

	paymentMethod := req.PaymentMethod
	if paymentMethod == "" {
		paymentMethod = "cash_on_delivery"
	}

	newOrder := &domain.Order{
		ID:              orderID,
		UserID:          userID,
		StoreID:         req.StoreID,
		BranchID:        req.BranchID,
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
				if full, err := s.orderRepo.FindFullByID(ctx, orderID); err == nil && full != nil {
					s.hub.BroadcastToAdmins(hub.MsgOrderNew, full)
					// If store-specific, also broadcast to the merchant
					if full.StoreID != nil {
						s.hub.BroadcastToMerchant(full.StoreID.String(), hub.MsgOrderNew, full)
					}
				}
			}()
		}
	}

	return newOrder, nil
}

// GetUserOrders returns all orders for a given user.
func (s *OrderService) GetUserOrders(ctx context.Context, userID uuid.UUID) ([]domain.Order, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindByUserID(ctx, userID)
	}
	return []domain.Order{}, nil
}

// GetOrderByID returns a simple order by ID.
func (s *OrderService) GetOrderByID(ctx context.Context, orderID uuid.UUID) (*domain.Order, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindByID(ctx, orderID)
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

	// Get current status before update for the broadcast payload
	var fromStatus domain.OrderStatus
	if current, err := s.orderRepo.FindByID(ctx, orderID); err == nil && current != nil {
		fromStatus = current.Status
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
		go s.hub.BroadcastToAdmins(hub.MsgOrderStatusChanged, payload)
	}

	return nil
}

// CancelOrder cancels an order and broadcasts the update.
func (s *OrderService) CancelOrder(ctx context.Context, orderID uuid.UUID) error {
	if s.orderRepo != nil {
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
			go s.hub.BroadcastToAdmins(hub.MsgOrderCancelled, payload)
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
