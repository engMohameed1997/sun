package repository

import (
	"context"
	"database/sql"

	"github.com/jmoiron/sqlx"

	"github.com/iraq-solar/api/internal/domain"
)

type CategoryRepository interface {
	ListAll(ctx context.Context) ([]domain.Category, error)
	GetByID(ctx context.Context, id int) (*domain.Category, error)
	Create(ctx context.Context, cat *domain.Category) error
	Update(ctx context.Context, cat *domain.Category) error
	Delete(ctx context.Context, id int) error
}

type postgresCategoryRepository struct {
	db *sqlx.DB
}

func NewCategoryRepository(db *sqlx.DB) CategoryRepository {
	return &postgresCategoryRepository{db: db}
}

func (r *postgresCategoryRepository) ListAll(ctx context.Context) ([]domain.Category, error) {
	if r.db == nil {
		return nil, nil
	}
	var categories []domain.Category
	query := `SELECT id, name, description, created_at FROM categories ORDER BY id ASC`
	err := r.db.SelectContext(ctx, &categories, query)
	return categories, err
}

func (r *postgresCategoryRepository) GetByID(ctx context.Context, id int) (*domain.Category, error) {
	if r.db == nil {
		return nil, nil
	}
	var cat domain.Category
	query := `SELECT id, name, description, created_at FROM categories WHERE id = $1`
	err := r.db.GetContext(ctx, &cat, query, id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &cat, err
}

func (r *postgresCategoryRepository) Create(ctx context.Context, cat *domain.Category) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO categories (name, description) VALUES ($1, $2) RETURNING id, created_at`
	return r.db.QueryRowContext(ctx, query, cat.Name, cat.Description).Scan(&cat.ID, &cat.CreatedAt)
}

func (r *postgresCategoryRepository) Update(ctx context.Context, cat *domain.Category) error {
	if r.db == nil {
		return nil
	}
	query := `UPDATE categories SET name = $1, description = $2 WHERE id = $3`
	_, err := r.db.ExecContext(ctx, query, cat.Name, cat.Description, cat.ID)
	return err
}

func (r *postgresCategoryRepository) Delete(ctx context.Context, id int) error {
	if r.db == nil {
		return nil
	}
	// Warning: We might need to handle products that use this category! 
	// For now, assume ON DELETE SET NULL or similar, or it restricts it.
	query := `DELETE FROM categories WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}
