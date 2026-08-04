package service

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type StoreService struct {
	storeRepo *repository.StoreRepository
	userRepo  repository.UserRepository
}

func NewStoreService(storeRepo *repository.StoreRepository, userRepo repository.UserRepository) *StoreService {
	return &StoreService{
		storeRepo: storeRepo,
		userRepo:  userRepo,
	}
}

// generateSlug creates a simple url-friendly slug from a string
func generateSlug(name string) string {
	slug := strings.ToLower(name)
	slug = strings.ReplaceAll(slug, " ", "-")
	return slug
}

// ─── STORES ─────────────────────────────────────────────────────────────

func (s *StoreService) CreateStore(ctx context.Context, req domain.CreateStoreRequest) (*domain.Store, error) {
	// Verify merchant exists and is a merchant
	merchant, err := s.userRepo.FindByID(ctx, req.MerchantID)
	if err != nil {
		return nil, fmt.Errorf("failed to get merchant: %w", err)
	}
	if merchant == nil {
		return nil, errors.New("merchant not found")
	}
	if merchant.Role != domain.RoleMerchant {
		return nil, errors.New("user is not a merchant")
	}

	// Check if merchant already has a store
	existingStore, err := s.storeRepo.GetStoreByMerchantID(ctx, req.MerchantID)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing store: %w", err)
	}
	if existingStore != nil {
		return nil, errors.New("merchant already has a store")
	}

	slug := req.Slug
	if slug == "" {
		slug = generateSlug(req.Name) + "-" + uuid.New().String()[:8]
	}

	store := &domain.Store{
		ID:         uuid.New(),
		MerchantID: req.MerchantID,
		Name:       req.Name,
		Slug:       slug,
		IsVerified: false,
		IsActive:   true,
	}

	if req.Description != "" {
		store.Description = &req.Description
	}
	if req.LogoURL != "" {
		store.LogoURL = &req.LogoURL
	}
	if req.CoverURL != "" {
		store.CoverURL = &req.CoverURL
	}
	if req.Phone != "" {
		store.Phone = &req.Phone
	}
	if err := s.storeRepo.CreateStore(ctx, store); err != nil {
		return nil, fmt.Errorf("failed to create store: %w", err)
	}

	return store, nil
}

func (s *StoreService) GetStoreByID(ctx context.Context, id uuid.UUID) (*domain.Store, error) {
	store, err := s.storeRepo.GetStoreByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get store: %w", err)
	}
	if store == nil {
		return nil, errors.New("store not found")
	}

	// Get branches
	branches, err := s.storeRepo.ListStoreBranches(ctx, id)
	if err == nil {
		store.Branches = branches
	}

	return store, nil
}

func (s *StoreService) GetStoreByMerchantID(ctx context.Context, merchantID uuid.UUID) (*domain.Store, error) {
	return s.storeRepo.GetStoreByMerchantID(ctx, merchantID)
}

func (s *StoreService) ListStores(ctx context.Context, search string, isVerified *bool, page, perPage int) ([]domain.Store, int, error) {
	if page < 1 {
		page = 1
	}
	if perPage < 1 || perPage > 100 {
		perPage = 20
	}
	offset := (page - 1) * perPage

	stores, total, err := s.storeRepo.ListStores(ctx, search, isVerified, perPage, offset)
	if err != nil {
		return nil, 0, err
	}

	for i := range stores {
		branches, branchErr := s.storeRepo.ListStoreBranches(ctx, stores[i].ID)
		if branchErr == nil {
			stores[i].Branches = branches
		}
	}

	return stores, total, nil
}

func (s *StoreService) UpdateStore(ctx context.Context, id uuid.UUID, req domain.UpdateStoreRequest) error {
	return s.storeRepo.UpdateStore(ctx, id, req)
}

func (s *StoreService) DeleteStore(ctx context.Context, id uuid.UUID) error {
	return s.storeRepo.DeleteStore(ctx, id)
}

func (s *StoreService) VerifyStore(ctx context.Context, id uuid.UUID, isVerified bool) error {
	return s.storeRepo.VerifyStore(ctx, id, isVerified)
}

// ─── BRANCHES ──────────────────────────────────────────────────────────

func (s *StoreService) CreateBranch(ctx context.Context, storeID uuid.UUID, req domain.CreateBranchRequest) (*domain.StoreBranch, error) {
	// Verify store exists
	store, err := s.storeRepo.GetStoreByID(ctx, storeID)
	if err != nil || store == nil {
		return nil, errors.New("store not found")
	}

	branch := &domain.StoreBranch{
		ID:            uuid.New(),
		StoreID:       storeID,
		Name:          req.Name,
		GovernorateID: req.GovernorateID,
		City:          req.City,
		Address:       req.Address,
		Phone:         req.Phone,
		IsActive:      true,
	}

	if err := s.storeRepo.CreateBranch(ctx, branch); err != nil {
		return nil, fmt.Errorf("failed to create branch: %w", err)
	}

	return branch, nil
}

func (s *StoreService) UpdateBranch(ctx context.Context, id uuid.UUID, req domain.UpdateBranchRequest) error {
	return s.storeRepo.UpdateBranch(ctx, id, req)
}

func (s *StoreService) DeleteBranch(ctx context.Context, id uuid.UUID) error {
	return s.storeRepo.DeleteBranch(ctx, id)
}
