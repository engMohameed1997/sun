import React, { useState, useEffect } from 'react';
import {
  Image as ImageIcon,
  Plus,
  Trash2,
  ExternalLink,
  ShieldAlert,
  Calendar,
  Clock,
  Store,
  MapPin,
  Users,
  CheckCircle2,
  XCircle,
  Smartphone,
  Layers,
  ChevronDown,
  ChevronUp
} from 'lucide-react';
import { api } from '../services/api';
import type { HomeBanner, BannerActionType, Store as StoreType, User, Governorate, BannerStoreTarget } from '../types';

export const BannersPage: React.FC = () => {
  const [banners, setBanners] = useState<HomeBanner[]>([]);
  const [stores, setStores] = useState<StoreType[]>([]);
  const [merchants, setMerchants] = useState<User[]>([]);
  const [governorates, setGovernorates] = useState<Governorate[]>([]);
  const [loading, setLoading] = useState(false);

  const [isBannerModalOpen, setIsBannerModalOpen] = useState(false);
  const [editingBannerId, setEditingBannerId] = useState<string | null>(null);

  // Form State - Media & Basic Info
  const [imageUrl, setImageUrl] = useState('');
  const [mobileImageUrl, setMobileImageUrl] = useState('');
  const [placement, setPlacement] = useState('home');
  const [priority, setPriority] = useState<number>(50);
  const [displayOrder, setDisplayOrder] = useState<number>(1);
  const [isActive, setIsActive] = useState<boolean>(true);
  const [merchantId, setMerchantId] = useState<string>('');

  // Form State - Schedule & Recurrence
  const [startsAt, setStartsAt] = useState<string>('');
  const [endsAt, setEndsAt] = useState<string>('');
  const [timezone, setTimezone] = useState<string>('Asia/Baghdad');
  const [recurrenceType, setRecurrenceType] = useState<'none' | 'daily' | 'weekly' | 'monthly'>('none');
  const [recurrenceTime, setRecurrenceTime] = useState<string>('08:00');
  const [recurrenceEnd, setRecurrenceEnd] = useState<string>('');

  // Form State - Action & Payload
  const [actionType, setActionType] = useState<BannerActionType>('none');
  const [actionValue, setActionValue] = useState('');

  // Form State - Stores & Branches Selection
  const [targetingScope, setTargetingScope] = useState<'all' | 'specific'>('all');
  const [selectedStoreIds, setSelectedStoreIds] = useState<string[]>([]);
  // Mapping storeId -> array of selected branchIds
  const [selectedBranchIdsMap, setSelectedBranchIdsMap] = useState<Record<string, string[]>>({});
  const [expandedStoreId, setExpandedStoreId] = useState<string | null>(null);

  // Form State - Audience & Governorate Targeting
  const [selectedRoles, setSelectedRoles] = useState<string[]>(['customer']);
  const [selectedGovIds, setSelectedGovIds] = useState<number[]>([]);

  const [uploading, setUploading] = useState(false);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [bRes, sRes, mRes, gRes] = await Promise.all([
        api.get('/admin/banners').catch(() => null),
        api.get('/admin/stores').catch(() => null),
        api.get('/admin/users?role=merchant').catch(() => null),
        api.get('/governorates').catch(() => null)
      ]);

      if (bRes?.data?.data) {
        const data = bRes.data.data;
        if (Array.isArray(data)) {
          setBanners(data);
        } else if (data.banners && Array.isArray(data.banners)) {
          setBanners(data.banners);
        }
      }

      if (sRes?.data?.data?.stores) {
        setStores(sRes.data.data.stores);
      } else if (Array.isArray(sRes?.data?.data)) {
        setStores(sRes.data.data);
      }

      if (mRes?.data?.data?.users) {
        setMerchants(mRes.data.data.users);
      }

      if (gRes?.data?.data) {
        setGovernorates(gRes.data.data);
      }
    } catch (err) {
      console.error('Failed to load data', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const resetForm = () => {
    setEditingBannerId(null);
    setImageUrl('');
    setMobileImageUrl('');
    setPlacement('home');
    setPriority(50);
    setDisplayOrder(banners.length + 1);
    setIsActive(true);
    setMerchantId('');
    setStartsAt('');
    setEndsAt('');
    setTimezone('Asia/Baghdad');
    setRecurrenceType('none');
    setRecurrenceTime('08:00');
    setRecurrenceEnd('');
    setActionType('none');
    setActionValue('');
    setTargetingScope('all');
    setSelectedStoreIds([]);
    setSelectedBranchIdsMap({});
    setSelectedRoles(['customer']);
    setSelectedGovIds([]);
    setExpandedStoreId(null);
  };

  const handleOpenCreateModal = () => {
    resetForm();
    setIsBannerModalOpen(true);
  };

  const safeToISOString = (dateStr?: string) => {
    if (!dateStr || !dateStr.trim()) return undefined;
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return undefined;
    return d.toISOString();
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>, isMobile = false) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('image', file);
    setUploading(true);

    try {
      const res = await api.post('/upload/image', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const url = res.data?.data?.url || res.data?.url;
      if (url) {
        if (isMobile) {
          setMobileImageUrl(url);
        } else {
          setImageUrl(url);
        }
      } else {
        alert('لم يتم استرجاع رابط الصورة المرفوعة');
      }
    } catch (err: any) {
      console.error('Failed upload', err);
      alert('فشل رفع صورة البنر: ' + (err.response?.data?.error || err.response?.data?.message || err.message));
    } finally {
      setUploading(false);
    }
  };

  const handleToggleStoreSelection = (storeId: string) => {
    if (selectedStoreIds.includes(storeId)) {
      setSelectedStoreIds(selectedStoreIds.filter((id) => id !== storeId));
      const newMap = { ...selectedBranchIdsMap };
      delete newMap[storeId];
      setSelectedBranchIdsMap(newMap);
    } else {
      setSelectedStoreIds([...selectedStoreIds, storeId]);
    }
  };

  const handleToggleBranchSelection = (storeId: string, branchId: string) => {
    const currentBranches = selectedBranchIdsMap[storeId] || [];
    if (currentBranches.includes(branchId)) {
      setSelectedBranchIdsMap({
        ...selectedBranchIdsMap,
        [storeId]: currentBranches.filter((id) => id !== branchId),
      });
    } else {
      setSelectedBranchIdsMap({
        ...selectedBranchIdsMap,
        [storeId]: [...currentBranches, branchId],
      });
    }
  };

  const handleSaveBanner = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!imageUrl) {
      alert('يرجى اختيار وإدراج صورة البنر الرئيسية');
      return;
    }

    // Action Payload
    const actionPayload: Record<string, any> = {};
    if (actionType === 'open_url') actionPayload.url = actionValue;
    if (actionType === 'open_store') actionPayload.store_id = actionValue;
    if (actionType === 'open_product') actionPayload.product_id = actionValue;
    if (actionType === 'open_category') actionPayload.category_id = actionValue;
    if (actionType === 'open_search') actionPayload.query = actionValue;

    // Build Store Targets
    const storeTargets: BannerStoreTarget[] = [];
    const storeIdsList: string[] = [];
    const branchIdsList: string[] = [];

    if (targetingScope === 'specific' && selectedStoreIds.length > 0) {
      selectedStoreIds.forEach((sId) => {
        storeIdsList.push(sId);
        const branches = selectedBranchIdsMap[sId] || [];
        if (branches.length > 0) {
          branches.forEach((bId) => {
            branchIdsList.push(bId);
            storeTargets.push({ store_id: sId, branch_id: bId });
          });
        } else {
          storeTargets.push({ store_id: sId });
        }
      });
    }

    // Targeting Rules
    const targetingRules: Record<string, any> = {
      version: 1,
      roles: selectedRoles,
    };
    if (selectedGovIds.length > 0) {
      targetingRules.governorate_ids = selectedGovIds;
    }

    const payload = {
      image_url: imageUrl,
      mobile_image_url: mobileImageUrl || undefined,
      placements: [placement],
      priority: Number(priority),
      display_order: Number(displayOrder),
      is_active: isActive,
      starts_at: safeToISOString(startsAt),
      ends_at: safeToISOString(endsAt),
      timezone: timezone || 'Asia/Baghdad',
      recurrence_type: recurrenceType,
      recurrence_time: recurrenceType !== 'none' ? recurrenceTime : undefined,
      recurrence_end: recurrenceType !== 'none' ? safeToISOString(recurrenceEnd) : undefined,
      action_type: actionType,
      action_payload: actionPayload,
      targeting_rules: targetingRules,
      merchant_id: merchantId || undefined,
      store_ids: storeIdsList,
      branch_ids: branchIdsList,
      store_targets: storeTargets,
    };

    try {
      if (editingBannerId) {
        await api.put(`/admin/banners/${editingBannerId}`, payload);
      } else {
        await api.post('/admin/banners', payload);
      }
      setIsBannerModalOpen(false);
      resetForm();
      fetchData();
    } catch (err: any) {
      alert('فشل حفظ البنر: ' + (err.response?.data?.message || err.message));
    }
  };

  const handleDeleteBanner = async (id: string) => {
    if (!confirm('هل أنت تأكد من حذف هذا البنر نهائياً؟')) return;
    try {
      await api.delete(`/admin/banners/${id}`);
      fetchData();
    } catch (err) {
      alert('فشل حذف البنر');
    }
  };

  const formatDateTime = (dateStr?: string) => {
    if (!dateStr) return 'مستمر (غير محدد)';
    const d = new Date(dateStr);
    return d.toLocaleString('ar-IQ', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getBannerStatusBadge = (b: HomeBanner) => {
    if (!b.is_active) {
      return <span className="bg-rose-500/10 text-rose-400 border border-rose-500/30 text-[10px] px-2 py-0.5 rounded-full font-bold">غير فعّال</span>;
    }
    const now = new Date();
    if (b.starts_at && new Date(b.starts_at) > now) {
      return <span className="bg-sky-500/10 text-sky-400 border border-sky-500/30 text-[10px] px-2 py-0.5 rounded-full font-bold">مجدول</span>;
    }
    if (b.ends_at && new Date(b.ends_at) < now) {
      return <span className="bg-slate-700 text-slate-400 border border-slate-600 text-[10px] px-2 py-0.5 rounded-full font-bold">منتهي</span>;
    }
    return <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 text-[10px] px-2 py-0.5 rounded-full font-bold">نشط الآن ✔</span>;
  };

  return (
    <div className="space-y-8">
      {/* Header Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <ImageIcon className="text-amber-400" size={24} />
            منصة إدارة البنرات والإعلانات التفصيلية (Enterprise Banners)
          </h1>
          <p className="text-slate-400 text-xs mt-1">
            إدخال كافة تفاصيل البنرات يدوياً: تواريخ العرض والانتهاء، التكرار، تحديد المتاجر والفروع، والأولويات
          </p>
        </div>
        <button
          onClick={handleOpenCreateModal}
          className="bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-slate-950 font-bold px-5 py-2.5 rounded-xl text-xs flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 transition cursor-pointer"
        >
          <Plus size={18} /> إضافة بنر جديد
        </button>
      </div>

      {/* Banners Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {banners.map((b) => (
          <div key={b.id} className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden group flex flex-col justify-between hover:border-amber-500/40 transition">
            <div>
              {/* Media Preview Header */}
              <div className="h-44 bg-slate-950 relative overflow-hidden">
                <img src={b.image_url} alt="Banner" className="w-full h-full object-cover group-hover:scale-105 transition duration-500" />
                <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-transparent to-black/30" />

                <div className="absolute top-3 right-3 flex items-center gap-1.5">
                  {getBannerStatusBadge(b)}
                </div>

                <button
                  onClick={() => handleDeleteBanner(b.id)}
                  className="absolute top-3 left-3 p-2 bg-rose-500/80 text-white rounded-xl backdrop-blur-md hover:bg-rose-600 transition shadow-md cursor-pointer"
                  title="حذف البنر"
                >
                  <Trash2 size={15} />
                </button>

                <div className="absolute bottom-2 right-3 flex items-center gap-2">
                  <span className="bg-slate-950/80 backdrop-blur-md text-amber-400 font-mono text-[10px] px-2 py-0.5 rounded-md border border-amber-500/30">
                    أولوية: {b.priority}
                  </span>
                  <span className="bg-slate-950/80 backdrop-blur-md text-slate-300 font-mono text-[10px] px-2 py-0.5 rounded-md border border-slate-700">
                    ترتيب: {b.display_order}
                  </span>
                </div>

                {b.mobile_image_url && (
                  <div className="absolute bottom-2 left-3 bg-slate-950/80 backdrop-blur-md text-sky-400 font-mono text-[10px] px-2 py-0.5 rounded-md border border-sky-500/30 flex items-center gap-1">
                    <Smartphone size={10} /> موبايل مخصص
                  </div>
                )}
              </div>

              {/* Banner Details Body */}
              <div className="p-4 space-y-3 text-xs">
                {/* Placement & Action */}
                <div className="flex items-center justify-between gap-2 border-b border-slate-800 pb-2.5">
                  <span className="bg-amber-500/10 text-amber-400 text-[10px] px-2.5 py-1 rounded-lg font-bold border border-amber-500/20 flex items-center gap-1">
                    <Layers size={12} /> {b.placements?.[0] || 'home'}
                  </span>
                  <span className="text-[10px] text-slate-300 font-mono bg-slate-800 px-2 py-1 rounded-lg flex items-center gap-1 line-clamp-1">
                    <ExternalLink size={12} className="text-slate-400" /> {b.action_type}
                  </span>
                </div>

                {/* Schedule Dates */}
                <div className="space-y-1 bg-slate-950/60 p-2.5 rounded-xl border border-slate-800/80">
                  <div className="flex items-center justify-between text-[11px]">
                    <span className="text-slate-400 flex items-center gap-1">
                      <Calendar size={12} className="text-emerald-400" /> البدء:
                    </span>
                    <span className="text-slate-200 font-mono">{formatDateTime(b.starts_at)}</span>
                  </div>
                  <div className="flex items-center justify-between text-[11px]">
                    <span className="text-slate-400 flex items-center gap-1">
                      <Calendar size={12} className="text-rose-400" /> الانتهاء:
                    </span>
                    <span className="text-slate-200 font-mono">{formatDateTime(b.ends_at)}</span>
                  </div>
                  {b.recurrence_type && b.recurrence_type !== 'none' && (
                    <div className="flex items-center justify-between text-[10px] text-amber-400 pt-1 border-t border-slate-800/50 mt-1">
                      <span className="flex items-center gap-1"><Clock size={10} /> تكرار: {b.recurrence_type}</span>
                      <span>{b.recurrence_time || '-'}</span>
                    </div>
                  )}
                </div>

                {/* Target Stores & Branches Badge */}
                <div className="bg-slate-950/40 p-2 rounded-xl border border-slate-800/60 flex items-center gap-2">
                  <Store size={14} className="text-amber-400 shrink-0" />
                  <div className="text-[11px] text-slate-300 line-clamp-1">
                    {b.store_ids && b.store_ids.length > 0 ? (
                      <span>
                        مستهدف ({b.store_ids.length}) متاجر
                        {b.branch_ids && b.branch_ids.length > 0 ? ` و (${b.branch_ids.length}) فروع` : ''}
                      </span>
                    ) : (
                      <span className="text-slate-400">جميع المتاجر والفروع (عام)</span>
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>
        ))}

        {banners.length === 0 && !loading && (
          <div className="col-span-full text-center py-16 bg-slate-900/50 border border-slate-800 rounded-2xl text-slate-400 text-xs space-y-2">
            <ShieldAlert className="mx-auto text-amber-400" size={36} />
            <p className="font-bold text-slate-200 text-sm">لا توجد بنرات ترويجية حالياً</p>
            <p className="text-slate-400">اضغط على زر "إضافة بنر جديد" لإدراج بنر وإدخال كافة التفاصيل يدوياً.</p>
          </div>
        )}
      </div>

      {/* Comprehensive Manual Entry Modal */}
      {isBannerModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-3xl w-full p-6 space-y-6 text-xs max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-lg font-bold text-slate-100 flex items-center gap-2">
                <ImageIcon className="text-amber-400" size={20} />
                إدخال تفاصيل البنر الترويجي يدوياً
              </h3>
              <button
                onClick={() => setIsBannerModalOpen(false)}
                className="text-slate-400 hover:text-slate-200 text-sm font-bold px-2 py-1 rounded-lg bg-slate-800 cursor-pointer"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSaveBanner} className="space-y-6">

              {/* Section 1: Banner Images & Placement */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h4 className="font-bold text-amber-400 border-b border-slate-800/80 pb-2 text-sm flex items-center gap-1.5">
                  <ImageIcon size={16} /> 1. صور البنر ومكان الظهور
                </h4>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">صورة الويب / الكبيرة (Image URL) *</label>
                    <input
                      required
                      type="url"
                      value={imageUrl}
                      onChange={(e) => setImageUrl(e.target.value)}
                      placeholder="https://..."
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100 outline-none focus:border-amber-500/50"
                    />
                    <div className="mt-2 flex items-center gap-2">
                      <input type="file" accept="image/*" onChange={(e) => handleImageUpload(e, false)} className="text-slate-400 text-xs" />
                    </div>
                    {imageUrl && <img src={imageUrl} alt="معاينة الويب" className="mt-2 w-full h-24 object-cover rounded-xl border border-slate-800" />}
                  </div>

                  <div>
                    <label className="block text-slate-300 font-bold mb-1">صورة تطبيق الموبايل (Mobile Image URL - اختياري)</label>
                    <input
                      type="url"
                      value={mobileImageUrl}
                      onChange={(e) => setMobileImageUrl(e.target.value)}
                      placeholder="https://..."
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100 outline-none focus:border-amber-500/50"
                    />
                    <div className="mt-2 flex items-center gap-2">
                      <input type="file" accept="image/*" onChange={(e) => handleImageUpload(e, true)} className="text-slate-400 text-xs" />
                    </div>
                    {mobileImageUrl && <img src={mobileImageUrl} alt="معاينة الموبايل" className="mt-2 w-full h-24 object-cover rounded-xl border border-slate-800" />}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">مكان الظهور (Placement)</label>
                    <select
                      value={placement}
                      onChange={(e) => setPlacement(e.target.value)}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100 outline-none focus:border-amber-500/50"
                    >
                      <option value="home">الصحفة الرئيسية (home)</option>
                      <option value="store">صفحة المتجر (store)</option>
                      <option value="category">صفحة التصنيف (category)</option>
                      <option value="product">صفحة المنتج (product)</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-slate-300 font-bold mb-1">التاجر المالك للبنر (Merchant Owner - اختياري)</label>
                    <select
                      value={merchantId}
                      onChange={(e) => setMerchantId(e.target.value)}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100 outline-none focus:border-amber-500/50"
                    >
                      <option value="">-- عام (مدير النظام) --</option>
                      {merchants.map((m) => (
                        <option key={m.id} value={m.id}>{m.full_name} ({m.phone})</option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              {/* Section 2: Priority & Display Order */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h4 className="font-bold text-amber-400 border-b border-slate-800/80 pb-2 text-sm flex items-center gap-1.5">
                  <Layers size={16} /> 2. الأولوية والترتيب وحالة التفعيل
                </h4>

                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">الأولوية Priority (0-100)</label>
                    <input
                      type="number"
                      min="0"
                      max="100"
                      value={priority}
                      onChange={(e) => setPriority(Number(e.target.value))}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100"
                    />
                  </div>

                  <div>
                    <label className="block text-slate-300 font-bold mb-1">تسلسل العرض Display Order</label>
                    <input
                      type="number"
                      min="1"
                      value={displayOrder}
                      onChange={(e) => setDisplayOrder(Number(e.target.value))}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100"
                    />
                  </div>

                  <div>
                    <label className="block text-slate-300 font-bold mb-1">حالة التفعيل</label>
                    <button
                      type="button"
                      onClick={() => setIsActive(!isActive)}
                      className={`w-full py-2 px-3 rounded-xl font-bold border transition flex items-center justify-center gap-2 cursor-pointer ${isActive ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/40' : 'bg-rose-500/20 text-rose-400 border-rose-500/40'}`}
                    >
                      {isActive ? <CheckCircle2 size={16} /> : <XCircle size={16} />}
                      {isActive ? 'فعّال ومكتمل' : 'غير فعّال'}
                    </button>
                  </div>
                </div>
              </div>

              {/* Section 3: Schedule & Dates & Recurrence */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h4 className="font-bold text-amber-400 border-b border-slate-800/80 pb-2 text-sm flex items-center gap-1.5">
                  <Calendar size={16} /> 3. تاريخ ووقت الإعلان والتكرار الدوري
                </h4>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">تاريخ ووقت البدء (Starts At)</label>
                    <input
                      type="datetime-local"
                      value={startsAt}
                      onChange={(e) => setStartsAt(e.target.value)}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100 font-mono"
                    />
                  </div>

                  <div>
                    <label className="block text-slate-300 font-bold mb-1">تاريخ ووقت الانتهاء (Ends At)</label>
                    <input
                      type="datetime-local"
                      value={endsAt}
                      onChange={(e) => setEndsAt(e.target.value)}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100 font-mono"
                    />
                  </div>

                  <div>
                    <label className="block text-slate-300 font-bold mb-1">المنطقة الزمنية (Timezone)</label>
                    <input
                      type="text"
                      value={timezone}
                      onChange={(e) => setTimezone(e.target.value)}
                      placeholder="Asia/Baghdad"
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100 font-mono"
                    />
                  </div>
                </div>

                {/* Recurrence Subsection */}
                <div className="bg-slate-900 p-3 rounded-xl border border-slate-800 space-y-3">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                      <label className="block text-slate-400 mb-1">نوع التكرار الدوري (Recurrence)</label>
                      <select
                        value={recurrenceType}
                        onChange={(e) => setRecurrenceType(e.target.value as any)}
                        className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                      >
                        <option value="none">بدون تكرار (مستمر)</option>
                        <option value="daily">يومي (Daily)</option>
                        <option value="weekly">أسبوعي (Weekly)</option>
                        <option value="monthly">شهري (Monthly)</option>
                      </select>
                    </div>

                    {recurrenceType !== 'none' && (
                      <>
                        <div>
                          <label className="block text-slate-400 mb-1">وقت البدء اليومي (HH:mm)</label>
                          <input
                            type="time"
                            value={recurrenceTime}
                            onChange={(e) => setRecurrenceTime(e.target.value)}
                            className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono"
                          />
                        </div>

                        <div>
                          <label className="block text-slate-400 mb-1">تاريخ نهاية التكرار</label>
                          <input
                            type="datetime-local"
                            value={recurrenceEnd}
                            onChange={(e) => setRecurrenceEnd(e.target.value)}
                            className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100 font-mono"
                          />
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </div>

              {/* Section 4: Action & Click Link */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h4 className="font-bold text-amber-400 border-b border-slate-800/80 pb-2 text-sm flex items-center gap-1.5">
                  <ExternalLink size={16} /> 4. إجراء الضغط على البنر (Action)
                </h4>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-slate-300 font-bold mb-1">نوع إجراء الضغط</label>
                    <select
                      value={actionType}
                      onChange={(e) => setActionType(e.target.value as BannerActionType)}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100"
                    >
                      <option value="none">بدون إجراء (none)</option>
                      <option value="open_url">فتح رابط خارجي (open_url)</option>
                      <option value="open_store">فتح متجر محدد (open_store)</option>
                      <option value="open_product">فتح منتج محدد (open_product)</option>
                      <option value="open_category">فتح قسم محدد (open_category)</option>
                      <option value="open_search">فتح بحث تلقائي (open_search)</option>
                    </select>
                  </div>

                  {actionType !== 'none' && (
                    <div>
                      <label className="block text-slate-300 font-bold mb-1">قيمة الإجراء (URL / Store ID / Product ID)</label>
                      <input
                        type="text"
                        value={actionValue}
                        onChange={(e) => setActionValue(e.target.value)}
                        placeholder="أدخل الرابط أو معرف المتجر / المنتج"
                        className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-slate-100"
                      />
                    </div>
                  )}
                </div>
              </div>

              {/* Section 5: Target Stores & Branches */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h4 className="font-bold text-amber-400 border-b border-slate-800/80 pb-2 text-sm flex items-center gap-1.5">
                  <Store size={16} /> 5. ربط البنر بالمتاجر والفروع التابعة
                </h4>

                <div className="flex items-center gap-6">
                  <label className="flex items-center gap-2 text-slate-200 font-bold cursor-pointer">
                    <input
                      type="radio"
                      name="targetingScope"
                      checked={targetingScope === 'all'}
                      onChange={() => setTargetingScope('all')}
                      className="accent-amber-500"
                    />
                    جميع المتاجر والفروع (إعلان عام)
                  </label>

                  <label className="flex items-center gap-2 text-slate-200 font-bold cursor-pointer">
                    <input
                      type="radio"
                      name="targetingScope"
                      checked={targetingScope === 'specific'}
                      onChange={() => setTargetingScope('specific')}
                      className="accent-amber-500"
                    />
                    تحديد متاجر وفروع معينة
                  </label>
                </div>

                {targetingScope === 'specific' && (
                  <div className="space-y-3 pt-2">
                    <p className="text-slate-400 text-[11px]">اختر المتجر، وإذا كان للمتجر أكثر من فرع يمكنك النقر لاختيار فروع محددة:</p>
                    <div className="max-h-56 overflow-y-auto space-y-2 pr-1">
                      {stores.map((s) => {
                        const isStoreSelected = selectedStoreIds.includes(s.id);
                        const hasBranches = s.branches && s.branches.length > 0;
                        const isExpanded = expandedStoreId === s.id;
                        const selectedBranchesForStore = selectedBranchIdsMap[s.id] || [];

                        return (
                          <div key={s.id} className="bg-slate-900 rounded-xl border border-slate-800 p-3 space-y-2">
                            <div className="flex items-center justify-between">
                              <label className="flex items-center gap-2 font-bold text-slate-100 cursor-pointer">
                                <input
                                  type="checkbox"
                                  checked={isStoreSelected}
                                  onChange={() => handleToggleStoreSelection(s.id)}
                                  className="accent-amber-500 w-4 h-4 rounded"
                                />
                                <span>{s.name}</span>
                              </label>

                              {hasBranches && isStoreSelected && (
                                <button
                                  type="button"
                                  onClick={() => setExpandedStoreId(isExpanded ? null : s.id)}
                                  className="text-amber-400 hover:text-amber-300 text-[11px] font-bold flex items-center gap-1 bg-amber-500/10 px-2 py-1 rounded-lg border border-amber-500/20 cursor-pointer"
                                >
                                  <MapPin size={12} />
                                  {s.branches?.length} فروع ({selectedBranchesForStore.length} محدد)
                                  {isExpanded ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                                </button>
                              )}
                            </div>

                            {/* Branches Dropdown List */}
                            {hasBranches && isStoreSelected && isExpanded && (
                              <div className="pt-2 border-t border-slate-800/80 pl-6 space-y-1.5 bg-slate-950/60 p-2.5 rounded-lg">
                                <span className="text-slate-400 text-[10px] block font-bold mb-1">اختر الفروع التابعة لـ ({s.name}):</span>
                                {s.branches?.map((br) => {
                                  const isBranchSelected = selectedBranchesForStore.includes(br.id);
                                  return (
                                    <label key={br.id} className="flex items-center gap-2 text-slate-300 text-[11px] cursor-pointer">
                                      <input
                                        type="checkbox"
                                        checked={isBranchSelected}
                                        onChange={() => handleToggleBranchSelection(s.id, br.id)}
                                        className="accent-amber-500 w-3.5 h-3.5 rounded"
                                      />
                                      <span>{br.name} ({br.governorate_name_ar || 'المحافظة'} - {br.city})</span>
                                    </label>
                                  );
                                })}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>

              {/* Section 6: Audience & Governorate Rules */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h4 className="font-bold text-amber-400 border-b border-slate-800/80 pb-2 text-sm flex items-center gap-1.5">
                  <Users size={16} /> 6. استهداف الجمهور والمحافظات
                </h4>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <label className="block text-slate-300 font-bold mb-2">الأدوار والشرائح المستهدفة (Roles)</label>
                    <div className="space-y-1.5">
                      {[
                        { id: 'customer', label: 'الزبائن (Customer)' },
                        { id: 'merchant', label: 'التجار (Merchant)' },
                        { id: 'engineer', label: 'المهندسين (Engineer)' },
                        { id: 'installer', label: 'المُصلحين / الفنيين (Installer)' },
                      ].map((r) => (
                        <label key={r.id} className="flex items-center gap-2 text-slate-300 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={selectedRoles.includes(r.id)}
                            onChange={(e) => {
                              if (e.target.checked) setSelectedRoles([...selectedRoles, r.id]);
                              else setSelectedRoles(selectedRoles.filter((id) => id !== r.id));
                            }}
                            className="accent-amber-500"
                          />
                          <span>{r.label}</span>
                        </label>
                      ))}
                    </div>
                  </div>

                  <div>
                    <label className="block text-slate-300 font-bold mb-2">المحافظات المستهدفة (اختياري - الكل إذا تُرك فارغاً)</label>
                    <div className="max-h-36 overflow-y-auto space-y-1.5 pr-1">
                      {governorates.map((g) => (
                        <label key={g.id} className="flex items-center gap-2 text-slate-300 cursor-pointer">
                          <input
                            type="checkbox"
                            checked={selectedGovIds.includes(g.id)}
                            onChange={(e) => {
                              if (e.target.checked) setSelectedGovIds([...selectedGovIds, g.id]);
                              else setSelectedGovIds(selectedGovIds.filter((id) => id !== g.id));
                            }}
                            className="accent-amber-500"
                          />
                          <span>{g.name_ar}</span>
                        </label>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              {/* Form Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsBannerModalOpen(false)}
                  className="px-5 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={!imageUrl || uploading}
                  className="px-7 py-2.5 bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-slate-950 rounded-xl font-bold shadow-lg shadow-amber-500/20 disabled:opacity-50 cursor-pointer"
                >
                  {uploading ? 'جارٍ رفع الصورة...' : 'حفظ البنر وتطبيق الإعدادات'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

