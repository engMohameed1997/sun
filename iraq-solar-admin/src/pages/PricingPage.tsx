import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Coins, Scale, TrendingUp, Users, Award, RefreshCw } from 'lucide-react';
import { api } from '../services/api';
import type { ServicePricing, TechnicianDispatchStats, TechnicianLevel } from '../types';

const PAYMENT_STATUS_LABELS: Record<string, { label: string; className: string }> = {
  unpaid: { label: 'غير مدفوع', className: 'text-slate-400 border-slate-700' },
  pending: { label: 'قيد الدفع', className: 'text-amber-300 border-amber-500/40' },
  paid_to_technician: { label: 'مدفوع للفني', className: 'text-sky-300 border-sky-500/40' },
  settled: { label: 'مُسدَّد', className: 'text-emerald-300 border-emerald-500/40' },
};

export const PricingPage: React.FC = () => {
  const [pricing, setPricing] = useState<ServicePricing[]>([]);
  const [levels, setLevels] = useState<TechnicianLevel[]>([]);
  const [stats, setStats] = useState<TechnicianDispatchStats[]>([]);
  const [statusFilter, setStatusFilter] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  const fetchAll = useCallback(async () => {
    setIsLoading(true);
    try {
      const [pricingRes, levelsRes, statsRes] = await Promise.all([
        api.get('/admin/service-pricing', { params: { payment_status: statusFilter } }),
        api.get('/admin/technician-levels'),
        api.get('/admin/dispatch-stats'),
      ]);
      setPricing(pricingRes.data?.data || []);
      setLevels(levelsRes.data?.data || []);
      setStats(statsRes.data?.data || []);
    } catch (err) {
      console.error('Failed to fetch pricing data', err);
    } finally {
      setIsLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  const totals = useMemo(() => {
    return pricing.reduce(
      (acc, p) => ({
        revenue: acc.revenue + Number(p.base_price_iqd || 0),
        commission: acc.commission + Number(p.platform_commission_iqd || 0),
        payout: acc.payout + Number(p.technician_payout_iqd || 0),
        pending: acc.pending + (p.payment_status === 'settled' ? 0 : Number(p.technician_payout_iqd || 0)),
      }),
      { revenue: 0, commission: 0, payout: 0, pending: 0 }
    );
  }, [pricing]);

  const totalOrdersThisMonth = useMemo(
    () => stats.reduce((sum, s) => sum + Number(s.orders_received_this_month || 0), 0),
    [stats]
  );

  const handlePaymentStatus = async (orderId: string, status: string) => {
    try {
      await api.put(`/admin/service-orders/${orderId}/payment-status`, { payment_status: status });
      fetchAll();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث حالة الدفع');
    }
  };

  const handleUpdateLevel = async (level: TechnicianLevel, commissionRate: number) => {
    try {
      await api.put(`/admin/technician-levels/${level.id}`, { ...level, commission_rate: commissionRate });
      fetchAll();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث المستوى');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Coins className="text-amber-400" size={22} />
            التسعير والعمولات وعدالة التوزيع
          </h1>
          <p className="text-slate-400 text-xs mt-1">
            متابعة أرباح المنصة، مستحقات الفنيين، مستويات العمولة، ومؤشرات Fair Dispatch
          </p>
        </div>
        <button
          onClick={fetchAll}
          className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <RefreshCw size={16} />
          تحديث
        </button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'إجمالي قيمة الخدمات', value: totals.revenue, icon: TrendingUp, color: 'text-amber-400' },
          { label: 'عمولات المنصة', value: totals.commission, icon: Scale, color: 'text-emerald-400' },
          { label: 'مستحقات الفنيين', value: totals.payout, icon: Users, color: 'text-sky-400' },
          { label: 'غير مُسدَّد', value: totals.pending, icon: Coins, color: 'text-rose-400' },
        ].map((card) => {
          const Icon = card.icon;
          return (
            <div key={card.label} className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <div className="flex items-center gap-2 text-[11px] text-slate-500">
                <Icon size={14} className={card.color} />
                {card.label}
              </div>
              <div className={`text-lg font-bold mt-2 ${card.color}`}>
                {Number(card.value).toLocaleString('en-US')} د.ع
              </div>
            </div>
          );
        })}
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-bold text-slate-200 flex items-center gap-2">
            <Award size={16} className="text-violet-400" />
            مستويات الفنيين ونسب العمولة
          </h2>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          {levels.map((level) => (
            <div key={level.id} className="bg-slate-950 border border-slate-800 rounded-xl p-3">
              <div className="font-bold text-sm" style={{ color: level.badge_color }}>
                {level.name_ar}
              </div>
              <div className="text-[11px] text-slate-500 mt-1">
                {level.min_jobs}+ عملية ⋅ تقييم {level.min_rating}+
              </div>
              <div className="mt-2 flex items-center gap-2">
                <input
                  type="number"
                  step="0.5"
                  defaultValue={level.commission_rate}
                  onBlur={(e) => {
                    const value = Number(e.target.value);
                    if (value !== level.commission_rate) handleUpdateLevel(level, value);
                  }}
                  className="w-20 bg-slate-900 border border-slate-800 rounded-lg px-2 py-1 text-slate-200 outline-none focus:border-amber-500/50 text-xs"
                />
                <span className="text-xs text-slate-400">% عمولة</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
        <h2 className="text-sm font-bold text-slate-200 flex items-center gap-2 mb-3">
          <Scale size={16} className="text-emerald-400" />
          عدالة التوزيع (Fair Dispatch)
        </h2>
        <div className="overflow-x-auto">
          <table className="w-full text-sm min-w-[720px]">
            <thead>
              <tr className="text-slate-400 text-xs border-b border-slate-800">
                <th className="text-right p-3">الفني</th>
                <th className="text-right p-3">هذا الشهر</th>
                <th className="text-right p-3">هذا الأسبوع</th>
                <th className="text-right p-3">آخر طلب</th>
                <th className="text-right p-3">Boost</th>
                <th className="text-right p-3">الحالة</th>
              </tr>
            </thead>
            <tbody>
              {stats.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-slate-500">
                    لا توجد بيانات توزيع بعد
                  </td>
                </tr>
              ) : (
                stats.map((s) => {
                  const share = totalOrdersThisMonth > 0 ? (s.orders_received_this_month / totalOrdersThisMonth) * 100 : 0;
                  return (
                    <tr key={s.id} className="border-b border-slate-800/60 hover:bg-slate-800/30">
                      <td className="p-3 text-slate-200 font-bold">{s.technician_name}</td>
                      <td className="p-3 text-slate-300">
                        {s.orders_received_this_month}
                        {share > 30 && (
                          <span className="mr-2 text-[10px] text-rose-300 border border-rose-500/40 px-1.5 py-0.5 rounded-full">
                            {share.toFixed(0)}% من الطلبات
                          </span>
                        )}
                      </td>
                      <td className="p-3 text-slate-300">{s.orders_received_this_week}</td>
                      <td className="p-3 text-slate-400 text-xs">
                        {s.last_order_received_at
                          ? new Date(s.last_order_received_at).toLocaleDateString('ar-IQ')
                          : 'لم يستلم بعد'}
                      </td>
                      <td className="p-3 text-amber-400 font-bold">{Number(s.fairness_boost).toFixed(1)}</td>
                      <td className="p-3">
                        {s.is_new_technician && s.new_technician_orders_count < 10 ? (
                          <span className="text-[10px] text-sky-300 border border-sky-500/40 px-2 py-0.5 rounded-full font-bold">
                            مرحلة الإثبات ({s.new_technician_orders_count}/10)
                          </span>
                        ) : (
                          <span className="text-[10px] text-slate-500">نشط</span>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-sm font-bold text-slate-200 flex items-center gap-2">
            <Coins size={16} className="text-amber-400" />
            تسعير الطلبات وحالة الدفع
          </h2>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 rounded-xl px-3 py-1.5 text-slate-200 outline-none focus:border-amber-500/50 text-xs"
          >
            <option value="">كل حالات الدفع</option>
            {Object.entries(PAYMENT_STATUS_LABELS).map(([value, meta]) => (
              <option key={value} value={value}>
                {meta.label}
              </option>
            ))}
          </select>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm min-w-[820px]">
            <thead>
              <tr className="text-slate-400 text-xs border-b border-slate-800">
                <th className="text-right p-3">رقم الطلب</th>
                <th className="text-right p-3">الفني</th>
                <th className="text-right p-3">السعر</th>
                <th className="text-right p-3">العمولة</th>
                <th className="text-right p-3">مستحق الفني</th>
                <th className="text-right p-3">حالة الدفع</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-slate-400 font-bold">
                    جارٍ التحميل...
                  </td>
                </tr>
              ) : pricing.length === 0 ? (
                <tr>
                  <td colSpan={6} className="p-8 text-center text-slate-500">
                    لا توجد سجلات تسعير
                  </td>
                </tr>
              ) : (
                pricing.map((p) => (
                  <tr key={p.id} className="border-b border-slate-800/60 hover:bg-slate-800/30">
                    <td className="p-3 text-amber-400 font-bold">{p.order_number}</td>
                    <td className="p-3 text-slate-300">{p.technician_name || '—'}</td>
                    <td className="p-3 text-slate-300">{Number(p.base_price_iqd).toLocaleString('en-US')}</td>
                    <td className="p-3 text-slate-400">
                      {Number(p.platform_commission_iqd).toLocaleString('en-US')} ({p.platform_commission_percent}%)
                    </td>
                    <td className="p-3 text-emerald-400 font-bold">
                      {Number(p.technician_payout_iqd).toLocaleString('en-US')}
                    </td>
                    <td className="p-3">
                      <select
                        value={p.payment_status}
                        onChange={(e) => handlePaymentStatus(p.order_id, e.target.value)}
                        className={`bg-slate-950 border rounded-lg px-2 py-1 text-xs font-bold outline-none cursor-pointer ${
                          PAYMENT_STATUS_LABELS[p.payment_status]?.className || 'text-slate-300 border-slate-700'
                        }`}
                      >
                        {Object.entries(PAYMENT_STATUS_LABELS).map(([value, meta]) => (
                          <option key={value} value={value} className="text-slate-200 bg-slate-900">
                            {meta.label}
                          </option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default PricingPage;
