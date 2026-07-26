import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Edit, Trash2, Shield, UserX, UserCheck, ArrowRight, MapPin, Phone, Mail, Calendar, Clock } from 'lucide-react';
import toast from 'react-hot-toast';
import StatusBadge from '../../components/shared/StatusBadge';
import ConfirmDialog from '../../components/shared/ConfirmDialog';
import { getUserById, toggleUserStatus, deleteUser } from '../../api/adminApi';
import { getRoleName, formatDate } from '../../utils/formatters';

const UserDetailPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const [confirmDialog, setConfirmDialog] = useState({ isOpen: false });

  const fetchUser = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await getUserById(id);
      const userData = res.data?.data || res.data;
      if (userData) {
        setUser(userData);
      } else {
        setError('لم يتم العثور على المستخدم');
      }
    } catch (err) {
      setError('فشل في جلب بيانات المستخدم');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUser();
  }, [id]);

  const handleToggleStatus = async () => {
    if (!user) return;
    try {
      await toggleUserStatus(id, !user.is_active);
      toast.success('تم تحديث حالة المستخدم بنجاح');
      fetchUser();
    } catch (e) {
      toast.error('حدث خطأ أثناء التحديث');
    }
  };

  const handleDelete = async () => {
    try {
      await deleteUser(id);
      toast.success('تم حذف المستخدم بنجاح');
      navigate('/users');
    } catch (e) {
      toast.error('حدث خطأ أثناء الحذف');
    } finally {
      setConfirmDialog({ isOpen: false });
    }
  };

  if (isLoading) {
    return (
      <div className="p-8 glass rounded-xl animate-slide-in">
        <div className="animate-pulse space-y-6">
          <div className="h-8 bg-gray-200 rounded w-1/4"></div>
          <div className="h-32 bg-gray-200 rounded w-full"></div>
          <div className="h-32 bg-gray-200 rounded w-full"></div>
        </div>
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="p-8 glass rounded-xl animate-slide-in text-center">
        <h2 className="text-xl font-bold text-red-600 mb-4">{error}</h2>
        <button onClick={() => navigate('/users')} className="btn btn-outline mx-auto">
          <ArrowRight size={20} className="ml-2" /> عودة للقائمة
        </button>
      </div>
    );
  }

  return (
    <div className="animate-slide-in max-w-4xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <button onClick={() => navigate('/users')} className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
          <ArrowRight size={24} className="text-gray-600" />
        </button>
        <h2 className="text-2xl font-bold text-dark-navy">تفاصيل المستخدم</h2>
      </div>

      <div className="glass p-8 rounded-xl relative overflow-hidden">
        {/* Header Section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 pb-6 border-b border-gray-100">
          <div>
            <h1 className="text-3xl font-bold text-gray-800 mb-2">{user.full_name || user.name}</h1>
            <div className="flex items-center gap-3">
              <div className="flex items-center gap-1 text-sm bg-primary-gold/10 text-primary-gold px-3 py-1 rounded-full font-medium">
                <Shield size={16} />
                {getRoleName(user.role)}
              </div>
              <StatusBadge status={user.is_active ? 'active' : 'inactive'} label={user.is_active ? 'نشط' : 'غير نشط'} />
            </div>
          </div>
          
          <div className="flex items-center gap-3 w-full md:w-auto">
            <button 
              onClick={() => navigate(`/users/edit/${id}`)}
              className="btn btn-outline flex-1 md:flex-none"
            >
              <Edit size={18} /> تعديل
            </button>
            <button 
              onClick={handleToggleStatus}
              className={`btn flex-1 md:flex-none ${user.is_active ? 'bg-orange-100 text-orange-700 hover:bg-orange-200' : 'bg-green-100 text-green-700 hover:bg-green-200'}`}
            >
              {user.is_active ? <><UserX size={18} /> تعطيل</> : <><UserCheck size={18} /> تنشيط</>}
            </button>
            <button 
              onClick={() => setConfirmDialog({ isOpen: true })}
              className="btn bg-red-100 text-red-700 hover:bg-red-200 flex-1 md:flex-none"
            >
              <Trash2 size={18} /> حذف
            </button>
          </div>
        </div>

        {/* Info Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 pt-6">
          <div className="space-y-6">
            <h3 className="text-lg font-bold text-gray-800 border-b pb-2">معلومات التواصل</h3>
            
            <div className="flex items-start gap-3">
              <Mail className="text-gray-400 mt-1" size={20} />
              <div>
                <p className="text-sm text-gray-500">البريد الإلكتروني</p>
                <p className="font-medium text-gray-800">{user.email || '—'}</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3">
              <Phone className="text-gray-400 mt-1" size={20} />
              <div>
                <p className="text-sm text-gray-500">رقم الهاتف</p>
                <p className="font-medium text-gray-800" dir="ltr">{user.phone}</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3">
              <MapPin className="text-gray-400 mt-1" size={20} />
              <div>
                <p className="text-sm text-gray-500">الموقع</p>
                <p className="font-medium text-gray-800">
                  {user.governorate || '—'} {user.city ? `، ${user.city}` : ''}
                </p>
              </div>
            </div>
          </div>
          
          <div className="space-y-6">
            <h3 className="text-lg font-bold text-gray-800 border-b pb-2">معلومات النظام</h3>
            
            <div className="flex items-start gap-3">
              <Calendar className="text-gray-400 mt-1" size={20} />
              <div>
                <p className="text-sm text-gray-500">تاريخ الإنشاء</p>
                <p className="font-medium text-gray-800">{user.created_at ? formatDate(user.created_at) : '—'}</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3">
              <Clock className="text-gray-400 mt-1" size={20} />
              <div>
                <p className="text-sm text-gray-500">آخر تحديث</p>
                <p className="font-medium text-gray-800">{user.updated_at ? formatDate(user.updated_at) : '—'}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <ConfirmDialog 
        isOpen={confirmDialog.isOpen}
        title="تأكيد الحذف"
        message={`هل أنت متأكد من رغبتك في حذف المستخدم "${user.full_name || user.name}"؟ لا يمكن التراجع عن هذا الإجراء.`}
        onConfirm={handleDelete}
        onCancel={() => setConfirmDialog({ isOpen: false })}
      />
    </div>
  );
};

export default UserDetailPage;
