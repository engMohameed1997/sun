export type Role = 'admin' | 'customer' | 'engineer' | 'installer' | 'merchant';

export type Permission =
  | 'users.manage'
  | 'orders.manage'
  | 'products.manage'
  | 'products.own'
  | 'banners.manage'
  | 'stores.verify'
  | 'delivery.manage'
  | 'settings.manage'
  | 'stats.view'
  | 'audit.view';

export interface User {
  id: string;
  full_name: string;
  email: string;
  phone: string;
  role: Role;
  governorate?: string;
  city?: string;
  is_active: boolean;
  is_verified?: boolean;
  verified_at?: string;
  verified_by?: string;
  created_at: string;
  updated_at: string;
}

export type ProductType = 'panel' | 'inverter' | 'battery' | 'structure' | 'cable' | 'accessory';

export interface Product {
  id: string;
  category_id?: number;
  merchant_id?: string;
  sku: string;
  name: string;
  brand: string;
  model: string;
  type: ProductType;
  price_usd: number;
  stock_quantity: number;
  reserved_quantity: number;
  low_stock_threshold: number;
  specifications: Record<string, any>;
  images: string[];
  is_available: boolean;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export type OrderStatus = 'pending' | 'confirmed' | 'processing' | 'completed' | 'cancelled';

export interface OrderItem {
  id: string;
  order_id: string;
  product_id: string;
  quantity: number;
  unit_price_usd: number;
  total_price_usd: number;
}

export interface OrderStatusHistory {
  id: string;
  order_id: string;
  from_status?: string;
  to_status: string;
  changed_by?: string;
  notes?: string;
  created_at: string;
}

export interface Order {
  id: string;
  user_id: string;
  status: OrderStatus;
  total_amount_usd: number;
  shipping_address: string;
  payment_method: string;
  payment_status: string;
  customer_name?: string;
  customer_email?: string;
  customer_phone?: string;
  created_at: string;
  updated_at: string;
  items?: OrderItem[];
}

export interface DeliveryFee {
  id: number;
  merchant_id: string;
  governorate_id: number;
  fee_iqd: number;
  estimated_days: number;
  is_active: boolean;
  governorate_name_ar?: string;
  governorate_name_en?: string;
}

export interface Governorate {
  id: number;
  name_ar: string;
  name_en: string;
  is_active: boolean;
}

export interface HomeBanner {
  id: string;
  title?: string;
  subtitle?: string;
  image_url: string;
  link_url?: string;
  display_order: number;
  is_active: boolean;
}

export interface DashboardStats {
  total_orders: number;
  total_revenue_usd: number;
  total_users: number;
  total_products: number;
  pending_orders: number;
  new_users_this_month: number;
  total_stores: number;
  active_installers: number;
}

export interface RevenueDataPoint {
  date: string;
  revenue: number;
}

export interface AuditLog {
  id: string;
  user_id?: string;
  action: string;
  entity_name: string;
  entity_id?: string;
  payload: Record<string, any>;
  created_at: string;
}

export interface SystemSetting {
  key: string;
  value: string;
  updated_at: string;
}
