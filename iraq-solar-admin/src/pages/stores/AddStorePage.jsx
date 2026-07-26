import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Store, User, Mail, Phone, Lock, MapPin, Save, X, Building2 } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { createStore, getUserById, updateUser } from '../../api/adminApi';

const GOVERNORATES = [
  'بغداد', 'البصرة', 'نينوى', 'أربيل', 'النجف', 'كربلاء', 
  'كركوك', 'الأنبار', 'ديالى', 'صلاح الدين', 'بابل', 
  'واسط', 'ميسان', 'الديوانية', 'ذي قار', 'المثنى', 
  'السليمانية', 'دهوك', 'حلبجة'
];

const AddStorePage = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = !!id;

  const [isLoading, setIsLoading] = useState(false);
  const [isFetching, setIsFetching] = useState(isEditMode);
  
  const [formData, setFormData] = useState({
    storeName: '',
    ownerName: '',
    email: '',
    phone: '',
    password: '',
    governorate: '',
    city: ''
  });

  useEffect(() => {
    if (isEditMode) {
      const fetchStore = async () => {
        try {
          const response = await getUserById(id);
          const userData = response?.data?.data?.user || response?.data?.data || response?.data;
          
          if (userData) {
            // Split full_name into storeName and ownerName if possible, else just use as storeName
            let sName = userData.full_name || '';
            let oName = '';
            if (sName.includes(' - ')) {
              const parts = sName.split(' - ');
              sName = parts[0];
              oName = parts[1];
            }
            
            setFormData({
              storeName: sName,
              ownerName: oName,
              email: userData.email || '',
              phone: userData.phone || '',
              password: '', // Leave empty for edit
              governorate: userData.governorate || '',
              city: userData.city || ''
            });
          }
        } catch (error) {
          console.error('Error fetching store:', error);
          toast.error('حدث خطأ أثناء جلب بيانات المتجر');
          navigate('/stores');
        } finally {
          setIsFetching(false);
        }
      };
      
      fetchStore();
    }
  }, [id, isEditMode, navigate]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      // Validate inputs
      if (!formData.storeName) {
        toast.error('يرجى إدخال اسم المتجر');
        setIsLoading(false);
        return;
      }
      
      if (!formData.phone) {
        toast.error('يرجى إدخال رقم الهاتف');
        setIsLoading(false);
        return;
      }
      
      if (!isEditMode && !formData.password) {
        toast.error('يرجى إدخال كلمة المرور');
        setIsLoading(false);
        return;
      }

      let fullName = formData.storeName;
      if (formData.ownerName) {
        fullName = `${formData.storeName} - ${formData.ownerName}`;
      }

      const payload = {
        full_name: fullName,
        email: formData.email || '',
        phone: formData.phone,
        role: 'merchant',
        governorate: formData.governorate,
        city: formData.city
      };
      
      // Only include password if provided
      if (formData.password) {
        payload.password = formData.password;
      }

      if (isEditMode) {
        await updateUser(id, payload);
        toast.success('تم تحديث المتجر بنجاح');
      } else {
        await createStore(payload);
        toast.success('تم إضافة المتجر بنجاح');
      }
      
      navigate('/stores');
    } catch (error) {
      console.error('Error saving store:', error);
      toast.error(error.response?.data?.message || 'حدث خطأ أثناء حفظ المتجر');
    } finally {
      setIsLoading(false);
    }
  };

  if (isFetching) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-gold"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6 animate-slide-in">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">
            {isEditMode ? 'تعديل بيانات المتجر' : 'إضافة متجر جديد'}
          </h1>
          <p className="text-gray-400">
            {isEditMode ? 'قم بتحديث بيانات المتجر الحالي' : 'قم بإدخال بيانات المتجر الجديد ليتم إضافته للنظام'}
          </p>
        </div>
      </div>

      <div className="glass rounded-2xl p-6 md:p-8">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Store Name */}
            <div className="form-group">
              <label className="form-label flex items-center gap-2">
                <Store className="w-4 h-4 text-primary-gold" />
                <span>اسم المتجر *</span>
              </label>
              <input
                type="text"
                name="storeName"
                value={formData.storeName}
                onChange={handleChange}
                className="form-input w-full"
                placeholder="أدخل اسم المتجر"
                required
              />
            </div>

            {/* Owner Name */}
            <div className="form-group">
              <label className="form-label flex items-center gap-2">
                <User className="w-4 h-4 text-primary-gold" />
                <span>اسم المالك</span>
              </label>
              <input
                type="text"
                name="ownerName"
                value={formData.ownerName}
                onChange={handleChange}
                className="form-input w-full"
                placeholder="أدخل اسم المالك (اختياري)"
              />
            </div>

            {/* Phone */}
            <div className="form-group">
              <label className="form-label flex items-center gap-2">
                <Phone className="w-4 h-4 text-primary-gold" />
                <span>رقم الهاتف *</span>
              </label>
              <input
                type="tel"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                className="form-input w-full"
                placeholder="07XX XXX XXXX"
                dir="ltr"
                required
              />
            </div>

            {/* Email */}
            <div className="form-group">
              <label className="form-label flex items-center gap-2">
                <Mail className="w-4 h-4 text-primary-gold" />
                <span>البريد الإلكتروني</span>
              </label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="form-input w-full"
                placeholder="example@domain.com"
                dir="ltr"
              />
            </div>

            {/* Password */}
            <div className="form-group">
              <label className="form-label flex items-center gap-2">
                <Lock className="w-4 h-4 text-primary-gold" />
                <span>كلمة المرور {isEditMode ? '(اتركه فارغاً لعدم التغيير)' : '*'}</span>
              </label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                className="form-input w-full"
                placeholder="أدخل كلمة المرور"
                required={!isEditMode}
              />
            </div>

            {/* Governorate */}
            <div className="form-group">
              <label className="form-label flex items-center gap-2">
                <MapPin className="w-4 h-4 text-primary-gold" />
                <span>المحافظة</span>
              </label>
              <select
                name="governorate"
                value={formData.governorate}
                onChange={handleChange}
                className="form-select w-full"
              >
                <option value="">اختر المحافظة</option>
                {GOVERNORATES.map(gov => (
                  <option key={gov} value={gov}>{gov}</option>
                ))}
              </select>
            </div>

            {/* City */}
            <div className="form-group md:col-span-2">
              <label className="form-label flex items-center gap-2">
                <Building2 className="w-4 h-4 text-primary-gold" />
                <span>المدينة / المنطقة</span>
              </label>
              <input
                type="text"
                name="city"
                value={formData.city}
                onChange={handleChange}
                className="form-input w-full"
                placeholder="أدخل المدينة أو المنطقة"
              />
            </div>
          </div>

          <div className="flex items-center justify-end gap-4 pt-6 border-t border-white/10">
            <button
              type="button"
              onClick={() => navigate('/stores')}
              className="btn btn-outline flex items-center gap-2"
              disabled={isLoading}
            >
              <X className="w-5 h-5" />
              <span>إلغاء</span>
            </button>
            <button
              type="submit"
              className="btn btn-primary flex items-center gap-2"
              disabled={isLoading}
            >
              {isLoading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <Save className="w-5 h-5" />
              )}
              <span>{isEditMode ? 'حفظ التعديلات' : 'إضافة المتجر'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default AddStorePage;
