import React, { useState, useEffect } from 'react';
import { Settings, Save } from 'lucide-react';
import { api } from '../services/api';
import type { SystemSetting } from '../types';

export const SettingsPage: React.FC = () => {
  const [settings, setSettings] = useState<SystemSetting[]>([]);
  const [savingKey, setSavingKey] = useState<string | null>(null);

  const fetchSettings = async () => {
    try {
      const res = await api.get('/admin/settings');
      if (res.data?.data) {
        setSettings(res.data.data);
      } else {
        setSettings([
          { key: 'pending_order_expiry_hours', value: '24', updated_at: new Date().toISOString() },
          { key: 'default_platform_delivery_fee_iqd', value: '10000', updated_at: new Date().toISOString() },
          { key: 'support_phone_number', value: '07700000000', updated_at: new Date().toISOString() },
        ]);
      }
    } catch (err) {
      console.error('Failed to fetch settings', err);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleUpdateSetting = async (key: string, value: string) => {
    setSavingKey(key);
    try {
      await api.put('/admin/settings', { key, value });
      fetchSettings();
      alert(`تم تعديل الإعداد [${key}] بنجاح`);
    } catch (err) {
      alert('فشل تعديل الإعداد');
    } finally {
      setSavingKey(null);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
          <Settings className="text-amber-400" size={22} />
          إعدادات النظام العامة
        </h1>
        <p className="text-slate-400 text-xs mt-1">التحكم بمدة حجز المخزون للطلبات المنتظرة، الرسوم الافتراضية، وهواتف الدعم الفني</p>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 space-y-6">
        {settings.map((s) => (
          <div key={s.key} className="space-y-2 border-b border-slate-800/80 pb-5 last:border-none last:pb-0 text-xs">
            <label className="block font-bold text-slate-200 uppercase tracking-wider font-mono">
              {s.key}
            </label>
            <div className="flex items-center gap-3">
              <input
                type="text"
                value={s.value}
                onChange={(e) => {
                  const val = e.target.value;
                  setSettings(settings.map((item) => (item.key === s.key ? { ...item, value: val } : item)));
                }}
                className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-4 py-2.5 text-slate-100 font-medium focus:outline-none focus:border-amber-500"
              />
              <button
                onClick={() => handleUpdateSetting(s.key, s.value)}
                disabled={savingKey === s.key}
                className="bg-amber-500 hover:bg-amber-600 text-slate-950 font-bold px-4 py-2.5 rounded-xl transition flex items-center gap-1.5 shadow-lg shadow-amber-500/20 disabled:opacity-50"
              >
                <Save size={16} />
                <span>{savingKey === s.key ? 'جارٍ الحفظ...' : 'حفظ'}</span>
              </button>
            </div>
            <span className="text-[10px] text-slate-500 block">
              آخر تعديل: {new Date(s.updated_at).toLocaleString('ar-IQ')}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};
