import React, { useState } from 'react';
import { Award, Store, Package, Star, TrendingUp } from 'lucide-react';

const topProducts = [
  { id: 1, name: 'إنفرتر Must Solar 5.5KW Hybrid', store: 'متجر دجلة للطاقة', sales: 142, rating: 4.9, price: '850,000 د.ع' },
  { id: 2, name: 'بطارية ليثيوم Felicity 100Ah 48V', store: 'شركة شمس الفرات', sales: 118, rating: 4.8, price: '2,100,000 د.ع' },
  { id: 3, name: 'لوح شمس Longi 580W N-Type', store: 'المدارات الشمسية', sales: 380, rating: 4.9, price: '165,000 د.ع' },
  { id: 4, name: 'منظومة طاقة هجينة 10KW كاملة', store: 'تقنيات المستقبل', sales: 45, rating: 5.0, price: '8,200,000 د.ع' },
];

const topStores = [
  { id: 1, name: 'متجر دجلة للطاقة الشمسية', governorate: 'بغداد', totalSales: '48,500,000 د.ع', ordersCount: 230, rating: 4.9 },
  { id: 2, name: 'شركة شمس الفرات', governorate: 'النجف', totalSales: '36,200,000 د.ع', ordersCount: 175, rating: 4.8 },
  { id: 3, name: 'مؤسسة البصرة للطاقة المستدامة', governorate: 'البصرة', totalSales: '31,800,000 د.ع', ordersCount: 142, rating: 4.7 },
  { id: 4, name: 'المدارات الشمسية لتجهيز المنظومات', governorate: 'أربيل', totalSales: '28,400,000 د.ع', ordersCount: 128, rating: 4.9 },
];

const TopPerformersWidget = () => {
  const [activeTab, setActiveTab] = useState('products');

  return (
    <div className="bg-white rounded-xl p-6 shadow-xs border border-slate-200 mb-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 mb-5 pb-4 border-b border-slate-100">
        <div className="flex items-center gap-2">
          <Award size={20} className="text-amber-500" />
          <h3 className="font-bold text-base text-slate-900 m-0">الأعلى أداءً ومبيعات في السوق</h3>
        </div>

        {/* Tab switcher */}
        <div className="flex bg-slate-100 p-1 rounded-lg text-xs font-bold">
          <button
            onClick={() => setActiveTab('products')}
            className={`px-3 py-1.5 rounded-md transition flex items-center gap-1.5 cursor-pointer ${
              activeTab === 'products'
                ? 'bg-white text-amber-700 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Package size={14} />
            <span>المنتجات الأكثر طلباً</span>
          </button>
          <button
            onClick={() => setActiveTab('stores')}
            className={`px-3 py-1.5 rounded-md transition flex items-center gap-1.5 cursor-pointer ${
              activeTab === 'stores'
                ? 'bg-white text-amber-700 shadow-xs'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            <Store size={14} />
            <span>المتاجر الأكثر مبيعات</span>
          </button>
        </div>
      </div>

      {activeTab === 'products' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
          {topProducts.map((item, idx) => (
            <div key={item.id} className="p-3.5 bg-slate-50/70 rounded-lg border border-slate-200/80 hover:border-amber-300 transition flex justify-between items-center gap-3">
              <div className="flex items-center gap-3">
                <span className="w-7 h-7 rounded-md bg-amber-100 text-amber-800 font-extrabold text-xs flex items-center justify-center shrink-0">
                  #{idx + 1}
                </span>
                <div>
                  <h4 className="font-bold text-xs text-slate-900 m-0">{item.name}</h4>
                  <p className="text-xs text-slate-500 font-medium mt-0.5 m-0">{item.store}</p>
                </div>
              </div>

              <div className="text-left shrink-0">
                <span className="text-xs font-extrabold text-amber-700 block">{item.price}</span>
                <div className="flex items-center justify-end gap-1.5 text-xs text-slate-500 mt-0.5">
                  <span className="flex items-center gap-0.5 text-amber-600 font-bold">
                    <Star size={12} fill="currentColor" /> {item.rating}
                  </span>
                  <span>•</span>
                  <span className="font-semibold">{item.sales} مبيعة</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
          {topStores.map((store, idx) => (
            <div key={store.id} className="p-3.5 bg-slate-50/70 rounded-lg border border-slate-200/80 hover:border-amber-300 transition flex justify-between items-center gap-3">
              <div className="flex items-center gap-3">
                <span className="w-7 h-7 rounded-md bg-emerald-100 text-emerald-800 font-extrabold text-xs flex items-center justify-center shrink-0">
                  #{idx + 1}
                </span>
                <div>
                  <h4 className="font-bold text-xs text-slate-900 m-0">{store.name}</h4>
                  <p className="text-xs text-slate-500 font-medium mt-0.5 m-0">المحافظة: {store.governorate}</p>
                </div>
              </div>

              <div className="text-left shrink-0">
                <span className="text-xs font-extrabold text-emerald-700 block flex items-center justify-end gap-1">
                  <TrendingUp size={13} />
                  {store.totalSales}
                </span>
                <div className="flex items-center justify-end gap-1.5 text-xs text-slate-500 mt-0.5">
                  <span className="flex items-center gap-0.5 text-amber-600 font-bold">
                    <Star size={12} fill="currentColor" /> {store.rating}
                  </span>
                  <span>•</span>
                  <span className="font-semibold">{store.ordersCount} طلب</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default TopPerformersWidget;
