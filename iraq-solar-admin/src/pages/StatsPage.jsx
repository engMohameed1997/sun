import React, { useState, useEffect } from 'react';
import { BarChart, Bar, LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { TrendingUp, DollarSign, ShoppingCart, Package } from 'lucide-react';
import toast from 'react-hot-toast';
import { getRevenueStats, getOrdersByStatus, getTopProductsStats } from '../api/adminApi';

const COLORS = ['#F59E0B', '#10B981', '#3B82F6', '#EF4444', '#8B5CF6', '#EC4899'];

const StatsPage = () => {
  const [revenueData, setRevenueData] = useState([]);
  const [ordersByStatus, setOrdersByStatus] = useState([]);
  const [topProducts, setTopProducts] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [days, setDays] = useState(30);

  const fetchStats = async () => {
    setIsLoading(true);
    try {
      const [revRes, ordRes, prodRes] = await Promise.allSettled([
        getRevenueStats(days),
        getOrdersByStatus(),
        getTopProductsStats(10)
      ]);

      if (revRes.status === 'fulfilled') {
        const data = revRes.value.data?.data || revRes.value.data || [];
        setRevenueData(Array.isArray(data) ? data : []);
      }

      if (ordRes.status === 'fulfilled') {
        const data = ordRes.value.data?.data || ordRes.value.data || [];
        setOrdersByStatus(Array.isArray(data) ? data : []);
      }

      if (prodRes.status === 'fulfilled') {
        const data = prodRes.value.data?.data || prodRes.value.data || [];
        setTopProducts(Array.isArray(data) ? data : []);
      }
    } catch (error) {
      console.error('Error fetching stats:', error);
      toast.error('فشل في جلب الإحصائيات');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, [days]);

  const STATUS_NAMES = {
    pending: 'قيد الانتظار',
    confirmed: 'مؤكد',
    processing: 'قيد التجهيز',
    completed: 'مكتمل',
    cancelled: 'ملغى'
  };

  return (
    <div className="animate-slide-in">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-dark-navy">الإحصائيات المتقدمة</h2>
        <select 
          value={days} 
          onChange={(e) => setDays(Number(e.target.value))}
          className="form-select w-auto"
        >
          <option value={7}>آخر 7 أيام</option>
          <option value={14}>آخر 14 يوم</option>
          <option value={30}>آخر 30 يوم</option>
          <option value={90}>آخر 90 يوم</option>
        </select>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="glass p-6 rounded-xl h-96 animate-pulse bg-gray-100" />
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Revenue Chart */}
          <div className="glass p-6 rounded-xl">
            <div className="flex items-center gap-2 mb-4">
              <DollarSign className="text-primary-gold" size={22} />
              <h3 className="font-bold text-lg">نمو الإيرادات</h3>
            </div>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={revenueData.length > 0 ? revenueData : [{name: 'لا توجد بيانات', revenue: 0}]}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" fontSize={12} />
                  <YAxis fontSize={12} />
                  <Tooltip formatter={(v) => [`$${v}`, 'الإيرادات']} />
                  <Bar dataKey="revenue" fill="var(--primary-gold)" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Orders by Status Pie */}
          <div className="glass p-6 rounded-xl">
            <div className="flex items-center gap-2 mb-4">
              <ShoppingCart className="text-primary-gold" size={22} />
              <h3 className="font-bold text-lg">الطلبات حسب الحالة</h3>
            </div>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={ordersByStatus.length > 0 ? ordersByStatus.map(item => ({
                      ...item,
                      name: STATUS_NAMES[item.status] || item.status || item.name,
                    })) : [{name: 'لا توجد بيانات', count: 1}]}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    outerRadius={100}
                    fill="#8884d8"
                    dataKey="count"
                    nameKey="name"
                    label={({name, percent}) => `${name} ${(percent * 100).toFixed(0)}%`}
                  >
                    {(ordersByStatus.length > 0 ? ordersByStatus : [{}]).map((_, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Top Products */}
          <div className="glass p-6 rounded-xl lg:col-span-2">
            <div className="flex items-center gap-2 mb-4">
              <Package className="text-primary-gold" size={22} />
              <h3 className="font-bold text-lg">أفضل المنتجات مبيعاً</h3>
            </div>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={topProducts.length > 0 ? topProducts : [{name: 'لا توجد بيانات', total_sold: 0}]} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" fontSize={12} />
                  <YAxis type="category" dataKey="name" width={150} fontSize={12} />
                  <Tooltip formatter={(v) => [v, 'المبيعات']} />
                  <Bar dataKey="total_sold" fill="#10B981" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
export default StatsPage;
