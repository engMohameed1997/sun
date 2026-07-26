import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowRight, Save, Image as ImageIcon } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { createBanner, updateBanner, uploadImage, getBanners } from '../../api/adminApi';
import ImageUploader from '../../components/shared/ImageUploader';

const BannerFormPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const isEditMode = !!id;

  const [isLoading, setIsLoading] = useState(isEditMode);
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const [formData, setFormData] = useState({
    title: '',
    subtitle: '',
    link_url: '',
    display_order: 0,
    is_active: true
  });
  
  const [imageFile, setImageFile] = useState(null);
  const [currentImageUrl, setCurrentImageUrl] = useState(null);

  useEffect(() => {
    const fetchBannerData = async () => {
      if (!isEditMode) return;
      
      try {
        const response = await getBanners();
        const data = response.data?.data || response.data || [];
        const banner = data.find(b => String(b.id) === String(id));
        
        if (banner) {
          setFormData({
            title: banner.title || '',
            subtitle: banner.subtitle || '',
            link_url: banner.link_url || '',
            display_order: banner.display_order || 0,
            is_active: banner.is_active ?? true
          });
          setCurrentImageUrl(banner.image_url);
        } else {
          toast.error('لم يتم العثور على اللافتة');
          navigate('/banners');
        }
      } catch (error) {
        console.error('Error fetching banner:', error);
        toast.error('حدث خطأ أثناء جلب بيانات اللافتة');
      } finally {
        setIsLoading(false);
      }
    };

    fetchBannerData();
  }, [id, isEditMode, navigate]);

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : (type === 'number' ? Number(value) : value)
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    
    try {
      let finalImageUrl = currentImageUrl;
      
      if (imageFile) {
        // Mock upload or real upload depending on API
        const uploadRes = await uploadImage(imageFile);
        finalImageUrl = uploadRes.data?.url || uploadRes.data?.data?.url;
        if (!finalImageUrl) {
           throw new Error('Failed to upload image');
        }
      }

      if (!finalImageUrl && !isEditMode) {
        toast.error('يرجى اختيار صورة للافتة');
        setIsSubmitting(false);
        return;
      }

      const payload = {
        ...formData,
        image_url: finalImageUrl
      };

      if (isEditMode) {
        await updateBanner(id, payload);
        toast.success('تم تحديث اللافتة بنجاح');
      } else {
        await createBanner(payload);
        toast.success('تم إضافة اللافتة بنجاح');
      }
      
      navigate('/banners');
    } catch (error) {
      console.error('Error saving banner:', error);
      toast.error('حدث خطأ أثناء حفظ اللافتة');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex justify-center py-12">
        <div className="w-8 h-8 border-4 border-primary-gold border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-slide-in max-w-4xl mx-auto">
      <div className="flex items-center gap-4">
        <button 
          onClick={() => navigate('/banners')}
          className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-white transition-colors"
        >
          <ArrowRight size={20} />
        </button>
        <div>
          <h1 className="text-2xl font-bold text-white mb-1">
            {isEditMode ? 'تعديل لافتة إعلانية' : 'إضافة لافتة جديدة'}
          </h1>
          <p className="text-white/60">
            {isEditMode ? 'تعديل بيانات اللافتة الإعلانية' : 'أدخل بيانات اللافتة الإعلانية الجديدة'}
          </p>
        </div>
      </div>

      <div className="glass rounded-xl p-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="space-y-6">
              <div className="form-group">
                <label className="form-label">العنوان الرئيسي <span className="text-red-500">*</span></label>
                <input 
                  type="text" 
                  name="title"
                  value={formData.title} 
                  onChange={handleChange}
                  className="form-input" 
                  required 
                  placeholder="مثال: خصومات كبرى على الألواح"
                />
              </div>
              
              <div className="form-group">
                <label className="form-label">العنوان الفرعي</label>
                <input 
                  type="text" 
                  name="subtitle"
                  value={formData.subtitle} 
                  onChange={handleChange}
                  className="form-input" 
                  placeholder="وصف قصير للإعلان"
                />
              </div>

              <div className="form-group">
                <label className="form-label">رابط التوجيه (اختياري)</label>
                <input 
                  type="url" 
                  name="link_url"
                  value={formData.link_url} 
                  onChange={handleChange}
                  className="form-input text-left" 
                  dir="ltr"
                  placeholder="https://..."
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="form-group">
                  <label className="form-label">ترتيب العرض</label>
                  <input 
                    type="number" 
                    name="display_order"
                    value={formData.display_order} 
                    onChange={handleChange}
                    className="form-input"
                    min="0"
                  />
                  <p className="text-xs text-white/40 mt-1">الرقم الأقل يظهر أولاً</p>
                </div>
              </div>

              <div className="form-group pt-2">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input 
                    type="checkbox" 
                    name="is_active"
                    checked={formData.is_active} 
                    onChange={handleChange}
                    className="w-5 h-5 rounded border-white/20 bg-dark-navy text-primary-gold focus:ring-primary-gold" 
                  />
                  <div>
                    <span className="block text-white">حالة اللافتة نشطة</span>
                    <span className="block text-xs text-white/50">سيتم عرضها في الصفحة الرئيسية إذا كانت نشطة</span>
                  </div>
                </label>
              </div>
            </div>

            <div className="space-y-4">
              <label className="form-label block">صورة اللافتة <span className="text-red-500">*</span></label>
              
              {currentImageUrl && !imageFile && (
                <div className="relative rounded-xl overflow-hidden mb-4 border border-white/10 group">
                  <img src={currentImageUrl} alt="Current banner" className="w-full h-auto object-cover" />
                  <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                    <p className="text-white font-medium">الصورة الحالية</p>
                  </div>
                </div>
              )}
              
              <ImageUploader 
                value={imageFile} 
                onChange={setImageFile} 
                label={currentImageUrl ? "تغيير الصورة" : "رفع صورة"}
              />
              <p className="text-xs text-white/50">
                يفضل استخدام صور أفقية بدقة عالية (مثال: 1920x800 بكسل)
              </p>
            </div>
          </div>

          <div className="pt-6 border-t border-white/10 flex justify-end gap-3">
            <button 
              type="button" 
              onClick={() => navigate('/banners')}
              className="btn bg-white/5 text-white hover:bg-white/10"
              disabled={isSubmitting}
            >
              إلغاء
            </button>
            <button 
              type="submit" 
              className="btn btn-primary flex items-center gap-2"
              disabled={isSubmitting}
            >
              <Save size={18} />
              <span>{isSubmitting ? 'جاري الحفظ...' : 'حفظ اللافتة'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default BannerFormPage;
