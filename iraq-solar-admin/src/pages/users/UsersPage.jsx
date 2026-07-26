import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Plus, Edit, Trash2, Shield, UserX, UserCheck, Eye, ChevronRight, ChevronLeft } from 'lucide-react';
import toast from 'react-hot-toast';
import DataTable from '../../components/shared/DataTable';
import SearchFilterBar from '../../components/shared/SearchFilterBar';
import StatusBadge from '../../components/shared/StatusBadge';
import ConfirmDialog from '../../components/shared/ConfirmDialog';
import { getUsers, toggleUserStatus, deleteUser } from '../../api/adminApi';
import { getRoleName } from '../../utils/formatters';

const UsersPage = () => {
  const navigate = useNavigate();
  const [users, setUsers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState({ role: '', status: '' });
  
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const limit = 10;
  
  const [confirmDialog, setConfirmDialog] = useState({ isOpen: false, id: null, action: null });

  const fetchUsers = async () => {
    setIsLoading(true);
    try {
      const is_active = filters.status === 'active' ? true : filters.status === 'inactive' ? false : undefined;
      const res = await getUsers({ search, role: filters.role, is_active, page, limit });
      
      let usersData = [];
      let totalCount = 0;
      
      if (res.data?.data?.users) {
        usersData = res.data.data.users;
        totalCount = res.data.data.total || 0;
      } else if (res.data?.data) {
        usersData = Array.isArray(res.data.data) ? res.data.data : [];
        totalCount = usersData.length;
      } else if (res.data) {
        usersData = Array.isArray(res.data) ? res.data : [];
        totalCount = usersData.length;
      }
      
      setUsers(usersData);
      setTotal(totalCount);
    } catch (error) {
      toast.error('فشل في جلب المستخدمين');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [search, filters, page]);

  const handleToggleStatus = async (id, currentStatus) => {
    try {
      await toggleUserStatus(id, !currentStatus);
      toast.success('تم تحديث حالة المستخدم بنجاح');
      fetchUsers();
    } catch (e) {
      toast.error('حدث خطأ أثناء التحديث');
    }
  };

  const handleDelete = async () => {
    try {
      await deleteUser(confirmDialog.id);
      toast.success('تم حذف المستخدم بنجاح');
      fetchUsers();
    } catch (e) {
      toast.error('حدث خطأ أثناء الحذف');
    } finally {
      setConfirmDialog({ isOpen: false, id: null, action: null });
    }
  };

  const columns = [
    { header: 'الاسم', accessor: 'full_name', render: (row) => <div className="font-bold text-gray-800">{row.full_name || row.name}</div> },
    { header: 'البريد الإلكتروني', accessor: 'email' },
    { header: 'رقم الهاتف', accessor: 'phone', render: (row) => <span dir="ltr">{row.phone}</span> },
    { header: 'الدور', accessor: 'role', render: (row) => (
      <div className="flex items-center gap-2">
        <Shield size={16} className="text-primary-gold" />
        <span>{getRoleName(row.role)}</span>
      </div>
    )},
    { header: 'المحافظة', accessor: 'governorate' },
    { header: 'الحالة', accessor: 'is_active', render: (row) => (
      <StatusBadge status={row.is_active ? 'active' : 'inactive'} label={row.is_active ? 'نشط' : 'غير نشط'} />
    )},
    { header: 'الإجراءات', accessor: 'actions', render: (row) => (
      <div className="flex gap-2">
        <button onClick={() => navigate(`/users/${row.id}`)} className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg" title="عرض التفاصيل"><Eye size={18} /></button>
        <button onClick={() => handleToggleStatus(row.id, row.is_active)} className={`p-2 rounded-lg ${row.is_active ? 'text-orange-600 hover:bg-orange-50' : 'text-green-600 hover:bg-green-50'}`} title={row.is_active ? 'تعطيل الحساب' : 'تنشيط الحساب'}>
          {row.is_active ? <UserX size={18} /> : <UserCheck size={18} />}
        </button>
        <button onClick={() => setConfirmDialog({ isOpen: true, id: row.id, action: 'delete' })} className="p-2 text-red-600 hover:bg-red-50 rounded-lg" title="حذف"><Trash2 size={18} /></button>
      </div>
    )}
  ];

  return (
    <div className="animate-slide-in">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-dark-navy">إدارة المستخدمين</h2>
        <button onClick={() => navigate('/users/add')} className="btn btn-primary">
          <Plus size={20} /> إضافة مستخدم جديد
        </button>
      </div>

      <SearchFilterBar 
        searchQuery={search}
        onSearchChange={setSearch}
        filters={[
          { key: 'role', placeholder: 'جميع الأدوار', value: filters.role, options: [
            { value: 'merchant', label: 'متجر' },
            { value: 'engineer', label: 'مهندس' },
            { value: 'installer', label: 'فني تركيب' },
            { value: 'customer', label: 'عميل' },
            { value: 'admin', label: 'مدير نظام' }
          ]},
          { key: 'status', placeholder: 'جميع الحالات', value: filters.status, options: [
            { value: 'active', label: 'نشط' },
            { value: 'inactive', label: 'غير نشط' }
          ]}
        ]}
        onFilterChange={(k, v) => { setFilters(prev => ({ ...prev, [k]: v })); setPage(1); }}
        onClear={() => { setSearch(''); setFilters({ role: '', status: '' }); setPage(1); }}
      />

      <DataTable 
        columns={columns} 
        data={users} 
        isLoading={isLoading} 
      />

      {!isLoading && total > limit && (
        <div className="flex justify-center items-center gap-4 mt-6">
          <button 
            disabled={page === 1}
            onClick={() => setPage(p => p - 1)}
            className="p-2 bg-white rounded shadow disabled:opacity-50"
          >
            <ChevronRight size={20} />
          </button>
          <span className="font-bold">{page}</span>
          <button 
            disabled={page * limit >= total}
            onClick={() => setPage(p => p + 1)}
            className="p-2 bg-white rounded shadow disabled:opacity-50"
          >
            <ChevronLeft size={20} />
          </button>
        </div>
      )}

      <ConfirmDialog 
        isOpen={confirmDialog.isOpen}
        title="تأكيد الحذف"
        message="هل أنت متأكد من رغبتك في حذف هذا المستخدم؟ لا يمكن التراجع عن هذا الإجراء."
        onConfirm={handleDelete}
        onCancel={() => setConfirmDialog({ isOpen: false, id: null, action: null })}
      />
    </div>
  );
};

export default UsersPage;
