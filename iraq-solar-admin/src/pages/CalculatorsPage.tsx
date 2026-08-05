import React, { useState, useEffect } from 'react';
import {
  Calculator,
  Plus,
  Edit2,
  Image as ImageIcon,
  Check,
  X,
  Star,
  Upload,
  RefreshCw,
  Eye,
  EyeOff,
} from 'lucide-react';
import { api } from '../services/api';

interface AdminCalculator {
  id: string;
  route_key: string;
  title: string;
  subtitle: string;
  icon_key: string;
  background_image_url?: string;
  badge?: string;
  color_hex?: string;
  is_featured: boolean;
  sort_order: number;
  version: number;
  allowed_roles: string[];
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

const AVAILABLE_ROLES = [
  { key: 'customer', label: '👤 مستخدم منزلي' },
  { key: 'installer', label: '👨‍🔧 فني تركيبات' },
  { key: 'engineer', label: '📐 مهندس طاقة' },
  { key: 'merchant', label: '🏪 تاجر ومورد' },
  { key: 'admin', label: '⚙️ مدير النظام' },
];

const ICON_KEYS = [
  { key: 'sun', label: '☀️ sun (شمس/منظومة)' },
  { key: 'savings', label: '💰 savings (توفير/ROI)' },
  { key: 'battery', label: '🔋 battery (تشغيل بطاريات)' },
  { key: 'power', label: '⚡ power (استهلاك أجهزة)' },
  { key: 'grid', label: '▦ grid (ألواح بالاستهلاك)' },
  { key: 'roof', label: '🏠 roof (مساحة السطح)' },
  { key: 'shopping_bag', label: '🛒 shopping_bag (متجر وكلفة)' },
  { key: 'cable', label: '🔌 cable (كابلات وهبوط جهد)' },
  { key: 'tune', label: '🎛️ tune (سلاسل MPPT)' },
  { key: 'shield', label: '🛡️ shield (قواطع وفيوزات)' },
  { key: 'battery_saver', label: '⚡ battery_saver (بنك البطاريات)' },
  { key: 'map', label: '🗺️ map (إنتاجية المحافظات)' },
];

export const CalculatorsPage: React.FC = () => {
  const [calculators, setCalculators] = useState<AdminCalculator[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingCalc, setEditingCalc] = useState<AdminCalculator | null>(null);

  const [formData, setFormData] = useState({
    route_key: '',
    title_ar: '',
    title_en: '',
    subtitle_ar: '',
    subtitle_en: '',
    icon_key: 'sun',
    background_image_url: '',
    badge: '',
    color_hex: '#FF9800',
    is_featured: false,
    sort_order: 1,
    allowed_roles: ['customer', 'installer', 'engineer', 'merchant', 'admin'] as string[],
  });

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isUploading, setIsUploading] = useState(false);

  const fetchCalculators = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/calculators');
      setCalculators(res.data?.data || []);
    } catch (err) {
      console.error('Failed to fetch admin calculators', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCalculators();
  }, []);

  const openAddModal = () => {
    setEditingCalc(null);
    setFormData({
      route_key: '',
      title_ar: '',
      title_en: '',
      subtitle_ar: '',
      subtitle_en: '',
      icon_key: 'sun',
      background_image_url: '',
      badge: '',
      color_hex: '#FF9800',
      is_featured: false,
      sort_order: calculators.length + 1,
      allowed_roles: ['customer', 'installer', 'engineer', 'merchant', 'admin'],
    });
    setIsModalOpen(true);
  };

  const openEditModal = (calc: AdminCalculator) => {
    setEditingCalc(calc);
    setFormData({
      route_key: calc.route_key,
      title_ar: calc.title,
      title_en: '',
      subtitle_ar: calc.subtitle,
      subtitle_en: '',
      icon_key: calc.icon_key || 'sun',
      background_image_url: calc.background_image_url || '',
      badge: calc.badge || '',
      color_hex: calc.color_hex || '#FF9800',
      is_featured: calc.is_featured,
      sort_order: calc.sort_order,
      allowed_roles: calc.allowed_roles || [],
    });
    setIsModalOpen(true);
  };

  const handleToggleStatus = async (calc: AdminCalculator) => {
    const newStatus = !calc.is_active;
    try {
      await api.patch(`/admin/calculators/${calc.id}/status`, { is_active: newStatus });
      setCalculators((prev) =>
        prev.map((item) => (item.id === calc.id ? { ...item, is_active: newStatus } : item))
      );
    } catch (err: any) {
      alert(err.response?.data?.message || 'فشل تغيير حالة الحاسبة');
    }
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const data = new FormData();
    data.append('image', file);

    setIsUploading(true);
    try {
      const res = await api.post('/upload/image', data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const url = res.data?.data?.url || res.data?.url;
      if (url) {
        setFormData((prev) => ({ ...prev, background_image_url: url }));
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'فشل رفع الصورة');
    } finally {
      setIsUploading(false);
    }
  };

  const toggleRoleSelection = (roleKey: string) => {
    setFormData((prev) => {
      const exists = prev.allowed_roles.includes(roleKey);
      if (exists) {
        return { ...prev, allowed_roles: prev.allowed_roles.filter((r) => r !== roleKey) };
      } else {
        return { ...prev, allowed_roles: [...prev.allowed_roles, roleKey] };
      }
    });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.title_ar.trim()) {
      alert('يرجى كتابة عنوان الحاسبة باللغة العربية');
      return;
    }
    if (!editingCalc && !formData.route_key.trim()) {
      alert('يرجى كتابة route_key الثابت للحاسبة');
      return;
    }
    if (formData.allowed_roles.length === 0) {
      alert('يرجى اختيار دور واحد على الأقل للمستخدمين المسموح لهم بفتح هذه الحاسبة');
      return;
    }

    setIsSubmitting(true);
    try {
      if (editingCalc) {
        await api.put(`/admin/calculators/${editingCalc.id}`, {
          title_ar: formData.title_ar,
          title_en: formData.title_en,
          subtitle_ar: formData.subtitle_ar,
          subtitle_en: formData.subtitle_en,
          icon_key: formData.icon_key,
          background_image_url: formData.background_image_url,
          badge: formData.badge,
          color_hex: formData.color_hex,
          is_featured: formData.is_featured,
          sort_order: Number(formData.sort_order),
          allowed_roles: formData.allowed_roles,
        });
        alert('تم تعديل الحاسبة بنجاح');
      } else {
        await api.post('/admin/calculators', {
          route_key: formData.route_key.trim(),
          title_ar: formData.title_ar,
          title_en: formData.title_en,
          subtitle_ar: formData.subtitle_ar,
          subtitle_en: formData.subtitle_en,
          icon_key: formData.icon_key,
          background_image_url: formData.background_image_url,
          badge: formData.badge,
          color_hex: formData.color_hex,
          is_featured: formData.is_featured,
          sort_order: Number(formData.sort_order),
          allowed_roles: formData.allowed_roles,
        });
        alert('تم إنشاء الحاسبة بنجاح');
      }
      setIsModalOpen(false);
      fetchCalculators();
    } catch (err: any) {
      alert(err.response?.data?.message || 'حدث خطأ أثناء حفظ بيانات الحاسبة');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Calculator className="text-amber-400" size={24} />
            إدارة الحاسبات الشمسية وتعيين الصور والأدوار
          </h1>
          <p className="text-slate-400 text-xs mt-1">
            الـ Backend هو المصدر الوحيد للحقيقة (Source of Truth). يمكنك تفعيل/تعطيل الحاسبات، رفع صور الخلفية، وتحديد الأدوار المسموح لها لرؤيتها.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={fetchCalculators}
            className="p-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl transition cursor-pointer"
            title="تحديث البيانات"
          >
            <RefreshCw size={18} />
          </button>
          <button
            onClick={openAddModal}
            className="bg-amber-500 hover:bg-amber-600 text-slate-950 px-4 py-2.5 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
          >
            <Plus size={18} />
            إضافة حاسبة جديدة
          </button>
        </div>
      </div>

      {/* Calculators Table Grid */}
      {isLoading ? (
        <div className="text-center py-16 bg-slate-900 border border-slate-800 rounded-2xl">
          <RefreshCw className="animate-spin text-amber-500 mx-auto mb-2" size={32} />
          <span className="text-slate-400 text-sm">جارٍ تحميل قائمة الحاسبات من الـ Backend...</span>
        </div>
      ) : calculators.length === 0 ? (
        <div className="text-center py-16 bg-slate-900 border border-slate-800 rounded-2xl">
          <Calculator className="text-slate-600 mx-auto mb-2" size={48} />
          <span className="text-slate-400 text-sm">لا توجد حاسبات مضافة حالياً</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {calculators.map((calc) => (
            <div
              key={calc.id}
              className={`relative bg-slate-900 border ${
                calc.is_active ? 'border-slate-800' : 'border-red-900/50 opacity-70'
              } rounded-2xl p-4 flex flex-col justify-between transition hover:border-slate-700 shadow-lg overflow-hidden`}
            >
              {/* Background image preview if available */}
              {calc.background_image_url && (
                <div
                  className="absolute inset-0 bg-cover bg-center opacity-10 pointer-events-none"
                  style={{ backgroundImage: `url(${calc.background_image_url})` }}
                />
              )}

              <div>
                {/* Top Row: Icon, Badge, Status Switch */}
                <div className="flex items-center justify-between gap-2 mb-3 relative z-10">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-9 h-9 rounded-xl flex items-center justify-center font-bold text-slate-950"
                      style={{ backgroundColor: calc.color_hex || '#FF9800' }}
                    >
                      <Calculator size={18} />
                    </div>
                    <div>
                      <span className="text-xs font-mono px-2 py-0.5 rounded bg-slate-800 text-amber-400 border border-slate-700">
                        {calc.route_key}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    {calc.badge && (
                      <span
                        className="text-[10px] font-bold px-2 py-0.5 rounded-full border"
                        style={{
                          borderColor: calc.color_hex || '#FF9800',
                          color: calc.color_hex || '#FF9800',
                        }}
                      >
                        {calc.badge}
                      </span>
                    )}

                    <button
                      onClick={() => handleToggleStatus(calc)}
                      className={`p-1.5 rounded-lg border transition cursor-pointer ${
                        calc.is_active
                          ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30 hover:bg-emerald-500/20'
                          : 'bg-red-500/10 text-red-400 border-red-500/30 hover:bg-red-500/20'
                      }`}
                      title={calc.is_active ? 'تعطيل الحاسبة' : 'تفعيل الحاسبة'}
                    >
                      {calc.is_active ? <Eye size={16} /> : <EyeOff size={16} />}
                    </button>
                  </div>
                </div>

                {/* Title & Subtitle */}
                <div className="relative z-10">
                  <h3 className="font-bold text-slate-100 text-base flex items-center gap-2">
                    {calc.title}
                    {calc.is_featured && <Star size={14} className="text-amber-400 fill-amber-400" />}
                  </h3>
                  <p className="text-xs text-slate-400 mt-1 line-clamp-2">{calc.subtitle || 'بدون وصف فرعي'}</p>
                </div>

                {/* Metadata Badges */}
                <div className="mt-3 pt-3 border-t border-slate-800/80 flex flex-wrap gap-1.5 text-[11px] relative z-10">
                  <span className="bg-slate-800 text-slate-300 px-2 py-0.5 rounded">
                    أيقونة: <strong className="text-amber-300">{calc.icon_key}</strong>
                  </span>
                  <span className="bg-slate-800 text-slate-300 px-2 py-0.5 rounded">
                    الترتيب: <strong className="text-amber-300">{calc.sort_order}</strong>
                  </span>
                  {calc.background_image_url && (
                    <span className="bg-emerald-950/60 text-emerald-400 px-2 py-0.5 rounded border border-emerald-800/40 flex items-center gap-1">
                      <ImageIcon size={12} /> صورة خلفية
                    </span>
                  )}
                </div>

                {/* Allowed Roles Badges */}
                <div className="mt-2 relative z-10 flex flex-wrap gap-1">
                  {calc.allowed_roles?.map((role) => (
                    <span
                      key={role}
                      className="text-[10px] bg-slate-800 text-slate-300 border border-slate-700 px-1.5 py-0.5 rounded-md"
                    >
                      {role}
                    </span>
                  ))}
                </div>
              </div>

              {/* Actions Footer */}
              <div className="mt-4 pt-3 border-t border-slate-800 flex items-center justify-between relative z-10">
                <span className={`text-[11px] ${calc.is_active ? 'text-emerald-400' : 'text-red-400 font-bold'}`}>
                  {calc.is_active ? '● نشطة في التطبيق' : '○ معطلة (مخفية)'}
                </span>

                <button
                  onClick={() => openEditModal(calc)}
                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-amber-400 rounded-lg text-xs font-bold flex items-center gap-1.5 transition cursor-pointer"
                >
                  <Edit2 size={14} />
                  تعديل
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create / Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 w-full max-w-2xl rounded-2xl p-6 space-y-5 my-8">
            <div className="flex items-center justify-between border-b border-slate-800 pb-4">
              <h2 className="text-lg font-bold text-slate-100 flex items-center gap-2">
                <Calculator className="text-amber-400" size={20} />
                {editingCalc ? `تعديل الحاسبة: ${editingCalc.title}` : 'إضافة حاسبة شمسية جديدة'}
              </h2>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-slate-800"
              >
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4 text-xs">
              {/* Route Key (Immutable in Edit mode) */}
              <div>
                <label className="block font-bold text-slate-300 mb-1">
                  مفتاح التنقل الثابت (route_key){' '}
                  <span className="text-amber-400 font-normal">
                    {editingCalc ? '(غير قابل للتغير لضمان الملاحة)' : '(مثال: system_sizing, roi, cable_sizing)'}
                  </span>
                </label>
                <input
                  type="text"
                  disabled={!!editingCalc}
                  value={formData.route_key}
                  onChange={(e) => setFormData({ ...formData, route_key: e.target.value })}
                  placeholder="مثال: roi"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2.5 text-slate-100 font-mono focus:border-amber-500 disabled:opacity-50"
                  required
                />
              </div>

              {/* Titles Row */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-300 mb-1">عنوان الحاسبة (عربي) *</label>
                  <input
                    type="text"
                    value={formData.title_ar}
                    onChange={(e) => setFormData({ ...formData, title_ar: e.target.value })}
                    placeholder="مثال: حاسبة التوفير واسترداد المال"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500"
                    required
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-300 mb-1">عنوان الحاسبة (English)</label>
                  <input
                    type="text"
                    value={formData.title_en}
                    onChange={(e) => setFormData({ ...formData, title_en: e.target.value })}
                    placeholder="e.g. ROI & Savings Calculator"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500"
                  />
                </div>
              </div>

              {/* Subtitles Row */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block font-bold text-slate-300 mb-1">الوصف الفرعي (عربي)</label>
                  <input
                    type="text"
                    value={formData.subtitle_ar}
                    onChange={(e) => setFormData({ ...formData, subtitle_ar: e.target.value })}
                    placeholder="مثال: حساب فترة استرجاع المال والتوفير الشهري"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500"
                  />
                </div>
                <div>
                  <label className="block font-bold text-slate-300 mb-1">الوصف الفرعي (English)</label>
                  <input
                    type="text"
                    value={formData.subtitle_en}
                    onChange={(e) => setFormData({ ...formData, subtitle_en: e.target.value })}
                    placeholder="e.g. Calculate payback period & monthly bill savings"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500"
                  />
                </div>
              </div>

              {/* Icon Key & Color Hex */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="block font-bold text-slate-300 mb-1">الأيقونة (icon_key) *</label>
                  <select
                    value={formData.icon_key}
                    onChange={(e) => setFormData({ ...formData, icon_key: e.target.value })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500 cursor-pointer"
                  >
                    {ICON_KEYS.map((item) => (
                      <option key={item.key} value={item.key}>
                        {item.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block font-bold text-slate-300 mb-1">لون البطاقة (color_hex)</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="color"
                      value={formData.color_hex}
                      onChange={(e) => setFormData({ ...formData, color_hex: e.target.value })}
                      className="w-9 h-9 rounded bg-transparent border-0 cursor-pointer"
                    />
                    <input
                      type="text"
                      value={formData.color_hex}
                      onChange={(e) => setFormData({ ...formData, color_hex: e.target.value })}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono"
                    />
                  </div>
                </div>

                <div>
                  <label className="block font-bold text-slate-300 mb-1">الشارة (Badge)</label>
                  <input
                    type="text"
                    value={formData.badge}
                    onChange={(e) => setFormData({ ...formData, badge: e.target.value })}
                    placeholder="مثال: ضرورية، استرداد، جديد"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500"
                  />
                </div>
              </div>

              {/* Sort Order & Featured */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 items-center">
                <div>
                  <label className="block font-bold text-slate-300 mb-1">ترتيب الظهور (sort_order)</label>
                  <input
                    type="number"
                    value={formData.sort_order}
                    onChange={(e) => setFormData({ ...formData, sort_order: Number(e.target.value) })}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500"
                    min={1}
                  />
                </div>

                <div className="pt-4">
                  <label className="flex items-center gap-2 cursor-pointer text-slate-200 font-bold">
                    <input
                      type="checkbox"
                      checked={formData.is_featured}
                      onChange={(e) => setFormData({ ...formData, is_featured: e.target.checked })}
                      className="w-4 h-4 rounded text-amber-500 focus:ring-0 cursor-pointer"
                    />
                    تأكيد حاسبة مميزة (Featured in Top)
                  </label>
                </div>
              </div>

              {/* Image Background & Upload */}
              <div>
                <label className="block font-bold text-slate-300 mb-1">صورة خلفية البطاقة (Background Image URL)</label>
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={formData.background_image_url}
                    onChange={(e) => setFormData({ ...formData, background_image_url: e.target.value })}
                    placeholder="https://.../calculator.webp"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 focus:border-amber-500"
                  />
                  <label className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-3 py-2 rounded-xl cursor-pointer flex items-center gap-1 shrink-0">
                    <Upload size={14} />
                    <span>{isUploading ? 'جارٍ الرفع...' : 'رفع صورة'}</span>
                    <input type="file" accept="image/*" onChange={handleImageUpload} className="hidden" />
                  </label>
                </div>
                {formData.background_image_url && (
                  <div className="mt-2 h-16 rounded-xl overflow-hidden bg-slate-950 border border-slate-800 relative">
                    <img
                      src={formData.background_image_url}
                      alt="Preview"
                      className="w-full h-full object-cover opacity-60"
                    />
                    <span className="absolute bottom-1 right-2 text-[10px] text-amber-400 font-bold">معاينة الصورة</span>
                  </div>
                )}
              </div>

              {/* Allowed Roles Selection (Multi-select) */}
              <div className="border-t border-slate-800 pt-3">
                <label className="block font-bold text-slate-300 mb-2">الأدوار المصرح لها برؤية هذه الحاسبة (Allowed Roles) *</label>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {AVAILABLE_ROLES.map((role) => {
                    const selected = formData.allowed_roles.includes(role.key);
                    return (
                      <button
                        type="button"
                        key={role.key}
                        onClick={() => toggleRoleSelection(role.key)}
                        className={`px-3 py-2 rounded-xl text-right transition border cursor-pointer flex items-center justify-between ${
                          selected
                            ? 'bg-amber-500/10 border-amber-500 text-amber-400 font-bold'
                            : 'bg-slate-950 border-slate-800 text-slate-400 hover:border-slate-700'
                        }`}
                      >
                        <span>{role.label}</span>
                        {selected && <Check size={14} className="text-amber-400" />}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Modal Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-amber-500 hover:bg-amber-600 text-slate-950 rounded-xl font-bold transition cursor-pointer disabled:opacity-50"
                >
                  {isSubmitting ? 'جارٍ الحفظ...' : editingCalc ? 'تحديث الحاسبة' : 'إضافة الحاسبة'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
