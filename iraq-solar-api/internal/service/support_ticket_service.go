package service

import (
	"context"
	"time"

	"github.com/google/uuid"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type SupportTicketService struct {
	repo repository.SupportTicketRepository
}

func NewSupportTicketService(repo repository.SupportTicketRepository) *SupportTicketService {
	return &SupportTicketService{repo: repo}
}

func (s *SupportTicketService) CreateTicket(ctx context.Context, userID uuid.UUID, req domain.CreateTicketRequest) (*domain.SupportTicket, error) {
	subject := req.Subject
	if subject == "" {
		subject = "بلاغ / استفسار عام"
	}

	ticket := &domain.SupportTicket{
		ID:        uuid.New(),
		UserID:    userID,
		Subject:   subject,
		Message:   req.Message,
		Status:    "open",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if s.repo != nil {
		if err := s.repo.Create(ctx, ticket); err != nil {
			return nil, err
		}
	}

	return ticket, nil
}

func (s *SupportTicketService) GetUserTickets(ctx context.Context, userID uuid.UUID) ([]domain.SupportTicket, error) {
	if s.repo != nil {
		return s.repo.FindByUserID(ctx, userID)
	}
	return []domain.SupportTicket{}, nil
}
