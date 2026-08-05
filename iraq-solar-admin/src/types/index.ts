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

export interface StoreBranch {
  id: string;
  store_id: string;
  name: string;
  governorate_id?: number;
  city?: string;
  address?: string;
  phone?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  governorate_name_ar?: string;
  governorate_name_en?: string;
}

export interface Store {
  id: string;
  merchant_id: string;
  name: string;
  slug: string;
  description?: string;
  logo_url?: string;
  cover_url?: string;
  phone?: string;
  is_verified: boolean;
  is_active: boolean;
  rating: number;
  total_ratings: number;
  created_at: string;
  updated_at: string;
  branches?: StoreBranch[];
}

export type ProductType = 'panel' | 'inverter' | 'battery' | 'structure' | 'cable' | 'accessory';

export interface Category {
  id: number;
  name: string;
  description: string;
  created_at?: string;
}

export interface Brand {
  id: string;
  name: string;
  logo_url?: string;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface Product {
  id: string;
  category_id?: number;
  merchant_id?: string;
  store_id?: string;
  branch_id?: string;
  sku: string;
  name: string;
  brand_id?: string;
  brand_name?: string;
  model: string;
  type: ProductType;
  price_iqd: number;
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
  unit_price_iqd: number;
  total_price_iqd: number;
}

export interface OrderStatusHistory {
  id: string;
  order_id: string;
  from_status?: string;
  to_status: string;
  changed_by?: string;
  changed_by_name?: string;
  notes?: string;
  created_at: string;
}

export interface Order {
  id: string;
  user_id: string;
  store_id?: string;
  branch_id?: string;
  status: OrderStatus;
  total_amount_iqd: number;
  shipping_address: string;
  payment_method: string;
  payment_status: string;
  customer_name?: string;
  customer_phone?: string;
  created_at: string;
  updated_at: string;
  items?: OrderItem[];
}

export interface OrderItemFull extends OrderItem {
  product_name?: string;
  product_sku?: string;
  product_image?: string;
}

export interface OrderFull {
  id: string;
  user_id: string;
  store_id?: string;
  branch_id?: string;
  status: OrderStatus;
  total_amount_iqd: number;
  shipping_address: string;
  payment_method: string;
  payment_status: string;
  created_at: string;
  updated_at: string;
  // Customer
  customer_name: string;
  customer_phone: string;
  customer_governorate?: string;
  customer_city?: string;
  // Store
  store_name?: string;
  store_slug?: string;
  store_logo_url?: string;
  store_phone?: string;
  // Branch
  branch_name?: string;
  branch_address?: string;
  branch_city?: string;
  branch_phone?: string;
  branch_governorate_ar?: string;
  branch_governorate_en?: string;
  // Collections
  items?: OrderItemFull[];
  status_history?: OrderStatusHistory[];
}

export type WSMessageType =
  | 'order.new'
  | 'order.status_changed'
  | 'order.cancelled'
  | 'ping'
  | 'pong';

export interface WSMessage {
  type: WSMessageType;
  payload: any;
  timestamp: string;
}

export interface OrderStatusChangedPayload {
  order_id: string;
  from_status: OrderStatus;
  to_status: OrderStatus;
  changed_by: string;
  notes?: string;
  updated_at: string;
}

export interface AdminOrdersResponse {
  orders: OrderFull[];
  total: number;
  page: number;
  limit: number;
  total_pages: number;
}

export interface OrderFilters {
  status?: OrderStatus | '';
  search?: string;
  store_id?: string;
  branch_id?: string;
  from_date?: string;
  to_date?: string;
  page?: number;
  limit?: number;
}

export interface DeliveryFee {
  id: number;
  merchant_id: string;
  store_id?: string;
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

export type BannerActionType = 'none' | 'open_store' | 'open_product' | 'open_category' | 'open_search' | 'open_url';

export interface BannerStoreTarget {
  store_id?: string;
  branch_id?: string;
}

export interface HomeBanner {
  id: string;
  image_url: string;
  mobile_image_url?: string;
  priority: number;
  display_order: number;
  is_active: boolean;
  starts_at?: string;
  ends_at?: string;
  action_type: BannerActionType;
  action_payload?: Record<string, any>;
  targeting_rules?: Record<string, any>;
  recurrence_type?: 'none' | 'daily' | 'weekly' | 'monthly';
  recurrence_time?: string;
  recurrence_end?: string;
  timezone?: string;
  created_by?: string;
  merchant_id?: string;
  placements?: string[];
  store_ids?: string[];
  branch_ids?: string[];
  store_targets?: BannerStoreTarget[];
  created_at?: string;
  updated_at?: string;
}

export interface DashboardStats {
  total_orders: number;
  total_revenue_iqd: number;
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

// --- Workforce Dispatch System ---

export type TechnicianRole = 'engineer' | 'installer' | 'technician' | 'worker';

export type AvailabilityStatus = 'available' | 'busy' | 'suspended' | 'offline' | 'vacation';

export type ServiceOrderType = 'installation' | 'maintenance' | 'inspection' | 'consultation' | 'repair';

export type ServiceOrderStatus =
  | 'new'
  | 'dispatching'
  | 'assigned'
  | 'tech_accepted'
  | 'on_the_way'
  | 'arrived'
  | 'working'
  | 'waiting_customer'
  | 'completed'
  | 'cancelled'
  | 'no_technician_available';

export type DispatchMode = 'sequential' | 'parallel' | 'hybrid';

export type DispatchStatus = 'queued' | 'sent' | 'accepted' | 'rejected' | 'expired' | 'cancelled';

export type LeadStatus = 'pending_review' | 'approved' | 'rejected' | 'converted';

export type ServicePaymentStatus = 'unpaid' | 'pending' | 'paid_to_technician' | 'settled';

export interface TechnicianLevel {
  id: string;
  name: string;
  name_ar: string;
  min_jobs: number;
  min_rating: number;
  commission_rate: number;
  badge_color: string;
  sort_order: number;
}

export interface Technician {
  id: string;
  user_id: string;
  full_name: string;
  profile_image_url?: string;
  phone_public?: string;
  role: TechnicianRole;
  specializations: string[];
  governorate_id?: number;
  district_id?: number;
  experience_years: number;
  bio?: string;
  is_verified: boolean;
  is_active: boolean;
  availability_status: AvailabilityStatus;
  rating: number;
  completed_jobs_count: number;
  acceptance_rate: number;
  avg_response_minutes: number;
  verification_level: number;
  level_id?: string;
  level_name_ar?: string;
  level_badge_color?: string;
  commission_rate?: number;
  governorate_name?: string;
  priority_score?: number;
  is_featured?: boolean;
  is_hidden?: boolean;
  created_at: string;
}

export interface TechnicianServiceZone {
  id: string;
  technician_id: string;
  governorate_id: number;
  is_primary: boolean;
  governorate_name_ar?: string;
}

export interface TechnicianWallet {
  id: string;
  technician_id: string;
  balance_iqd: number;
  total_earned_iqd: number;
  total_commission_iqd: number;
  pending_payout_iqd: number;
  last_settlement_at?: string;
}

export interface TechnicianAvailability {
  id: string;
  technician_id: string;
  status: string;
  available_from?: string;
  available_until?: string;
  working_days: string[];
}

export interface TechnicianDocument {
  id: string;
  technician_id: string;
  type: string;
  url: string;
  status: 'pending' | 'under_review' | 'approved' | 'rejected';
  created_at: string;
}

export interface ServiceOrder {
  id: string;
  order_number: string;
  customer_id?: string;
  order_type: ServiceOrderType;
  description?: string;
  system_size_kw?: number;
  governorate_id?: number;
  address?: string;
  preferred_date?: string;
  status: ServiceOrderStatus;
  priority: string;
  assigned_technician_id?: string;
  dispatch_mode: DispatchMode;
  created_at: string;
  completed_at?: string;
  customer_name?: string;
  customer_phone?: string;
  governorate_name?: string;
  district_name?: string;
  technician_name?: string;
}

export interface DispatchQueueEntry {
  id: string;
  service_order_id: string;
  technician_id: string;
  priority_score: number;
  dispatch_mode: DispatchMode;
  position: number;
  status: DispatchStatus;
  selection_reason: Record<string, any>;
  sent_at?: string;
  responded_at?: string;
  expires_at?: string;
  technician_name?: string;
}

export interface DispatchSettings {
  id: string;
  service_type: ServiceOrderType;
  dispatch_mode: DispatchMode;
  response_timeout_minutes: number;
  parallel_candidates_count: number;
  minimum_score: number;
  auto_assign_enabled: boolean;
}

export interface TechnicianDispatchStats {
  id: string;
  technician_id: string;
  technician_name?: string;
  orders_received_this_month: number;
  orders_received_this_week: number;
  total_orders_received: number;
  total_earnings_this_month: number;
  last_order_received_at?: string;
  days_since_last_order: number;
  is_new_technician: boolean;
  new_technician_orders_count: number;
  fairness_boost: number;
}

export interface ServicePricing {
  id: string;
  order_id: string;
  base_price_iqd: number;
  platform_commission_percent: number;
  platform_commission_iqd: number;
  technician_payout_iqd: number;
  payment_status: ServicePaymentStatus;
  settled_at?: string;
  created_at: string;
  order_number?: string;
  technician_name?: string;
}

export interface TechnicianLead {
  id: string;
  technician_id: string;
  technician_name?: string;
  customer_name: string;
  customer_phone: string;
  order_type: ServiceOrderType;
  description?: string;
  system_size_kw?: number;
  governorate_id?: number;
  address?: string;
  estimated_price_iqd?: number;
  status: LeadStatus;
  converted_order_id?: string;
  created_at: string;
}

export interface ServiceOrderStatusEvent {
  id: string;
  order_id: string;
  status: string;
  notes?: string;
  created_at: string;
}

export interface TechnicianTracking {
  id: string;
  order_id: string;
  technician_id: string;
  lat: number;
  lng: number;
  status: string;
  created_at: string;
}
