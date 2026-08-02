import React, { useState, useEffect } from 'react';
import { Star, Plus, Edit2, Trash2, Tag, ImageIcon } from 'lucide-react';
import { api } from '../services/api';

interface Brand {
  id: string;
  name: string;
  logo_url: string;
  is_active: boolean;
}

export const BrandsPage: React.FC = () => {
  const [brands, setBrands] = useState<Brand[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBrand, setEditingBrand] = useState<Brand | null>(null);
  const [formData, setFormData] = useState({ name: '', logo_url: '', is_active: true });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const fetchBrands = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/brands');
      setBrands(res.data?.data || []);
    } catch (err) {
      console.error('Failed to fetch brands', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchBrands();
  }, []);

  const openAddModal = () => {
    setEditingBrand(null);
    setFormData({ name: '', logo_url: '', is_active: true });
    setIsModalOpen(true);
  };

  const openEditModal = (brand: Brand) => {
    setEditingBrand(brand);
    setFormData({ name: brand.name, logo_url: brand.logo_url || '', is_active: brand.is_active });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim()) return;

    setIsSubmitting(true);
    try {
      if (editingBrand) {
        await api.put(`/admin/brands/${editingBrand.id}`, formData);
        alert('تم تعديل الماركة بنجاح');
      } else {
        await api.post('/admin/brands', formData);
        alert('تم إضافة الماركة بنجاح');
      }
      setIsModalOpen(false);
      fetchBrands();
    } catch (err: any) {
      alert(err.response?.data?.message || 'حدث خطأ أثناء حفظ الماركة');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!window.confirm('هل أنت متأكد من حذف هذه الماركة؟')) return;
    try {
      await api.delete(`/admin/brands/${id}`);
      alert('تم حذف الماركة بنجاح');
      fetchBrands();
    } catch (err: any) {
      alert(err.response?.data?.message || 'فشل الحذف');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Star className="text-amber-400" size={22} />
            إدارة الماركات (Brands)
          </h1>
          <p className="text-slate-400 text-xs mt-1">عرض، إضافة، وتعديل ماركات المنتجات (مثل: LONGi, Deye...)</p>
        </div>
        <button
          onClick={openAddModal}
          className="bg-amber-500 hover:bg-amber-600 text-slate-950 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <Plus size={18} />
          إضافة ماركة جديدة
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        {isLoading ? (
          <div className="col-span-full p-10 text-center text-slate-400 font-bold">جارٍ التحميل...</div>
        ) : brands.length === 0 ? (
          <div className="col-span-full p-10 text-center text-slate-500 bg-slate-900 border border-slate-800 rounded-2xl">لا توجد ماركات مضافة</div>
        ) : (
          brands.map((brand) => (
            <div key={brand.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-4 flex flex-col gap-3">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center overflow-hidden flex-shrink-0 text-slate-500">
                  {brand.logo_url ? <img src={brand.logo_url} alt={brand.name} className="w-full h-full object-cover" /> : <Star size={20} />}
                </div>
                <div>
                  <h3 className="font-bold text-slate-100 text-sm">{brand.name}</h3>
                  <div className={`text-[10px] mt-0.5 ${brand.is_active ? 'text-emerald-400' : 'text-slate-500'}`}>
                    {brand.is_active ? 'فعال' : 'غير فعال'}
                  </div>
                </div>
              </div>
              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-800/60 mt-auto">
                <button
                  onClick={() => openEditModal(brand)}
                  className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-amber-500 hover:text-slate-950 transition cursor-pointer"
                  title="تعديل"
                >
                  <Edit2 size={14} />
                </button>
                <button
                  onClick={() => handleDelete(brand.id)}
                  className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-rose-500 hover:text-white transition cursor-pointer"
                  title="حذف"
                >
                  <Trash2 size={14} />
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-sm w-full p-6">
            <h2 className="text-xl font-bold text-slate-100 mb-4 flex items-center gap-2">
              <Star className="text-amber-500" size={20} />
              {editingBrand ? 'تعديل الماركة' : 'إضافة ماركة جديدة'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-slate-400 text-xs mb-1">اسم الماركة *</label>
                <div className="relative">
                  <Tag className="absolute right-3 top-2.5 text-slate-500" size={16} />
                  <input
                    required
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="مثال: LONGi"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl pr-10 pl-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-left dir-ltr"
                    dir="ltr"
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-400 text-xs mb-1">رابط شعار الماركة (اختياري)</label>
                <div className="relative">
                  <ImageIcon className="absolute right-3 top-2.5 text-slate-500" size={16} />
                  <input
                    type="url"
                    value={formData.logo_url}
                    onChange={(e) => setFormData({ ...formData, logo_url: e.target.value })}
                    placeholder="https://..."
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl pr-10 pl-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-left dir-ltr"
                    dir="ltr"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 mt-2">
                <input
                  type="checkbox"
                  id="isActive"
                  checked={formData.is_active}
                  onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                  className="w-4 h-4 rounded border-slate-700 bg-slate-900 accent-amber-500"
                />
                <label htmlFor="isActive" className="text-slate-300 text-sm cursor-pointer">
                  الماركة مفعلة وتظهر في التطبيق
                </label>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-sm font-bold hover:bg-slate-700 cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-6 py-2 bg-amber-500 text-slate-950 rounded-xl text-sm font-bold hover:bg-amber-600 disabled:opacity-50 cursor-pointer"
                >
                  {isSubmitting ? 'جارٍ الحفظ...' : 'حفظ'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default BrandsPage;
