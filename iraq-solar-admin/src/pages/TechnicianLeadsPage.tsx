import React, { useCallback, useEffect, useState } from 'react';
import { UserPlus, Check, X, RefreshCw, Phone, MapPin } from 'lucide-react';
import { api } from '../services/api';
import type { LeadStatus, TechnicianLead } from '../types';

const TYPE_LABELS: Record<string, string> = {
  installation: 'تركيب',
  maintenance: 'صيانة',
  inspection: 'معاينة',
  consultation: 'استشارة',
  repair: 'إصلاح',
};

const STATUS_LABELS: Record<LeadStatus, { label: string; className: string }> = {
  pending_review: { label: 'بانتظار المراجعة', className: 'text-amber-300 border-amber-500/40' },
  approved: { label: 'مقبول', className: 'text-emerald-300 border-emerald-500/40' },
  rejected: { label: 'مرفوض', className: 'text-rose-300 border-rose-500/40' },
  converted: { label: 'محوّل لطلب خدمة', className: 'text-sky-300 border-sky-500/40' },
};

export const TechnicianLeadsPage: React.FC = () => {
  const [leads, setLeads] = useState<TechnicianLead[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>('pending_review');
  const [isLoading, setIsLoading] = useState(true);

  const fetchLeads = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/leads', { params: { status: statusFilter } });
      setLeads(res.data?.data || []);
    } catch (err) {
      console.error('Failed to fetch leads', err);
    } finally {
      setIsLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchLeads();
  }, [fetchLeads]);

  const handleApprove = async (lead: TechnicianLead) => {
    const priceInput = window.prompt(
      'السعر الأساسي للطلب (د.ع) — اتركه فارغاً لاستخدام السعر المقترح من الفني',
      lead.estimated_price_iqd ? String(lead.estimated_price_iqd) : ''
    );
    if (priceInput === null) return;
    try {
      await api.put(`/admin/leads/${lead.id}/approve`, {
        base_price_iqd: priceInput ? Number(priceInput) : undefined,
      });
      alert('تم قبول الطلب وتحويله لطلب خدمة، والفني صاحب الطلب له الأولوية');
      fetchLeads();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر قبول الطلب');
    }
  };

  const handleReject = async (lead: TechnicianLead) => {
    if (!window.confirm('تأكيد رفض هذا الطلب؟')) return;
    try {
      await api.put(`/admin/leads/${lead.id}/reject`, {});
      fetchLeads();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر رفض الطلب');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <UserPlus className="text-amber-400" size={22} />
            طلبات الفنيين (Leads)
          </h1>
          <p className="text-slate-400 text-xs mt-1">
            عملاء وصلوا للفنيين خارج المنصة — عند القبول يتحول الطلب لطلب خدمة رسمي مع أولوية للفني صاحبه
          </p>
        </div>
        <div className="flex items-center gap-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
          >
            <option value="">كل الحالات</option>
            {Object.entries(STATUS_LABELS).map(([value, meta]) => (
              <option key={value} value={value}>
                {meta.label}
              </option>
            ))}
          </select>
          <button
            onClick={fetchLeads}
            className="bg-slate-800 hover:bg-slate-700 text-slate-200 px-4 py-2 rounded-xl text-sm font-bold flex items-center gap-2 transition cursor-pointer"
          >
            <RefreshCw size={16} />
            تحديث
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {isLoading ? (
          <div className="col-span-full p-10 text-center text-slate-400 font-bold">جارٍ التحميل...</div>
        ) : leads.length === 0 ? (
          <div className="col-span-full p-10 text-center text-slate-500 bg-slate-900 border border-slate-800 rounded-2xl">
            لا توجد طلبات من الفنيين
          </div>
        ) : (
          leads.map((lead) => {
            const meta = STATUS_LABELS[lead.status];
            return (
              <div key={lead.id} className="bg-slate-900 border border-slate-800 rounded-2xl p-4 space-y-3">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="font-bold text-slate-100 text-sm">{lead.customer_name}</h3>
                    <div className="text-[11px] text-slate-500 flex items-center gap-1 mt-1" dir="ltr">
                      <Phone size={11} />
                      {lead.customer_phone}
                    </div>
                  </div>
                  <span className={`text-[10px] px-2 py-0.5 rounded-full border font-bold ${meta.className}`}>
                    {meta.label}
                  </span>
                </div>

                <div className="text-xs text-slate-400 space-y-1">
                  <div>نوع الخدمة: {TYPE_LABELS[lead.order_type] || lead.order_type}</div>
                  {lead.system_size_kw ? <div>حجم المنظومة: {lead.system_size_kw} kW</div> : null}
                  {lead.address ? (
                    <div className="flex items-center gap-1">
                      <MapPin size={11} />
                      {lead.address}
                    </div>
                  ) : null}
                  {lead.estimated_price_iqd ? (
                    <div className="text-amber-400 font-bold">
                      سعر مقترح: {Number(lead.estimated_price_iqd).toLocaleString('en-US')} د.ع
                    </div>
                  ) : null}
                  {lead.description ? <p className="text-slate-500 line-clamp-2">{lead.description}</p> : null}
                </div>

                <div className="text-[11px] text-slate-500 pt-2 border-t border-slate-800/60">
                  أرسله: <span className="text-slate-300 font-bold">{lead.technician_name}</span> ⋅{' '}
                  {new Date(lead.created_at).toLocaleDateString('ar-IQ')}
                </div>

                {lead.status === 'pending_review' && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleApprove(lead)}
                      className="flex-1 px-3 py-2 bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 rounded-xl text-xs font-bold hover:bg-emerald-500/30 flex items-center justify-center gap-1.5 cursor-pointer"
                    >
                      <Check size={14} />
                      قبول وتحويل لطلب
                    </button>
                    <button
                      onClick={() => handleReject(lead)}
                      className="px-3 py-2 bg-rose-500/20 text-rose-300 border border-rose-500/40 rounded-xl text-xs font-bold hover:bg-rose-500/30 cursor-pointer"
                    >
                      <X size={14} />
                    </button>
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

export default TechnicianLeadsPage;
