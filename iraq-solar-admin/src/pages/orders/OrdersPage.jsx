import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Eye, PackageSearch, Download } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { getOrders, updateOrderStatus } from '../../api/adminApi';
import { getStatusName, formatDate, formatUSD, getPaymentMethodName } from '../../utils/formatters';
import { ORDER_STATUSES } from '../../utils/constants';
import DataTable from '../../components/shared/DataTable';
import SearchFilterBar from '../../components/shared/SearchFilterBar';
import StatusBadge from '../../components/shared/StatusBadge';

const OrdersPage = () => {
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState({
    status: ''
  });

  const fetchOrders = useCallback(async () => {
    setIsLoading(true);
    try {
      // API expects { search, status } 
      const response = await getOrders({ search, status: filters.status });
      let ordersData = [];
      if (response?.data?.data?.orders) {
        ordersData = response.data.data.orders;
      } else if (response?.data?.data) {
        ordersData = response.data.data;
      } else if (response?.data) {
        ordersData = response.data;
      }
      
      setOrders(Array.isArray(ordersData) ? ordersData : []);
    } catch (error) {
      console.error('Error fetching orders:', error);
      toast.error('حدث خطأ أثناء جلب الطلبات');
    } finally {
      setIsLoading(false);
    }
  }, [search, filters.status]);

  useEffect(() => {
    // Add debounce for search
    const timer = setTimeout(() => {
      fetchOrders();
    }, 500);
    return () => clearTimeout(timer);
  }, [fetchOrders]);

  const handleStatusChange = async (id, newStatus) => {
    try {
      await updateOrderStatus(id, newStatus);
      toast.success('تم تحديث حالة الطلب بنجاح');
      fetchOrders();
    } catch (error) {
      console.error('Error updating order status:', error);
      toast.error('حدث خطأ أثناء تحديث حالة الطلب');
    }
  };

  const columns = [
    {
      header: 'رقم الطلب',
      accessor: 'id',
      cell: (row) => (
        <span className="font-mono text-gray-300">
          #{String(row.id).substring(0, 8)}
        </span>
      )
    },
    {
      header: 'المبلغ',
      accessor: 'total_amount_usd',
      cell: (row) => (
        <span className="font-bold text-white">
          {formatUSD ? formatUSD(row.total_amount_usd) : '$' + Number(row.total_amount_usd).toFixed(2)}
        </span>
      )
    },
    {
      header: 'طريقة الدفع',
      accessor: 'payment_method',
      cell: (row) => (
        <span className="text-gray-300">
          {getPaymentMethodName ? getPaymentMethodName(row.payment_method) : row.payment_method}
        </span>
      )
    },
    {
      header: 'التاريخ',
      accessor: 'created_at',
      cell: (row) => (
        <span className="text-gray-300 text-sm">
          {formatDate ? formatDate(row.created_at) : row.created_at}
        </span>
      )
    },
    {
      header: 'الحالة',
      accessor: 'status',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <StatusBadge status={row.status} label={getStatusName ? getStatusName(row.status) : row.status} />
        </div>
      )
    },
    {
      header: 'تحديث الحالة',
      accessor: 'update_status',
      cell: (row) => (
        <select
          value={row.status}
          onChange={(e) => handleStatusChange(row.id, e.target.value)}
          className="form-select py-1 px-2 text-sm bg-white/5 border-white/10"
        >
          {ORDER_STATUSES && ORDER_STATUSES.map(s => (
            <option key={s.value} value={s.value} className="bg-dark-navy text-white">
              {s.label}
            </option>
          ))}
          {(!ORDER_STATUSES) && (
            <>
              <option value="pending" className="bg-dark-navy text-white">قيد الانتظار</option>
              <option value="confirmed" className="bg-dark-navy text-white">مؤكد</option>
              <option value="processing" className="bg-dark-navy text-white">قيد التجهيز</option>
              <option value="completed" className="bg-dark-navy text-white">مكتمل</option>
              <option value="cancelled" className="bg-dark-navy text-white">ملغي</option>
            </>
          )}
        </select>
      )
    },
    {
      header: 'الإجراءات',
      accessor: 'actions',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate(`/orders/${row.id}`)}
            className="p-2 hover:bg-white/5 rounded-lg text-blue-400 transition-colors"
            title="عرض التفاصيل"
          >
            <Eye className="w-5 h-5" />
          </button>
        </div>
      )
    }
  ];

  const filterOptions = [
    {
      key: 'status',
      placeholder: 'جميع الحالات',
      value: filters.status,
      options: [
        { value: 'pending', label: 'قيد الانتظار' },
        { value: 'confirmed', label: 'مؤكد' },
        { value: 'processing', label: 'قيد التجهيز' },
        { value: 'completed', label: 'مكتمل' },
        { value: 'cancelled', label: 'ملغي' }
      ]
    }
  ];

  return (
    <div className="space-y-6 animate-slide-in">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">الطلبات</h1>
          <p className="text-gray-400">إدارة ومتابعة طلبات العملاء</p>
        </div>
      </div>

      <div className="glass rounded-2xl p-6">
        <SearchFilterBar
          searchQuery={search}
          onSearchChange={setSearch}
          placeholder="ابحث برقم الطلب..."
          filters={filterOptions}
          activeFilters={filters}
          onFilterChange={(key, value) => setFilters(prev => ({ ...prev, [key]: value }))}
          onClearFilters={() => setFilters({ status: '' })}
        />
        
        <div className="mt-6">
          <DataTable
            columns={columns}
            data={orders}
            isLoading={isLoading}
            emptyMessage="لا توجد طلبات مطابقة للبحث"
            emptyIcon={PackageSearch}
          />
        </div>
      </div>
    </div>
  );
};

export default OrdersPage;
