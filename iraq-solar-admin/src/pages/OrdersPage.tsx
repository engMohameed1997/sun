import React, { useState, useEffect } from 'react';
import { ShoppingCart, Search, Eye, CheckCircle2, Clock, XCircle, Truck, PackageCheck } from 'lucide-react';
import { api } from '../services/api';
import type { Order, OrderStatus } from '../types';

export const OrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [search, setSearch] = useState('');
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/admin/orders?status=${statusFilter}&search=${search}`);
      if (res.data?.data?.orders) {
        setOrders(res.data.data.orders);
      } else {
        setOrders([]);
      }
    } catch (err) {
      console.error('Failed to fetch orders', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [statusFilter]);

  const handleUpdateStatus = async (orderId: string, newStatus: OrderStatus) => {
    try {
      await api.put(`/admin/orders/${orderId}/status`, { status: newStatus });
      fetchOrders();
      if (selectedOrder && selectedOrder.id === orderId) {
        setSelectedOrder({ ...selectedOrder, status: newStatus });
      }
    } catch (err) {
      alert('حدث خطأ أثناء تحديث حالة الطلب');
    }
  };

  const openDetailModal = async (order: Order) => {
    setSelectedOrder(order);
    try {
      const res = await api.get(`/admin/orders/${order.id}`);
      if (res.data?.data?.items) {
        setSelectedOrder({ ...order, items: res.data.data.items });
      }
    } catch (err) {}
  };

  const getStatusBadge = (status: OrderStatus) => {
    switch (status) {
      case 'pending':
        return <span className="bg-amber-500/10 text-amber-400 border border-amber-500/30 px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1.5"><Clock size={14}/> قيد الانتظار</span>;
      case 'confirmed':
        return <span className="bg-blue-500/10 text-blue-400 border border-blue-500/30 px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1.5"><CheckCircle2 size={14}/> تم التأكيد</span>;
      case 'processing':
        return <span className="bg-purple-500/10 text-purple-400 border border-purple-500/30 px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1.5"><Truck size={14}/> قيد التجهيز</span>;
      case 'completed':
        return <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1.5"><PackageCheck size={14}/> مكتمل</span>;
      case 'cancelled':
        return <span className="bg-rose-500/10 text-rose-400 border border-rose-500/30 px-3 py-1 rounded-full text-xs font-semibold flex items-center gap-1.5"><XCircle size={14}/> ملغي</span>;
      default:
        return <span className="bg-slate-800 text-slate-300 text-xs px-3 py-1 rounded-full">{status}</span>;
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <ShoppingCart className="text-amber-400" size={22} />
            إدارة الطلبات والحجوزات اللحظية
          </h1>
          <p className="text-slate-400 text-xs mt-1">متابعة تدفق الطلبات، تحديث الحالات، وتتبع تايم لاين التنفيذ</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative flex-1 sm:w-64">
            <input
              type="text"
              placeholder="بحث باسم الزبون أو رَقَم الطلب..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchOrders()}
              className="w-full bg-slate-950/80 border border-slate-800 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
            />
            <Search size={15} className="absolute left-3 top-2.5 text-slate-500" />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-slate-950/80 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
          >
            <option value="">جميع الحالات</option>
            <option value="pending">قيد الانتظار</option>
            <option value="confirmed">تم التأكيد</option>
            <option value="processing">قيد التجهيز</option>
            <option value="completed">مكتمل</option>
            <option value="cancelled">ملغي</option>
          </select>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-right text-xs">
            <thead className="bg-slate-950/60 text-slate-400 border-b border-slate-800">
              <tr>
                <th className="p-4 font-semibold">معرف الطلب</th>
                <th className="p-4 font-semibold">الزبون</th>
                <th className="p-4 font-semibold">العنوان</th>
                <th className="p-4 font-semibold">المبلغ الإجمالي</th>
                <th className="p-4 font-semibold">الحالة الحالية</th>
                <th className="p-4 font-semibold">التاريخ</th>
                <th className="p-4 font-semibold text-center">الإجراءات</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 text-slate-200">
              {loading ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-slate-400">
                    ↻ جارٍ تحميل الطلبات...
                  </td>
                </tr>
              ) : orders.length === 0 ? (
                <tr>
                  <td colSpan={7} className="p-8 text-center text-slate-400">
                    لا توجد طلبات تطابق الفلتر المحدد
                  </td>
                </tr>
              ) : (
                orders.map((order) => (
                  <tr key={order.id} className="hover:bg-slate-800/40 transition">
                    <td className="p-4 font-mono font-bold text-amber-400">{order.id.slice(0, 8)}</td>
                    <td className="p-4">
                      <div className="font-semibold text-slate-100">{order.customer_name || 'زبون عام'}</div>
                      <div className="text-[11px] text-slate-400">{order.customer_phone}</div>
                    </td>
                    <td className="p-4 text-slate-300 max-w-xs truncate">{order.shipping_address}</td>
                    <td className="p-4 font-bold text-emerald-400">${order.total_amount_usd.toLocaleString()}</td>
                    <td className="p-4">{getStatusBadge(order.status)}</td>
                    <td className="p-4 text-slate-400">{new Date(order.created_at).toLocaleDateString('ar-IQ')}</td>
                    <td className="p-4 text-center">
                      <div className="flex items-center justify-center gap-2">
                        <button
                          onClick={() => openDetailModal(order)}
                          className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg transition"
                          title="عرض التاصيل والتاريخ"
                        >
                          <Eye size={16} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {selectedOrder && (
        <div className="fixed inset-y-0 right-0 left-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-6 space-y-6 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800 pb-4">
              <div>
                <h3 className="text-lg font-bold text-slate-100">تفاصيل الطلب #{selectedOrder.id.slice(0, 8)}</h3>
                <p className="text-xs text-slate-400">تاريخ الطلب: {new Date(selectedOrder.created_at).toLocaleString('ar-IQ')}</p>
              </div>
              <button
                onClick={() => setSelectedOrder(null)}
                className="p-2 text-slate-400 hover:text-slate-100 rounded-lg hover:bg-slate-800"
              >
                ✕
              </button>
            </div>

            <div className="grid grid-cols-2 gap-4 bg-slate-950/60 p-4 rounded-xl text-xs border border-slate-800/80">
              <div>
                <span className="text-slate-500 font-semibold block mb-1">اسم الزبون:</span>
                <span className="text-slate-200 font-bold">{selectedOrder.customer_name || 'غير محدد'}</span>
              </div>
              <div>
                <span className="text-slate-500 font-semibold block mb-1">رقم الهاتف:</span>
                <span className="text-slate-200 font-mono">{selectedOrder.customer_phone || 'غير محدد'}</span>
              </div>
              <div className="col-span-2">
                <span className="text-slate-500 font-semibold block mb-1">عنوان التوصيل:</span>
                <span className="text-slate-200">{selectedOrder.shipping_address}</span>
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-semibold text-slate-300">تغيير حالة الطلب:</label>
              <div className="flex flex-wrap gap-2">
                {(['pending', 'confirmed', 'processing', 'completed', 'cancelled'] as OrderStatus[]).map((st) => (
                  <button
                    key={st}
                    onClick={() => handleUpdateStatus(selectedOrder.id, st)}
                    className={`px-3 py-1.5 rounded-xl text-xs font-semibold border transition ${
                      selectedOrder.status === st
                        ? 'bg-amber-500 text-slate-950 border-amber-400 font-bold'
                        : 'bg-slate-800 text-slate-300 border-slate-700 hover:bg-slate-700'
                    }`}
                  >
                    {st === 'pending' && 'قيد الانتظار'}
                    {st === 'confirmed' && 'تأكيد'}
                    {st === 'processing' && 'تجهيز'}
                    {st === 'completed' && 'إكمال'}
                    {st === 'cancelled' && 'إلغاء'}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex justify-end pt-4 border-t border-slate-800">
              <button
                onClick={() => setSelectedOrder(null)}
                className="px-4 py-2 bg-slate-800 text-slate-200 rounded-xl text-xs font-bold hover:bg-slate-700"
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
