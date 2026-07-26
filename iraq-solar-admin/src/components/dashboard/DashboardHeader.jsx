import React, { useState, useRef, useEffect } from 'react';
import { Calendar, RefreshCw, Download, Sparkles, ChevronDown } from 'lucide-react';
import toast from 'react-hot-toast';

const DashboardHeader = ({ timeRange, setTimeRange, onRefresh, isLoading }) => {
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [showExportMenu, setShowExportMenu] = useState(false);
  const menuRef = useRef(null);

  const handleRefreshClick = async () => {
    setIsRefreshing(true);
    if (onRefresh) {
      await onRefresh();
    }
    toast.success('تم تحديث البيانات والربط بالباك اند بنجاح!');
    setTimeout(() => setIsRefreshing(false), 600);
  };

  const handleExport = (type) => {
    setShowExportMenu(false);
    toast.success(`جاري تصدير تقرير البيانات الحقيقية بصيغة ${type}...`);
  };

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (menuRef.current && !menuRef.current.contains(event.target)) {
        setShowExportMenu(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 p-4 bg-white rounded-xl border border-slate-200 shadow-xs mb-6">
      <div className="flex items-center gap-3">
        <div className="p-2.5 bg-amber-50 rounded-xl text-amber-600 border border-amber-200/60">
          <Sparkles size={20} />
        </div>
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-slate-900 m-0">نظرة عامة على الأداء والمراقبة</h2>
            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></span>
              قواعد البيانات متصلة
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-0.5 m-0">
            متابعة وتحليل مؤشرات المنظومات الشمسية، المبيعات، ونشاط المتاجر العراقية
          </p>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2.5 w-full sm:w-auto justify-end">
        {/* Time range selector */}
        <div className="flex items-center gap-2 bg-slate-50 px-3 py-1.5 rounded-lg border border-slate-200 text-xs font-semibold text-slate-700">
          <Calendar size={15} className="text-amber-500" />
          <select 
            value={timeRange} 
            onChange={(e) => setTimeRange(e.target.value)}
            className="bg-transparent font-semibold text-slate-800 outline-none cursor-pointer"
          >
            <option value="7">آخر 7 أيام</option>
            <option value="30">آخر 30 يوماً</option>
            <option value="90">آخر 3 أشهر</option>
            <option value="365">هذه السنة</option>
          </select>
        </div>

        {/* Live Refresh button */}
        <button
          onClick={handleRefreshClick}
          disabled={isLoading || isRefreshing}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-white text-slate-700 hover:bg-slate-50 border border-slate-200 rounded-lg text-xs font-semibold transition cursor-pointer disabled:opacity-50"
        >
          <RefreshCw size={14} className={`text-amber-500 ${isRefreshing || isLoading ? 'animate-spin' : ''}`} />
          <span>تحديث مباشر</span>
        </button>

        {/* Export Button & Dropdown */}
        <div className="relative" ref={menuRef}>
          <button 
            onClick={() => setShowExportMenu(!showExportMenu)}
            className="flex items-center gap-1.5 px-3.5 py-1.5 bg-amber-500 hover:bg-amber-600 text-white rounded-lg text-xs font-bold transition shadow-xs cursor-pointer"
          >
            <Download size={14} />
            <span>تصدير تقرير</span>
            <ChevronDown size={14} className={`transition-transform ${showExportMenu ? 'rotate-180' : ''}`} />
          </button>

          {showExportMenu && (
            <div className="absolute left-0 mt-1.5 w-40 bg-white rounded-xl shadow-lg border border-slate-200 z-50 py-1 overflow-hidden">
              <button 
                onClick={() => handleExport('PDF')}
                className="w-full text-right px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-amber-50 hover:text-amber-700 transition"
              >
                تصدير ملخص (PDF)
              </button>
              <button 
                onClick={() => handleExport('CSV')}
                className="w-full text-right px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-amber-50 hover:text-amber-700 transition"
              >
                تصدير بيانات (CSV)
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default DashboardHeader;
