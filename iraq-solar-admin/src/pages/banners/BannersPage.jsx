import React, { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, Image as ImageIcon } from 'lucide-react';
import { Link } from 'react-router-dom';
import { toast } from 'react-hot-toast';
import { getBanners, deleteBanner } from '../../api/adminApi';
import { getPlaceholderImage } from '../../utils/formatters';
import ConfirmDialog from '../../components/shared/ConfirmDialog';
import StatusBadge from '../../components/shared/StatusBadge';

const BannersPage = () => {
  const [banners, setBanners] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [deleteDialog, setDeleteDialog] = useState({ isOpen: false, id: null });

  const fetchBanners = async () => {
    setIsLoading(true);
    try {
      const response = await getBanners();
      const data = response.data?.data || response.data || [];
      // Sort by display order
      setBanners(Array.isArray(data) ? data.sort((a, b) => a.display_order - b.display_order) : []);
    } catch (error) {
      console.error('Error fetching banners:', error);
      toast.error('حدث خطأ أثناء جلب اللافتات الإعلانية');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  const handleDeleteClick = (id) => {
    setDeleteDialog({ isOpen: true, id });
  };

  const confirmDelete = async () => {
    try {
      await deleteBanner(deleteDialog.id);
      toast.success('تم حذف اللافتة بنجاح');
      fetchBanners();
    } catch (error) {
      console.error('Error deleting banner:', error);
      toast.error('حدث خطأ أثناء حذف اللافتة');
    } finally {
      setDeleteDialog({ isOpen: false, id: null });
    }
  };

  const handleImageError = (e) => {
    e.target.src = getPlaceholderImage();
  };

  return (
    <div className="space-y-6 animate-slide-in">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">اللافتات الإعلانية (Banners)</h1>
          <p className="text-white/60">إدارة لافتات الصفحة الرئيسية</p>
        </div>
        
        <Link to="/banners/new" className="btn btn-primary flex items-center gap-2">
          <Plus size={20} />
          <span>إضافة لافتة جديدة</span>
        </Link>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <div className="w-8 h-8 border-4 border-primary-gold border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : banners.length === 0 ? (
        <div className="glass flex flex-col items-center justify-center p-12 rounded-xl text-center">
          <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center text-white/40 mb-4">
            <ImageIcon size={32} />
          </div>
          <h3 className="text-xl font-semibold text-white mb-2">لا توجد لافتات إعلانية</h3>
          <p className="text-white/60 max-w-md">
            قم بإضافة لافتات إعلانية لعرضها في الصفحة الرئيسية للمتجر لجذب انتباه العملاء.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {banners.map((banner) => (
            <div key={banner.id} className="glass rounded-xl overflow-hidden flex flex-col group">
              <div className="relative h-48 w-full bg-dark-navy overflow-hidden">
                <img 
                  src={banner.image_url || getPlaceholderImage()} 
                  alt={banner.title} 
                  onError={handleImageError}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                <div className="absolute top-3 right-3 flex gap-2">
                  <StatusBadge 
                    status={banner.is_active ? 'active' : 'inactive'} 
                    text={banner.is_active ? 'نشط' : 'غير نشط'} 
                  />
                  <span className="px-2 py-1 rounded-full text-xs font-medium bg-black/60 text-white backdrop-blur-md">
                    ترتيب: {banner.display_order || 0}
                  </span>
                </div>
              </div>
              
              <div className="p-5 flex-1 flex flex-col">
                <h3 className="text-lg font-bold text-white mb-1 truncate">{banner.title}</h3>
                {banner.subtitle && <p className="text-sm text-white/60 mb-4 line-clamp-2">{banner.subtitle}</p>}
                
                <div className="mt-auto pt-4 border-t border-white/10 flex items-center justify-between">
                  <Link 
                    to={`/banners/${banner.id}/edit`}
                    className="flex-1 text-center py-2 bg-white/5 hover:bg-white/10 text-white rounded-lg ml-2 transition-colors flex items-center justify-center gap-2"
                  >
                    <Edit size={16} />
                    <span>تعديل</span>
                  </Link>
                  <button 
                    onClick={() => handleDeleteClick(banner.id)}
                    className="p-2 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-500 transition-colors"
                    title="حذف"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <ConfirmDialog 
        isOpen={deleteDialog.isOpen}
        title="تأكيد الحذف"
        message="هل أنت متأكد من رغبتك في حذف هذه اللافتة الإعلانية؟ لا يمكن التراجع عن هذا الإجراء."
        onConfirm={confirmDelete}
        onCancel={() => setDeleteDialog({ isOpen: false, id: null })}
      />
    </div>
  );
};

export default BannersPage;
