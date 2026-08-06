import React, { useCallback, useEffect, useState } from 'react';
import { ClipboardList, RefreshCw, UserCheck, X, MapPin, Clock, Route, Search, Wifi } from 'lucide-react';
import { api } from '../services/api';
import { useOrdersWebSocket } from '../hooks/useOrdersWebSocket';
import type {
  DispatchQueueEntry,
  ServiceOrder,
  ServiceOrderStatus,
  ServiceOrderStatusEvent,
  ServicePricing,
  Technician,
  TechnicianTracking,
} from '../types';

const KANBAN_COLUMNS: { status: ServiceOrderStatus; label: string; accent: string }[] = [
  { status: 'new', label: 'جديد', accent: 'border-slate-600' },
  { status: 'dispatching', label: 'جاري التوزيع', accent: 'border-sky-500/60' },
  { status: 'assigned', label: 'مُعيَّن', accent: 'border-amber-500/60' },
  { status: 'working', label: 'قيد التنفيذ', accent: 'border-violet-500/60' },
  { status: 'completed', label: 'مكتمل', accent: 'border-emerald-500/60' },
  { status: 'no_technician_available', label: 'لا يوجد فني', accent: 'border-rose-500/60' },
  { status: 'cancelled', label: 'ملغى', accent: 'border-slate-700' },
];

const TYPE_LABELS: Record<string, string> = {
  installation: 'تركيب',
  maintenance: 'صيانة',
  inspection: 'معاينة',
  consultation: 'استشارة',
  repair: 'إصلاح',
};

const DISPATCH_STATUS_LABELS: Record<string, { label: string; className: string }> = {
  queued: { label: 'بالانتظار', className: 'text-slate-400 border-slate-700' },
  sent: { label: 'مُرسل', className: 'text-sky-300 border-sky-500/40' },
  accepted: { label: 'قبل', className: 'text-emerald-300 border-emerald-500/40' },
  rejected: { label: 'رفض', className: 'text-rose-300 border-rose-500/40' },
  expired: { label: 'انتهت المهلة', className: 'text-amber-300 border-amber-500/40' },
  cancelled: { label: 'ملغى', className: 'text-slate-500 border-slate-800' },
};

interface OrderDetail {
  order: ServiceOrder;
  dispatch_queue: DispatchQueueEntry[];
  timeline: ServiceOrderStatusEvent[];
  pricing: ServicePricing | null;
  tracking: TechnicianTracking | null;
}

export const ServiceOrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<ServiceOrder[]>([]);
  const [technicians, setTechnicians] = useState<Technician[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('');
  const [detail, setDetail] = useState<OrderDetail | null>(null);

  const fetchOrders = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/service-orders', {
        params: { search, order_type: typeFilter, limit: 200 },
      });
      setOrders(res.data?.data?.orders || []);
    } catch (err) {
      console.error('Failed to fetch service orders', err);
    } finally {
      setIsLoading(false);
    }
  }, [search, typeFilter]);

  const handleRealtimeUpdate = useCallback(() => {
    fetchOrders();
  }, [fetchOrders]);

  const { status: wsStatus } = useOrdersWebSocket({
    onServiceOrderCreated: handleRealtimeUpdate,
    onServiceOrderStatusChanged: handleRealtimeUpdate,
  });

  useEffect(() => {
    fetchOrders();
  }, [fetchOrders]);

  useEffect(() => {
    api
      .get('/admin/technicians', { params: { limit: 200 } })
      .then((res) => setTechnicians(res.data?.data?.technicians || []))
      .catch(() => {});
  }, []);

  const openDetail = async (id: string) => {
    try {
      const res = await api.get(`/admin/service-orders/${id}`);
      setDetail({
        order: res.data?.data?.order,
        dispatch_queue: res.data?.data?.dispatch_queue || [],
        timeline: res.data?.data?.timeline || [],
        pricing: res.data?.data?.pricing || null,
        tracking: res.data?.data?.tracking || null,
      });
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر جلب تفاصيل الطلب');
    }
  };

  const handleRedispatch = async (id: string) => {
    try {
      await api.post(`/admin/service-orders/${id}/redispatch`);
      alert('تم إعادة تشغيل محرك التوزيع');
      fetchOrders();
      openDetail(id);
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر إعادة التوزيع');
    }
  };

  const handleManualAssign = async (id: string, technicianId: string) => {
    if (!technicianId) return;
    try {
      await api.put(`/admin/service-orders/${id}/assign`, { technician_id: technicianId });
      alert('تم تعيين الفني');
      fetchOrders();
      openDetail(id);
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر التعيين');
    }
  };

  const handleStatusChange = async (id: string, status: ServiceOrderStatus) => {
    try {
      await api.put(`/admin/service-orders/${id}/status`, { status });
      fetchOrders();
      openDetail(id);
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث الحالة');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <ClipboardList className="text-amber-400" size={22} />
            الطلبات الخدمية ومحرك التوزيع
            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full flex items-center gap-1 ${
              wsStatus === 'connected' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : 'bg-slate-800 text-slate-400'
            }`}>
              <Wifi size={10} className={wsStatus === 'connected' ? 'animate-pulse' : ''} />
              {wsStatus === 'connected' ? 'مباشر (WebSocket)' : 'جاري الاتصال...'}
            </span>
          </h1>
          <p className="text-slate-400 text-xs mt-1">
            متابعة طابور التوزيع، التعيين اليدوي، إعادة التوزيع، وتتبع الفني لحظياً
          </p>
        </div>
        <button
          onClick={fetchOrders}
          className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <RefreshCw size={16} />
          تحديث
        </button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4 grid grid-cols-1 md:grid-cols-2 gap-3">
        <div className="relative">
          <Search className="absolute right-3 top-2.5 text-slate-500" size={16} />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="بحث برقم الطلب أو اسم الزبون..."
            className="w-full bg-slate-950 border border-slate-800 rounded-xl pr-10 pl-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
          />
        </div>
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
        >
          <option value="">كل أنواع الخدمة</option>
          {Object.entries(TYPE_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <div className="p-10 text-center text-slate-400 font-bold bg-slate-900 border border-slate-800 rounded-2xl">
          جارٍ التحميل...
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
          {KANBAN_COLUMNS.map((column) => {
            const columnOrders = orders.filter((o) => o.status === column.status);
            return (
              <div key={column.status} className={`bg-slate-900 border-t-2 ${column.accent} border-x border-b border-slate-800 rounded-2xl p-3`}>
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-bold text-slate-200">{column.label}</h3>
                  <span className="text-xs bg-slate-800 text-slate-400 px-2 py-0.5 rounded-full font-bold">
                    {columnOrders.length}
                  </span>
                </div>
                <div className="space-y-2 max-h-[520px] overflow-y-auto">
                  {columnOrders.length === 0 ? (
                    <div className="text-center text-slate-600 text-xs py-6">لا توجد طلبات</div>
                  ) : (
                    columnOrders.map((order) => (
                      <button
                        key={order.id}
                        onClick={() => openDetail(order.id)}
                        className="w-full text-right bg-slate-950 border border-slate-800 hover:border-amber-500/40 rounded-xl p-3 transition cursor-pointer"
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-bold text-amber-400">{order.order_number}</span>
                          <span className="text-[10px] text-slate-500">{TYPE_LABELS[order.order_type]}</span>
                        </div>
                        <div className="text-sm text-slate-200 mt-1 font-medium">{order.customer_name || 'زبون'}</div>
                        <div className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
                          <MapPin size={11} />
                          {order.governorate_name || '—'}
                          {order.technician_name && ` ⋅ ${order.technician_name}`}
                        </div>
                      </button>
                    ))
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {detail && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-3xl w-full p-6 my-8">
            <div className="flex items-start justify-between mb-4">
              <div>
                <h2 className="text-lg font-bold text-slate-100">{detail.order?.order_number}</h2>
                <p className="text-xs text-slate-500 mt-1">
                  {TYPE_LABELS[detail.order?.order_type]} ⋅ {detail.order?.governorate_name || '—'} ⋅{' '}
                  {detail.order?.customer_name || 'زبون'} {detail.order?.customer_phone || ''}
                </p>
              </div>
              <button onClick={() => setDetail(null)} className="p-2 text-slate-400 hover:text-white cursor-pointer">
                <X size={18} />
              </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <div className="space-y-4">
                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3">
                  <h3 className="text-xs font-bold text-slate-300 mb-2 flex items-center gap-1.5">
                    <Route size={14} className="text-amber-400" />
                    طابور التوزيع
                  </h3>
                  {detail.dispatch_queue.length === 0 ? (
                    <div className="text-xs text-slate-600 py-3 text-center">لم يتم التوزيع بعد</div>
                  ) : (
                    <div className="space-y-2 max-h-64 overflow-y-auto">
                      {detail.dispatch_queue.map((entry) => {
                        const meta = DISPATCH_STATUS_LABELS[entry.status];
                        return (
                          <div key={entry.id} className="bg-slate-900 border border-slate-800 rounded-lg p-2.5">
                            <div className="flex items-center justify-between">
                              <span className="text-xs font-bold text-slate-200">
                                #{entry.position} {entry.technician_name}
                              </span>
                              <span className={`text-[10px] px-2 py-0.5 rounded-full border font-bold ${meta.className}`}>
                                {meta.label}
                              </span>
                            </div>
                            <div className="text-[10px] text-slate-500 mt-1">
                              Score {Number(entry.priority_score).toFixed(1)}
                              {entry.selection_reason?.governorate && ` ⋅ ${entry.selection_reason.governorate}`}
                              {entry.selection_reason?.rating !== undefined &&
                                ` ⋅ تقييم ${Number(entry.selection_reason.rating).toFixed(1)}`}
                              {entry.selection_reason?.completed_jobs !== undefined &&
                                ` ⋅ ${entry.selection_reason.completed_jobs} عملية`}
                              {entry.selection_reason?.is_new_technician && ' ⋅ مرحلة الإثبات'}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>

                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3">
                  <h3 className="text-xs font-bold text-slate-300 mb-2 flex items-center gap-1.5">
                    <UserCheck size={14} className="text-emerald-400" />
                    تعيين يدوي
                  </h3>
                  <select
                    defaultValue=""
                    onChange={(e) => handleManualAssign(detail.order.id, e.target.value)}
                    className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
                  >
                    <option value="">اختر فنياً لتعيينه...</option>
                    {technicians.map((t) => (
                      <option key={t.id} value={t.id}>
                        {t.full_name} ⋅ {t.governorate_name || '—'} ⋅ {Number(t.rating).toFixed(1)}★
                      </option>
                    ))}
                  </select>
                  <button
                    onClick={() => handleRedispatch(detail.order.id)}
                    className="w-full mt-2 px-4 py-2 bg-sky-500/20 text-sky-300 border border-sky-500/40 rounded-xl text-xs font-bold hover:bg-sky-500/30 cursor-pointer"
                  >
                    إعادة تشغيل التوزيع التلقائي
                  </button>
                </div>

                {detail.tracking && (
                  <div className="bg-slate-950 border border-slate-800 rounded-xl p-3">
                    <h3 className="text-xs font-bold text-slate-300 mb-2 flex items-center gap-1.5">
                      <MapPin size={14} className="text-rose-400" />
                      تتبع الفني
                    </h3>
                    <div className="text-xs text-slate-400">
                      الحالة: {detail.tracking.status} ⋅ الإحداثيات: {detail.tracking.lat}, {detail.tracking.lng}
                    </div>
                    <a
                      href={`https://www.google.com/maps?q=${detail.tracking.lat},${detail.tracking.lng}`}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-block mt-2 text-xs text-sky-400 hover:underline"
                    >
                      فتح على الخريطة
                    </a>
                  </div>
                )}
              </div>

              <div className="space-y-4">
                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3">
                  <h3 className="text-xs font-bold text-slate-300 mb-2 flex items-center gap-1.5">
                    <Clock size={14} className="text-violet-400" />
                    سجل الحالات
                  </h3>
                  <div className="space-y-2 max-h-52 overflow-y-auto">
                    {detail.timeline.map((event) => (
                      <div key={event.id} className="text-xs border-r-2 border-slate-800 pr-3">
                        <div className="text-slate-200 font-bold">{event.status}</div>
                        <div className="text-slate-500 text-[11px]">
                          {event.notes} ⋅ {new Date(event.created_at).toLocaleString('ar-IQ')}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3">
                  <h3 className="text-xs font-bold text-slate-300 mb-2">التسعير</h3>
                  {detail.pricing ? (
                    <div className="text-xs text-slate-400 space-y-1">
                      <div>السعر الأساسي: {Number(detail.pricing.base_price_iqd).toLocaleString('en-US')} د.ع</div>
                      <div>
                        العمولة ({detail.pricing.platform_commission_percent}%):{' '}
                        {Number(detail.pricing.platform_commission_iqd).toLocaleString('en-US')} د.ع
                      </div>
                      <div className="text-emerald-400 font-bold">
                        مستحق الفني: {Number(detail.pricing.technician_payout_iqd).toLocaleString('en-US')} د.ع
                      </div>
                      <div>حالة الدفع: {detail.pricing.payment_status}</div>
                    </div>
                  ) : (
                    <div className="text-xs text-slate-600">لم يتم التسعير بعد</div>
                  )}
                </div>

                <div className="bg-slate-950 border border-slate-800 rounded-xl p-3">
                  <h3 className="text-xs font-bold text-slate-300 mb-2">تغيير الحالة</h3>
                  <select
                    value={detail.order?.status}
                    onChange={(e) => handleStatusChange(detail.order.id, e.target.value as ServiceOrderStatus)}
                    className="w-full bg-slate-900 border border-slate-800 rounded-xl px-3 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
                  >
                    {KANBAN_COLUMNS.map((column) => (
                      <option key={column.status} value={column.status}>
                        {column.label}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ServiceOrdersPage;
