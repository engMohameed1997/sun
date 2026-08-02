package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type OrderService struct {
	orderRepo   repository.OrderRepository
	productRepo repository.ProductRepository
}

func NewOrderService(orderRepo repository.OrderRepository, productRepo repository.ProductRepository) *OrderService {
	return &OrderService{
		orderRepo:   orderRepo,
		productRepo: productRepo,
	}
}

func (s *OrderService) CreateOrder(ctx context.Context, userID uuid.UUID, req domain.CreateOrderRequest) (*domain.Order, error) {
	if len(req.Items) == 0 {
		return nil, errors.New("يجب تضمين منتج واحد على الأقل في الطلب")
	}

	orderID := uuid.New()
	var totalAmount float64
	var orderItems []domain.OrderItem

	for _, itemReq := range req.Items {
		var unitPrice float64 = 115.0 // Default price fallback

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
	}

	return newOrder, nil
}

func (s *OrderService) GetUserOrders(ctx context.Context, userID uuid.UUID) ([]domain.Order, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindByUserID(ctx, userID)
	}
	return []domain.Order{}, nil
}

func (s *OrderService) GetOrderByID(ctx context.Context, orderID uuid.UUID) (*domain.Order, error) {
	if s.orderRepo != nil {
		return s.orderRepo.FindByID(ctx, orderID)
	}
	return nil, nil
}

func (s *OrderService) UpdateOrderStatus(ctx context.Context, orderID uuid.UUID, status domain.OrderStatus) error {
	if s.orderRepo != nil {
		return s.orderRepo.UpdateStatus(ctx, orderID, status)
	}
	return nil
}

func (s *OrderService) CancelOrder(ctx context.Context, orderID uuid.UUID) error {
	if s.orderRepo != nil {
		return s.orderRepo.Cancel(ctx, orderID)
	}
	return nil
}

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
