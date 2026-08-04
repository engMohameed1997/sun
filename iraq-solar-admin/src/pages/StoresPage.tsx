import React, { useState, useEffect } from 'react';
import { Store, ShieldCheck, Truck, CheckCircle2, XCircle, Plus, MapPin } from 'lucide-react';
import { api } from '../services/api';
import type { Store as StoreType, DeliveryFee, User, Governorate } from '../types';

export const StoresPage: React.FC = () => {
  const [stores, setStores] = useState<StoreType[]>([]);
  const [merchants, setMerchants] = useState<User[]>([]);
  const [governorates, setGovernorates] = useState<Governorate[]>([]);
  const [selectedStoreFees, setSelectedStoreFees] = useState<{ store: StoreType; fees: DeliveryFee[] } | null>(null);
  const [updatingFee, setUpdatingFee] = useState(false);

  const [isAddStoreModalOpen, setIsAddStoreModalOpen] = useState(false);
  const [newStore, setNewStore] = useState({
    merchant_id: '',
    name: '',
    slug: '',
    phone: '',
    description: '',
    logo_url: '',
    cover_url: '',
    // Branch info
    governorate_id: '',
    city: '',
    address: ''
  });
  const [creatingStore, setCreatingStore] = useState(false);

  const fetchStores = async () => {
    try {
      const res = await api.get('/admin/stores');
      if (res.data?.data?.stores) {
        setStores(res.data.data.stores);
      } else {
        setStores([]);
      }
    } catch (err) {
      console.error('Failed to fetch stores', err);
    }
  };

  const fetchMerchants = async () => {
    try {
      const res = await api.get('/admin/users?role=merchant');
      if (res.data?.data?.users) {
        setMerchants(res.data.data.users);
      }
    } catch (err) {
      console.error('Failed to fetch merchants', err);
    }
  };

  const fetchGovernorates = async () => {
    try {
      const res = await api.get('/governorates');
      if (res.data?.data) {
        setGovernorates(res.data.data);
      }
    } catch (err) {
      console.error('Failed to fetch governorates', err);
    }
  };

  useEffect(() => {
    fetchStores();
    fetchMerchants();
    fetchGovernorates();
  }, []);

  const handleToggleVerification = async (storeId: string, currentStatus: boolean) => {
    try {
      await api.put(`/admin/stores/${storeId}/verify`, { is_verified: !currentStatus });
      fetchStores();
    } catch (err) {
      alert('حدث خطأ أثناء تعديل توثيق المتجر');
    }
  };

  const openDeliveryFeesModal = async (store: StoreType) => {
    try {
      const res = await api.get(`/admin/stores/${store.id}/delivery-fees`);
      const savedFees: DeliveryFee[] = res.data?.data || [];
      const savedGovIds = new Set(savedFees.map((f) => f.governorate_id));
      const missing = governorates.filter((g) => !savedGovIds.has(g.id));
      const defaultFees: DeliveryFee[] = missing.map((g) => ({
        id: 0,
        merchant_id: store.merchant_id,
        store_id: store.id,
        governorate_id: g.id,
        fee_iqd: 5000,
        estimated_days: 2,
        is_active: true,
        governorate_name_ar: g.name_ar,
        governorate_name_en: g.name_en,
      }));
      const feesList = [...savedFees, ...defaultFees];
      setSelectedStoreFees({ store, fees: feesList });
    } catch (err) {
      alert('فشل جلب أسعار التوصيل للمتجر');
    }
  };

  const handleSaveDeliveryFees = async () => {
    if (!selectedStoreFees) return;
    setUpdatingFee(true);
    try {
      const payload = {
        merchant_id: selectedStoreFees.store.merchant_id,
        fees: selectedStoreFees.fees.map((f) => ({
          governorate_id: f.governorate_id,
          fee_iqd: Number(f.fee_iqd),
          estimated_days: Number(f.estimated_days),
          is_active: f.is_active,
        })),
      };
      await api.put(`/admin/stores/${selectedStoreFees.store.id}/delivery-fees`, payload);
      alert('تم حفظ أسعار التوصيل بنجاح');
      setSelectedStoreFees(null);
    } catch (err) {
      alert('فشل حفظ أسعار التوصيل');
    } finally {
      setUpdatingFee(false);
    }
  };

  const handleCreateStore = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newStore.merchant_id || !newStore.name) {
      alert('الرجاء اختيار التاجر وإدخال اسم المتجر');
      return;
    }

    setCreatingStore(true);
    try {
      // 1. Create the store
      const storeRes = await api.post('/admin/stores', {
        merchant_id: newStore.merchant_id,
        name: newStore.name,
        slug: newStore.slug,
        phone: newStore.phone,
        description: newStore.description,
        logo_url: newStore.logo_url,
        cover_url: newStore.cover_url,
      });

      const createdStore = storeRes.data.data;

      // 2. Automatically create the first (main) branch if governorate is selected
      if (newStore.governorate_id) {
        await api.post(`/admin/stores/${createdStore.id}/branches`, {
          name: 'الفرع الرئيسي',
          governorate_id: Number(newStore.governorate_id),
          city: newStore.city,
          address: newStore.address,
          phone: newStore.phone // copy store phone to branch if provided
        });
      }

      alert('تم إنشاء المتجر والفرع بنجاح');
      setIsAddStoreModalOpen(false);
      setNewStore({ merchant_id: '', name: '', slug: '', phone: '', description: '', logo_url: '', cover_url: '', governorate_id: '', city: '', address: '' });
      fetchStores();
    } catch (err: any) {
      alert(err.response?.data?.message || 'فشل إنشاء المتجر');
    } finally {
      setCreatingStore(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Store className="text-amber-400" size={22} />
            إدارة المتاجر والفروع
          </h1>
          <p className="text-slate-400 text-xs mt-1">منح شارة التوثيق للتجار، ضبط أسعار التوصيل وإضافة متاجر جديدة</p>
        </div>
        <button
          onClick={() => setIsAddStoreModalOpen(true)}
          className="bg-amber-500 hover:bg-amber-600 text-slate-950 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <Plus size={18} />
          إضافة متجر جديد
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {stores.map((s) => (
          <div key={s.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4 flex flex-col justify-between">
            <div>
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400 font-bold overflow-hidden">
                    {s.logo_url ? <img src={s.logo_url} alt={s.name} className="w-full h-full object-cover rounded-xl" /> : <Store size={24} />}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-100 text-sm flex items-center gap-2">
                      {s.name}
                      {s.is_verified && (
                        <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 text-[10px] px-2 py-0.5 rounded-full flex items-center gap-1">
                          <ShieldCheck size={12} /> موثّق
                        </span>
                      )}
                    </h3>
                    <div className="text-xs text-slate-400 mt-1 line-clamp-1">{s.description || 'لا يوجد وصف'}</div>

                    {s.branches && s.branches.length > 0 && (
                      <div className="mt-2 flex items-center gap-1 text-[10px] text-amber-500 bg-amber-500/10 px-2 py-1 rounded-lg w-fit">
                        <MapPin size={10} />
                        {s.branches.length} فروع (الرئيسي: {s.branches[0].governorate_name_ar} - {s.branches[0].city})
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 bg-slate-950/60 p-3 rounded-xl border border-slate-800/80 text-xs">
                <div>
                  <span className="text-slate-500 block text-[10px]">الهاتف</span>
                  <span className="text-slate-300 font-mono">{s.phone || '-'}</span>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2 border-t border-slate-800/60 mt-4">
              <button
                onClick={() => handleToggleVerification(s.id, !!s.is_verified)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition cursor-pointer ${s.is_verified
                  ? 'bg-rose-500/10 text-rose-400 border border-rose-500/30 hover:bg-rose-500/20'
                  : 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/20'
                  }`}
              >
                {s.is_verified ? <XCircle size={14} /> : <CheckCircle2 size={14} />}
                {s.is_verified ? 'إلغاء التوثيق' : 'منح التوثيق ✔'}
              </button>

              <button
                onClick={() => openDeliveryFeesModal(s)}
                className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-amber-400 rounded-xl text-xs font-bold flex items-center gap-1.5 transition cursor-pointer"
              >
                <Truck size={14} /> ضبط التوصيل
              </button>
            </div>
          </div>
        ))}

        {stores.length === 0 && (
          <div className="col-span-1 md:col-span-2 text-center py-10 bg-slate-900 border border-slate-800 rounded-2xl">
            <Store className="text-slate-600 mx-auto mb-3" size={48} />
            <p className="text-slate-400">لا توجد متاجر مضافة حالياً</p>
          </div>
        )}
      </div>

      {isAddStoreModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-6 max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold text-slate-100 mb-4">إنشاء متجر جديد وفرع رئيسي</h2>
            <form onSubmit={handleCreateStore} className="space-y-6">

              {/* Section 1: Store Main Info */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h3 className="text-sm font-bold text-amber-500 border-b border-slate-800 pb-2">1. معلومات المتجر الأساسية</h3>

                <div>
                  <label className="block text-slate-400 text-xs mb-1">صاحب المتجر (التاجر) *</label>
                  <select
                    required
                    value={newStore.merchant_id}
                    onChange={(e) => setNewStore({ ...newStore, merchant_id: e.target.value })}
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                  >
                    <option value="">-- اختر التاجر --</option>
                    {merchants.map((m) => (
                      <option key={m.id} value={m.id}>
                        {m.full_name} ({m.phone})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-slate-400 text-xs mb-1">اسم المتجر (العلامة التجارية) *</label>
                  <input
                    required
                    type="text"
                    value={newStore.name}
                    onChange={(e) => setNewStore({ ...newStore, name: e.target.value })}
                    placeholder="مثال: العالمية للطاقة النظيفة"
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                  />
                </div>

                <div>
                  <label className="block text-slate-400 text-xs mb-1">رابط المتجر (Slug بالإنجليزية - اختياري)</label>
                  <input
                    type="text"
                    value={newStore.slug}
                    onChange={(e) => {
                      // Allow only english letters, numbers, and hyphens. Replace spaces with hyphens.
                      const val = e.target.value.toLowerCase().replace(/\\s+/g, '-').replace(/[^a-z0-9-]/g, '');
                      setNewStore({ ...newStore, slug: val });
                    }}
                    placeholder="مثال: al-alamiya-store"
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-left"
                    dir="ltr"
                  />
                  <p className="text-[10px] text-slate-500 mt-1">يُستخدم في الرابط: /store/al-alamiya-store. إذا تُرك فارغاً سيتم إنشاؤه تلقائياً.</p>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-slate-400 text-xs mb-1">رابط الشعار (Logo URL - اختياري)</label>
                    <input
                      type="url"
                      value={newStore.logo_url}
                      onChange={(e) => setNewStore({ ...newStore, logo_url: e.target.value })}
                      placeholder="https://..."
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 text-xs mb-1">رابط الغلاف (Cover URL - اختياري)</label>
                    <input
                      type="url"
                      value={newStore.cover_url}
                      onChange={(e) => setNewStore({ ...newStore, cover_url: e.target.value })}
                      placeholder="https://..."
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-slate-400 text-xs mb-1">وصف المتجر (اختياري)</label>
                  <textarea
                    value={newStore.description}
                    onChange={(e) => setNewStore({ ...newStore, description: e.target.value })}
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 h-20 resize-none"
                  ></textarea>
                </div>
              </div>

              {/* Section 2: Store Contact Info */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h3 className="text-sm font-bold text-amber-500 border-b border-slate-800 pb-2">2. معلومات التواصل العامة (تظهر للزبائن - اختياري)</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-slate-400 text-xs mb-1">هاتف خدمة العملاء</label>
                    <input
                      type="text"
                      value={newStore.phone}
                      onChange={(e) => setNewStore({ ...newStore, phone: e.target.value })}
                      placeholder="07..."
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                    />
                  </div>
                </div>
              </div>

              {/* Section 3: Main Branch Info */}
              <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-4">
                <h3 className="text-sm font-bold text-amber-500 border-b border-slate-800 pb-2">3. موقع الفرع الرئيسي</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-slate-400 text-xs mb-1">محافظة الفرع الرئيسي</label>
                    <select
                      value={newStore.governorate_id}
                      onChange={(e) => setNewStore({ ...newStore, governorate_id: e.target.value })}
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                    >
                      <option value="">-- اختر المحافظة --</option>
                      {governorates.map((g) => (
                        <option key={g.id} value={g.id}>{g.name_ar}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-slate-400 text-xs mb-1">المدينة / المنطقة</label>
                    <input
                      type="text"
                      value={newStore.city}
                      onChange={(e) => setNewStore({ ...newStore, city: e.target.value })}
                      placeholder="مثال: المنصور"
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-slate-400 text-xs mb-1">العنوان التفصيلي</label>
                  <input
                    type="text"
                    value={newStore.address}
                    onChange={(e) => setNewStore({ ...newStore, address: e.target.value })}
                    placeholder="الشارع، رقم المبنى..."
                    className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsAddStoreModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-sm font-bold hover:bg-slate-700 cursor-pointer"
                >
                  إلغاء
                </button>
                <button
                  type="submit"
                  disabled={creatingStore}
                  className="px-6 py-2 bg-amber-500 text-slate-950 rounded-xl text-sm font-bold hover:bg-amber-600 disabled:opacity-50 cursor-pointer"
                >
                  {creatingStore ? 'جارٍ الحفظ...' : 'حفظ المتجر والفرع'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {selectedStoreFees && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-xl w-full p-6 space-y-5">
            <h3 className="text-lg font-bold text-slate-100">
              ضبط أسعار التوصيل لـ ({selectedStoreFees.store.name})
            </h3>

            <div className="space-y-3 max-h-60 overflow-y-auto pr-1">
              {selectedStoreFees.fees.map((fee, idx) => (
                <div key={fee.governorate_id} className="flex items-center justify-between gap-3 bg-slate-950 p-3 rounded-xl border border-slate-800 text-xs">
                  <span className="font-bold text-slate-200 w-24">{fee.governorate_name_ar || `محافظة ${fee.governorate_id}`}</span>

                  <div className="flex items-center gap-2">
                    <label className="text-slate-400">السعر (د.ع):</label>
                    <input
                      type="number"
                      value={fee.fee_iqd}
                      onChange={(e) => {
                        const newFees = [...selectedStoreFees.fees];
                        newFees[idx].fee_iqd = Number(e.target.value);
                        setSelectedStoreFees({ ...selectedStoreFees, fees: newFees });
                      }}
                      className="w-24 bg-slate-900 border border-slate-700 rounded-lg px-2 py-1 text-slate-100"
                    />
                  </div>

                  <div className="flex items-center gap-2">
                    <label className="text-slate-400">أيام التوصيل:</label>
                    <input
                      type="number"
                      value={fee.estimated_days}
                      onChange={(e) => {
                        const newFees = [...selectedStoreFees.fees];
                        newFees[idx].estimated_days = Number(e.target.value);
                        setSelectedStoreFees({ ...selectedStoreFees, fees: newFees });
                      }}
                      className="w-16 bg-slate-900 border border-slate-700 rounded-lg px-2 py-1 text-slate-100"
                    />
                  </div>
                </div>
              ))}
            </div>

            <div className="flex justify-end gap-2 pt-4 border-t border-slate-800">
              <button
                onClick={() => setSelectedStoreFees(null)}
                className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-xs font-bold cursor-pointer"
              >
                إلغاء
              </button>
              <button
                onClick={handleSaveDeliveryFees}
                disabled={updatingFee}
                className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl text-xs font-bold cursor-pointer"
              >
                {updatingFee ? 'جارٍ الحفظ...' : 'حفظ التعديلات'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
