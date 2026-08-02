package repository

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type UserRepository interface {
	Create(ctx context.Context, user *domain.User) error
	FindByEmail(ctx context.Context, email string) (*domain.User, error)
	FindByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
	ListByRole(ctx context.Context, roles []string, governorate, search string, page, perPage int) ([]domain.User, int, error)
	Update(ctx context.Context, user *domain.User) error
	UpdatePassword(ctx context.Context, id uuid.UUID, passwordHash string) error
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

func (r *postgresUserRepository) ListByRole(ctx context.Context, roles []string, governorate, search string, page, perPage int) ([]domain.User, int, error) {
	if r.db == nil {
		return []domain.User{}, 0, nil
	}

	var conditions []string
	var args []interface{}
	argID := 1

	if len(roles) > 0 {
		var rolePlaceholders []string
		for _, role := range roles {
			rolePlaceholders = append(rolePlaceholders, fmt.Sprintf("$%d", argID))
			args = append(args, role)
			argID++
		}
		conditions = append(conditions, fmt.Sprintf("role IN (%s)", strings.Join(rolePlaceholders, ", ")))
	}
	
	conditions = append(conditions, "deleted_at IS NULL", "is_active = true")

	if governorate != "" {
		conditions = append(conditions, fmt.Sprintf("governorate = $%d", argID))
		args = append(args, governorate)
		argID++
	}

	if search != "" {
		conditions = append(conditions, fmt.Sprintf("full_name ILIKE $%d", argID))
		args = append(args, "%"+search+"%")
		argID++
	}

	whereClause := "WHERE " + strings.Join(conditions, " AND ")

	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM users %s", whereClause)
	var total int
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to count users: %w", err)
	}

	offset := (page - 1) * perPage
	query := fmt.Sprintf(`SELECT id, full_name, COALESCE(email, '') AS email, COALESCE(phone, '') AS phone, password_hash, role, COALESCE(governorate, '') AS governorate, COALESCE(city, '') AS city, is_active, created_at, updated_at FROM users %s ORDER BY created_at DESC LIMIT $%d OFFSET $%d`, whereClause, argID, argID+1)
	args = append(args, perPage, offset)

	var users []domain.User
	if err := r.db.SelectContext(ctx, &users, query, args...); err != nil {
		return nil, 0, fmt.Errorf("failed to list users by role: %w", err)
	}

	return users, total, nil
}

func (r *postgresUserRepository) Update(ctx context.Context, user *domain.User) error {
	if r.db == nil {
		return nil
	}
	query := `UPDATE users SET full_name=$1, phone=$2, governorate=$3, city=$4, updated_at=$5 WHERE id=$6`
	_, err := r.db.ExecContext(ctx, query, user.FullName, user.Phone, user.Governorate, user.City, user.UpdatedAt, user.ID)
	if err != nil {
		return fmt.Errorf("failed to update user: %w", err)
	}
	return nil
}

func (r *postgresUserRepository) UpdatePassword(ctx context.Context, id uuid.UUID, passwordHash string) error {
	if r.db == nil {
		return nil
	}
	query := `UPDATE users SET password_hash=$1, updated_at=$2 WHERE id=$3`
	_, err := r.db.ExecContext(ctx, query, passwordHash, time.Now(), id)
	if err != nil {
		return fmt.Errorf("failed to update user password: %w", err)
	}
	return nil
}
