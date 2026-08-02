package repository

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type BrandRepository interface {
	ListAll(ctx context.Context, onlyActive bool) ([]domain.Brand, error)
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Brand, error)
	Create(ctx context.Context, brand *domain.Brand) error
	Update(ctx context.Context, id uuid.UUID, req domain.UpdateBrandRequest) error
	Delete(ctx context.Context, id uuid.UUID) error
}

type postgresBrandRepository struct {
	db *sqlx.DB
}

func NewBrandRepository(db *sqlx.DB) BrandRepository {
	return &postgresBrandRepository{db: db}
}

func (r *postgresBrandRepository) ListAll(ctx context.Context, onlyActive bool) ([]domain.Brand, error) {
	if r.db == nil {
		return nil, nil
	}
	var brands []domain.Brand
	query := `SELECT * FROM brands WHERE 1=1`
	
	if onlyActive {
		query += ` AND is_active = true`
	}
	query += ` ORDER BY name ASC`
	
	err := r.db.SelectContext(ctx, &brands, query)
	return brands, err
}

func (r *postgresBrandRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.Brand, error) {
	if r.db == nil {
		return nil, nil
	}
	var brand domain.Brand
	query := `SELECT * FROM brands WHERE id = $1`
	err := r.db.GetContext(ctx, &brand, query, id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &brand, err
}

func (r *postgresBrandRepository) Create(ctx context.Context, brand *domain.Brand) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO brands (id, name, logo_url, is_active, created_at, updated_at) VALUES (:id, :name, :logo_url, :is_active, NOW(), NOW())`
	_, err := r.db.NamedExecContext(ctx, query, brand)
	return err
}

func (r *postgresBrandRepository) Update(ctx context.Context, id uuid.UUID, req domain.UpdateBrandRequest) error {
	if r.db == nil {
		return nil
	}

	var setParts []string
	var args []interface{}
	argID := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argID))
		args = append(args, *req.Name)
		argID++
	}
	if req.LogoURL != nil {
		setParts = append(setParts, fmt.Sprintf("logo_url = $%d", argID))
		args = append(args, *req.LogoURL)
		argID++
	}
	if req.IsActive != nil {
		setParts = append(setParts, fmt.Sprintf("is_active = $%d", argID))
		args = append(args, *req.IsActive)
		argID++
	}

	if len(setParts) == 0 {
		return nil
	}

	setParts = append(setParts, "updated_at = NOW()")
	query := fmt.Sprintf("UPDATE brands SET %s WHERE id = $%d", strings.Join(setParts, ", "), argID)
	args = append(args, id)

	_, err := r.db.ExecContext(ctx, query, args...)
	return err
}

func (r *postgresBrandRepository) Delete(ctx context.Context, id uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	query := `DELETE FROM brands WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}
