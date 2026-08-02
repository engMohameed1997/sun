import React, { useState, useEffect } from 'react';
import { Package, Search, Plus, Edit2, Trash2, AlertTriangle, Image as ImageIcon } from 'lucide-react';
import { api } from '../services/api';
import type { Product, ProductType, Category, Store } from '../types';
import { useAuth } from '../context/AuthContext';

export const ProductsPage: React.FC = () => {
  const { user } = useAuth();
  const isAdmin = user?.role === 'admin';
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedType, setSelectedType] = useState<ProductType | ''>('');
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  // Form states
  const [sku, setSku] = useState('');
  const [name, setName] = useState('');
  const [brand, setBrand] = useState('');
  const [model, setModel] = useState('');
  const [type, setType] = useState<ProductType>('panel');
  const [categoryId, setCategoryId] = useState<number | ''>('');
  const [storeId, setStoreId] = useState<string>('');
  const [branchId, setBranchId] = useState<string>('');
  const [priceUSD, setPriceUSD] = useState<number>(0);
  const [stockQuantity, setStockQuantity] = useState<number>(0);
  const [lowStockThreshold, setLowStockThreshold] = useState<number>(5);
  const [imageUrl, setImageUrl] = useState('');
  const [uploadingImage, setUploadingImage] = useState(false);

  const fetchInitialData = async () => {
    try {
      // Fetch Categories
      const catRes = await api.get('/categories');
      if (catRes.data?.data) {
        setCategories(catRes.data.data);
      }

      // Fetch Stores (for Admin, fetch all. For Merchant, fetch own)
      if (isAdmin) {
         const storeRes = await api.get('/admin/stores');
         if (storeRes.data?.data?.stores) setStores(storeRes.data.data.stores);
      } else {
         // Merchant logic: normally backend would return only their stores
         const storeRes = await api.get('/admin/stores'); // Might need a specific endpoint for merchant stores
         if (storeRes.data?.data?.stores) {
            const myStores = storeRes.data.data.stores.filter((s: Store) => s.merchant_id === user?.id);
            setStores(myStores);
            if (myStores.length > 0) setStoreId(myStores[0].id);
         }
      }
    } catch (err) {
      console.error('Failed to load initial data', err);
    }
  };

  const fetchProducts = async () => {
    try {
      const endpoint = isAdmin ? '/admin/products' : '/products/merchant/me';
      const res = await api.get(endpoint, {
        params: { search: searchQuery, type: selectedType }
      });
      if (res.data?.data?.products) {
        setProducts(res.data.data.products);
      } else {
        // Fallback for merchant endpoint if it returns list directly
        setProducts(res.data?.data || []);
      }
    } catch (err) {
      console.error('Failed to fetch products', err);
    }
  };

  useEffect(() => {
    fetchInitialData();
  }, [isAdmin, user?.id]);

  useEffect(() => {
    fetchProducts();
  }, [searchQuery, selectedType]);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files?.[0]) return;
    setUploadingImage(true);
    const formData = new FormData();
    formData.append('file', e.target.files[0]);

    try {
      const res = await api.post('/upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      setImageUrl(res.data?.data?.url || '');
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
        category_id: categoryId ? Number(categoryId) : undefined,
        store_id: storeId || undefined,
        branch_id: branchId || undefined,
        price_usd: priceUSD,
        stock_quantity: stockQuantity,
        low_stock_threshold: lowStockThreshold,
        images: imageUrl ? [imageUrl] : [],
      };

      if (editingProduct) {
        const endpoint = isAdmin ? `/admin/products/${editingProduct.id}` : `/products/merchant/${editingProduct.id}`;
        await api.put(endpoint, payload);
        alert('تم التعديل بنجاح');
      } else {
        // Create endpoint depends on role, or if admin is creating on behalf of someone
        // But for now let's use the merchant endpoint if it's a merchant, admin endpoint otherwise
        const endpoint = isAdmin ? '/admin/products' : '/products/merchant'; 
        // Note: The backend admin handler doesn't have a CreateProduct yet, we might need to use the public one if it accepts merchant_id
        await api.post(endpoint, payload);
        alert('تمت الإضافة بنجاح');
      }

      setIsModalOpen(false);
      fetchProducts();
    } catch (err: any) {
      alert(err.response?.data?.message || 'فشل حفظ المنتج');
    }
  };

  const handleSoftDelete = async (id: string) => {
    if (!window.confirm('هل أنت متأكد من إخفاء هذا المنتج؟')) return;
    try {
      const endpoint = isAdmin ? `/admin/products/${id}` : `/products/merchant/${id}`;
      await api.delete(endpoint);
      alert('تم إخفاء المنتج بنجاح');
      fetchProducts();
    } catch (err) {
      alert('فشل الإخفاء');
    }
  };

  // Find branches for the selected store
  const selectedStore = stores.find(s => s.id === storeId);
  const availableBranches = selectedStore?.branches || [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Package className="text-amber-400" size={22} />
            {isAdmin ? 'إدارة كتالوج المنتجات' : 'إدارة منتجات متجري'}
          </h1>
          <p className="text-slate-400 text-xs mt-1">تتبع المخزون، وتحديث الأسعار والمواصفات للمنظومات الشمسية</p>
        </div>
        <button
          onClick={() => {
            setEditingProduct(null);
            setSku(''); setName(''); setBrand(''); setModel(''); setType('panel'); 
            setPriceUSD(0); setStockQuantity(0); setLowStockThreshold(5); setImageUrl('');
            setCategoryId('');
            setBranchId('');
            setIsModalOpen(true);
          }}
          className="bg-amber-500 hover:bg-amber-600 text-slate-950 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
        >
          <Plus size={18} />
          إضافة منتج جديد
        </button>
      </div>

      <div className="flex flex-col sm:flex-row gap-4 mb-4">
        <div className="relative flex-1">
          <Search className="absolute right-3 top-2.5 text-slate-500" size={18} />
          <input
            type="text"
            placeholder="ابحث برمز SKU، الاسم، أو الماركة..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-slate-900 border border-slate-800 rounded-xl pr-10 pl-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
          />
        </div>
        <select
          value={selectedType}
          onChange={(e) => setSelectedType(e.target.value as ProductType | '')}
          className="bg-slate-900 border border-slate-800 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
        >
          <option value="">جميع الأنواع</option>
          <option value="panel">ألواح شمسية</option>
          <option value="inverter">عواكس (Inverters)</option>
          <option value="battery">بطاريات</option>
          <option value="structure">هياكل تثبيت</option>
          <option value="cable">كابلات</option>
          <option value="accessory">ملحقات</option>
        </select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {products.map((p) => {
          const availableQty = p.stock_quantity - (p.reserved_quantity || 0);
          const isLowStock = availableQty <= p.low_stock_threshold;

          return (
            <div key={p.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-4 flex flex-col gap-4 relative overflow-hidden group">
              {isLowStock && (
                <div className="absolute top-0 right-0 bg-rose-500/90 text-white text-[10px] font-bold px-2 py-1 rounded-bl-lg flex items-center gap-1 z-10">
                  <AlertTriangle size={10} />
                  مخزون منخفض
                </div>
              )}

              <div className="flex gap-3">
                <div className="w-16 h-16 rounded-xl bg-slate-800 border border-slate-700 flex-shrink-0 overflow-hidden flex items-center justify-center text-slate-500">
                  {p.images && p.images[0] ? (
                    <img src={p.images[0]} alt={p.name} className="w-full h-full object-cover" />
                  ) : (
                    <ImageIcon size={24} />
                  )}
                </div>
                <div>
                  <h3 className="font-bold text-slate-200 text-sm line-clamp-2 leading-snug">{p.name}</h3>
                  <div className="text-xs text-slate-400 mt-1">{p.brand} • {p.model}</div>
                  <div className="text-[10px] text-amber-500/80 font-mono mt-1">SKU: {p.sku}</div>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2 bg-slate-950/50 p-2 rounded-xl border border-slate-800/50 text-center">
                <div>
                  <span className="text-slate-500 block text-[10px]">السعر</span>
                  <span className="font-bold text-emerald-400">${p.price_usd}</span>
                </div>
                <div>
                  <span className="text-slate-500 block text-[10px]">المحجوز</span>
                  <span className="font-bold text-amber-400">{p.reserved_quantity || 0}</span>
                </div>
                <div>
                  <span className="text-slate-500 block text-[10px]">المتاح للبيع</span>
                  <span className={`font-bold ${isLowStock ? 'text-rose-400' : 'text-slate-200'}`}>
                    {availableQty} / {p.stock_quantity}
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-800/60 mt-auto">
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
                    setCategoryId(p.category_id || '');
                    setStoreId(p.store_id || '');
                    setBranchId(p.branch_id || '');
                    setIsModalOpen(true);
                  }}
                  className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-xs flex items-center gap-1 font-medium transition cursor-pointer"
                >
                  <Edit2 size={14} /> تعديل
                </button>
                <button
                  onClick={() => handleSoftDelete(p.id)}
                  className="p-2 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 rounded-lg text-xs flex items-center gap-1 font-medium transition cursor-pointer"
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
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-6 space-y-5 max-h-[90vh] overflow-y-auto">
            <h3 className="text-lg font-bold text-slate-100">
              {editingProduct ? 'تعديل بيانات المنتج' : 'إضافة منتج جديد'}
            </h3>

            <form onSubmit={handleSaveProduct} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">رمز المنتج (SKU) *</label>
                  <input
                    type="text"
                    required
                    value={sku}
                    onChange={(e) => setSku(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">نوع المنتج *</label>
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

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">التصنيف *</label>
                  <select
                    required
                    value={categoryId}
                    onChange={(e) => setCategoryId(Number(e.target.value))}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  >
                    <option value="">-- اختر التصنيف --</option>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">المتجر *</label>
                  <select
                    required
                    value={storeId}
                    onChange={(e) => {
                      setStoreId(e.target.value);
                      setBranchId(''); // reset branch when store changes
                    }}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  >
                    <option value="">-- اختر المتجر --</option>
                    {stores.map((s) => (
                      <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                  </select>
                </div>
              </div>

              {availableBranches.length > 0 && (
                <div>
                  <label className="block text-slate-400 mb-1">الفرع المتوفر به المنتج (اختياري)</label>
                  <select
                    value={branchId}
                    onChange={(e) => setBranchId(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  >
                    <option value="">-- متوفر في جميع الفروع --</option>
                    {availableBranches.map((b) => (
                      <option key={b.id} value={b.id}>{b.name} ({b.governorate_name_ar})</option>
                    ))}
                  </select>
                </div>
              )}

              <div>
                <label className="block text-slate-400 mb-1">اسم المنتج الكامل *</label>
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
                  <label className="block text-slate-400 mb-1">الماركة (Brand) *</label>
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
                  <label className="block text-slate-400 mb-1">الموديل (Model) *</label>
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
                  <label className="block text-slate-400 mb-1">السعر ($ USD) *</label>
                  <input
                    type="number"
                    required
                    value={priceUSD}
                    onChange={(e) => setPriceUSD(Number(e.target.value))}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">المخزون الكلي *</label>
                  <input
                    type="number"
                    required
                    value={stockQuantity}
                    onChange={(e) => setStockQuantity(Number(e.target.value))}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1">حد المخزون الحرج *</label>
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
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl font-bold cursor-pointer"
                >
                  إلغاء
                </button>
                <button type="submit" className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold cursor-pointer">
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

export default ProductsPage;
