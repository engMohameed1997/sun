import React, { useState, useEffect } from 'react';
import { Package, Search, Plus, Edit2, Trash2, AlertTriangle, Image as ImageIcon } from 'lucide-react';
import { api } from '../services/api';
import type { Product, ProductType, Category, Store, StoreBranch, Brand } from '../types';
import { useAuth } from '../context/AuthContext';

export const ProductsPage: React.FC = () => {
  const { user } = useAuth();
  const isAdmin = user?.role === 'admin';
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [brands, setBrands] = useState<Brand[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [branches, setBranches] = useState<StoreBranch[]>([]);

  const [searchQuery, setSearchQuery] = useState('');
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  // Form states
  const [sku, setSku] = useState('');
  const [name, setName] = useState('');
  const [brandId, setBrandId] = useState<string>('');
  const [model, setModel] = useState('');
  const [type] = useState<ProductType>('accessory');
  const [categoryId, setCategoryId] = useState<number | ''>('');
  const [storeId, setStoreId] = useState<string>('');
  const [branchId, setBranchId] = useState<string>('');
  const [priceIQD, setPriceIQD] = useState<number>(0);
  const [stockQuantity, setStockQuantity] = useState<number>(0);
  const [lowStockThreshold, setLowStockThreshold] = useState<number>(5);
  const [imageUrl, setImageUrl] = useState('');
  const [uploadingImage, setUploadingImage] = useState(false);
  const [warranty, setWarranty] = useState('');
  const [specRows, setSpecRows] = useState<{ key: string; value: string }[]>([{ key: '', value: '' }]);

  const fetchInitialData = async () => {
    // Fetch Categories (independent)
    try {
      const catRes = await api.get('/categories');
      if (catRes.data?.data) {
        setCategories(catRes.data.data);
      }
    } catch (err) {
      console.error('Failed to load categories', err);
    }

    // Fetch Brands (independent, use admin endpoint for admin)
    try {
      const brandEndpoint = isAdmin ? '/admin/brands' : '/brands';
      const brandRes = await api.get(brandEndpoint);
      if (brandRes.data?.data) {
        setBrands(brandRes.data.data);
      }
    } catch (err) {
      console.error('Failed to load brands', err);
    }

    // Fetch Stores (independent, for Admin fetch all, for Merchant fetch own)
    try {
      const storeEndpoint = isAdmin ? '/admin/stores' : '/stores';
      const storeRes = await api.get(storeEndpoint);
      const storeData = storeRes.data?.data?.stores || storeRes.data?.stores || storeRes.data?.data || [];
      if (Array.isArray(storeData) && storeData.length > 0) {
        if (isAdmin) {
          setStores(storeData);
        } else {
          const myStores = storeData.filter((s: Store) => s.merchant_id === user?.id);
          setStores(myStores);
          if (myStores.length > 0) setStoreId(myStores[0].id);
        }
      } else {
        console.warn('No stores found in response:', storeRes.data);
      }
    } catch (err) {
      console.error('Failed to load stores', err);
    }
  };

  const fetchProducts = async () => {
    try {
      const endpoint = isAdmin ? '/admin/products' : '/merchant/products';
      const res = await api.get(endpoint, {
        params: { search: searchQuery }
      });
      const productData = res.data?.data?.products;
      if (Array.isArray(productData)) {
        setProducts(productData);
      } else if (Array.isArray(res.data?.data)) {
        setProducts(res.data.data);
      } else {
        setProducts([]);
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
  }, [searchQuery]);

  // Fetch branches when a store is selected
  useEffect(() => {
    if (!storeId) {
      setBranches([]);
      return;
    }
    const fetchBranches = async () => {
      try {
        const endpoint = isAdmin ? `/admin/stores/${storeId}` : `/stores/${storeId}`;
        const res = await api.get(endpoint);
        const storeData = res.data?.data || res.data;
        if (storeData?.branches) {
          setBranches(storeData.branches);
        } else {
          // Fallback: check if branches are in the stores array
          const store = stores.find(s => s.id === storeId);
          setBranches(store?.branches || []);
        }
      } catch (err) {
        console.error('Failed to fetch store branches', err);
        const store = stores.find(s => s.id === storeId);
        setBranches(store?.branches || []);
      }
    };
    fetchBranches();
  }, [storeId, isAdmin]);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (!e.target.files?.[0]) return;
    setUploadingImage(true);
    const formData = new FormData();
    formData.append('image', e.target.files[0]);

    try {
      const res = await api.post('/upload/image', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      const url = res.data?.data?.url || res.data?.url;
      if (url) {
        setImageUrl(url);
      } else {
        alert('لم يتم استرجاع رابط الصورة المرفوعة');
      }
    } catch (err: any) {
      console.error('Upload image error:', err);
      alert('فشل رفع الصورة: ' + (err.response?.data?.error || err.response?.data?.message || err.message));
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSaveProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const specsObj: Record<string, string> = {};
      if (warranty.trim()) specsObj['الضمان'] = warranty.trim();
      specRows.forEach(r => {
        if (r.key.trim() && r.value.trim()) specsObj[r.key.trim()] = r.value.trim();
      });

      const payload = {
        sku,
        name,
        brand_id: brandId || undefined,
        model,
        type,
        category_id: categoryId ? Number(categoryId) : undefined,
        store_id: storeId || undefined,
        branch_id: branchId || undefined,
        price_iqd: priceIQD,
        stock_quantity: stockQuantity,
        low_stock_threshold: lowStockThreshold,
        images: imageUrl ? [imageUrl] : [],
        specifications: specsObj,
      };

      if (editingProduct) {
        const endpoint = isAdmin ? `/admin/products/${editingProduct.id}` : `/merchant/products/${editingProduct.id}`;
        await api.put(endpoint, payload);
        alert('تم التعديل بنجاح');
      } else {
        // Create endpoint depends on role, or if admin is creating on behalf of someone
        // But for now let's use the merchant endpoint if it's a merchant, admin endpoint otherwise
        const endpoint = isAdmin ? '/admin/products' : '/merchant/products';
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
      const endpoint = isAdmin ? `/admin/products/${id}` : `/merchant/products/${id}`;
      await api.delete(endpoint);
      alert('تم إخفاء المنتج بنجاح');
      fetchProducts();
    } catch (err) {
      alert('فشل الإخفاء');
    }
  };

  // Use branches from separate fetch, fallback to store object
  const selectedStore = stores.find(s => s.id === storeId);
  const availableBranches = branches.length > 0 ? branches : (selectedStore?.branches || []);

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
            const randomSku = 'SKU-' + Math.random().toString(36).substring(2, 8).toUpperCase();
            setSku(randomSku); setName(''); setBrandId(''); setModel('');
            setPriceIQD(0); setStockQuantity(0); setLowStockThreshold(5); setImageUrl('');
            setCategoryId('');
            setBranchId('');
            setWarranty('');
            setSpecRows([{ key: '', value: '' }]);
            if (isAdmin) setStoreId('');
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
                  <div className="text-xs text-slate-400 mt-1">{p.brand_name || '—'} • {p.model}</div>
                  <div className="text-[10px] text-amber-500/80 font-mono mt-1">SKU: {p.sku}</div>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2 bg-slate-950/50 p-2 rounded-xl border border-slate-800/50 text-center">
                <div>
                  <span className="text-slate-500 block text-[10px]">السعر</span>
                  <span className="font-bold text-emerald-400">{p.price_iqd.toLocaleString()} د.ع</span>
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
                    setBrandId(p.brand_id || '');
                    setModel(p.model);
                    setPriceIQD(p.price_iqd);
                    setStockQuantity(p.stock_quantity);
                    setLowStockThreshold(p.low_stock_threshold);
                    setImageUrl(p.images?.[0] || '');
                    setCategoryId(p.category_id || '');
                    setStoreId(p.store_id || '');
                    setBranchId(p.branch_id || '');
                    const existingSpecs = (p.specifications && typeof p.specifications === 'object') ? p.specifications as Record<string, string> : {};
                    setWarranty(existingSpecs['الضمان'] || '');
                    const specEntries = Object.entries(existingSpecs).filter(([k]) => k !== 'الضمان');
                    setSpecRows(specEntries.length > 0 ? specEntries.map(([k, v]) => ({ key: k, value: v })) : [{ key: '', value: '' }]);
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
              <div>
                <label className="block text-slate-400 mb-1">رمز المنتج (SKU)</label>
                <input
                  type="text"
                  readOnly
                  value={sku}
                  className="w-full bg-slate-950/50 border border-slate-800 rounded-xl px-3 py-2 text-slate-500 font-mono"
                />
              </div>

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

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1">الماركة (Brand) *</label>
                  <select
                    required
                    value={brandId}
                    onChange={(e) => setBrandId(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                  >
                    <option value="">-- اختر الماركة --</option>
                    {brands.map((b) => (
                      <option key={b.id} value={b.id}>{b.name}</option>
                    ))}
                  </select>
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
                  <label className="block text-slate-400 mb-1">السعر (د.ع IQD) *</label>
                  <input
                    type="number"
                    required
                    value={priceIQD}
                    onChange={(e) => setPriceIQD(Number(e.target.value))}
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

              <div>
                <label className="block text-slate-400 mb-1">الضمان (Warranty)</label>
                <input
                  type="text"
                  value={warranty}
                  onChange={(e) => setWarranty(e.target.value)}
                  placeholder="مثال: 25 سنة كفاءة وتوليد"
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                />
              </div>

              <div className="space-y-2">
                <label className="block text-slate-400">المواصفات الفنية (مفتاح / قيمة)</label>
                {specRows.map((row, idx) => (
                  <div key={idx} className="flex gap-2">
                    <input
                      type="text"
                      value={row.key}
                      onChange={(e) => {
                        const updated = [...specRows];
                        updated[idx] = { ...updated[idx], key: e.target.value };
                        setSpecRows(updated);
                      }}
                      placeholder="المواصفة (مثال: القدرة)"
                      className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                    />
                    <input
                      type="text"
                      value={row.value}
                      onChange={(e) => {
                        const updated = [...specRows];
                        updated[idx] = { ...updated[idx], value: e.target.value };
                        setSpecRows(updated);
                      }}
                      placeholder="القيمة (مثال: 550W)"
                      className="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                    />
                    {specRows.length > 1 && (
                      <button
                        type="button"
                        onClick={() => setSpecRows(specRows.filter((_, i) => i !== idx))}
                        className="px-2 bg-rose-500/10 text-rose-400 rounded-lg border border-rose-500/30"
                      >
                        ✕
                      </button>
                    )}
                  </div>
                ))}
                <button
                  type="button"
                  onClick={() => setSpecRows([...specRows, { key: '', value: '' }])}
                  className="text-amber-400 text-xs font-bold flex items-center gap-1"
                >
                  <Plus size={14} /> إضافة مواصفة جديدة
                </button>
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
