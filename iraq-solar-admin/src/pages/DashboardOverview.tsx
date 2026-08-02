import React, { useEffect, useState } from 'react';
import {
  TrendingUp,
  ShoppingCart,
  Users,
  Store,
  AlertTriangle,
  DollarSign,
  Clock
} from 'lucide-react';
import { ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';
import { api } from '../services/api';
import type { DashboardStats, Product, RevenueDataPoint } from '../types';

export const DashboardOverview: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [revenueData, setRevenueData] = useState<RevenueDataPoint[]>([]);
  const [lowStockProducts, setLowStockProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsRes, revRes, lowStockRes] = await Promise.all([
          api.get('/admin/stats').catch(() => null),
          api.get('/admin/stats/revenue?days=7').catch(() => null),
          api.get('/admin/products/low-stock').catch(() => null),
        ]);

        if (statsRes?.data?.data) {
          setStats(statsRes.data.data);
        } else {
          setStats({
            total_orders: 0,
            total_revenue_iqd: 0,
            total_users: 1,
            total_products: 0,
            pending_orders: 0,
            new_users_this_month: 0,
            total_stores: 0,
            active_installers: 0,
          });
        }

        if (revRes?.data?.data) {
          setRevenueData(revRes.data.data);
        } else {
          setRevenueData([]);
        }

        if (lowStockRes?.data?.data) {
          setLowStockProducts(lowStockRes.data.data);
        }
      } catch (err) {
        console.error('Failed to load dashboard stats', err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 text-amber-500 font-bold">
        <span className="animate-spin text-2xl ml-2">↻</span> جارٍ تحميل الإحصائيات...
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100">لوحة التحكم والإحصائيات الحية</h1>
          <p className="text-slate-400 text-xs mt-1">نظرة عامة شمولية على المبيعات، الطلبات الحالية، وأوضاع المتاجر</p>
        </div>
        <div className="flex items-center gap-2 text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/30 px-3.5 py-2 rounded-xl">
          <Clock size={16} />
          <span>آخر تحديث: الآن (تحديث لحظي)</span>
        </div>
      </div>

      {lowStockProducts.length > 0 && (
        <div className="bg-rose-500/10 border border-rose-500/30 p-4 rounded-2xl flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-rose-500/20 text-rose-400">
              <AlertTriangle size={20} />
            </div>
            <div>
              <div className="font-bold text-rose-200 text-sm">تنبيه مخزون حرج!</div>
              <div className="text-xs text-rose-300/80">
                هناك {lowStockProducts.length} منتجات وصلت لحد النفاد أو أقل من حد الأمان.
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl space-y-3">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">إجمالي المبيعات</span>
            <div className="p-2 rounded-xl bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
              <DollarSign size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-100">
            {stats?.total_revenue_iqd.toLocaleString()} <span className="text-xs text-slate-400 font-normal">د.ع</span>
          </div>
          <div className="text-xs text-emerald-400 flex items-center gap-1 font-medium">
            <TrendingUp size={14} /> +14.2% مقارنة بالشهر السابق
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl space-y-3">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">إجمالي الطلبات</span>
            <div className="p-2 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20">
              <ShoppingCart size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-100">{stats?.total_orders} طلب</div>
          <div className="text-xs text-amber-400 font-medium">
            {stats?.pending_orders} طلب بانتظار التأكيد
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl space-y-3">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">المتاجر المعتمدة</span>
            <div className="p-2 rounded-xl bg-amber-500/10 text-amber-400 border border-amber-500/20">
              <Store size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-100">{stats?.total_stores} متجر</div>
          <div className="text-xs text-slate-400">موزعة على كافة المحافظات</div>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl space-y-3">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-semibold">المستخدمين والمهندسين</span>
            <div className="p-2 rounded-xl bg-purple-500/10 text-purple-400 border border-purple-500/20">
              <Users size={18} />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-100">{stats?.total_users} مستخدم</div>
          <div className="text-xs text-purple-400 font-medium">
            +{stats?.new_users_this_month} مستخدم جديد هذا الشهر
          </div>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-bold text-slate-200">مخطط المبيعات اليومية (آخر 7 أيام)</h2>
          <span className="text-xs text-slate-400 bg-slate-800 px-3 py-1 rounded-lg">بالدولار USD</span>
        </div>

        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={revenueData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.4} />
                  <stop offset="95%" stopColor="#f59e0b" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} />
              <YAxis stroke="#94a3b8" fontSize={12} />
              <Tooltip
                contentStyle={{ backgroundColor: '#1e293b', borderColor: '#475569', borderRadius: '12px', color: '#fff' }}
              />
              <Area type="monotone" dataKey="revenue" stroke="#f59e0b" strokeWidth={3} fillOpacity={1} fill="url(#colorRev)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};
