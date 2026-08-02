package domain_test

import (
	"testing"

	"github.com/iraq-solar/api/internal/domain"
)

func TestHasPermission(t *testing.T) {
	tests := []struct {
		name     string
		role     domain.Role
		perm     domain.Permission
		expected bool
	}{
		{
			name:     "Admin has users.manage",
			role:     domain.RoleAdmin,
			perm:     domain.PermUsersManage,
			expected: true,
		},
		{
			name:     "Admin has stores.verify",
			role:     domain.RoleAdmin,
			perm:     domain.PermStoresVerify,
			expected: true,
		},
		{
			name:     "Merchant has products.own",
			role:     domain.RoleMerchant,
			perm:     domain.PermProductsOwn,
			expected: true,
		},
		{
			name:     "Merchant does not have users.manage",
			role:     domain.RoleMerchant,
			perm:     domain.PermUsersManage,
			expected: false,
		},
		{
			name:     "Customer has no admin/merchant permissions",
			role:     domain.RoleCustomer,
			perm:     domain.PermProductsOwn,
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := domain.HasPermission(tt.role, tt.perm)
			if got != tt.expected {
				t.Errorf("HasPermission(%v, %v) = %v; want %v", tt.role, tt.perm, got, tt.expected)
			}
		})
	}
}
