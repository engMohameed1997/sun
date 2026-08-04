package repository

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/jmoiron/sqlx"
)

type StoreRepository struct {
	db *sqlx.DB
}

func NewStoreRepository(db *sqlx.DB) *StoreRepository {
	return &StoreRepository{db: db}
}

// ─── STORES ─────────────────────────────────────────────────────────────

func (r *StoreRepository) CreateStore(ctx context.Context, store *domain.Store) error {
	query := `
		INSERT INTO stores (id, merchant_id, name, slug, description, logo_url, cover_url, phone, is_verified, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
		RETURNING created_at, updated_at
	`
	return r.db.QueryRowContext(ctx, query,
		store.ID, store.MerchantID, store.Name, store.Slug, store.Description, store.LogoURL, store.CoverURL, store.Phone, store.IsVerified, store.IsActive,
	).Scan(&store.CreatedAt, &store.UpdatedAt)
}

func (r *StoreRepository) GetStoreByID(ctx context.Context, id uuid.UUID) (*domain.Store, error) {
	var store domain.Store
	query := `SELECT id, merchant_id, name, slug, description, logo_url, cover_url, phone, is_verified, is_active, rating, total_ratings, created_at, updated_at FROM stores WHERE id = $1`
	err := r.db.GetContext(ctx, &store, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &store, nil
}

func (r *StoreRepository) GetStoreByMerchantID(ctx context.Context, merchantID uuid.UUID) (*domain.Store, error) {
	var store domain.Store
	query := `SELECT id, merchant_id, name, slug, description, logo_url, cover_url, phone, is_verified, is_active, rating, total_ratings, created_at, updated_at FROM stores WHERE merchant_id = $1 LIMIT 1`
	err := r.db.GetContext(ctx, &store, query, merchantID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &store, nil
}

func (r *StoreRepository) ListStores(ctx context.Context, search string, isVerified *bool, limit, offset int) ([]domain.Store, int, error) {
	query := `SELECT id, merchant_id, name, slug, description, logo_url, cover_url, phone, is_verified, is_active, rating, total_ratings, created_at, updated_at FROM stores WHERE 1=1`
	countQuery := `SELECT COUNT(*) FROM stores WHERE 1=1`
	var args []interface{}
	argID := 1

	if search != "" {
		query += fmt.Sprintf(` AND (name ILIKE $%d OR slug ILIKE $%d)`, argID, argID)
		countQuery += fmt.Sprintf(` AND (name ILIKE $%d OR slug ILIKE $%d)`, argID, argID)
		args = append(args, "%"+search+"%")
		argID++
	}

	if isVerified != nil {
		query += fmt.Sprintf(` AND is_verified = $%d`, argID)
		countQuery += fmt.Sprintf(` AND is_verified = $%d`, argID)
		args = append(args, *isVerified)
		argID++
	}

	var total int
	if err := r.db.GetContext(ctx, &total, countQuery, args...); err != nil {
		return nil, 0, err
	}

	query += fmt.Sprintf(` ORDER BY created_at DESC LIMIT $%d OFFSET $%d`, argID, argID+1)
	args = append(args, limit, offset)

	var stores []domain.Store
	if err := r.db.SelectContext(ctx, &stores, query, args...); err != nil {
		return nil, 0, err
	}

	return stores, total, nil
}

func (r *StoreRepository) UpdateStore(ctx context.Context, id uuid.UUID, req domain.UpdateStoreRequest) error {
	var setParts []string
	var args []interface{}
	argID := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argID))
		args = append(args, *req.Name)
		argID++
	}
	if req.Slug != nil {
		setParts = append(setParts, fmt.Sprintf("slug = $%d", argID))
		args = append(args, *req.Slug)
		argID++
	}
	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argID))
		args = append(args, *req.Description)
		argID++
	}
	if req.LogoURL != nil {
		setParts = append(setParts, fmt.Sprintf("logo_url = $%d", argID))
		args = append(args, *req.LogoURL)
		argID++
	}
	if req.CoverURL != nil {
		setParts = append(setParts, fmt.Sprintf("cover_url = $%d", argID))
		args = append(args, *req.CoverURL)
		argID++
	}
	if req.Phone != nil {
		setParts = append(setParts, fmt.Sprintf("phone = $%d", argID))
		args = append(args, *req.Phone)
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
	query := fmt.Sprintf("UPDATE stores SET %s WHERE id = $%d", strings.Join(setParts, ", "), argID)
	args = append(args, id)

	_, err := r.db.ExecContext(ctx, query, args...)
	return err
}

func (r *StoreRepository) DeleteStore(ctx context.Context, id uuid.UUID) error {
	// Let's do a hard delete for now since CASCADE takes care of relations. Or we can just set is_active to false.
	_, err := r.db.ExecContext(ctx, `DELETE FROM stores WHERE id = $1`, id)
	return err
}

func (r *StoreRepository) VerifyStore(ctx context.Context, id uuid.UUID, isVerified bool) error {
	_, err := r.db.ExecContext(ctx, `UPDATE stores SET is_verified = $1, updated_at = NOW() WHERE id = $2`, isVerified, id)
	return err
}

// ─── BRANCHES ──────────────────────────────────────────────────────────

func (r *StoreRepository) CreateBranch(ctx context.Context, branch *domain.StoreBranch) error {
	query := `
		INSERT INTO store_branches (id, store_id, name, governorate_id, city, address, phone, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
		RETURNING created_at, updated_at
	`
	return r.db.QueryRowContext(ctx, query,
		branch.ID, branch.StoreID, branch.Name, branch.GovernorateID, branch.City, branch.Address, branch.Phone, branch.IsActive,
	).Scan(&branch.CreatedAt, &branch.UpdatedAt)
}

func (r *StoreRepository) GetBranchByID(ctx context.Context, id uuid.UUID) (*domain.StoreBranch, error) {
	var branch domain.StoreBranch
	query := `
		SELECT b.*, g.name_ar AS governorate_name_ar, g.name_en AS governorate_name_en 
		FROM store_branches b
		LEFT JOIN governorates g ON b.governorate_id = g.id
		WHERE b.id = $1
	`
	err := r.db.GetContext(ctx, &branch, query, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &branch, nil
}

func (r *StoreRepository) ListStoreBranches(ctx context.Context, storeID uuid.UUID) ([]domain.StoreBranch, error) {
	var branches []domain.StoreBranch
	query := `
		SELECT b.*, g.name_ar AS governorate_name_ar, g.name_en AS governorate_name_en 
		FROM store_branches b
		LEFT JOIN governorates g ON b.governorate_id = g.id
		WHERE b.store_id = $1 ORDER BY b.created_at ASC
	`
	if err := r.db.SelectContext(ctx, &branches, query, storeID); err != nil {
		return nil, err
	}
	return branches, nil
}

func (r *StoreRepository) UpdateBranch(ctx context.Context, id uuid.UUID, req domain.UpdateBranchRequest) error {
	var setParts []string
	var args []interface{}
	argID := 1

	if req.Name != nil {
		setParts = append(setParts, fmt.Sprintf("name = $%d", argID))
		args = append(args, *req.Name)
		argID++
	}
	if req.GovernorateID != nil {
		setParts = append(setParts, fmt.Sprintf("governorate_id = $%d", argID))
		args = append(args, *req.GovernorateID)
		argID++
	}
	if req.City != nil {
		setParts = append(setParts, fmt.Sprintf("city = $%d", argID))
		args = append(args, *req.City)
		argID++
	}
	if req.Address != nil {
		setParts = append(setParts, fmt.Sprintf("address = $%d", argID))
		args = append(args, *req.Address)
		argID++
	}
	if req.Phone != nil {
		setParts = append(setParts, fmt.Sprintf("phone = $%d", argID))
		args = append(args, *req.Phone)
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
	query := fmt.Sprintf("UPDATE store_branches SET %s WHERE id = $%d", strings.Join(setParts, ", "), argID)
	args = append(args, id)

	_, err := r.db.ExecContext(ctx, query, args...)
	return err
}

func (r *StoreRepository) DeleteBranch(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM store_branches WHERE id = $1`, id)
	return err
}
