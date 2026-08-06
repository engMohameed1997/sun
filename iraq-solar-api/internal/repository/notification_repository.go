package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/iraq-solar/api/internal/domain"
)

type NotificationRepository struct {
	db *sqlx.DB
}

func NewNotificationRepository(db *sqlx.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

func (r *NotificationRepository) Create(ctx context.Context, n *domain.Notification) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO notifications (id, recipient_id, type, title, body, data, is_read) 
			  VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING created_at`
	return r.db.QueryRowContext(ctx, query, n.ID, n.RecipientID, n.Type, n.Title, n.Body, n.Data, n.IsRead).Scan(&n.CreatedAt)
}

func (r *NotificationRepository) ListByRecipient(ctx context.Context, recipientID uuid.UUID, page, perPage int) ([]domain.Notification, int, error) {
	if r.db == nil {
		return []domain.Notification{}, 0, nil
	}
	offset := (page - 1) * perPage

	var total int
	_ = r.db.GetContext(ctx, &total, "SELECT COUNT(*) FROM notifications WHERE recipient_id = $1", recipientID)

	notifications := make([]domain.Notification, 0)
	err := r.db.SelectContext(ctx, &notifications, `SELECT * FROM notifications WHERE recipient_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`, recipientID, perPage, offset)
	if notifications == nil {
		notifications = make([]domain.Notification, 0)
	}
	return notifications, total, err
}

func (r *NotificationRepository) MarkAsRead(ctx context.Context, id, recipientID uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE notifications SET is_read = true WHERE id = $1 AND recipient_id = $2", id, recipientID)
	return err
}

func (r *NotificationRepository) MarkAllAsRead(ctx context.Context, recipientID uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE notifications SET is_read = true WHERE recipient_id = $1", recipientID)
	return err
}

func (r *NotificationRepository) CountUnread(ctx context.Context, recipientID uuid.UUID) (int, error) {
	if r.db == nil {
		return 0, nil
	}
	var count int
	err := r.db.GetContext(ctx, &count, "SELECT COUNT(*) FROM notifications WHERE recipient_id = $1 AND is_read = false", recipientID)
	return count, err
}

func (r *NotificationRepository) Delete(ctx context.Context, id, recipientID uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "DELETE FROM notifications WHERE id = $1 AND recipient_id = $2", id, recipientID)
	return err
}
