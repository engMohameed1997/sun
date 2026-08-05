import React, { useCallback, useEffect, useState } from 'react';
import { SlidersHorizontal, Save, RefreshCw } from 'lucide-react';
import { api } from '../services/api';
import type { DispatchMode, DispatchSettings, ServiceOrderType } from '../types';

const SERVICE_TYPES: { value: ServiceOrderType; label: string }[] = [
  { value: 'installation', label: 'تركيب' },
  { value: 'maintenance', label: 'صيانة' },
  { value: 'inspection', label: 'معاينة' },
  { value: 'consultation', label: 'استشارة' },
  { value: 'repair', label: 'إصلاح' },
];

const MODES: { value: DispatchMode; label: string; hint: string }[] = [
  { value: 'sequential', label: 'تسلسلي', hint: 'إرسال للفني الأول ثم التالي عند الرفض' },
  { value: 'parallel', label: 'متوازي', hint: 'إرسال لعدة فنيين — أسرع قبول يفوز' },
  { value: 'hybrid', label: 'هجين', hint: 'النظام يقرر حسب نوع وحجم الطلب' },
];

const defaultRow = (serviceType: ServiceOrderType): DispatchSettings => ({
  id: serviceType,
  service_type: serviceType,
  dispatch_mode: 'hybrid',
  response_timeout_minutes: 10,
  parallel_candidates_count: 3,
  minimum_score: 0,
  auto_assign_enabled: true,
});

export const DispatchSettingsPage: React.FC = () => {
  const [rows, setRows] = useState<DispatchSettings[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [savingType, setSavingType] = useState<string | null>(null);

  const fetchSettings = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/dispatch-settings');
      const existing: DispatchSettings[] = res.data?.data || [];
      const merged = SERVICE_TYPES.map(
        (t) => existing.find((s) => s.service_type === t.value) || defaultRow(t.value)
      );
      setRows(merged);
    } catch (err) {
      console.error('Failed to fetch dispatch settings', err);
      setRows(SERVICE_TYPES.map((t) => defaultRow(t.value)));
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  const patchRow = (serviceType: string, patch: Partial<DispatchSettings>) => {
    setRows((prev) => prev.map((r) => (r.service_type === serviceType ? { ...r, ...patch } : r)));
  };

  const handleSave = async (row: DispatchSettings) => {
    setSavingType(row.service_type);
    try {
      await api.put('/admin/dispatch-settings', {
        service_type: row.service_type,
        dispatch_mode: row.dispatch_mode,
        response_timeout_minutes: Number(row.response_timeout_minutes),
        parallel_candidates_count: Number(row.parallel_candidates_count),
        minimum_score: Number(row.minimum_score),
        auto_assign_enabled: row.auto_assign_enabled,
      });
      alert('تم حفظ الإعدادات');
      fetchSettings();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر حفظ الإعدادات');
    } finally {
      setSavingType(null);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <SlidersHorizontal className="text-amber-400" size={22} />
            إعدادات محرك التوزيع
          </h1>
          <p className="text-slate-400 text-xs mt-1">
            تحكّم بسلوك التوزيع لكل نوع خدمة بدون تعديل الكود — الوضع، مهلة الرد، عدد المرشحين، وأقل Score مقبول
          </p>
        </div>
        <button
          onClick={fetchSettings}
          className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <RefreshCw size={16} />
          تحديث
        </button>
      </div>

      {isLoading ? (
        <div className="p-10 text-center text-slate-400 font-bold bg-slate-900 border border-slate-800 rounded-2xl">
          جارٍ التحميل...
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {rows.map((row) => {
            const typeLabel = SERVICE_TYPES.find((t) => t.value === row.service_type)?.label || row.service_type;
            const modeHint = MODES.find((m) => m.value === row.dispatch_mode)?.hint;
            return (
              <div key={row.service_type} className="bg-slate-900 border border-slate-800 rounded-2xl p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <h2 className="font-bold text-slate-100 text-sm">{typeLabel}</h2>
                  <label className="flex items-center gap-2 text-xs text-slate-400 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={row.auto_assign_enabled}
                      onChange={(e) => patchRow(row.service_type, { auto_assign_enabled: e.target.checked })}
                      className="w-4 h-4 rounded border-slate-700 bg-slate-900 accent-amber-500"
                    />
                    توزيع تلقائي
                  </label>
                </div>

                <div>
                  <label className="block text-slate-400 text-xs mb-1">وضع التوزيع</label>
                  <div className="grid grid-cols-3 gap-2">
                    {MODES.map((mode) => (
                      <button
                        key={mode.value}
                        onClick={() => patchRow(row.service_type, { dispatch_mode: mode.value })}
                        className={`px-2 py-1.5 rounded-lg text-xs font-bold border transition cursor-pointer ${
                          row.dispatch_mode === mode.value
                            ? 'bg-amber-500/20 text-amber-300 border-amber-500/40'
                            : 'bg-slate-950 text-slate-400 border-slate-800 hover:border-slate-700'
                        }`}
                      >
                        {mode.label}
                      </button>
                    ))}
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1">{modeHint}</p>
                </div>

                <div className="grid grid-cols-3 gap-2">
                  <div>
                    <label className="block text-slate-400 text-[11px] mb-1">مهلة الرد (دقيقة)</label>
                    <input
                      type="number"
                      min={1}
                      value={row.response_timeout_minutes}
                      onChange={(e) => patchRow(row.service_type, { response_timeout_minutes: Number(e.target.value) })}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 text-[11px] mb-1">عدد المرشحين</label>
                    <input
                      type="number"
                      min={1}
                      value={row.parallel_candidates_count}
                      onChange={(e) => patchRow(row.service_type, { parallel_candidates_count: Number(e.target.value) })}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 text-[11px] mb-1">أقل Score</label>
                    <input
                      type="number"
                      min={0}
                      max={100}
                      step="0.5"
                      value={row.minimum_score}
                      onChange={(e) => patchRow(row.service_type, { minimum_score: Number(e.target.value) })}
                      className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
                    />
                  </div>
                </div>

                <button
                  onClick={() => handleSave(row)}
                  disabled={savingType === row.service_type}
                  className="w-full px-4 py-2 bg-amber-500 text-slate-950 rounded-xl text-sm font-bold hover:bg-amber-600 disabled:opacity-50 flex items-center justify-center gap-2 cursor-pointer"
                >
                  <Save size={16} />
                  {savingType === row.service_type ? 'جارٍ الحفظ...' : 'حفظ'}
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default DispatchSettingsPage;
