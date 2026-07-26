import React, { useState, useEffect } from 'react';
import { Save, RefreshCw, Settings } from 'lucide-react';
import toast from 'react-hot-toast';
import { getSettings, updateSettings } from '../api/adminApi';

const SettingsPage = () => {
  const [loading, setLoading] = useState(false);
  const [isFetching, setIsFetching] = useState(true);
  const [settings, setSettings] = useState({
    exchange_rate: '1500',
    tax_percentage: '0',
    min_order_amount: '50000',
    maintenance_mode: 'false'
  });

  const fetchSettings = async () => {
    setIsFetching(true);
    try {
      const res = await getSettings();
      const data = res.data?.data || res.data || {};
      
      // Settings come as key-value pairs or as an object
      if (Array.isArray(data)) {
        const settingsMap = {};
        data.forEach(item => {
          settingsMap[item.key] = item.value;
        });
        setSettings(prev => ({ ...prev, ...settingsMap }));
      } else if (typeof data === 'object') {
        setSettings(prev => ({ ...prev, ...data }));
      }
    } catch (error) {
      console.error('Error fetching settings:', error);
      // Keep defaults
    } finally {
      setIsFetching(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleSave = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      // Send each setting as a key-value update
      const promises = Object.entries(settings).map(([key, value]) =>
        updateSettings({ key, value: String(value) })
      );
      await Promise.allSettled(promises);
      toast.success('تم حفظ الإعدادات بنجاح');
    } catch (error) {
      console.error('Error saving settings:', error);
      toast.error('فشل في حفظ الإعدادات');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (key, value) => {
    setSettings(prev => ({ ...prev, [key]: value }));
  };

  if (isFetching) {
    return (
      <div className="max-w-4xl mx-auto animate-slide-in">
        <h2 className="text-2xl font-bold text-dark-navy mb-6">إعدادات النظام</h2>
        <div className="glass p-8 rounded-xl space-y-6">
          {[1, 2, 3, 4].map(i => (
            <div key={i} className="h-16 bg-gray-100 rounded-lg animate-pulse" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto animate-slide-in">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-2">
          <Settings className="text-primary-gold" size={28} />
          <h2 className="text-2xl font-bold text-dark-navy">إعدادات النظام</h2>
        </div>
        <button onClick={fetchSettings} className="btn btn-outline text-sm">
          <RefreshCw size={16} /> تحديث
        </button>
      </div>

      <form onSubmit={handleSave} className="glass p-8 rounded-xl space-y-6">
        
        <h3 className="font-bold text-lg border-b pb-2 mb-4">الإعدادات المالية</h3>
        <div className="grid grid-cols-2 gap-6">
          <div className="form-group mb-0">
            <label className="form-label">سعر صرف الدولار (IQD)</label>
            <input 
              type="number" 
              value={settings.exchange_rate} 
              onChange={e => handleChange('exchange_rate', e.target.value)}
              className="form-input" 
              required 
              dir="ltr" 
            />
            <p className="text-xs text-gray-400 mt-1">سعر الدولار الواحد بالدينار العراقي</p>
          </div>
          <div className="form-group mb-0">
            <label className="form-label">نسبة الضريبة (%)</label>
            <input 
              type="number" 
              value={settings.tax_percentage}
              onChange={e => handleChange('tax_percentage', e.target.value)}
              className="form-input" 
              required 
              dir="ltr"
              min="0"
              max="100"
              step="0.1"
            />
          </div>
          <div className="form-group mb-0">
            <label className="form-label">الحد الأدنى للطلب (IQD)</label>
            <input 
              type="number" 
              value={settings.min_order_amount}
              onChange={e => handleChange('min_order_amount', e.target.value)}
              className="form-input" 
              required 
              dir="ltr" 
            />
          </div>
        </div>

        <h3 className="font-bold text-lg border-b pb-2 mb-4 mt-8">إعدادات النظام العامة</h3>
        <div className="form-group mb-0">
          <label className="form-label flex items-center gap-2 cursor-pointer">
            <input 
              type="checkbox" 
              checked={settings.maintenance_mode === 'true'}
              onChange={e => handleChange('maintenance_mode', e.target.checked ? 'true' : 'false')}
              className="w-5 h-5 text-primary-gold rounded focus:ring-primary-gold" 
            />
            تفعيل وضع الصيانة (إيقاف التطبيق للعملاء)
          </label>
          <p className="text-sm text-gray-500 mt-1 mr-7">عند التفعيل، ستظهر رسالة الصيانة لجميع المستخدمين عدا الإدارة.</p>
        </div>

        <div className="flex justify-end pt-6 border-t border-gray-100">
          <button type="submit" disabled={loading} className="btn btn-primary">
            <Save size={20} /> {loading ? 'جاري الحفظ...' : 'حفظ الإعدادات'}
          </button>
        </div>
      </form>
    </div>
  );
};
export default SettingsPage;
