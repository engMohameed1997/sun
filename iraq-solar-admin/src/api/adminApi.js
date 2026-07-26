import client from './client';

export const login = (email, password) => client.post('/auth/login', { email, password });

// Users
export const getUsers = (params) => client.get('/admin/users', { params });
export const getUserById = (id) => client.get(`/admin/users/${id}`);
export const createUser = (data) => client.post('/admin/users', data);
export const updateUser = (id, data) => client.put(`/admin/users/${id}`, data);
export const toggleUserStatus = (id, isActive) => client.put(`/admin/users/${id}/status`, { is_active: isActive });
export const deleteUser = (id) => client.delete(`/admin/users/${id}`);

// Stores (merchants in backend)
export const getStores = (params) => client.get('/admin/users', { params: { ...params, role: 'merchant' } });
export const createStore = (data) => client.post('/admin/users', { ...data, role: 'merchant' });
export const updateStore = (id, data) => client.put(`/admin/users/${id}`, data);
export const toggleStoreStatus = (id, isActive) => client.put(`/admin/users/${id}/status`, { is_active: isActive });
export const deleteStore = (id) => client.delete(`/admin/users/${id}`);

// Orders
export const getOrders = (params) => client.get('/admin/orders', { params });
export const getOrderById = (id) => client.get(`/admin/orders/${id}`);
export const updateOrderStatus = (id, status) => client.put(`/admin/orders/${id}/status`, { status });

// Products
export const getProducts = (params) => client.get('/admin/products', { params });
export const getProductById = (id) => client.get(`/admin/products/${id}`);
export const updateProduct = (id, data) => client.put(`/admin/products/${id}`, data);
export const deleteProduct = (id) => client.delete(`/admin/products/${id}`);

// Categories
export const getCategories = () => client.get('/categories');

// Banners (home page)
export const getBanners = () => client.get('/admin/banners');
export const createBanner = (data) => client.post('/admin/banners', data);
export const updateBanner = (id, data) => client.put(`/admin/banners/${id}`, data);
export const deleteBanner = (id) => client.delete(`/admin/banners/${id}`);

// Store Banners
export const getStoreBanners = (merchantId) => client.get(`/admin/banners?merchant_id=${merchantId}`);

// Governorates
export const getGovernorates = () => client.get('/admin/governorates');
export const createGovernorate = (data) => client.post('/admin/governorates', data);
export const updateGovernorate = (id, data) => client.put(`/admin/governorates/${id}`, data);
export const toggleGovernorateStatus = (id, isActive) => client.put(`/admin/governorates/${id}/status`, { is_active: isActive });
export const deleteGovernorate = (id) => client.delete(`/admin/governorates/${id}`);

// Real Admin Dashboard Analytics Endpoints
export const getDashboardStats = () => client.get('/admin/stats');
export const getRevenueStats = (days = 7) => client.get('/admin/stats/revenue', { params: { days } });
export const getOrdersByStatus = () => client.get('/admin/stats/orders-by-status');
export const getTopProductsStats = (limit = 5) => client.get('/admin/stats/top-products', { params: { limit } });

// Notifications
export const getNotifications = (params) => client.get('/admin/notifications', { params });

// Audit Logs
export const getAuditLogs = (params) => client.get('/admin/audit-logs', { params });

// Settings
export const getSettings = () => client.get('/admin/settings');
export const updateSettings = (data) => client.put('/admin/settings', data);

// Upload
export const uploadImage = (file) => {
  const formData = new FormData();
  formData.append('image', file);
  return client.post('/upload/image', formData, { headers: { 'Content-Type': 'multipart/form-data' }});
};
