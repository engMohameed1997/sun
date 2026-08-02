import React, { useState, useEffect } from 'react';
import { Store, ShieldCheck, Truck, CheckCircle2, XCircle } from 'lucide-react';
import { api } from '../services/api';
import type { User, DeliveryFee } from '../types';

export const StoresPage: React.FC = () => {
  const [stores, setStores] = useState<User[]>([]);
  const [selectedStoreFees, setSelectedStoreFees] = useState<{ store: User; fees: DeliveryFee[] } | null>(null);
  const [updatingFee, setUpdatingFee] = useState(false);

  const fetchStores = async () => {
    try {
      const res = await api.get('/admin/users?role=merchant');
      if (res.data?.data?.users) {
        setStores(res.data.data.users);
      } else {
        setStores([]);
      }
    } catch (err) {
      console.error('Failed to fetch stores', err);
    }
  };

  useEffect(() => {
    fetchStores();
  }, []);

  const handleToggleVerification = async (storeId: string, currentStatus: boolean) => {
    try {
      await api.put(`/admin/stores/${storeId}/verify`, { is_verified: !currentStatus });
      fetchStores();
    } catch (err) {
      alert('حدث خطأ أثناء تعديل توثيق المتجر');
    }
  };

  const openDeliveryFeesModal = async (store: User) => {
    try {
      const res = await api.get(`/admin/stores/${store.id}/delivery-fees`);
      let feesList: DeliveryFee[] = res.data?.data || [];
      if (feesList.length === 0) {
        feesList = [
          { id: 1, merchant_id: store.id, governorate_id: 1, fee_iqd: 5000, estimated_days: 1, is_active: true, governorate_name_ar: 'بغداد' },
          { id: 2, merchant_id: store.id, governorate_id: 2, fee_iqd: 15000, estimated_days: 3, is_active: true, governorate_name_ar: 'البصرة' },
          { id: 3, merchant_id: store.id, governorate_id: 3, fee_iqd: 12000, estimated_days: 2, is_active: true, governorate_name_ar: 'نينوى' },
          { id: 4, merchant_id: store.id, governorate_id: 4, fee_iqd: 10000, estimated_days: 2, is_active: true, governorate_name_ar: 'أربيل' },
        ];
      }
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

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Store className="text-amber-400" size={22} />
            إدارة المتاجر وتوثيق الاعتماد
          </h1>
          <p className="text-slate-400 text-xs mt-1">منح شارة التوثيق للتجار وضبط مصفوفة أسعار التوصيل لكل محافظة</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {stores.map((s) => (
          <div key={s.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-5 space-y-4">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400 font-bold">
                  <Store size={24} />
                </div>
                <div>
                  <h3 className="font-bold text-slate-100 text-sm flex items-center gap-2">
                    {s.full_name}
                    {s.is_verified && (
                      <span className="bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 text-[10px] px-2 py-0.5 rounded-full flex items-center gap-1">
                        <ShieldCheck size={12} /> متجر موثّق
                      </span>
                    )}
                  </h3>
                  <div className="text-xs text-slate-400">{s.governorate} - {s.city}</div>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2 bg-slate-950/60 p-3 rounded-xl border border-slate-800/80 text-xs">
              <div>
                <span className="text-slate-500 block text-[10px]">البريد</span>
                <span className="text-slate-300 font-medium">{s.email}</span>
              </div>
              <div>
                <span className="text-slate-500 block text-[10px]">الهاتف</span>
                <span className="text-slate-300 font-mono">{s.phone}</span>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2 border-t border-slate-800/60">
              <button
                onClick={() => handleToggleVerification(s.id, !!s.is_verified)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition ${
                  s.is_verified
                    ? 'bg-rose-500/10 text-rose-400 border border-rose-500/30 hover:bg-rose-500/20'
                    : 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/20'
                }`}
              >
                {s.is_verified ? <XCircle size={14} /> : <CheckCircle2 size={14} />}
                {s.is_verified ? 'إلغاء التوثيق' : 'منح التوثيق ✔'}
              </button>

              <button
                onClick={() => openDeliveryFeesModal(s)}
                className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-amber-400 rounded-xl text-xs font-bold flex items-center gap-1.5 transition"
              >
                <Truck size={14} /> ضبط أسعار التوصيل
              </button>
            </div>
          </div>
        ))}
      </div>

      {selectedStoreFees && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-xl w-full p-6 space-y-5">
            <h3 className="text-lg font-bold text-slate-100">
              ضبط أسعار التوصيل لـ ({selectedStoreFees.store.full_name})
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
                className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-xs font-bold"
              >
                إلغاء
              </button>
              <button
                onClick={handleSaveDeliveryFees}
                disabled={updatingFee}
                className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl text-xs font-bold"
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
