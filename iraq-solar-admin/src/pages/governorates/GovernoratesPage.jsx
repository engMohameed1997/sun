import React, { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, MapPin, Check, X } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { getGovernorates, createGovernorate, updateGovernorate, toggleGovernorateStatus, deleteGovernorate } from '../../api/adminApi';
import DataTable from '../../components/shared/DataTable';
import StatusBadge from '../../components/shared/StatusBadge';
import ConfirmDialog from '../../components/shared/ConfirmDialog';

const GovernoratesPage = () => {
  const [governorates, setGovernorates] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [formData, setFormData] = useState({ name_ar: '', name_en: '' });
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const [editingId, setEditingId] = useState(null);
  const [editData, setEditData] = useState({ name_ar: '', name_en: '' });
  
  const [deleteDialog, setDeleteDialog] = useState({ isOpen: false, id: null });

  const fetchGovernorates = async () => {
    setIsLoading(true);
    try {
      const response = await getGovernorates();
      const data = response.data?.data || response.data || [];
      setGovernorates(data);
    } catch (error) {
      console.error('Error fetching governorates:', error);
      toast.error('حدث خطأ أثناء جلب المحافظات');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchGovernorates();
  }, []);

  const handleAddSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name_ar || !formData.name_en) {
      toast.error('يرجى تعبئة جميع الحقول المطلوبة');
      return;
    }
    
    setIsSubmitting(true);
    try {
      await createGovernorate(formData);
      toast.success('تم إضافة المحافظة بنجاح');
      setFormData({ name_ar: '', name_en: '' });
      fetchGovernorates();
    } catch (error) {
      console.error('Error adding governorate:', error);
      toast.error('حدث خطأ أثناء إضافة المحافظة');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEditStart = (gov) => {
    setEditingId(gov.id);
    setEditData({ name_ar: gov.name_ar, name_en: gov.name_en });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleEditCancel = () => {
    setEditingId(null);
    setEditData({ name_ar: '', name_en: '' });
  };

  const handleEditSave = async (e) => {
    e.preventDefault();
    if (!editData.name_ar || !editData.name_en) {
      toast.error('يرجى تعبئة جميع الحقول المطلوبة');
      return;
    }

    setIsSubmitting(true);
    try {
      await updateGovernorate(editingId, editData);
      toast.success('تم تحديث المحافظة بنجاح');
      setEditingId(null);
      fetchGovernorates();
    } catch (error) {
      console.error('Error updating governorate:', error);
      toast.error('حدث خطأ أثناء تحديث المحافظة');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleStatus = async (id) => {
    try {
      await toggleGovernorateStatus(id);
      toast.success('تم تغيير حالة المحافظة');
      fetchGovernorates();
    } catch (error) {
      console.error('Error toggling governorate status:', error);
      toast.error('حدث خطأ أثناء تغيير الحالة');
    }
  };

  const handleDeleteClick = (id) => {
    setDeleteDialog({ isOpen: true, id });
  };

  const confirmDelete = async () => {
    try {
      await deleteGovernorate(deleteDialog.id);
      toast.success('تم حذف المحافظة بنجاح');
      fetchGovernorates();
    } catch (error) {
      console.error('Error deleting governorate:', error);
      toast.error('حدث خطأ أثناء حذف المحافظة');
    } finally {
      setDeleteDialog({ isOpen: false, id: null });
    }
  };

  const columns = [
    {
      header: 'اسم المحافظة (عربي)',
      accessor: 'name_ar',
      render: (gov) => (
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-primary-gold/10 flex items-center justify-center text-primary-gold flex-shrink-0">
            <MapPin size={16} />
          </div>
          <span className="font-semibold text-white">{gov.name_ar}</span>
        </div>
      )
    },
    {
      header: 'الاسم (إنجليزي)',
      accessor: 'name_en',
      render: (gov) => gov.name_en
    },
    {
      header: 'الحالة',
      accessor: 'is_active',
      render: (gov) => (
        <div onClick={() => handleToggleStatus(gov.id)} className="cursor-pointer" title="انقر لتغيير الحالة">
          <StatusBadge 
            status={gov.is_active ? 'active' : 'inactive'} 
            text={gov.is_active ? 'نشطة' : 'غير نشطة'} 
          />
        </div>
      )
    },
    {
      header: 'الإجراءات',
      accessor: 'id',
      render: (gov) => (
        <div className="flex items-center gap-2">
          <button 
            onClick={() => handleEditStart(gov)}
            className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-white transition-colors"
            title="تعديل"
          >
            <Edit size={18} />
          </button>
          <button 
            onClick={() => handleDeleteClick(gov.id)}
            className="p-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-500 transition-colors"
            title="حذف"
          >
            <Trash2 size={18} />
          </button>
        </div>
      )
    }
  ];

  return (
    <div className="space-y-6 animate-slide-in max-w-5xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-white mb-2">إدارة المحافظات</h1>
        <p className="text-white/60">إضافة وتعديل وحذف المحافظات المتاحة للتوصيل والخدمات</p>
      </div>

      {/* Form Section */}
      <div className="glass rounded-xl p-5 border border-primary-gold/20">
        <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
          {editingId ? <Edit size={20} className="text-primary-gold" /> : <Plus size={20} className="text-primary-gold" />}
          {editingId ? 'تعديل محافظة' : 'إضافة محافظة جديدة'}
        </h2>
        
        <form onSubmit={editingId ? handleEditSave : handleAddSubmit} className="flex flex-col md:flex-row gap-4 items-end">
          <div className="form-group flex-1 w-full">
            <label className="form-label">الاسم بالعربية <span className="text-red-500">*</span></label>
            <input 
              type="text" 
              value={editingId ? editData.name_ar : formData.name_ar}
              onChange={(e) => editingId ? setEditData({...editData, name_ar: e.target.value}) : setFormData({...formData, name_ar: e.target.value})}
              className="form-input" 
              required
              placeholder="مثال: بغداد"
            />
          </div>
          
          <div className="form-group flex-1 w-full">
            <label className="form-label">الاسم بالإنجليزية <span className="text-red-500">*</span></label>
            <input 
              type="text" 
              value={editingId ? editData.name_en : formData.name_en}
              onChange={(e) => editingId ? setEditData({...editData, name_en: e.target.value}) : setFormData({...formData, name_en: e.target.value})}
              className="form-input" 
              dir="ltr"
              required
              placeholder="Example: Baghdad"
            />
          </div>
          
          <div className="flex gap-2 w-full md:w-auto mt-4 md:mt-0">
            {editingId && (
              <button 
                type="button" 
                onClick={handleEditCancel}
                className="btn bg-white/10 hover:bg-white/20 text-white w-full md:w-auto h-11"
                disabled={isSubmitting}
              >
                <X size={20} />
              </button>
            )}
            <button 
              type="submit" 
              className="btn btn-primary w-full md:w-auto h-11 flex items-center justify-center gap-2"
              disabled={isSubmitting}
            >
              {isSubmitting ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
              ) : editingId ? (
                <>
                  <Check size={20} />
                  <span>حفظ</span>
                </>
              ) : (
                <>
                  <Plus size={20} />
                  <span>إضافة</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>

      <div className="glass rounded-xl p-4 md:p-6">
        <DataTable 
          columns={columns} 
          data={governorates} 
          isLoading={isLoading} 
          emptyMessage="لا توجد محافظات مضافة حالياً"
        />
      </div>

      <ConfirmDialog 
        isOpen={deleteDialog.isOpen}
        title="تأكيد الحذف"
        message="هل أنت متأكد من رغبتك في حذف هذه المحافظة؟ لا يمكن التراجع عن هذا الإجراء وقد يؤثر على العناوين المرتبطة بها."
        onConfirm={confirmDelete}
        onCancel={() => setDeleteDialog({ isOpen: false, id: null })}
      />
    </div>
  );
};

export default GovernoratesPage;
