package service

import (
	"context"

	"github.com/iraq-solar/api/internal/domain"
	"github.com/iraq-solar/api/internal/repository"
)

type CatalogService struct {
	productRepo repository.ProductRepository
	storeRepo   *repository.StoreRepository
}

func NewCatalogService(productRepo repository.ProductRepository, storeRepo *repository.StoreRepository) *CatalogService {
	return &CatalogService{
		productRepo: productRepo,
		storeRepo:   storeRepo,
	}
}

func (s *CatalogService) GetAvailableProductsByType(ctx context.Context, pType domain.ProductType) ([]domain.Product, error) {
	if s.productRepo == nil {
		return []domain.Product{}, nil
	}
	return s.productRepo.FindByType(ctx, pType)
}

func (s *CatalogService) GetAllAvailableProducts(ctx context.Context) ([]domain.Product, error) {
	if s.productRepo == nil {
		return []domain.Product{}, nil
	}
	return s.productRepo.ListAll(ctx)
}

func (s *CatalogService) GetStoreMap(ctx context.Context) (map[string]domain.Store, error) {
	result := make(map[string]domain.Store)
	if s.storeRepo == nil {
		return result, nil
	}
	stores, _, err := s.storeRepo.ListStores(ctx, "", nil, 100, 0)
	if err != nil {
		return result, err
	}
	for _, store := range stores {
		result[store.ID.String()] = store
	}
	return result, nil
}
