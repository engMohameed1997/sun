import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import toast from 'react-hot-toast';
import { Save, X, AlertCircle } from 'lucide-react';
import { createUser, updateUser, getUserById, getGovernorates } from '../../api/adminApi';

const AddUserPage = () => {
  const { id } = useParams();
  const isEditMode = !!id;
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isLoading, setIsLoading] = useState(isEditMode);
  const [governoratesList, setGovernoratesList] = useState([]);
  
  const [formData, setFormData] = useState({
    full_name: '',
    email: '',
    phone: '',
    password: '',
    role: 'engineer',
    governorate: '',
    city: ''
  });

  useEffect(() => {
    const fetchGovs = async () => {
      try {
        const res = await getGovernorates();
        if (res.data && res.data.data) {
          setGovernoratesList(res.data.data);
        }
      } catch (err) {
        console.error('فشل في جلب المحافظات:', err);
      }
    };
    fetchGovs();
  }, []);

  useEffect(() => {
    const fetchUser = async () => {
      if (!isEditMode) return;
      
      try {
        const res = await getUserById(id);
        const user = res.data?.data || res.data;
        if (user) {
          setFormData({
            full_name: user.full_name || user.name || '',
            email: user.email || '',
            phone: user.phone || '',
            password: '', // Leave empty in edit mode unless they want to change it
            role: user.role || 'engineer',
            governorate: user.governorate || '',
            city: user.city || ''
          });
        }
      } catch (err) {
        toast.error('فشل في جلب بيانات المستخدم');
        navigate('/users');
      } finally {
        setIsLoading(false);
      }
    };

    fetchUser();
  }, [id, isEditMode, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (formData.role === 'admin' && !formData.email.trim()) {
      toast.error('لا يمكن إضافة حساب مدير نظام (Admin) بدون بريد إلكتروني، يُرجى إدخال البريد الإلكتروني');
      return;
    }

    setIsSubmitting(true);
    try {
      const payload = {
        full_name: formData.full_name.trim(),
        email: formData.email.trim(),
        phone: formData.phone.trim(),
        role: formData.role,
        governorate: formData.governorate,
        city: formData.city.trim()
      };

      if (!isEditMode) {
        payload.password = formData.password;
        await createUser(payload);
        toast.success('تم إضافة المستخدم بنجاح');
      } else {
        if (formData.password) {
          payload.password = formData.password;
        }
        await updateUser(id, payload);
        toast.success('تم تعديل المستخدم بنجاح');
      }
      
      navigate('/users');
    } catch (error) {
      console.error('Error saving user:', error);
      if (error.response && error.response.status === 404) {
        toast.error('خطأ 404: المسار غير موجود في الـ Backend');
      } else {
        const errMsg = error.response?.data?.message || (isEditMode ? 'حدث خطأ أثناء تعديل المستخدم' : 'حدث خطأ أثناء إضافة المستخدم');
        toast.error(errMsg);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const isAdminRole = formData.role === 'admin';

  if (isLoading) {
    return <div className="p-8 text-center">جاري تحميل البيانات...</div>;
  }

  return (
    <div className="max-w-3xl mx-auto animate-slide-in">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-2xl font-bold text-dark-navy">
            {isEditMode ? 'تعديل المستخدم' : 'إضافة مستخدم جديد'}
          </h2>
          <p className="text-sm text-gray-500 mt-1">
            {isEditMode ? 'قم بتعديل بيانات المستخدم أدناه' : 'قم بملء البيانات المطلوبة لإنشاء حساب جديد في النظام'}
          </p>
        </div>
      </div>

      <div className="glass p-8 rounded-xl">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="form-group mb-0">
              <label className="form-label">
                الاسم الكامل <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                className="form-input"
                required
                value={formData.full_name}
                onChange={e => setFormData({ ...formData, full_name: e.target.value })}
                placeholder="أدخل الاسم الكامل"
                autoComplete="name"
              />
            </div>

            <div className="form-group mb-0">
              <label className="form-label flex items-center justify-between">
                <span>
                  البريد الإلكتروني {isAdminRole ? <span className="text-red-500">*</span> : <span className="text-gray-400 font-normal text-xs">(اختياري)</span>}
                </span>
                {isAdminRole && (
                  <span className="text-xs text-amber-600 font-medium">مطلوب لمدير النظام</span>
                )}
              </label>
              <input
                type="email"
                className={`form-input ${isAdminRole && !formData.email ? 'border-amber-400 focus:border-amber-500' : ''}`}
                required={isAdminRole}
                value={formData.email}
                onChange={e => setFormData({ ...formData, email: e.target.value })}
                placeholder={isAdminRole ? 'admin@example.com (مطلوب)' : 'user@example.com'}
                autoComplete="email"
              />
            </div>

            <div className="form-group mb-0">
              <label className="form-label">
                رقم الهاتف <span className="text-red-500">*</span>
              </label>
              <input
                type="tel"
                className="form-input"
                required
                value={formData.phone}
                onChange={e => setFormData({ ...formData, phone: e.target.value })}
                dir="ltr"
                placeholder="07XX XXX XXXX"
                autoComplete="tel"
              />
            </div>

            <div className="form-group mb-0">
              <label className="form-label flex items-center justify-between">
                <span>كلمة المرور {!isEditMode && <span className="text-red-500">*</span>}</span>
                {isEditMode && <span className="text-gray-400 font-normal text-xs">(اتركه فارغاً لعدم التغيير)</span>}
              </label>
              <input
                type="password"
                className="form-input"
                required={!isEditMode}
                minLength={6}
                value={formData.password}
                onChange={e => setFormData({ ...formData, password: e.target.value })}
                placeholder="6 أحرف على الأقل"
                autoComplete="new-password"
              />
            </div>

            <div className="form-group mb-0">
              <label className="form-label">
                الدور / الصلاحية <span className="text-red-500">*</span>
              </label>
              <select
                className="form-select"
                required
                value={formData.role}
                onChange={e => setFormData({ ...formData, role: e.target.value })}
              >
                <option value="engineer">مهندس</option>
                <option value="installer">فني تركيب</option>
                <option value="merchant">متجر</option>
                <option value="customer">عميل</option>
                <option value="admin">مدير نظام (Admin)</option>
              </select>
            </div>

            <div className="form-group mb-0">
              <label className="form-label">المحافظة</label>
              <select
                className="form-select"
                value={formData.governorate}
                onChange={e => setFormData({ ...formData, governorate: e.target.value })}
              >
                <option value="">اختر المحافظة...</option>
                {governoratesList.length > 0 ? (
                  governoratesList.map((g) => (
                    <option key={g.id} value={g.name_ar}>
                      {g.name_ar}
                    </option>
                  ))
                ) : (
                  <>
                    <option value="بغداد">بغداد</option>
                    <option value="البصرة">البصرة</option>
                    <option value="أربيل">أربيل</option>
                    <option value="النجف">النجف</option>
                    <option value="كربلاء">كربلاء</option>
                  </>
                )}
              </select>
            </div>
            
            <div className="form-group mb-0">
              <label className="form-label">المدينة</label>
              <input
                type="text"
                className="form-input"
                value={formData.city}
                onChange={e => setFormData({ ...formData, city: e.target.value })}
                placeholder="اسم المدينة أو المنطقة"
              />
            </div>
          </div>

          {isAdminRole && (
            <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-2 text-amber-800 text-sm">
              <AlertCircle size={18} className="mt-0.5 shrink-0 text-amber-600" />
              <span>
                <strong>ملاحظة أمان:</strong> صلاحية مدير النظام (Admin) تمكّن من الوصول لجميع إعدادات اللوحة. يُشترط وجود بريد إلكتروني موثق لإنشاء حساب مدير نظام.
              </span>
            </div>
          )}

          <div className="flex justify-end gap-4 pt-6 border-t border-gray-100">
            <button
              type="button"
              onClick={() => navigate('/users')}
              className="btn btn-outline"
            >
              <X size={20} /> إلغاء
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="btn btn-primary"
            >
              <Save size={20} /> {isSubmitting ? 'جاري الحفظ...' : (isEditMode ? 'حفظ التعديلات' : 'حفظ المستخدم')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddUserPage;
