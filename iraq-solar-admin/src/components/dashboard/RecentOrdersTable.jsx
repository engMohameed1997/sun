import React, { useState } from 'react';
import StatusBadge from '../shared/StatusBadge';
import { Eye, ArrowUpRight, ShoppingBag } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

const mockOrders = [
  {
    id: 'ORD-9821',
    customer: 'علي الحلي',
    governorate: 'بابل',
    item: 'منظومة طاقة شمسية 5kW متكاملة',
    amount: '4,250,000 د.ع',
    status: 'pending',
    statusLabel: 'قيد الانتظار',
    date: '2026-07-26'
  },
  {
    id: 'ORD-9820',
    customer: 'شركة الأفق الهندسي',
    governorate: 'بغداد',
    item: 'عدد 10 ألواح شمسية Jinko 550W',
    amount: '1,800,000 د.ع',
    status: 'processing',
    statusLabel: 'قيد التجهيز',
    date: '2026-07-26'
  },
  {
    id: 'ORD-9819',
    customer: 'د. محمد الكرخي',
    governorate: 'النجف',
    item: 'بطارية ليثيوم 48V 100Ah + إنفرتر 3kW',
    amount: '2,900,000 د.ع',
    status: 'confirmed',
    statusLabel: 'مؤكدة',
    date: '2026-07-25'
  },
  {
    id: 'ORD-9818',
    customer: 'حسن البصري',
    governorate: 'البصرة',
    item: 'منظومة 10kW ثلاثية الأطوار (3-Phase)',
    amount: '7,800,000 د.ع',
    status: 'completed',
    statusLabel: 'مكتملة',
    date: '2026-07-25'
  },
  {
    id: 'ORD-9817',
    customer: 'عمر الموصلي',
    governorate: 'نينوى',
    item: 'إنفرتر هوائي Must 5KW Off-Grid',
    amount: '850,000 د.ع',
    status: 'cancelled',
    statusLabel: 'ملغاة',
    date: '2026-07-24'
  }
];

const RecentOrdersTable = () => {
  const [orders, setOrders] = useState(mockOrders);
  const navigate = useNavigate();

  const handleStatusChange = (orderId, newStatus, label) => {
    setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: newStatus, statusLabel: label } : o));
    toast.success(`تم تحديث حالة الطلب ${orderId} إلى: ${label}`);
  };

  return (
    <div className="bg-white rounded-xl p-6 shadow-xs border border-slate-200 mb-6">
      <div className="flex justify-between items-center mb-5 pb-4 border-b border-slate-100">
        <div>
          <h3 className="font-bold text-base text-slate-900 flex items-center gap-2 m-0">
            <ShoppingBag size={18} className="text-amber-500" />
            أحدث الطلبات الواردة
          </h3>
          <p className="text-xs text-slate-500 mt-0.5 m-0">آخر المعاملات والطلبات المقدمة عبر المنصة</p>
        </div>

        <button 
          onClick={() => navigate('/orders')}
          className="text-amber-600 hover:text-amber-700 text-xs font-bold flex items-center gap-1 hover:underline cursor-pointer"
        >
          <span>عرض كافة الطلبات</span>
          <ArrowUpRight size={14} />
        </button>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-right text-xs">
          <thead>
            <tr className="bg-slate-50 text-slate-700 font-bold border-b border-slate-200">
              <th className="py-3 px-3 rounded-r-lg">رقم الطلب</th>
              <th className="py-3 px-3">العميل</th>
              <th className="py-3 px-3">المحافظة</th>
              <th className="py-3 px-3">المنتج / المنظومة</th>
              <th className="py-3 px-3">القيمة</th>
              <th className="py-3 px-3">الحالة</th>
              <th className="py-3 px-3">التاريخ</th>
              <th className="py-3 px-3 text-center rounded-l-lg">الإجراء</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {orders.map((order) => (
              <tr key={order.id} className="hover:bg-slate-50/80 transition-colors">
                <td className="py-3 px-3 font-bold text-slate-900">{order.id}</td>
                <td className="py-3 px-3 font-semibold text-slate-800">{order.customer}</td>
                <td className="py-3 px-3 text-slate-600 font-medium">{order.governorate}</td>
                <td className="py-3 px-3 text-slate-700 font-medium max-w-xs truncate" title={order.item}>
                  {order.item}
                </td>
                <td className="py-3 px-3 font-extrabold text-amber-700">{order.amount}</td>
                <td className="py-3 px-3">
                  <StatusBadge status={order.status} label={order.statusLabel} />
                </td>
                <td className="py-3 px-3 text-slate-500 font-medium">{order.date}</td>
                <td className="py-3 px-3 text-center">
                  <div className="flex items-center justify-center gap-2">
                    <select
                      value={order.status}
                      onChange={(e) => {
                        const labels = {
                          pending: 'قيد الانتظار',
                          confirmed: 'مؤكدة',
                          processing: 'قيد التجهيز',
                          completed: 'مكتملة',
                          cancelled: 'ملغاة'
                        };
                        handleStatusChange(order.id, e.target.value, labels[e.target.value]);
                      }}
                      className="text-xs border border-slate-200 rounded-md px-2 py-1 bg-white hover:border-slate-300 font-semibold text-slate-700 outline-none cursor-pointer"
                    >
                      <option value="pending">قيد الانتظار</option>
                      <option value="confirmed">مؤكدة</option>
                      <option value="processing">قيد التجهيز</option>
                      <option value="completed">مكتملة</option>
                      <option value="cancelled">ملغاة</option>
                    </select>

                    <button
                      onClick={() => navigate(`/orders?id=${order.id}`)}
                      className="p-1 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-md transition cursor-pointer"
                      title="عرض التفاصيل"
                    >
                      <Eye size={16} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default RecentOrdersTable;
