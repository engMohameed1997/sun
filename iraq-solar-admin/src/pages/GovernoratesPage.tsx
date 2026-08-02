import React, { useState, useEffect } from 'react';
import { MapPin, Plus, Trash2, Edit3, CheckCircle2, XCircle } from 'lucide-react';
import { api } from '../services/api';
import type { Governorate } from '../types';

export const GovernoratesPage: React.FC = () => {
  const [governorates, setGovernorates] = useState<Governorate[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingGov, setEditingGov] = useState<Governorate | null>(null);
  const [nameAr, setNameAr] = useState('');
  const [nameEn, setNameEn] = useState('');
  const [saving, setSaving] = useState(false);

  const fetchGovernorates = async () => {
    try {
      const res = await api.get('/admin/governorates');
      if (res.data?.data) {
        setGovernorates(res.data.data);
      }
    } catch (err) {
      console.error('Failed to fetch governorates', err);
    }
  };

  useEffect(() => {
    fetchGovernorates();
  }, []);

  const openAddModal = () => {
    setEditingGov(null);
    setNameAr('');
    setNameEn('');
    setIsModalOpen(true);
  };

  const openEditModal = (g: Governorate) => {
    setEditingGov(g);
    setNameAr(g.name_ar);
    setNameEn(g.name_en);
    setIsModalOpen(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nameAr.trim()) {
      alert('الرجاء إدخال اسم المحافظة بالعربية');
      return;
    }
    setSaving(true);
    try {
      if (editingGov) {
        await api.put(`/admin/governorates/${editingGov.id}`, {
          name_ar: nameAr,
          name_en: nameEn,
        });
        alert('تم تحديث المحافظة بنجاح');
      } else {
        await api.post('/admin/governorates', {
          name_ar: nameAr,
          name_en: nameEn,
        });
        alert('تم إضافة المحافظة بنجاح');
      }
      setIsModalOpen(false);
      fetchGovernorates();
    } catch (err) {
      alert('فشل حفظ المحافظة');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleActive = async (g: Governorate) => {
    try {
      await api.put(`/admin/governorates/${g.id}/status`, { is_active: !g.is_active });
      fetchGovernorates();
    } catch (err) {
      alert('فشل تغيير حالة المحافظة');
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('حذف هذه المحافظة؟ سيتم حذف أسعار التوصيل المرتبطة بها.')) return;
    try {
      await api.delete(`/admin/governorates/${id}`);
      fetchGovernorates();
    } catch (err) {
      alert('فشل حذف المحافظة');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <MapPin className="text-amber-400" size={22} />
            إدارة المحافظات وأسعار التوصيل
          </h1>
          <p className="text-slate-400 text-xs mt-1">إضافة وتعديل المحافظات العراقية، يتم استخدامها لربط أسعار التوصيل لكل متجر</p>
        </div>
        <button
          onClick={openAddModal}
          className="bg-amber-500 hover:bg-amber-600 text-slate-950 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <Plus size={18} />
          إضافة محافظة
        </button>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-slate-800 text-slate-400 text-xs">
              <th className="text-right p-4 font-medium">#</th>
              <th className="text-right p-4 font-medium">الاسم بالعربية</th>
              <th className="text-right p-4 font-medium">الاسم بالإنجليزية</th>
              <th className="text-right p-4 font-medium">الحالة</th>
              <th className="text-right p-4 font-medium">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {governorates.map((g) => (
              <tr key={g.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition">
                <td className="p-4 text-slate-500 font-mono">{g.id}</td>
                <td className="p-4 text-slate-100 font-bold">{g.name_ar}</td>
                <td className="p-4 text-slate-400 font-mono text-xs" dir="ltr">{g.name_en || '-'}</td>
                <td className="p-4">
                  <button
                    onClick={() => handleToggleActive(g)}
                    className={`px-2 py-1 rounded-lg text-xs font-bold flex items-center gap-1 transition cursor-pointer ${
                      g.is_active
                        ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/20'
                        : 'bg-rose-500/10 text-rose-400 border border-rose-500/30 hover:bg-rose-500/20'
                    }`}
                  >
                    {g.is_active ? <CheckCircle2 size={12} /> : <XCircle size={12} />}
                    {g.is_active ? 'مفعّلة' : 'معطّلة'}
                  </button>
                </td>
                <td className="p-4">
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => openEditModal(g)}
                      className="p-2 bg-slate-800 hover:bg-slate-700 text-amber-400 rounded-lg transition cursor-pointer"
                      title="تعديل"
                    >
                      <Edit3 size={14} />
                    </button>
                    <button
                      onClick={() => handleDelete(g.id)}
                      className="p-2 bg-slate-800 hover:bg-rose-500/20 text-rose-400 rounded-lg transition cursor-pointer"
                      title="حذف"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {governorates.length === 0 && (
              <tr>
                <td colSpan={5} className="text-center py-10 text-slate-500">
                  <MapPin className="text-slate-600 mx-auto mb-2" size={36} />
                  لا توجد محافظات مضافة حالياً
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4">
            <h3 className="text-lg font-bold text-slate-100">
              {editingGov ? 'تعديل المحافظة' : 'إضافة محافظة جديدة'}
            </h3>
            <form onSubmit={handleSave} className="space-y-3">
              <div>
                <label className="block text-slate-400 text-xs mb-1">الاسم بالعربية *</label>
                <input
                  required
                  type="text"
                  value={nameAr}
                  onChange={(e) => setNameAr(e.target.value)}
                  placeholder="مثال: بغداد"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 outline-none focus:border-amber-500/50"
                />
              </div>
              <div>
                <label className="block text-slate-400 text-xs mb-1">الاسم بالإنجليزية</label>
                <input
                  type="text"
                  value={nameEn}
                  onChange={(e) => setNameEn(e.target.value)}
                  placeholder="e.g. Baghdad"
                  dir="ltr"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 outline-none focus:border-amber-500/50 text-left"
                />
              </div>
              <div className="flex justify-end gap-2 pt-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-xs font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl text-xs font-bold cursor-pointer disabled:opacity-50"
                >
                  {saving ? 'جارٍ الحفظ...' : 'حفظ'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
