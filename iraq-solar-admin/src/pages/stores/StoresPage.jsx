import React, { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Edit, Trash2, Eye, Store, ShieldAlert, CheckCircle, XCircle } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { getStores, toggleUserStatus, deleteUser } from '../../api/adminApi';
import DataTable from '../../components/shared/DataTable';
import SearchFilterBar from '../../components/shared/SearchFilterBar';
import StatusBadge from '../../components/shared/StatusBadge';
import ConfirmDialog from '../../components/shared/ConfirmDialog';

const StoresPage = () => {
  const navigate = useNavigate();
  const [stores, setStores] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  
  // Delete dialog state
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [storeToDelete, setStoreToDelete] = useState(null);

  const fetchStores = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await getStores();
      let storesData = [];
      if (response?.data?.data?.users) {
        storesData = response.data.data.users;
      } else if (response?.data?.data) {
        storesData = response.data.data;
      } else if (response?.data) {
        storesData = response.data;
      }
      setStores(Array.isArray(storesData) ? storesData : []);
    } catch (error) {
      console.error('Error fetching stores:', error);
      toast.error('حدث خطأ أثناء جلب المتاجر');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchStores();
  }, [fetchStores]);

  const handleToggleStatus = async (id, currentStatus) => {
    try {
      await toggleUserStatus(id);
      toast.success('تم تحديث حالة المتجر بنجاح');
      fetchStores();
    } catch (error) {
      console.error('Error toggling store status:', error);
      toast.error('حدث خطأ أثناء تحديث حالة المتجر');
    }
  };

  const confirmDelete = (store) => {
    setStoreToDelete(store);
    setIsDeleteDialogOpen(true);
  };

  const handleDelete = async () => {
    if (!storeToDelete) return;
    
    try {
      await deleteUser(storeToDelete.id);
      toast.success('تم حذف المتجر بنجاح');
      setIsDeleteDialogOpen(false);
      setStoreToDelete(null);
      fetchStores();
    } catch (error) {
      console.error('Error deleting store:', error);
      toast.error('حدث خطأ أثناء حذف المتجر');
    }
  };

  // Filter based on search (done client-side since API might not handle it or we can pass it to getStores)
  const filteredStores = stores.filter(store => 
    (store.full_name && store.full_name.toLowerCase().includes(search.toLowerCase())) ||
    (store.email && store.email.toLowerCase().includes(search.toLowerCase())) ||
    (store.phone && store.phone.includes(search))
  );

  const columns = [
    {
      header: 'اسم المتجر',
      accessor: 'full_name',
      cell: (row) => (
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary-gold/10 flex items-center justify-center text-primary-gold">
            <Store className="w-5 h-5" />
          </div>
          <div>
            <div className="font-semibold text-white">{row.full_name || 'غير محدد'}</div>
            <div className="text-sm text-gray-400">{row.email || 'لا يوجد بريد'}</div>
          </div>
        </div>
      )
    },
    {
      header: 'رقم الهاتف',
      accessor: 'phone',
      cell: (row) => (
        <div dir="ltr" className="text-right text-gray-300">
          {row.phone || 'غير محدد'}
        </div>
      )
    },
    {
      header: 'المحافظة',
      accessor: 'governorate',
      cell: (row) => (
        <span className="text-gray-300">{row.governorate || 'غير محدد'}</span>
      )
    },
    {
      header: 'الحالة',
      accessor: 'is_active',
      cell: (row) => (
        <StatusBadge 
          status={row.is_active ? 'active' : 'inactive'} 
          label={row.is_active ? 'نشط' : 'غير نشط'} 
        />
      )
    },
    {
      header: 'الإجراءات',
      accessor: 'actions',
      cell: (row) => (
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate(`/users/${row.id}`)}
            className="p-2 hover:bg-white/5 rounded-lg text-blue-400 transition-colors"
            title="عرض التفاصيل"
          >
            <Eye className="w-5 h-5" />
          </button>
          <button
            onClick={() => navigate(`/stores/edit/${row.id}`)}
            className="p-2 hover:bg-white/5 rounded-lg text-green-400 transition-colors"
            title="تعديل المتجر"
          >
            <Edit className="w-5 h-5" />
          </button>
          <button
            onClick={() => handleToggleStatus(row.id, row.is_active)}
            className={`p-2 hover:bg-white/5 rounded-lg transition-colors ${
              row.is_active ? 'text-orange-400' : 'text-emerald-400'
            }`}
            title={row.is_active ? 'تعطيل المتجر' : 'تفعيل المتجر'}
          >
            {row.is_active ? <XCircle className="w-5 h-5" /> : <CheckCircle className="w-5 h-5" />}
          </button>
          <button
            onClick={() => confirmDelete(row)}
            className="p-2 hover:bg-red-500/10 rounded-lg text-red-400 transition-colors"
            title="حذف المتجر"
          >
            <Trash2 className="w-5 h-5" />
          </button>
        </div>
      )
    }
  ];

  return (
    <div className="space-y-6 animate-slide-in">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">إدارة المتاجر</h1>
          <p className="text-gray-400">إدارة حسابات التجار والمتاجر في النظام</p>
        </div>
        <button
          onClick={() => navigate('/stores/add')}
          className="btn btn-primary flex items-center gap-2 whitespace-nowrap"
        >
          <Plus className="w-5 h-5" />
          <span>إضافة متجر</span>
        </button>
      </div>

      <div className="glass rounded-2xl p-6">
        <SearchFilterBar
          searchQuery={search}
          onSearchChange={setSearch}
          placeholder="ابحث عن متجر بالاسم، البريد، أو الهاتف..."
        />
        
        <div className="mt-6">
          <DataTable
            columns={columns}
            data={filteredStores}
            isLoading={isLoading}
            emptyMessage="لا توجد متاجر مطابقة للبحث"
          />
        </div>
      </div>

      <ConfirmDialog
        isOpen={isDeleteDialogOpen}
        title="حذف المتجر"
        message={`هل أنت متأكد من رغبتك في حذف المتجر "${storeToDelete?.full_name}"؟ لا يمكن التراجع عن هذا الإجراء.`}
        confirmText="حذف المتجر"
        cancelText="إلغاء"
        onConfirm={handleDelete}
        onCancel={() => {
          setIsDeleteDialogOpen(false);
          setStoreToDelete(null);
        }}
        isDestructive={true}
      />
    </div>
  );
};

export default StoresPage;
