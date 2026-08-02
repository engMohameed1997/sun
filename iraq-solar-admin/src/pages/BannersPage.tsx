import React, { useState, useEffect } from 'react';
import { Image as ImageIcon, Plus, Trash2 } from 'lucide-react';
import { api } from '../services/api';
import type { HomeBanner } from '../types';

export const BannersPage: React.FC = () => {
  const [banners, setBanners] = useState<HomeBanner[]>([]);
  const [isBannerModalOpen, setIsBannerModalOpen] = useState(false);

  // Banner Form
  const [title, setTitle] = useState('');
  const [subtitle, setSubtitle] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [uploading, setUploading] = useState(false);

  const fetchData = async () => {
    try {
      const bRes = await api.get('/banners').catch(() => null);
      if (bRes?.data?.data) setBanners(bRes.data.data);
    } catch (err) {
      console.error('Failed to load banners', err);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('image', file);
    setUploading(true);

    try {
      const res = await api.post('/upload/image', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      if (res.data?.data?.url) {
        setImageUrl(res.data.data.url);
      }
    } catch (err) {
      alert('فشل رفع صورة البنر');
    } finally {
      setUploading(false);
    }
  };

  const handleCreateBanner = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.post('/admin/banners', {
        title,
        subtitle,
        image_url: imageUrl,
        display_order: banners.length + 1,
        is_active: true,
      });
      setIsBannerModalOpen(false);
      fetchData();
    } catch (err) {
      alert('فشل حفظ البنر');
    }
  };

  const handleDeleteBanner = async (id: string) => {
    if (!confirm('حذف البنر المعين؟')) return;
    try {
      await api.delete(`/admin/banners/${id}`);
      fetchData();
    } catch (err) {
      alert('فشل حذف البنر');
    }
  };

  return (
    <div className="space-y-8">
      <div className="space-y-4">
        <div className="flex items-center justify-between bg-slate-900 border border-slate-800 p-5 rounded-2xl">
          <div>
            <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
              <ImageIcon className="text-amber-400" size={22} />
              بنرات الصفحة الرئيسية للتطبيق
            </h1>
            <p className="text-slate-400 text-xs mt-1">التحكم في إعلانات السلايدر الرئيسي بالتطبيق وتعديل الترتيب</p>
          </div>
          <button
            onClick={() => {
              setTitle('');
              setSubtitle('');
              setImageUrl('');
              setIsBannerModalOpen(true);
            }}
            className="bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 font-bold px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-lg shadow-amber-500/20"
          >
            <Plus size={16} /> إضافة بنر جديد
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {banners.map((b) => (
            <div key={b.id} className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden group">
              <div className="h-40 bg-slate-950 relative overflow-hidden">
                <img src={b.image_url} alt={b.title} className="w-full h-full object-cover group-hover:scale-105 transition duration-300" />
                <button
                  onClick={() => handleDeleteBanner(b.id)}
                  className="absolute top-3 left-3 p-2 bg-rose-500/80 text-white rounded-lg text-xs backdrop-blur-md hover:bg-rose-600 transition"
                  title="حذف البنر"
                >
                  <Trash2 size={16} />
                </button>
              </div>
              <div className="p-4 space-y-1">
                <h3 className="font-bold text-slate-100 text-sm">{b.title || 'بنر بدون عنوان'}</h3>
                <p className="text-xs text-slate-400">{b.subtitle || 'إعلان ترويجي للمنظومات الشمسية'}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {isBannerModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4 text-xs">
            <h3 className="text-lg font-bold text-slate-100">إضافة بنر ترويجي جديد</h3>
            <form onSubmit={handleCreateBanner} className="space-y-3">
              <div>
                <label className="block text-slate-400 mb-1">العنوان الرئيسي</label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="عروض الصيف للطاقة الشمسية"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">العنوان الفرعي</label>
                <input
                  type="text"
                  value={subtitle}
                  onChange={(e) => setSubtitle(e.target.value)}
                  placeholder="خصم 15% على انفيرترات Deye"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">صورة البنر</label>
                <input type="file" accept="image/*" onChange={handleImageUpload} className="text-slate-400 text-xs" />
                {uploading && <div className="text-amber-400 mt-1">جارٍ رفع صورة البنر...</div>}
                {imageUrl && <img src={imageUrl} alt="معاينة" className="mt-2 w-full h-32 object-cover rounded-xl border border-slate-800" />}
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsBannerModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl font-bold"
                >
                  إلغاء
                </button>
                <button type="submit" disabled={!imageUrl} className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold disabled:opacity-50">
                  حفظ البنر
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
