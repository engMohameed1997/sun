package repository

import (
	"context"
	"database/sql"

	"github.com/jmoiron/sqlx"
	"github.com/iraq-solar/api/internal/domain"
)

type GovernorateRepository struct {
	db *sqlx.DB
}

func NewGovernorateRepository(db *sqlx.DB) *GovernorateRepository {
	return &GovernorateRepository{db: db}
}

func (r *GovernorateRepository) List(ctx context.Context) ([]domain.Governorate, error) {
	if r.db == nil {
		return []domain.Governorate{}, nil
	}
	var governorates []domain.Governorate
	err := r.db.SelectContext(ctx, &governorates, "SELECT id, name_ar, name_en, is_active, created_at FROM governorates ORDER BY id ASC")
	return governorates, err
}

func (r *GovernorateRepository) GetByID(ctx context.Context, id int) (*domain.Governorate, error) {
	if r.db == nil {
		return nil, nil
	}
	var g domain.Governorate
	err := r.db.GetContext(ctx, &g, "SELECT id, name_ar, name_en, is_active, created_at FROM governorates WHERE id = $1", id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &g, err
}

func (r *GovernorateRepository) Create(ctx context.Context, g *domain.Governorate) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO governorates (name_ar, name_en, is_active) 
              VALUES ($1, $2, $3) RETURNING id, created_at`
	return r.db.QueryRowContext(ctx, query, g.NameAr, g.NameEn, g.IsActive).Scan(&g.ID, &g.CreatedAt)
}

func (r *GovernorateRepository) Update(ctx context.Context, id int, nameAr, nameEn string) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE governorates SET name_ar = $1, name_en = $2 WHERE id = $3", nameAr, nameEn, id)
	return err
}

func (r *GovernorateRepository) ToggleActive(ctx context.Context, id int, isActive bool) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE governorates SET is_active = $1 WHERE id = $2", isActive, id)
	return err
}

func (r *GovernorateRepository) Delete(ctx context.Context, id int) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "DELETE FROM governorates WHERE id = $1", id)
	return err
}
