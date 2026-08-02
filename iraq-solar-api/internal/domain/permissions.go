package domain

type Permission string

const (
	PermUsersManage    Permission = "users.manage"
	PermOrdersManage   Permission = "orders.manage"
	PermProductsManage Permission = "products.manage"
	PermProductsOwn    Permission = "products.own"
	PermBannersManage  Permission = "banners.manage"
	PermStoresVerify   Permission = "stores.verify"
	PermDeliveryManage Permission = "delivery.manage"
	PermSettingsManage Permission = "settings.manage"
	PermStatsView      Permission = "stats.view"
	PermAuditView      Permission = "audit.view"
)

var RolePermissions = map[Role][]Permission{
	RoleAdmin: {
		PermUsersManage,
		PermOrdersManage,
		PermProductsManage,
		PermProductsOwn,
		PermBannersManage,
		PermStoresVerify,
		PermDeliveryManage,
		PermSettingsManage,
		PermStatsView,
		PermAuditView,
	},
	RoleMerchant: {
		PermProductsOwn,
	},
}

func HasPermission(role Role, perm Permission) bool {
	perms, exists := RolePermissions[role]
	if !exists {
		return false
	}
	for _, p := range perms {
		if p == perm {
			return true
		}
	}
	return false
}
