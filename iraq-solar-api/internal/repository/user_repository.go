package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type UserRepository interface {
	Create(ctx context.Context, user *domain.User) error
	FindByEmail(ctx context.Context, email string) (*domain.User, error)
	FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
}

type postgresUserRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) UserRepository {
	return &postgresUserRepository{db: db}
}

func (r *postgresUserRepository) Create(ctx context.Context, user *domain.User) error {
	if r.db == nil {
		// Standalone / offline mode: user is processed in memory
		return nil
	}

	query := `
		INSERT INTO users (id, full_name, email, phone, password_hash, role, governorate, city, is_active, created_at, updated_at)
		VALUES (:id, :full_name, :email, :phone, :password_hash, :role, :governorate, :city, :is_active, :created_at, :updated_at)
	`

	_, err := r.db.NamedExecContext(ctx, query, user)
	if err != nil {
		return fmt.Errorf("failed to insert user: %w", err)
	}
	return nil
}

func (r *postgresUserRepository) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
	if r.db == nil {
		return nil, nil
	}

	var user domain.User
	query := `SELECT id, full_name, COALESCE(email, '') AS email, COALESCE(phone, '') AS phone, password_hash, role, COALESCE(governorate, '') AS governorate, COALESCE(city, '') AS city, is_active, created_at, updated_at FROM users WHERE email = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &user, query, email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil // Return nil if not found
		}
		return nil, fmt.Errorf("failed to query user by email: %w", err)
	}
	return &user, nil
}

func (r *postgresUserRepository) FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	if r.db == nil {
		return nil, nil
	}

	var user domain.User
	query := `SELECT id, full_name, COALESCE(email, '') AS email, COALESCE(phone, '') AS phone, password_hash, role, COALESCE(governorate, '') AS governorate, COALESCE(city, '') AS city, is_active, created_at, updated_at FROM users WHERE id = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &user, query, id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to query user by id: %w", err)
	}
	return &user, nil
}
