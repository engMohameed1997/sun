package repository

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/iraq-solar/api/internal/domain"
)

type BannerRepository struct {
	db *sqlx.DB
}

func NewBannerRepository(db *sqlx.DB) *BannerRepository {
	return &BannerRepository{db: db}
}

// ─── Home Banners (Admin controlled) ───

func (r *BannerRepository) ListHomeBanners(ctx context.Context) ([]domain.HomeBanner, error) {
	if r.db == nil {
		return []domain.HomeBanner{}, nil
	}
	var banners []domain.HomeBanner
	err := r.db.SelectContext(ctx, &banners, "SELECT * FROM home_banners ORDER BY display_order ASC, created_at DESC")
	return banners, err
}

func (r *BannerRepository) GetHomeBannerByID(ctx context.Context, id uuid.UUID) (*domain.HomeBanner, error) {
	if r.db == nil {
		return nil, nil
	}
	var b domain.HomeBanner
	err := r.db.GetContext(ctx, &b, "SELECT * FROM home_banners WHERE id = $1", id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &b, err
}

func (r *BannerRepository) CreateHomeBanner(ctx context.Context, b *domain.HomeBanner) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO home_banners (id, title, subtitle, image_url, link_url, display_order, is_active, starts_at, ends_at)
			  VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING created_at`
	return r.db.QueryRowContext(ctx, query, b.ID, b.Title, b.Subtitle, b.ImageURL, b.LinkURL, b.DisplayOrder, b.IsActive, b.StartsAt, b.EndsAt).Scan(&b.CreatedAt)
}

func (r *BannerRepository) UpdateHomeBanner(ctx context.Context, id uuid.UUID, title, subtitle, imageURL, linkURL string, displayOrder int, isActive bool) error {
	if r.db == nil {
		return nil
	}
	query := `UPDATE home_banners SET title=$1, subtitle=$2, image_url=$3, link_url=$4, display_order=$5, is_active=$6 WHERE id=$7`
	_, err := r.db.ExecContext(ctx, query, title, subtitle, imageURL, linkURL, displayOrder, isActive, id)
	return err
}

func (r *BannerRepository) DeleteHomeBanner(ctx context.Context, id uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "DELETE FROM home_banners WHERE id = $1", id)
	return err
}

// ─── Store Banners (Merchant & Admin controlled) ───

func (r *BannerRepository) ListStoreBanners(ctx context.Context, merchantID uuid.UUID) ([]domain.StoreBanner, error) {
	if r.db == nil {
		return []domain.StoreBanner{}, nil
	}
	var banners []domain.StoreBanner
	err := r.db.SelectContext(ctx, &banners, "SELECT * FROM store_banners WHERE merchant_id = $1 ORDER BY created_at DESC", merchantID)
	return banners, err
}

func (r *BannerRepository) CreateStoreBanner(ctx context.Context, b *domain.StoreBanner) error {
	if r.db == nil {
		return nil
	}
	query := `INSERT INTO store_banners (id, merchant_id, title, image_url, is_active)
			  VALUES ($1, $2, $3, $4, $5) RETURNING created_at`
	return r.db.QueryRowContext(ctx, query, b.ID, b.MerchantID, b.Title, b.ImageURL, b.IsActive).Scan(&b.CreatedAt)
}

func (r *BannerRepository) UpdateStoreBanner(ctx context.Context, id uuid.UUID, title string, isActive bool) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "UPDATE store_banners SET title=$1, is_active=$2 WHERE id=$3", title, isActive, id)
	return err
}

func (r *BannerRepository) DeleteStoreBanner(ctx context.Context, id uuid.UUID) error {
	if r.db == nil {
		return nil
	}
	_, err := r.db.ExecContext(ctx, "DELETE FROM store_banners WHERE id = $1", id)
	return err
}
