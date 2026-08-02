import React, { useState, useEffect } from 'react';
import { Package, Plus, Search, Edit2, Trash2, AlertTriangle, Image as ImageIcon } from 'lucide-react';
import { api } from '../services/api';
import type { Product, ProductType } from '../types';
import { useAuth } from '../context/AuthContext';

export const ProductsPage: React.FC = () => {
  const { user } = useAuth();
  const [products, setProducts] = useState<Product[]>([]);
  const [search, setSearch] = useState('');
  const [typeFilter] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  // Form State
  const [sku, setSku] = useState('');
  const [name, setName] = useState('');
  const [brand, setBrand] = useState('');
  const [model, setModel] = useState('');
  const [type, setType] = useState<ProductType>('panel');
  const [priceUSD, setPriceUSD] = useState(0);
  const [stockQuantity, setStockQuantity] = useState(10);
  const [lowStockThreshold, setLowStockThreshold] = useState(5);
  const [imageUrl, setImageUrl] = useState('');
  const [uploadingImage, setUploadingImage] = useState(false);

  const fetchProducts = async () => {
    try {
      const endpoint = user?.role === 'merchant' ? '/merchant/products' : '/admin/products';
      const res = await api.get(`${endpoint}?type=${typeFilter}&search=${search}`);
      if (res.data?.data?.products) {
        setProducts(res.data.data.products);
      } else {
        setProducts([]);
      }
    } catch (err) {
      console.error('Failed to fetch products', err);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, [typeFilter]);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('image', file);
    setUploadingImage(true);

    try {
      const res = await api.post('/upload/image', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      if (res.data?.data?.url) {
        setImageUrl(res.data.data.url);
      }
    } catch (err) {
      alert('فشل رفع الصورة');
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSaveProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const payload = {
        sku,
        name,
        brand,
        model,
        type,
        price_usd: Number(priceUSD),
        stock_quantity: Number(stockQuantity),
        low_stock_threshold: Number(lowStockThreshold),
        images: imageUrl ? [imageUrl] : [],
      };

      if (editingProduct) {
        await api.put(`/admin/products/${editingProduct.id}`, payload);
      } else {
        await api.post('/admin/products', payload);
      }

      setIsModalOpen(false);
      fetchProducts();
    } catch (err) {
      alert('حدث خطأ أثناء حفظ المنتج');
    }
  };

  const handleSoftDelete = async (id: string) => {
    if (!confirm('هل أنت تأكد من إخفاء/حذف هذا المنتج كـ Soft Delete؟')) return;
    try {
      await api.delete(`/admin/products/${id}`);
      fetchProducts();
    } catch (err) {
      alert('فشل إخفاء المنتج');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Package className="text-amber-400" size={22} />
            إدارة المنتجات وحجز المخزون
          </h1>
          <p className="text-slate-400 text-xs mt-1">التحكم بالمنتجات، تفاصيل المخزون المحجوز والمتاح، والتنبيهات الحادة</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <input
              type="text"
              placeholder="بحث بالاسم أو الـ SKU..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchProducts()}
              className="bg-slate-950/80 border border-slate-800 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
            />
            <Search size={15} className="absolute left-3 top-2.5 text-slate-500" />
          </div>

          <button
            onClick={() => {
              setEditingProduct(null);
              setSku(`SOL-${Math.floor(1000 + Math.random() * 9000)}`);
              setName('');
              setBrand('');
              setModel('');
              setPriceUSD(100);
              setStockQuantity(20);
              setImageUrl('');
              setIsModalOpen(true);
            }}
            className="bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 font-bold px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-lg shadow-amber-500/20"
          >
            <Plus size={16} /> إضافة منتج جديد
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {products.map((p) => {
          const availableQty = p.stock_quantity - p.reserved_quantity;
          const isLowStock = availableQty <= p.low_stock_threshold;

          return (
            <div
              key={p.id}
              className={`bg-slate-900 border rounded-2xl p-5 space-y-4 relative overflow-hidden transition hover:border-slate-700 ${
                isLowStock ? 'border-rose-500/40 bg-rose-500/5' : 'border-slate-800'
              }`}
            >
              {isLowStock && (
                <div className="absolute top-3 left-3 bg-rose-500/20 text-rose-300 border border-rose-500/30 text-[10px] font-bold px-2 py-0.5 rounded-full flex items-center gap-1">
                  <AlertTriangle size={12} /> مخزون منخفض
                </div>
              )}

              <div className="flex items-start gap-4">
                <div className="w-16 h-16 rounded-xl bg-slate-950 border border-slate-800 flex items-center justify-center overflow-hidden shrink-0">
                  {p.images && p.images[0] ? (
                    <img src={p.images[0]} alt={p.name} className="w-full h-full object-cover" />
                  ) : (
                    <ImageIcon className="text-slate-600" size={24} />
                  )}
                </div>

                <div className="space-y-1 min-w-0">
                  <span className="text-[10px] font-bold text-amber-400 bg-amber-500/10 border border-amber-500/20 px-2 py-0.5 rounded-md uppercase">
                    {p.type}
                  </span>
                  <h3 className="font-bold text-slate-100 text-sm truncate">{p.name}</h3>
                  <div className="text-xs text-slate-400">{p.brand} - {p.model}</div>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2 bg-slate-950/70 p-3 rounded-xl border border-slate-800/80 text-center text-xs">
                <div>
                  <span className="text-slate-500 block text-[10px]">السعر</span>
                  <span className="font-bold text-emerald-400">${p.price_usd}</span>
                </div>
                <div>
                  <span className="text-slate-500 block text-[10px]">المحجوز</span>
                  <span className="font-bold text-amber-400">{p.reserved_quantity}</span>
                </div>
                <div>
                  <span className="text-slate-500 block text-[10px]">المتاح للبيع</span>
                  <span className={`font-bold ${isLowStock ? 'text-rose-400' : 'text-slate-200'}`}>
                    {availableQty} / {p.stock_quantity}
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-800/60">
                <button
                  onClick={() => {
                    setEditingProduct(p);
                    setSku(p.sku);
                    setName(p.name);
                    setBrand(p.brand);
                    setModel(p.model);
                    setType(p.type);
                    setPriceUSD(p.price_usd);
                    setStockQuantity(p.stock_quantity);
                    setLowStockThreshold(p.low_stock_threshold);
                    setImageUrl(p.images?.[0] || '');
                    setIsModalOpen(true);
                  }}
                  className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-xs flex items-center gap-1 font-medium transition"
                >
                  <Edit2 size={14} /> تعديل
                </button>
                <button
                  onClick={() => handleSoftDelete(p.id)}
                  className="p-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 rounded-lg text-xs flex items-center gap-1 font-medium transition"
                >
                  <Trash2 size={14} /> إخفاء
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-xl w-full p-6 space-y-5">
            <h3 className="text-lg font-bold text-slate-100">
              {editingProduct ? 'تعديل بيانات المنتج' : 'إضافة منتج جديد'}
            </h3>

            <form onSubmit={handleSaveProduct} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">رمز المنتج (SKU)</label>
                  <input
                    type="text"
                    required
                    value={sku}
                    onChange={(e) => setSku(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">نوع المنتج</label>
                  <select
                    value={type}
                    onChange={(e) => setType(e.target.value as ProductType)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  >
                    <option value="panel">لوح طاقة شمسية</option>
                    <option value="inverter">انفيرتر (مُحول)</option>
                    <option value="battery">بطارية</option>
                    <option value="structure">هيكل وتثبيت</option>
                    <option value="cable">كابلات وتوصيلات</option>
                    <option value="accessory">ملحقات أخرى</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-slate-400 mb-1">اسم المنتج الكامل</label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="مثال: لوح طاقة شمسية Longi 550W"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">الماركة (Brand)</label>
                  <input
                    type="text"
                    required
                    value={brand}
                    onChange={(e) => setBrand(e.target.value)}
                    placeholder="Deye / LONGi"
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">الموديل (Model)</label>
                  <input
                    type="text"
                    required
                    value={model}
                    onChange={(e) => setModel(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">السعر ($ USD)</label>
                  <input
                    type="number"
                    required
                    value={priceUSD}
                    onChange={(e) => setPriceUSD(Number(e.target.value))}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">كمية المخزون الكلي</label>
                  <input
                    type="number"
                    required
                    value={stockQuantity}
                    onChange={(e) => setStockQuantity(Number(e.target.value))}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">حد المخزون الحرج</label>
                  <input
                    type="number"
                    required
                    value={lowStockThreshold}
                    onChange={(e) => setLowStockThreshold(Number(e.target.value))}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="block text-slate-400">صورة المنتج</label>
                <input type="file" accept="image/*" onChange={handleImageUpload} className="text-slate-400 text-xs" />
                {uploadingImage && <div className="text-amber-400">جارٍ رفع الصورة...</div>}
                {imageUrl && <img src={imageUrl} alt="معاينة" className="w-20 h-20 object-cover rounded-xl border border-slate-800" />}
              </div>

              <div className="flex justify-end gap-2 pt-4 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl font-bold"
                >
                  إلغاء
                </button>
                <button type="submit" className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold">
                  حفظ المنتج
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
