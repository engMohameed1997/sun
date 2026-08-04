import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  ShoppingCart, Search, Eye, CheckCircle2, Clock, XCircle,
  Truck, PackageCheck, Store, MapPin, Wifi, WifiOff, RotateCcw,
  Package, CreditCard, User, Phone, ChevronLeft, ChevronRight,
  Bell, Filter,
} from 'lucide-react';
import { api } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useOrdersWebSocket } from '../hooks/useOrdersWebSocket';
import { OrderStatusTimeline } from '../components/orders/OrderStatusTimeline';
import type { OrderFull, OrderStatus, OrderStatusChangedPayload, AdminOrdersResponse, OrderFilters } from '../types';

// ─── Status configuration ───────────────────────────────────────────────────

const STATUS_CONFIG: Record<OrderStatus, { label: string; icon: React.FC<any>; color: string; bg: string; border: string; dot: string }> = {
  pending: {
    label: 'قيد الانتظار', icon: Clock,
    color: 'text-amber-400', bg: 'bg-amber-500/10', border: 'border-amber-500/30', dot: 'bg-amber-400',
  },
  confirmed: {
    label: 'تم التأكيد', icon: CheckCircle2,
    color: 'text-blue-400', bg: 'bg-blue-500/10', border: 'border-blue-500/30', dot: 'bg-blue-400',
  },
  processing: {
    label: 'قيد التجهيز', icon: Truck,
    color: 'text-purple-400', bg: 'bg-purple-500/10', border: 'border-purple-500/30', dot: 'bg-purple-400',
  },
  completed: {
    label: 'مكتمل', icon: PackageCheck,
    color: 'text-emerald-400', bg: 'bg-emerald-500/10', border: 'border-emerald-500/30', dot: 'bg-emerald-400',
  },
  cancelled: {
    label: 'ملغي', icon: XCircle,
    color: 'text-rose-400', bg: 'bg-rose-500/10', border: 'border-rose-500/30', dot: 'bg-rose-400',
  },
};

const ALL_STATUSES: OrderStatus[] = ['pending', 'confirmed', 'processing', 'completed', 'cancelled'];

function getStatusBadge(status: OrderStatus) {
  const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.pending;
  const Icon = cfg.icon;
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-semibold border ${cfg.bg} ${cfg.color} ${cfg.border}`}>
      <Icon size={12} />
      {cfg.label}
    </span>
  );
}

function formatDate(dateStr: string) {
  return new Intl.DateTimeFormat('ar-IQ', { year: 'numeric', month: 'short', day: 'numeric' }).format(new Date(dateStr));
}

function relativeTime(dateStr: string) {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'الآن';
  if (mins < 60) return `منذ ${mins}د`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `منذ ${hrs}س`;
  return `منذ ${Math.floor(hrs / 24)}ي`;
}

// ─── Toast Notification ──────────────────────────────────────────────────────

interface Toast { id: string; message: string; type: 'new' | 'update' }

function ToastNotification({ toast, onDismiss }: { toast: Toast; onDismiss: () => void }) {
  useEffect(() => {
    const t = setTimeout(onDismiss, 5000);
    return () => clearTimeout(t);
  }, [onDismiss]);

  return (
    <div
      className={`flex items-start gap-3 p-4 rounded-xl border shadow-2xl backdrop-blur-sm animate-slide-in max-w-sm w-full
        ${toast.type === 'new'
          ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'
          : 'bg-blue-500/10 border-blue-500/30 text-blue-300'}`}
      style={{ animation: 'slideInRight 0.3s ease-out' }}
    >
      <Bell size={18} className="flex-shrink-0 mt-0.5" />
      <div className="flex-1 text-sm">{toast.message}</div>
      <button onClick={onDismiss} className="text-current opacity-60 hover:opacity-100 text-lg leading-none">×</button>
    </div>
  );
}

// ─── Main OrdersPage ─────────────────────────────────────────────────────────

export const OrdersPage: React.FC = () => {
  const { token } = useAuth();

  // Data state
  const [orders, setOrders] = useState<OrderFull[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [selectedOrder, setSelectedOrder] = useState<OrderFull | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [statusNotes, setStatusNotes] = useState('');
  const [toasts, setToasts] = useState<Toast[]>([]);

  // Filters
  const [filters, setFilters] = useState<OrderFilters>({ page: 1, limit: 20, status: '', search: '' });
  const [showFilters, setShowFilters] = useState(false);

  const searchRef = useRef<HTMLInputElement>(null);

  // ─ Toast helpers ────────────────────────────────────────────────────────────
  const addToast = useCallback((message: string, type: Toast['type'] = 'new') => {
    const id = Math.random().toString(36).slice(2);
    setToasts(prev => [...prev.slice(-2), { id, message, type }]);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  // ─ WebSocket ────────────────────────────────────────────────────────────────
  const { status: wsStatus, connect: wsConnect } = useOrdersWebSocket({
    token,
    enabled: !!token,
    onNewOrder: useCallback((order: OrderFull) => {
      setOrders(prev => [order, ...prev]);
      setTotal(t => t + 1);
      addToast(`طلب جديد #${order.id.slice(0, 8)} من ${order.customer_name || 'زبون'}`, 'new');
    }, [addToast]),
    onStatusChanged: useCallback((payload: OrderStatusChangedPayload) => {
      setOrders(prev =>
        prev.map(o => o.id === payload.order_id ? { ...o, status: payload.to_status, updated_at: payload.updated_at } : o)
      );
      setSelectedOrder(prev =>
        prev?.id === payload.order_id ? { ...prev, status: payload.to_status } : prev
      );
      addToast(`تم تحديث الطلب #${payload.order_id.slice(0, 8)} إلى "${STATUS_CONFIG[payload.to_status]?.label}"`, 'update');
    }, [addToast]),
    onOrderCancelled: useCallback((payload: OrderStatusChangedPayload) => {
      setOrders(prev =>
        prev.map(o => o.id === payload.order_id ? { ...o, status: 'cancelled', updated_at: payload.updated_at } : o)
      );
      addToast(`تم إلغاء الطلب #${payload.order_id.slice(0, 8)}`, 'update');
    }, [addToast]),
  });

  // ─ Fetch orders ─────────────────────────────────────────────────────────────
  const fetchOrders = useCallback(async (f: OrderFilters = filters) => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (f.status) params.set('status', f.status);
      if (f.search) params.set('search', f.search);
      if (f.store_id) params.set('store_id', f.store_id);
      if (f.branch_id) params.set('branch_id', f.branch_id);
      if (f.from_date) params.set('from_date', f.from_date);
      if (f.to_date) params.set('to_date', f.to_date);
      params.set('page', String(f.page || 1));
      params.set('limit', String(f.limit || 20));

      const res = await api.get<{ data: AdminOrdersResponse }>(`/admin/orders?${params}`);
      const data = res.data?.data;
      setOrders(data?.orders || []);
      setTotal(data?.total || 0);
      setTotalPages(data?.total_pages || 1);
    } catch {
      setOrders([]);
    } finally {
      setLoading(false);
    }
  }, [filters]);

  useEffect(() => { fetchOrders(filters); }, [filters.status, filters.page]);

  // ─ Open order detail ─────────────────────────────────────────────────────────
  const openDetail = async (order: OrderFull) => {
    setSelectedOrder(order);
    setDetailLoading(true);
    setStatusNotes('');
    try {
      const res = await api.get<{ data: OrderFull }>(`/admin/orders/${order.id}`);
      if (res.data?.data) setSelectedOrder(res.data.data);
    } finally {
      setDetailLoading(false);
    }
  };

  // ─ Update status ─────────────────────────────────────────────────────────────
  const handleUpdateStatus = async (orderId: string, newStatus: OrderStatus) => {
    setUpdatingStatus(true);
    try {
      await api.put(`/admin/orders/${orderId}/status`, { status: newStatus, notes: statusNotes });
      setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: newStatus } : o));
      if (selectedOrder?.id === orderId) {
        setSelectedOrder(prev => prev ? { ...prev, status: newStatus } : null);
      }
      setStatusNotes('');
    } catch {
      addToast('حدث خطأ أثناء تحديث حالة الطلب', 'update');
    } finally {
      setUpdatingStatus(false);
    }
  };

  // ─ Stats derived from orders (today) ─────────────────────────────────────────
  const today = new Date().toDateString();
  const todayOrders = orders.filter(o => new Date(o.created_at).toDateString() === today);
  const pendingCount = orders.filter(o => o.status === 'pending').length;
  const completedToday = todayOrders.filter(o => o.status === 'completed').length;
  const todayRevenue = todayOrders.reduce((s, o) => s + o.total_amount_iqd, 0);

  return (
    <div className="space-y-5 pb-8" dir="rtl">
      {/* Toast Notifications */}
      <div className="fixed top-4 left-4 z-[100] space-y-2 flex flex-col items-end">
        {toasts.map(t => (
          <ToastNotification key={t.id} toast={t} onDismiss={() => removeToast(t.id)} />
        ))}
      </div>

      {/* ── Header ─────────────────────────────────────────────────── */}
      <div className="bg-gradient-to-l from-slate-900 to-slate-900/80 border border-slate-800 rounded-2xl p-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
              <ShoppingCart className="text-amber-400" size={20} />
            </div>
            <div>
              <h1 className="text-lg font-bold text-slate-100">إدارة الطلبات</h1>
              <p className="text-xs text-slate-400 mt-0.5">متابعة تدفق الطلبات لحظياً عبر WebSocket</p>
            </div>
          </div>

          {/* WS Status indicator */}
          <div className="flex items-center gap-3">
            <div
              className={`flex items-center gap-2 text-xs font-semibold px-3 py-1.5 rounded-full border transition-all
                ${wsStatus === 'connected'
                  ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400'
                  : wsStatus === 'connecting'
                    ? 'bg-amber-500/10 border-amber-500/30 text-amber-400'
                    : 'bg-slate-800 border-slate-700 text-slate-400'}`}
            >
              {wsStatus === 'connected' ? (
                <>
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  <Wifi size={12} /> مباشر
                </>
              ) : wsStatus === 'connecting' ? (
                <><span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" /> جارٍ الاتصال...</>
              ) : (
                <>
                  <WifiOff size={12} /> غير متصل
                  <button onClick={wsConnect} className="ml-1 hover:text-white transition">
                    <RotateCcw size={11} />
                  </button>
                </>
              )}
            </div>
            <button
              onClick={() => setShowFilters(v => !v)}
              className={`p-2 rounded-xl border transition ${showFilters ? 'bg-amber-500/10 border-amber-500/30 text-amber-400' : 'bg-slate-800 border-slate-700 text-slate-400 hover:text-slate-200'}`}
            >
              <Filter size={16} />
            </button>
          </div>
        </div>

        {/* Stats Bar */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-4">
          {[
            { label: 'طلبات اليوم', value: todayOrders.length, color: 'text-amber-400', icon: ShoppingCart },
            { label: 'معلّقة', value: pendingCount, color: 'text-amber-400', icon: Clock },
            { label: 'مكتملة اليوم', value: completedToday, color: 'text-emerald-400', icon: PackageCheck },
            { label: 'إيرادات اليوم', value: `${todayRevenue.toLocaleString()} د.ع`, color: 'text-blue-400', icon: CreditCard },
          ].map(({ label, value, color, icon: Icon }) => (
            <div key={label} className="bg-slate-800/50 border border-slate-700/60 rounded-xl p-3 flex items-center gap-2.5">
              <Icon size={16} className={color} />
              <div>
                <div className={`text-base font-bold ${color}`}>{value}</div>
                <div className="text-[10px] text-slate-500">{label}</div>
              </div>
            </div>
          ))}
        </div>

        {/* Extended Filters */}
        {showFilters && (
          <div className="mt-4 pt-4 border-t border-slate-800 grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="relative">
              <input
                ref={searchRef}
                type="text"
                placeholder="بحث بالاسم / الهاتف / رقم الطلب..."
                defaultValue={filters.search}
                onKeyDown={e => {
                  if (e.key === 'Enter') {
                    setFilters(f => ({ ...f, search: searchRef.current?.value || '', page: 1 }));
                    fetchOrders({ ...filters, search: searchRef.current?.value || '', page: 1 });
                  }
                }}
                className="w-full bg-slate-950/60 border border-slate-700 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 focus:outline-none focus:border-amber-500 transition"
              />
              <Search size={14} className="absolute left-3 top-2.5 text-slate-500" />
            </div>
            <input
              type="date"
              onChange={e => setFilters(f => ({ ...f, from_date: e.target.value, page: 1 }))}
              placeholder="من تاريخ"
              className="bg-slate-950/60 border border-slate-700 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500 transition"
            />
            <input
              type="date"
              onChange={e => setFilters(f => ({ ...f, to_date: e.target.value, page: 1 }))}
              placeholder="إلى تاريخ"
              className="bg-slate-950/60 border border-slate-700 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500 transition"
            />
          </div>
        )}
      </div>

      {/* ── Status Filter Tabs ─────────────────────────────────────── */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-hide">
        {[{ value: '', label: 'الكل' }, ...ALL_STATUSES.map(s => ({ value: s, label: STATUS_CONFIG[s].label }))].map(opt => (
          <button
            key={opt.value}
            onClick={() => setFilters(f => ({ ...f, status: opt.value as any, page: 1 }))}
            className={`whitespace-nowrap px-3.5 py-1.5 rounded-xl text-xs font-semibold border transition-all
              ${filters.status === opt.value
                ? 'bg-amber-500 text-slate-950 border-amber-400'
                : 'bg-slate-800/60 text-slate-400 border-slate-700 hover:text-slate-200 hover:border-slate-600'}`}
          >
            {opt.label}
          </button>
        ))}
      </div>

      {/* ── Orders Table ───────────────────────────────────────────── */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="flex items-center justify-between px-5 py-3 border-b border-slate-800">
          <span className="text-xs text-slate-400">
            إجمالي <span className="text-slate-200 font-bold">{total}</span> طلب
          </span>
          <button onClick={() => fetchOrders(filters)} className="text-slate-400 hover:text-amber-400 transition">
            <RotateCcw size={14} />
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-xs text-right">
            <thead className="bg-slate-950/60 text-slate-400 border-b border-slate-800">
              <tr>
                <th className="p-4 font-semibold">رقم الطلب</th>
                <th className="p-4 font-semibold">الزبون</th>
                <th className="p-4 font-semibold">المتجر / الفرع</th>
                <th className="p-4 font-semibold">المبلغ</th>
                <th className="p-4 font-semibold">الدفع</th>
                <th className="p-4 font-semibold">الحالة</th>
                <th className="p-4 font-semibold">التاريخ</th>
                <th className="p-4 font-semibold text-center">إجراء</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/50 text-slate-200">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    {Array.from({ length: 8 }).map((_, j) => (
                      <td key={j} className="p-4">
                        <div className="h-3 bg-slate-800 rounded animate-pulse" />
                      </td>
                    ))}
                  </tr>
                ))
              ) : orders.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-16 text-center text-slate-500">
                    <ShoppingCart size={36} className="mx-auto mb-3 opacity-30" />
                    <p>لا توجد طلبات تطابق البحث</p>
                  </td>
                </tr>
              ) : (
                orders.map(order => {
                  return (
                    <tr
                      key={order.id}
                      className="hover:bg-slate-800/30 transition cursor-pointer group"
                      onClick={() => openDetail(order)}
                    >
                      {/* Order ID */}
                      <td className="p-4">
                        <div className="font-mono font-bold text-amber-400">#{order.id.slice(0, 8).toUpperCase()}</div>
                        <div className="text-[10px] text-slate-500 mt-0.5">{relativeTime(order.created_at)}</div>
                      </td>

                      {/* Customer */}
                      <td className="p-4">
                        <div className="font-semibold text-slate-100 truncate max-w-[120px]">{order.customer_name || 'زبون عام'}</div>
                        <div className="text-[10px] text-slate-400 font-mono">{order.customer_phone || '—'}</div>
                      </td>

                      {/* Store / Branch */}
                      <td className="p-4">
                        {order.store_name ? (
                          <div>
                            <div className="flex items-center gap-1 text-slate-200 font-medium">
                              <Store size={11} className="text-slate-400 flex-shrink-0" />
                              <span className="truncate max-w-[100px]">{order.store_name}</span>
                            </div>
                            {order.branch_name && (
                              <div className="flex items-center gap-1 text-[10px] text-slate-400 mt-0.5">
                                <MapPin size={9} className="flex-shrink-0" />
                                {order.branch_name}
                              </div>
                            )}
                          </div>
                        ) : (
                          <span className="text-slate-600">—</span>
                        )}
                      </td>

                      {/* Amount */}
                      <td className="p-4 font-bold text-emerald-400 whitespace-nowrap">
                        {order.total_amount_iqd.toLocaleString()} <span className="text-[10px] font-normal text-slate-500">د.ع</span>
                      </td>

                      {/* Payment */}
                      <td className="p-4">
                        <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${order.payment_status === 'paid'
                            ? 'bg-emerald-500/10 text-emerald-400'
                            : order.payment_status === 'failed'
                              ? 'bg-rose-500/10 text-rose-400'
                              : 'bg-slate-700 text-slate-400'
                          }`}>
                          {order.payment_status === 'paid' ? 'مدفوع' : order.payment_status === 'failed' ? 'فشل' : 'غير مدفوع'}
                        </span>
                      </td>

                      {/* Status */}
                      <td className="p-4">{getStatusBadge(order.status)}</td>

                      {/* Date */}
                      <td className="p-4 text-slate-400 whitespace-nowrap">{formatDate(order.created_at)}</td>

                      {/* Action */}
                      <td className="p-4 text-center">
                        <button
                          onClick={e => { e.stopPropagation(); openDetail(order); }}
                          className="p-2 bg-slate-800 hover:bg-amber-500/10 hover:text-amber-400 text-slate-300 rounded-lg transition group-hover:border-amber-500/20 border border-transparent"
                        >
                          <Eye size={14} />
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-5 py-3 border-t border-slate-800">
            <span className="text-xs text-slate-500">
              صفحة <span className="text-slate-300 font-bold">{filters.page}</span> من <span className="text-slate-300 font-bold">{totalPages}</span>
            </span>
            <div className="flex items-center gap-2">
              <button
                disabled={filters.page! <= 1}
                onClick={() => setFilters(f => ({ ...f, page: (f.page || 1) - 1 }))}
                className="p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-slate-200 disabled:opacity-30 transition"
              >
                <ChevronRight size={14} />
              </button>
              <button
                disabled={filters.page! >= totalPages}
                onClick={() => setFilters(f => ({ ...f, page: (f.page || 1) + 1 }))}
                className="p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-slate-200 disabled:opacity-30 transition"
              >
                <ChevronLeft size={14} />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ── Order Detail Modal ─────────────────────────────────────── */}
      {selectedOrder && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4" dir="rtl">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-3xl w-full max-h-[92vh] overflow-y-auto shadow-2xl">
            {/* Modal Header */}
            <div className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800 px-6 py-4 flex items-center justify-between rounded-t-2xl">
              <div>
                <h2 className="text-base font-bold text-slate-100 flex items-center gap-2">
                  <ShoppingCart size={18} className="text-amber-400" />
                  طلب #{selectedOrder.id.slice(0, 8).toUpperCase()}
                </h2>
                <p className="text-xs text-slate-400 mt-0.5">
                  {new Intl.DateTimeFormat('ar-IQ', { dateStyle: 'long', timeStyle: 'short' }).format(new Date(selectedOrder.created_at))}
                </p>
              </div>
              <div className="flex items-center gap-2">
                {getStatusBadge(selectedOrder.status)}
                <button
                  onClick={() => setSelectedOrder(null)}
                  className="p-2 text-slate-400 hover:text-slate-100 rounded-lg hover:bg-slate-800 transition text-lg leading-none"
                >
                  ×
                </button>
              </div>
            </div>

            <div className="p-6 space-y-5">
              {detailLoading ? (
                <div className="space-y-3">
                  {Array.from({ length: 4 }).map((_, i) => (
                    <div key={i} className="h-16 bg-slate-800 rounded-xl animate-pulse" />
                  ))}
                </div>
              ) : (
                <>
                  {/* Grid Info: Customer + Store */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {/* Customer Card */}
                    <div className="bg-slate-800/50 border border-slate-700/60 rounded-xl p-4 space-y-3">
                      <div className="flex items-center gap-2 text-xs font-bold text-slate-300 border-b border-slate-700/60 pb-2">
                        <User size={14} className="text-amber-400" /> معلومات الزبون
                      </div>
                      <InfoRow icon={User} label="الاسم" value={selectedOrder.customer_name || 'غير محدد'} />
                      <InfoRow icon={Phone} label="الهاتف" value={selectedOrder.customer_phone || 'غير محدد'} mono />
                      <InfoRow icon={MapPin} label="العنوان" value={selectedOrder.shipping_address} />
                      {selectedOrder.customer_governorate && (
                        <InfoRow icon={MapPin} label="المحافظة" value={`${selectedOrder.customer_governorate} / ${selectedOrder.customer_city || '—'}`} />
                      )}
                    </div>

                    {/* Store/Branch Card */}
                    {selectedOrder.store_name ? (
                      <div className="bg-slate-800/50 border border-slate-700/60 rounded-xl p-4 space-y-3">
                        <div className="flex items-center gap-2 text-xs font-bold text-slate-300 border-b border-slate-700/60 pb-2">
                          <Store size={14} className="text-blue-400" /> المتجر والفرع
                        </div>
                        <div className="flex items-center gap-2">
                          {selectedOrder.store_logo_url && (
                            <img src={selectedOrder.store_logo_url} alt="" className="w-8 h-8 rounded-lg object-cover bg-slate-700" />
                          )}
                          <div>
                            <div className="text-sm font-bold text-slate-100">{selectedOrder.store_name}</div>
                            {selectedOrder.store_phone && <div className="text-[11px] text-slate-400 font-mono">{selectedOrder.store_phone}</div>}
                          </div>
                        </div>
                        {selectedOrder.branch_name && (
                          <>
                            <InfoRow icon={MapPin} label="الفرع" value={selectedOrder.branch_name} />
                            {selectedOrder.branch_city && <InfoRow icon={MapPin} label="المدينة" value={`${selectedOrder.branch_city} / ${selectedOrder.branch_governorate_ar || ''}`} />}
                            {selectedOrder.branch_address && <InfoRow icon={MapPin} label="العنوان" value={selectedOrder.branch_address} />}
                            {selectedOrder.branch_phone && <InfoRow icon={Phone} label="الهاتف" value={selectedOrder.branch_phone} mono />}
                          </>
                        )}
                      </div>
                    ) : (
                      <div className="bg-slate-800/30 border border-slate-700/40 rounded-xl p-4 flex items-center justify-center text-slate-600 text-xs">
                        لا يوجد متجر مرتبط بهذا الطلب
                      </div>
                    )}
                  </div>

                  {/* Products */}
                  {selectedOrder.items && selectedOrder.items.length > 0 && (
                    <div className="bg-slate-800/50 border border-slate-700/60 rounded-xl overflow-hidden">
                      <div className="flex items-center gap-2 px-4 py-3 border-b border-slate-700/60 text-xs font-bold text-slate-300">
                        <Package size={14} className="text-purple-400" /> المنتجات ({selectedOrder.items.length})
                      </div>
                      <div className="divide-y divide-slate-700/40">
                        {selectedOrder.items.map(item => (
                          <div key={item.id} className="flex items-center gap-3 px-4 py-3">
                            {item.product_image && (
                              <img src={item.product_image} alt="" className="w-10 h-10 rounded-lg object-cover bg-slate-700 flex-shrink-0" />
                            )}
                            <div className="flex-1 min-w-0">
                              <div className="text-xs font-semibold text-slate-200 truncate">{item.product_name || 'منتج'}</div>
                              {item.product_sku && <div className="text-[10px] text-slate-500 font-mono">{item.product_sku}</div>}
                            </div>
                            <div className="text-right flex-shrink-0">
                              <div className="text-xs text-slate-400">×{item.quantity}</div>
                              <div className="text-xs font-bold text-emerald-400">{item.total_price_iqd.toLocaleString()} د.ع</div>
                            </div>
                          </div>
                        ))}
                      </div>
                      {/* Summary */}
                      <div className="border-t border-slate-700/60 px-4 py-3 flex justify-between items-center">
                        <div className="flex items-center gap-3 text-xs text-slate-400">
                          <CreditCard size={12} />
                          {selectedOrder.payment_method === 'cash_on_delivery' ? 'الدفع عند الاستلام' : selectedOrder.payment_method}
                        </div>
                        <div className="text-sm font-bold text-emerald-400">
                          {selectedOrder.total_amount_iqd.toLocaleString()} <span className="text-xs font-normal text-slate-500">د.ع</span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Update Status */}
                  <div className="bg-slate-800/50 border border-slate-700/60 rounded-xl p-4 space-y-3">
                    <div className="text-xs font-bold text-slate-300 flex items-center gap-2">
                      <CheckCircle2 size={14} className="text-amber-400" /> تغيير حالة الطلب
                    </div>
                    <div className="flex flex-wrap gap-2">
                      {ALL_STATUSES.map(st => {
                        const cfg = STATUS_CONFIG[st];
                        const Icon = cfg.icon;
                        const isCurrent = selectedOrder.status === st;
                        return (
                          <button
                            key={st}
                            disabled={updatingStatus}
                            onClick={() => handleUpdateStatus(selectedOrder.id, st)}
                            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all disabled:opacity-50
                              ${isCurrent
                                ? `${cfg.bg} ${cfg.color} ${cfg.border} ring-2 ring-amber-500/30`
                                : 'bg-slate-700/50 text-slate-400 border-slate-600 hover:bg-slate-700 hover:text-slate-200'}`}
                          >
                            <Icon size={12} />
                            {cfg.label}
                          </button>
                        );
                      })}
                    </div>
                    <input
                      type="text"
                      placeholder="ملاحظة اختيارية عند تغيير الحالة..."
                      value={statusNotes}
                      onChange={e => setStatusNotes(e.target.value)}
                      className="w-full bg-slate-950/50 border border-slate-700 rounded-lg px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500 transition"
                    />
                  </div>

                  {/* Status Timeline */}
                  {selectedOrder.status_history && selectedOrder.status_history.length > 0 && (
                    <div className="bg-slate-800/50 border border-slate-700/60 rounded-xl p-4">
                      <div className="text-xs font-bold text-slate-300 flex items-center gap-2 mb-4 pb-2 border-b border-slate-700/60">
                        <Clock size={14} className="text-slate-400" /> سجل تغييرات الحالة
                      </div>
                      <OrderStatusTimeline
                        history={selectedOrder.status_history}
                        currentStatus={selectedOrder.status}
                      />
                    </div>
                  )}
                </>
              )}
            </div>

            {/* Modal Footer */}
            <div className="sticky bottom-0 bg-slate-900/95 backdrop-blur-sm border-t border-slate-800 px-6 py-3 flex justify-end rounded-b-2xl">
              <button
                onClick={() => setSelectedOrder(null)}
                className="px-5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-bold transition border border-slate-700"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// ─── Helper Components ────────────────────────────────────────────────────────

function InfoRow({ icon: Icon, label, value, mono }: { icon: React.FC<any>; label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex items-start gap-2 text-xs">
      <Icon size={11} className="text-slate-500 mt-0.5 flex-shrink-0" />
      <div>
        <span className="text-slate-500">{label}: </span>
        <span className={`text-slate-200 ${mono ? 'font-mono' : ''}`}>{value}</span>
      </div>
    </div>
  );
}
