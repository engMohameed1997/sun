import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowRight, Package, MapPin, CreditCard, Calendar, ShoppingCart, CheckCircle, Clock, Truck } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { getOrderById, updateOrderStatus } from '../../api/adminApi';
import { getStatusName, formatDate, formatUSD, getPaymentMethodName } from '../../utils/formatters';
import { ORDER_STATUSES } from '../../utils/constants';
import StatusBadge from '../../components/shared/StatusBadge';

const OrderDetailPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [order, setOrder] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);
  const [newStatus, setNewStatus] = useState('');

  const fetchOrder = async () => {
    setIsLoading(true);
    try {
      const response = await getOrderById(id);
      const orderData = response?.data?.data?.order || response?.data?.data || response?.data;
      setOrder(orderData);
      if (orderData?.status) {
        setNewStatus(orderData.status);
      }
    } catch (error) {
      console.error('Error fetching order details:', error);
      toast.error('حدث خطأ أثناء جلب تفاصيل الطلب');
      navigate('/orders');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (id) {
      fetchOrder();
    }
  }, [id, navigate]);

  const handleUpdateStatus = async () => {
    if (!newStatus || newStatus === order?.status) return;
    
    setIsUpdating(true);
    try {
      await updateOrderStatus(id, newStatus);
      toast.success('تم تحديث حالة الطلب بنجاح');
      fetchOrder(); // Refetch to get updated data
    } catch (error) {
      console.error('Error updating order status:', error);
      toast.error('حدث خطأ أثناء تحديث حالة الطلب');
    } finally {
      setIsUpdating(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-gold"></div>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="text-center py-12">
        <Package className="w-16 h-16 text-gray-500 mx-auto mb-4" />
        <h2 className="text-2xl font-bold text-white mb-2">الطلب غير موجود</h2>
        <p className="text-gray-400 mb-6">عذراً، لم يتم العثور على الطلب المطلوب.</p>
        <button onClick={() => navigate('/orders')} className="btn btn-primary">
          العودة للطلبات
        </button>
      </div>
    );
  }

  const statuses = ORDER_STATUSES || [
    { value: 'pending', label: 'قيد الانتظار' },
    { value: 'confirmed', label: 'مؤكد' },
    { value: 'processing', label: 'قيد التجهيز' },
    { value: 'completed', label: 'مكتمل' },
    { value: 'cancelled', label: 'ملغي' }
  ];

  return (
    <div className="space-y-6 animate-slide-in">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div className="flex items-center gap-4">
          <button 
            onClick={() => navigate('/orders')}
            className="p-2 bg-white/5 hover:bg-white/10 rounded-xl transition-colors text-gray-300"
          >
            <ArrowRight className="w-5 h-5" />
          </button>
          <div>
            <h1 className="text-2xl font-bold text-white mb-1 flex items-center gap-3">
              تفاصيل الطلب <span className="text-primary-gold font-mono">#{String(order.id).substring(0, 8)}</span>
            </h1>
            <div className="flex items-center gap-3 text-sm text-gray-400">
              <span className="flex items-center gap-1">
                <Calendar className="w-4 h-4" />
                {formatDate ? formatDate(order.created_at) : order.created_at}
              </span>
              <span>•</span>
              <StatusBadge status={order.status} label={getStatusName ? getStatusName(order.status) : order.status} />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Content - Left Side (2 cols) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Order Items */}
          <div className="glass rounded-2xl p-6">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <ShoppingCart className="w-5 h-5 text-primary-gold" />
              المنتجات
            </h2>
            
            {order.items && order.items.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full text-right">
                  <thead>
                    <tr className="border-b border-white/10 text-gray-400 text-sm">
                      <th className="pb-3 font-medium">المنتج</th>
                      <th className="pb-3 font-medium text-center">الكمية</th>
                      <th className="pb-3 font-medium">السعر</th>
                      <th className="pb-3 font-medium">الإجمالي</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {order.items.map((item, index) => (
                      <tr key={index} className="text-white hover:bg-white/5 transition-colors">
                        <td className="py-4">
                          <div className="font-medium">{item.product_name || `منتج #${item.product_id}`}</div>
                        </td>
                        <td className="py-4 text-center text-gray-300">{item.quantity}</td>
                        <td className="py-4 font-mono text-gray-300">{formatUSD ? formatUSD(item.unit_price_usd) : '$' + item.unit_price_usd}</td>
                        <td className="py-4 font-mono font-bold">{formatUSD ? formatUSD(item.total_price_usd) : '$' + item.total_price_usd}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="text-center py-8 text-gray-400">
                لا توجد منتجات مسجلة لهذا الطلب
              </div>
            )}
          </div>
        </div>

        {/* Sidebar - Right Side (1 col) */}
        <div className="space-y-6">
          {/* Order Summary & Status Update */}
          <div className="glass rounded-2xl p-6">
            <h2 className="text-xl font-bold text-white mb-6">تحديث حالة الطلب</h2>
            
            <div className="space-y-4">
              <div className="form-group">
                <label className="form-label text-sm text-gray-400 mb-2 block">الحالة الحالية</label>
                <select
                  value={newStatus}
                  onChange={(e) => setNewStatus(e.target.value)}
                  className="form-select w-full mb-4"
                  disabled={isUpdating}
                >
                  {statuses.map(s => (
                    <option key={s.value} value={s.value} className="bg-dark-navy">
                      {s.label}
                    </option>
                  ))}
                </select>
              </div>
              
              <button
                onClick={handleUpdateStatus}
                disabled={isUpdating || newStatus === order.status}
                className="btn btn-primary w-full flex justify-center items-center gap-2"
              >
                {isUpdating ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <CheckCircle className="w-5 h-5" />
                )}
                <span>حفظ الحالة الجديدة</span>
              </button>
            </div>
          </div>

          {/* Customer & Shipping Info */}
          <div className="glass rounded-2xl p-6 space-y-6">
            <div>
              <h3 className="text-gray-400 text-sm mb-3 flex items-center gap-2">
                <MapPin className="w-4 h-4" />
                عنوان الشحن
              </h3>
              <p className="text-white font-medium bg-white/5 p-3 rounded-xl border border-white/10">
                {order.shipping_address || 'لم يتم تحديد عنوان'}
              </p>
            </div>

            <div>
              <h3 className="text-gray-400 text-sm mb-3 flex items-center gap-2">
                <CreditCard className="w-4 h-4" />
                معلومات الدفع
              </h3>
              <div className="bg-white/5 p-4 rounded-xl border border-white/10 space-y-3">
                <div className="flex justify-between items-center text-sm">
                  <span className="text-gray-400">طريقة الدفع:</span>
                  <span className="text-white font-medium">
                    {getPaymentMethodName ? getPaymentMethodName(order.payment_method) : order.payment_method}
                  </span>
                </div>
                <div className="flex justify-between items-center text-sm">
                  <span className="text-gray-400">حالة الدفع:</span>
                  <StatusBadge 
                    status={order.payment_status === 'paid' ? 'active' : 'pending'} 
                    label={order.payment_status === 'paid' ? 'مدفوع' : 'غير مدفوع'} 
                  />
                </div>
                <div className="pt-3 border-t border-white/10 flex justify-between items-center">
                  <span className="text-gray-400">الإجمالي:</span>
                  <span className="text-xl font-bold text-primary-gold font-mono">
                    {formatUSD ? formatUSD(order.total_amount_usd) : '$' + order.total_amount_usd}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OrderDetailPage;
