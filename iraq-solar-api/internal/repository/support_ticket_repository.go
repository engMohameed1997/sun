package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type SupportTicketRepository interface {
	Create(ctx context.Context, ticket *domain.SupportTicket) error
	FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.SupportTicket, error)
}

type postgresSupportTicketRepository struct {
	db *sqlx.DB
}

func NewSupportTicketRepository(db *sqlx.DB) SupportTicketRepository {
	return &postgresSupportTicketRepository{db: db}
}

func (r *postgresSupportTicketRepository) Create(ctx context.Context, ticket *domain.SupportTicket) error {
	if r.db == nil {
		return nil
	}

	query := `
		INSERT INTO support_tickets (id, user_id, subject, message, status, response, created_at, updated_at)
		VALUES (:id, :user_id, :subject, :message, :status, :response, :created_at, :updated_at)
	`
	_, err := r.db.NamedExecContext(ctx, query, ticket)
	if err != nil {
		return fmt.Errorf("failed to insert support ticket: %w", err)
	}
	return nil
}

func (r *postgresSupportTicketRepository) FindByUserID(ctx context.Context, userID uuid.UUID) ([]domain.SupportTicket, error) {
	if r.db == nil {
		return []domain.SupportTicket{}, nil
	}

	var tickets []domain.SupportTicket
	query := `SELECT id, user_id, subject, message, status, response, created_at, updated_at FROM support_tickets WHERE user_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &tickets, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user support tickets: %w", err)
	}
	if tickets == nil {
		tickets = []domain.SupportTicket{}
	}
	return tickets, nil
}
