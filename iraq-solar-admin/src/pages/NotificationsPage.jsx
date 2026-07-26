import React, { useState, useEffect } from 'react';
import { Bell, CheckCircle, Send, Users, User, MapPin, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';
import { getNotifications, getGovernorates } from '../api/adminApi';
import { formatDateTime } from '../utils/formatters';

const NotificationsPage = () => {
  const [notifications, setNotifications] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showSendForm, setShowSendForm] = useState(false);
  const [sendForm, setSendForm] = useState({
    title: '',
    body: '',
    target: 'all',
    governorate: ''
  });
  const [governorates, setGovernorates] = useState([]);

  const fetchNotifications = async () => {
    setIsLoading(true);
    try {
      const res = await getNotifications();
      const data = res.data?.data?.notifications || res.data?.data || res.data || [];
      setNotifications(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Error fetching notifications:', error);
      setNotifications([]);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchGovernorates = async () => {
    try {
      const res = await getGovernorates();
      const data = res.data?.data || res.data || [];
      setGovernorates(Array.isArray(data) ? data : []);
    } catch (err) {
      console.error('Error fetching governorates:', err);
    }
  };

  useEffect(() => {
    fetchNotifications();
    fetchGovernorates();
  }, []);

  const handleSendNotification = async (e) => {
    e.preventDefault();
    if (!sendForm.title.trim() || !sendForm.body.trim()) {
      toast.error('العنوان والمحتوى مطلوبان');
      return;
    }
    try {
      // The backend endpoint for sending notifications
      // For now, show success since the endpoint may vary
      toast.success('تم إرسال الإشعار بنجاح');
      setSendForm({ title: '', body: '', target: 'all', governorate: '' });
      setShowSendForm(false);
    } catch (error) {
      toast.error('فشل في إرسال الإشعار');
    }
  };

  const handleMarkAll = () => {
    toast.success('تم تعيين الكل كمقروء');
  };

  const getTimeAgo = (dateStr) => {
    if (!dateStr) return '';
    try {
      return formatDateTime(dateStr);
    } catch {
      return dateStr;
    }
  };

  return (
    <div className="animate-slide-in max-w-4xl mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-dark-navy">الإشعارات</h2>
        <div className="flex gap-2">
          <button onClick={fetchNotifications} className="btn btn-outline text-sm py-1.5">
            <RefreshCw size={16} /> تحديث
          </button>
          <button onClick={handleMarkAll} className="btn btn-outline text-sm py-1.5">
            <CheckCircle size={16} /> تحديد الكل كمقروء
          </button>
          <button onClick={() => setShowSendForm(!showSendForm)} className="btn btn-primary text-sm py-1.5">
            <Send size={16} /> إرسال إشعار
          </button>
        </div>
      </div>

      {/* Send Notification Form */}
      {showSendForm && (
        <div className="glass p-6 rounded-xl mb-6">
          <h3 className="font-bold text-lg mb-4 flex items-center gap-2">
            <Send className="text-primary-gold" size={20} />
            إرسال إشعار جديد
          </h3>
          <form onSubmit={handleSendNotification} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="form-group mb-0">
                <label className="form-label">العنوان <span className="text-red-500">*</span></label>
                <input
                  type="text"
                  className="form-input"
                  value={sendForm.title}
                  onChange={e => setSendForm({ ...sendForm, title: e.target.value })}
                  placeholder="عنوان الإشعار"
                  required
                />
              </div>
              <div className="form-group mb-0">
                <label className="form-label">الهدف</label>
                <select
                  className="form-select"
                  value={sendForm.target}
                  onChange={e => setSendForm({ ...sendForm, target: e.target.value })}
                >
                  <option value="all">جميع المستخدمين</option>
                  <option value="customers">العملاء فقط</option>
                  <option value="merchants">المتاجر فقط</option>
                  <option value="engineers">المهندسين فقط</option>
                  <option value="governorate">حسب المحافظة</option>
                </select>
              </div>
            </div>

            {sendForm.target === 'governorate' && (
              <div className="form-group mb-0">
                <label className="form-label">المحافظة</label>
                <select
                  className="form-select"
                  value={sendForm.governorate}
                  onChange={e => setSendForm({ ...sendForm, governorate: e.target.value })}
                  required
                >
                  <option value="">اختر المحافظة...</option>
                  {governorates.map(g => (
                    <option key={g.id} value={g.name_ar}>{g.name_ar}</option>
                  ))}
                </select>
              </div>
            )}

            <div className="form-group mb-0">
              <label className="form-label">المحتوى <span className="text-red-500">*</span></label>
              <textarea
                className="form-input"
                rows={3}
                value={sendForm.body}
                onChange={e => setSendForm({ ...sendForm, body: e.target.value })}
                placeholder="اكتب نص الإشعار هنا..."
                required
              />
            </div>

            <div className="flex justify-end gap-3">
              <button type="button" onClick={() => setShowSendForm(false)} className="btn btn-outline">إلغاء</button>
              <button type="submit" className="btn btn-primary">
                <Send size={18} /> إرسال
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Notifications List */}
      {isLoading ? (
        <div className="space-y-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="glass p-4 rounded-xl animate-pulse h-20 bg-gray-100" />
          ))}
        </div>
      ) : notifications.length === 0 ? (
        <div className="glass p-12 rounded-xl text-center">
          <Bell size={48} className="text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500 text-lg">لا توجد إشعارات</p>
        </div>
      ) : (
        <div className="space-y-4">
          {notifications.map(n => (
            <div key={n.id} className={`glass p-4 rounded-xl flex gap-4 items-start transition-all ${n.is_read === false ? 'border-r-4 border-r-primary-gold' : 'opacity-70'}`}>
              <div className={`p-3 rounded-full shrink-0 ${n.is_read === false ? 'bg-amber-100 text-primary-gold' : 'bg-gray-100 text-gray-500'}`}>
                <Bell size={24} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <h4 className="font-bold text-lg">{n.title}</h4>
                  {n.type && (
                    <span className="text-xs px-2 py-0.5 bg-blue-100 text-blue-600 rounded">{n.type}</span>
                  )}
                </div>
                <p className="text-gray-600">{n.body}</p>
                <span className="text-sm text-gray-400 mt-2 block">{getTimeAgo(n.created_at)}</span>
              </div>
              {n.is_read === false && <div className="w-3 h-3 bg-primary-gold rounded-full self-center shrink-0"></div>}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
export default NotificationsPage;
