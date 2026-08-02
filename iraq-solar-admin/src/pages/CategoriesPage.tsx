import React, { useState, useEffect } from 'react';
import { Layers, Plus, Edit2, Trash2, Tag, FileText } from 'lucide-react';
import { api } from '../services/api';

interface Category {
  id: number;
  name: string;
  description: string;
  created_at?: string;
}

export const CategoriesPage: React.FC = () => {
  const [categories, setCategories] = useState<Category[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [formData, setFormData] = useState({ name: '', description: '' });
  const [isSubmitting, setIsSubmitting] = useState(false);

  const fetchCategories = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/categories');
      setCategories(res.data?.data || []);
    } catch (err) {
      console.error('Failed to fetch categories', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const openAddModal = () => {
    setEditingCategory(null);
    setFormData({ name: '', description: '' });
    setIsModalOpen(true);
  };

  const openEditModal = (cat: Category) => {
    setEditingCategory(cat);
    setFormData({ name: cat.name, description: cat.description || '' });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name.trim()) return;

    setIsSubmitting(true);
    try {
      if (editingCategory) {
        await api.put(`/admin/categories/${editingCategory.id}`, formData);
        alert('تم تعديل التصنيف بنجاح');
      } else {
        await api.post('/admin/categories', formData);
        alert('تم إضافة التصنيف بنجاح');
      }
      setIsModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      alert(err.response?.data?.message || 'حدث خطأ أثناء حفظ التصنيف');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('هل أنت متأكد من حذف هذا التصنيف؟ قد يتسبب ذلك في مشاكل إذا كانت هناك منتجات مرتبطة به.')) return;
    try {
      await api.delete(`/admin/categories/${id}`);
      alert('تم حذف التصنيف بنجاح');
      fetchCategories();
    } catch (err: any) {
      alert(err.response?.data?.message || 'فشل الحذف');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Layers className="text-amber-400" size={22} />
            إدارة تصنيفات المنتجات
          </h1>
          <p className="text-slate-400 text-xs mt-1">عرض، إضافة، وتعديل الأقسام الرئيسية للمنتجات (مثل: ألواح، عواكس...)</p>
        </div>
        <button
          onClick={openAddModal}
          className="bg-amber-500 hover:bg-amber-600 text-slate-950 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <Plus size={18} />
          إضافة تصنيف جديد
        </button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
        {isLoading ? (
          <div className="p-10 text-center text-slate-400 font-bold">جارٍ التحميل...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-right text-sm">
              <thead className="bg-slate-950 text-slate-400">
                <tr>
                  <th className="px-4 py-3 font-medium w-16 text-center">#</th>
                  <th className="px-4 py-3 font-medium">اسم التصنيف</th>
                  <th className="px-4 py-3 font-medium">الوصف</th>
                  <th className="px-4 py-3 font-medium w-32 text-center">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-slate-300">
                {categories.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="px-4 py-8 text-center text-slate-500">لا توجد تصنيفات مضافة</td>
                  </tr>
                ) : (
                  categories.map((cat, idx) => (
                    <tr key={cat.id} className="hover:bg-slate-800/50 transition">
                      <td className="px-4 py-3 text-center text-slate-500">{idx + 1}</td>
                      <td className="px-4 py-3 font-bold text-slate-200">
                        <div className="flex items-center gap-2">
                          <Tag size={14} className="text-amber-500" />
                          {cat.name}
                        </div>
                      </td>
                      <td className="px-4 py-3 text-slate-400 text-xs truncate max-w-xs" title={cat.description}>
                        {cat.description || '-'}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-center gap-2">
                          <button
                            onClick={() => openEditModal(cat)}
                            className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-amber-500 hover:text-slate-950 transition cursor-pointer"
                            title="تعديل"
                          >
                            <Edit2 size={14} />
                          </button>
                          <button
                            onClick={() => handleDelete(cat.id)}
                            className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-rose-500 hover:text-white transition cursor-pointer"
                            title="حذف"
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6">
            <h2 className="text-xl font-bold text-slate-100 mb-4 flex items-center gap-2">
              <Layers className="text-amber-500" size={20} />
              {editingCategory ? 'تعديل التصنيف' : 'إضافة تصنيف جديد'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-slate-400 text-xs mb-1">اسم التصنيف *</label>
                <div className="relative">
                  <Tag className="absolute right-3 top-2.5 text-slate-500" size={16} />
                  <input
                    required
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    placeholder="مثال: ألواح شمسية"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl pr-10 pl-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-400 text-xs mb-1">الوصف (اختياري)</label>
                <div className="relative">
                  <FileText className="absolute right-3 top-3 text-slate-500" size={16} />
                  <textarea
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder="وصف مختصر للتصنيف..."
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl pr-10 pl-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 h-24 resize-none"
                  ></textarea>
                </div>
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

export default CategoriesPage;
