import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { toast } from 'react-hot-toast';
import { updateProduct } from '../../api/adminApi';
import { PRODUCT_TYPES } from '../../utils/constants';

const EditProductModal = ({ product, isOpen, onClose, onSave }) => {
  const [formData, setFormData] = useState({
    name: '',
    brand: '',
    model: '',
    price_usd: 0,
    stock_quantity: 0,
    type: '',
    is_available: true
  });
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (product) {
      setFormData({
        name: product.name || '',
        brand: product.brand || '',
        model: product.model || '',
        price_usd: product.price_usd || 0,
        stock_quantity: product.stock_quantity || 0,
        type: product.type || '',
        is_available: product.is_available ?? true
      });
    }
  }, [product]);

  if (!isOpen) return null;

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await updateProduct(product.id, formData);
      toast.success('تم تحديث المنتج بنجاح');
      onSave();
    } catch (error) {
      console.error('Error updating product:', error);
      toast.error('حدث خطأ أثناء تحديث المنتج');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
      <div className="glass w-full max-w-2xl rounded-xl overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <h2 className="text-xl font-bold text-white">تعديل المنتج</h2>
          <button 
            onClick={onClose}
            className="text-white/60 hover:text-white transition-colors"
          >
            <X size={24} />
          </button>
        </div>
        
        <div className="p-6 overflow-y-auto flex-1">
          <form id="edit-product-form" onSubmit={handleSubmit} className="space-y-4">
            <div className="form-group">
              <label className="form-label">اسم المنتج</label>
              <input 
                type="text" 
                name="name"
                value={formData.name} 
                onChange={handleChange}
                className="form-input" 
                required 
              />
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="form-group">
                <label className="form-label">العلامة التجارية</label>
                <input 
                  type="text" 
                  name="brand"
                  value={formData.brand} 
                  onChange={handleChange}
                  className="form-input" 
                />
              </div>
              
              <div className="form-group">
                <label className="form-label">الموديل</label>
                <input 
                  type="text" 
                  name="model"
                  value={formData.model} 
                  onChange={handleChange}
                  className="form-input" 
                />
              </div>
              
              <div className="form-group">
                <label className="form-label">السعر (USD)</label>
                <input 
                  type="number" 
                  step="0.01"
                  name="price_usd"
                  value={formData.price_usd} 
                  onChange={handleChange}
                  className="form-input" 
                  required 
                />
              </div>
              
              <div className="form-group">
                <label className="form-label">المخزون</label>
                <input 
                  type="number" 
                  name="stock_quantity"
                  value={formData.stock_quantity} 
                  onChange={handleChange}
                  className="form-input" 
                  required 
                />
              </div>
              
              <div className="form-group">
                <label className="form-label">النوع</label>
                <select 
                  name="type"
                  value={formData.type} 
                  onChange={handleChange}
                  className="form-select" 
                  required
                >
                  <option value="">اختر النوع</option>
                  {Object.entries(PRODUCT_TYPES).map(([key, label]) => (
                    <option key={key} value={key}>{label}</option>
                  ))}
                </select>
              </div>
            </div>
            
            <div className="form-group pt-2">
              <label className="flex items-center gap-3 cursor-pointer">
                <input 
                  type="checkbox" 
                  name="is_available"
                  checked={formData.is_available} 
                  onChange={handleChange}
                  className="w-5 h-5 rounded border-white/20 bg-dark-navy text-primary-gold focus:ring-primary-gold" 
                />
                <span className="text-white">المنتج متاح للعرض</span>
              </label>
            </div>
          </form>
        </div>
        
        <div className="p-6 border-t border-white/10 bg-white/5 flex justify-end gap-3">
          <button 
            type="button" 
            onClick={onClose}
            className="btn bg-white/10 text-white hover:bg-white/20"
            disabled={isSubmitting}
          >
            إلغاء
          </button>
          <button 
            type="submit" 
            form="edit-product-form"
            className="btn btn-primary"
            disabled={isSubmitting}
          >
            {isSubmitting ? 'جاري الحفظ...' : 'حفظ التغييرات'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default EditProductModal;
