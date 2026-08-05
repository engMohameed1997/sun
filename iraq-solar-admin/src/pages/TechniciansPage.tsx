import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  HardHat,
  Search,
  ShieldCheck,
  Wallet,
  MapPin,
  Star,
  Pin,
  EyeOff,
  Clock,
  Award,
  FileCheck2,
  X,
} from 'lucide-react';
import { api } from '../services/api';
import type {
  Governorate,
  Technician,
  TechnicianDocument,
  TechnicianLevel,
  TechnicianServiceZone,
  TechnicianWallet,
} from '../types';

const ROLE_LABELS: Record<string, string> = {
  engineer: 'مهندس',
  installer: 'مُركّب',
  technician: 'فني',
  worker: 'عامل',
};

const STATUS_LABELS: Record<string, { label: string; dot: string; text: string }> = {
  available: { label: 'متوفر', dot: 'bg-emerald-400', text: 'text-emerald-400' },
  busy: { label: 'مشغول', dot: 'bg-amber-400', text: 'text-amber-400' },
  vacation: { label: 'إجازة', dot: 'bg-rose-400', text: 'text-rose-400' },
  suspended: { label: 'موقوف', dot: 'bg-rose-500', text: 'text-rose-400' },
  offline: { label: 'غير متصل', dot: 'bg-slate-500', text: 'text-slate-400' },
};

const SPECIALIZATIONS = ['installation', 'maintenance', 'inspection', 'inverter', 'battery', 'wiring'];
const SPECIALIZATION_LABELS: Record<string, string> = {
  installation: 'تركيب',
  maintenance: 'صيانة',
  inspection: 'معاينة',
  inverter: 'انفرترات',
  battery: 'بطاريات',
  wiring: 'تمديدات',
};

type TechnicianDetail = {
  technician: Technician;
  zones: TechnicianServiceZone[];
  documents: TechnicianDocument[];
  wallet: TechnicianWallet | null;
};

export const TechniciansPage: React.FC = () => {
  const [technicians, setTechnicians] = useState<Technician[]>([]);
  const [governorates, setGovernorates] = useState<Governorate[]>([]);
  const [levels, setLevels] = useState<TechnicianLevel[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const [detail, setDetail] = useState<TechnicianDetail | null>(null);
  const [detailTab, setDetailTab] = useState<'zones' | 'documents' | 'wallet' | 'level'>('zones');

  const fetchTechnicians = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/technicians', {
        params: { search, role: roleFilter, status: statusFilter, limit: 100 },
      });
      setTechnicians(res.data?.data?.technicians || []);
    } catch (err) {
      console.error('Failed to fetch technicians', err);
    } finally {
      setIsLoading(false);
    }
  }, [search, roleFilter, statusFilter]);

  useEffect(() => {
    fetchTechnicians();
  }, [fetchTechnicians]);

  useEffect(() => {
    api.get('/admin/governorates').then((res) => setGovernorates(res.data?.data || [])).catch(() => {});
    api.get('/admin/technician-levels').then((res) => setLevels(res.data?.data || [])).catch(() => {});
  }, []);

  const governorateName = useMemo(() => {
    const map = new Map<number, string>();
    governorates.forEach((g) => map.set(g.id, g.name_ar));
    return map;
  }, [governorates]);

  const openDetail = async (id: string, tab: 'zones' | 'documents' | 'wallet' | 'level') => {
    try {
      const res = await api.get(`/admin/technicians/${id}`);
      setDetail({
        technician: res.data?.data?.technician,
        zones: res.data?.data?.zones || [],
        documents: res.data?.data?.documents || [],
        wallet: res.data?.data?.wallet || null,
      });
      setDetailTab(tab);
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر جلب بيانات الفني');
    }
  };

  const handleVerify = async (tech: Technician) => {
    const level = window.prompt('مستوى التوثيق (0=غير موثق, 1=هوية, 2=هوية+شهادة, 3=كامل)', String(tech.verification_level));
    if (level === null) return;
    try {
      await api.put(`/admin/technicians/${tech.id}/verify`, {
        is_verified: Number(level) > 0,
        verification_level: Number(level),
      });
      fetchTechnicians();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث التوثيق');
    }
  };

  const handleToggleActive = async (tech: Technician) => {
    try {
      await api.put(`/admin/technicians/${tech.id}`, { is_active: !tech.is_active });
      fetchTechnicians();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث الحالة');
    }
  };

  const handleRanking = async (tech: Technician, patch: { is_featured?: boolean; is_hidden?: boolean }) => {
    try {
      await api.put(`/admin/technicians/${tech.id}/ranking`, patch);
      fetchTechnicians();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث الترتيب');
    }
  };

  const handleSaveZones = async (technicianId: string, zoneIds: number[], primary: number | null) => {
    try {
      await api.put(`/admin/technicians/${technicianId}/zones`, {
        governorate_ids: zoneIds,
        primary_governorate: primary,
      });
      await openDetail(technicianId, 'zones');
      alert('تم تحديث مناطق التغطية');
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث مناطق التغطية');
    }
  };

  const handleReviewDocument = async (technicianId: string, docId: string, status: 'approved' | 'rejected') => {
    try {
      await api.put(`/admin/technicians/${technicianId}/documents/${docId}`, { status });
      await openDetail(technicianId, 'documents');
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تحديث حالة المستند');
    }
  };

  const handleSettle = async (technicianId: string) => {
    if (!window.confirm('تأكيد تسديد كامل مستحقات هذا الفني؟')) return;
    try {
      await api.post(`/admin/technicians/${technicianId}/wallet/settle`);
      await openDetail(technicianId, 'wallet');
      alert('تم التسديد');
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر التسديد');
    }
  };

  const handleChangeLevel = async (technicianId: string, levelId: string) => {
    try {
      await api.put(`/admin/technicians/${technicianId}`, { level_id: levelId });
      await openDetail(technicianId, 'level');
      fetchTechnicians();
    } catch (err: any) {
      alert(err.response?.data?.message || 'تعذر تغيير المستوى');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <HardHat className="text-amber-400" size={22} />
            إدارة الفنيين والمهندسين
          </h1>
          <p className="text-slate-400 text-xs mt-1">
            توثيق الفنيين، مناطق التغطية، المحافظ المالية، والمستويات (Bronze/Silver/Gold)
          </p>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4 grid grid-cols-1 md:grid-cols-3 gap-3">
        <div className="relative">
          <Search className="absolute right-3 top-2.5 text-slate-500" size={16} />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="بحث بالاسم، رقم الهاتف، أو المحافظة..."
            className="w-full bg-slate-950 border border-slate-800 rounded-xl pr-10 pl-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
          />
        </div>
        <select
          value={roleFilter}
          onChange={(e) => setRoleFilter(e.target.value)}
          className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
        >
          <option value="">كل الأدوار</option>
          {Object.entries(ROLE_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
        >
          <option value="">كل حالات التواجد</option>
          {Object.entries(STATUS_LABELS).map(([value, meta]) => (
            <option key={value} value={value}>
              {meta.label}
            </option>
          ))}
        </select>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-x-auto">
        <table className="w-full text-sm min-w-[900px]">
          <thead>
            <tr className="text-slate-400 text-xs border-b border-slate-800">
              <th className="text-right p-3">الفني</th>
              <th className="text-right p-3">الدور</th>
              <th className="text-right p-3">المحافظة</th>
              <th className="text-right p-3">التواجد</th>
              <th className="text-right p-3">التقييم</th>
              <th className="text-right p-3">الأعمال</th>
              <th className="text-right p-3">نسبة القبول</th>
              <th className="text-right p-3">المستوى</th>
              <th className="text-right p-3">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr>
                <td colSpan={9} className="p-10 text-center text-slate-400 font-bold">
                  جارٍ التحميل...
                </td>
              </tr>
            ) : technicians.length === 0 ? (
              <tr>
                <td colSpan={9} className="p-10 text-center text-slate-500">
                  لا يوجد فنيون مسجلون
                </td>
              </tr>
            ) : (
              technicians.map((tech) => {
                const status = STATUS_LABELS[tech.availability_status] || STATUS_LABELS.offline;
                return (
                  <tr key={tech.id} className="border-b border-slate-800/60 hover:bg-slate-800/30">
                    <td className="p-3">
                      <div className="font-bold text-slate-100">{tech.full_name}</div>
                      <div className="text-[11px] text-slate-500">
                        {tech.is_verified ? `موثق (مستوى ${tech.verification_level})` : 'غير موثق'}
                        {!tech.is_active && ' ⋅ موقوف'}
                      </div>
                    </td>
                    <td className="p-3 text-slate-300">{ROLE_LABELS[tech.role] || tech.role}</td>
                    <td className="p-3 text-slate-300">
                      {tech.governorate_name || governorateName.get(tech.governorate_id || 0) || '—'}
                    </td>
                    <td className="p-3">
                      <span className={`inline-flex items-center gap-1.5 text-xs font-bold ${status.text}`}>
                        <span className={`w-2 h-2 rounded-full ${status.dot}`} />
                        {status.label}
                      </span>
                    </td>
                    <td className="p-3 text-amber-400 font-bold">{Number(tech.rating).toFixed(1)}</td>
                    <td className="p-3 text-slate-300">{tech.completed_jobs_count}</td>
                    <td className="p-3 text-slate-300">{Number(tech.acceptance_rate).toFixed(0)}%</td>
                    <td className="p-3">
                      <span
                        className="text-[11px] font-bold px-2 py-0.5 rounded-full border"
                        style={{
                          color: tech.level_badge_color || '#94a3b8',
                          borderColor: `${tech.level_badge_color || '#94a3b8'}55`,
                        }}
                      >
                        {tech.level_name_ar || 'بدون'}
                      </span>
                    </td>
                    <td className="p-3">
                      <div className="flex items-center gap-1.5">
                        <button
                          onClick={() => handleVerify(tech)}
                          title="توثيق"
                          className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-emerald-500 hover:text-slate-950 transition cursor-pointer"
                        >
                          <ShieldCheck size={14} />
                        </button>
                        <button
                          onClick={() => openDetail(tech.id, 'zones')}
                          title="مناطق التغطية"
                          className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-amber-500 hover:text-slate-950 transition cursor-pointer"
                        >
                          <MapPin size={14} />
                        </button>
                        <button
                          onClick={() => openDetail(tech.id, 'documents')}
                          title="المستندات"
                          className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-sky-500 hover:text-slate-950 transition cursor-pointer"
                        >
                          <FileCheck2 size={14} />
                        </button>
                        <button
                          onClick={() => openDetail(tech.id, 'wallet')}
                          title="المحفظة"
                          className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-emerald-500 hover:text-slate-950 transition cursor-pointer"
                        >
                          <Wallet size={14} />
                        </button>
                        <button
                          onClick={() => openDetail(tech.id, 'level')}
                          title="المستوى"
                          className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-violet-500 hover:text-white transition cursor-pointer"
                        >
                          <Award size={14} />
                        </button>
                        <button
                          onClick={() => handleRanking(tech, { is_featured: !tech.is_featured })}
                          title="تثبيت بالأعلى"
                          className={`p-1.5 rounded-lg transition cursor-pointer ${
                            tech.is_featured ? 'bg-amber-500 text-slate-950' : 'bg-slate-800 text-slate-300 hover:bg-amber-500 hover:text-slate-950'
                          }`}
                        >
                          <Pin size={14} />
                        </button>
                        <button
                          onClick={() => handleRanking(tech, { is_hidden: !tech.is_hidden })}
                          title="إخفاء"
                          className={`p-1.5 rounded-lg transition cursor-pointer ${
                            tech.is_hidden ? 'bg-rose-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-rose-500 hover:text-white'
                          }`}
                        >
                          <EyeOff size={14} />
                        </button>
                        <button
                          onClick={() => handleToggleActive(tech)}
                          title={tech.is_active ? 'إيقاف' : 'تفعيل'}
                          className="p-1.5 bg-slate-800 text-slate-300 rounded-lg hover:bg-slate-700 transition cursor-pointer"
                        >
                          <Clock size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {detail && (
        <TechnicianDetailModal
          detail={detail}
          tab={detailTab}
          setTab={setDetailTab}
          governorates={governorates}
          levels={levels}
          onClose={() => setDetail(null)}
          onSaveZones={handleSaveZones}
          onReviewDocument={handleReviewDocument}
          onSettle={handleSettle}
          onChangeLevel={handleChangeLevel}
        />
      )}
    </div>
  );
};

interface DetailModalProps {
  detail: TechnicianDetail;
  tab: 'zones' | 'documents' | 'wallet' | 'level';
  setTab: (t: 'zones' | 'documents' | 'wallet' | 'level') => void;
  governorates: Governorate[];
  levels: TechnicianLevel[];
  onClose: () => void;
  onSaveZones: (technicianId: string, zoneIds: number[], primary: number | null) => void;
  onReviewDocument: (technicianId: string, docId: string, status: 'approved' | 'rejected') => void;
  onSettle: (technicianId: string) => void;
  onChangeLevel: (technicianId: string, levelId: string) => void;
}

const TechnicianDetailModal: React.FC<DetailModalProps> = ({
  detail,
  tab,
  setTab,
  governorates,
  levels,
  onClose,
  onSaveZones,
  onReviewDocument,
  onSettle,
  onChangeLevel,
}) => {
  const tech = detail.technician;
  const [selectedZones, setSelectedZones] = useState<number[]>(detail.zones.map((z) => z.governorate_id));
  const [primaryZone, setPrimaryZone] = useState<number | null>(
    detail.zones.find((z) => z.is_primary)?.governorate_id ?? null
  );

  useEffect(() => {
    setSelectedZones(detail.zones.map((z) => z.governorate_id));
    setPrimaryZone(detail.zones.find((z) => z.is_primary)?.governorate_id ?? null);
  }, [detail]);

  const tabs = [
    { key: 'zones' as const, label: 'مناطق التغطية', icon: MapPin },
    { key: 'documents' as const, label: 'المستندات', icon: FileCheck2 },
    { key: 'wallet' as const, label: 'المحفظة', icon: Wallet },
    { key: 'level' as const, label: 'المستوى', icon: Award },
  ];

  return (
    <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4 overflow-y-auto">
      <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-2xl w-full p-6 my-8">
        <div className="flex items-start justify-between mb-4">
          <div>
            <h2 className="text-lg font-bold text-slate-100 flex items-center gap-2">
              <HardHat className="text-amber-500" size={20} />
              {tech?.full_name}
            </h2>
            <p className="text-xs text-slate-500 mt-1 flex items-center gap-2">
              <Star size={12} className="text-amber-400" />
              {Number(tech?.rating || 0).toFixed(1)} ⋅ {tech?.completed_jobs_count} عملية ⋅ نسبة القبول{' '}
              {Number(tech?.acceptance_rate || 0).toFixed(0)}%
            </p>
          </div>
          <button onClick={onClose} className="p-2 text-slate-400 hover:text-white cursor-pointer">
            <X size={18} />
          </button>
        </div>

        <div className="flex gap-2 border-b border-slate-800 mb-4">
          {tabs.map((t) => {
            const Icon = t.icon;
            return (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={`px-3 py-2 text-xs font-bold flex items-center gap-1.5 border-b-2 transition cursor-pointer ${
                  tab === t.key ? 'border-amber-500 text-amber-400' : 'border-transparent text-slate-400 hover:text-slate-200'
                }`}
              >
                <Icon size={14} />
                {t.label}
              </button>
            );
          })}
        </div>

        {tab === 'zones' && (
          <div className="space-y-4">
            <div className="flex flex-wrap gap-2 max-h-48 overflow-y-auto">
              {governorates.map((g) => {
                const active = selectedZones.includes(g.id);
                return (
                  <button
                    key={g.id}
                    onClick={() =>
                      setSelectedZones(active ? selectedZones.filter((z) => z !== g.id) : [...selectedZones, g.id])
                    }
                    className={`px-3 py-1 rounded-lg text-xs border transition cursor-pointer ${
                      active
                        ? 'bg-emerald-500/20 text-emerald-300 border-emerald-500/40'
                        : 'bg-slate-950 text-slate-400 border-slate-800 hover:border-slate-700'
                    }`}
                  >
                    {g.name_ar}
                  </button>
                );
              })}
            </div>
            <div>
              <label className="block text-slate-400 text-xs mb-1">المحافظة الرئيسية</label>
              <select
                value={primaryZone ?? 0}
                onChange={(e) => setPrimaryZone(Number(e.target.value) || null)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-200 outline-none focus:border-amber-500/50 text-sm"
              >
                <option value={0}>بدون تحديد</option>
                {governorates
                  .filter((g) => selectedZones.includes(g.id))
                  .map((g) => (
                    <option key={g.id} value={g.id}>
                      {g.name_ar}
                    </option>
                  ))}
              </select>
            </div>
            <button
              onClick={() => onSaveZones(tech.id, selectedZones, primaryZone)}
              className="w-full px-4 py-2 bg-amber-500 text-slate-950 rounded-xl text-sm font-bold hover:bg-amber-600 cursor-pointer"
            >
              حفظ مناطق التغطية
            </button>
          </div>
        )}

        {tab === 'documents' && (
          <div className="space-y-2">
            {detail.documents.length === 0 ? (
              <div className="text-center text-slate-500 py-8 text-sm">لا توجد مستندات مرفوعة</div>
            ) : (
              detail.documents.map((doc) => (
                <div
                  key={doc.id}
                  className="flex items-center justify-between bg-slate-950 border border-slate-800 rounded-xl p-3"
                >
                  <div>
                    <a
                      href={doc.url}
                      target="_blank"
                      rel="noreferrer"
                      className="text-sm text-sky-400 hover:underline font-bold"
                    >
                      {doc.type}
                    </a>
                    <div className="text-[11px] text-slate-500">{doc.status}</div>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => onReviewDocument(tech.id, doc.id, 'approved')}
                      className="px-3 py-1 bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 rounded-lg text-xs font-bold cursor-pointer"
                    >
                      قبول
                    </button>
                    <button
                      onClick={() => onReviewDocument(tech.id, doc.id, 'rejected')}
                      className="px-3 py-1 bg-rose-500/20 text-rose-300 border border-rose-500/40 rounded-lg text-xs font-bold cursor-pointer"
                    >
                      رفض
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {tab === 'wallet' && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              {[
                { label: 'الرصيد الحالي', value: detail.wallet?.balance_iqd },
                { label: 'إجمالي الأرباح', value: detail.wallet?.total_earned_iqd },
                { label: 'إجمالي العمولات', value: detail.wallet?.total_commission_iqd },
                { label: 'المستحق غير المدفوع', value: detail.wallet?.pending_payout_iqd },
              ].map((item) => (
                <div key={item.label} className="bg-slate-950 border border-slate-800 rounded-xl p-3">
                  <div className="text-[11px] text-slate-500">{item.label}</div>
                  <div className="text-lg font-bold text-amber-400">
                    {Number(item.value || 0).toLocaleString('en-US')} د.ع
                  </div>
                </div>
              ))}
            </div>
            <button
              onClick={() => onSettle(tech.id)}
              className="w-full px-4 py-2 bg-emerald-500 text-slate-950 rounded-xl text-sm font-bold hover:bg-emerald-600 cursor-pointer"
            >
              تسديد المستحقات
            </button>
          </div>
        )}

        {tab === 'level' && (
          <div className="space-y-3">
            {levels.map((level) => (
              <button
                key={level.id}
                onClick={() => onChangeLevel(tech.id, level.id)}
                className={`w-full flex items-center justify-between bg-slate-950 border rounded-xl p-3 transition cursor-pointer ${
                  tech.level_id === level.id ? 'border-amber-500/60' : 'border-slate-800 hover:border-slate-700'
                }`}
              >
                <div className="text-right">
                  <div className="font-bold text-sm" style={{ color: level.badge_color }}>
                    {level.name_ar}
                  </div>
                  <div className="text-[11px] text-slate-500">
                    {level.min_jobs}+ عملية ⋅ تقييم {level.min_rating}+
                  </div>
                </div>
                <div className="text-sm font-bold text-slate-300">عمولة {level.commission_rate}%</div>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default TechniciansPage;
