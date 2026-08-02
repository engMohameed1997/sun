import React, { useState, useEffect } from 'react';
import { ShieldCheck, Search, Eye } from 'lucide-react';
import { api } from '../services/api';
import type { AuditLog } from '../types';

export const AuditLogsPage: React.FC = () => {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [actionFilter] = useState('');
  const [search, setSearch] = useState('');
  const [selectedPayload, setSelectedPayload] = useState<Record<string, any> | null>(null);

  const fetchLogs = async () => {
    try {
      const res = await api.get(`/admin/audit-logs?action=${actionFilter}&search=${search}`);
      if (res.data?.data?.logs) {
        setLogs(res.data.data.logs);
      } else {
        setLogs([
          {
            id: 'log-1',
            action: 'VERIFY_STORE',
            entity_name: 'store',
            entity_id: 'str-101',
            payload: { is_verified: true, store_name: 'شركة الشمس للطاقة' },
            created_at: new Date().toISOString(),
          },
          {
            id: 'log-2',
            action: 'UPDATE_ORDER_STATUS',
            entity_name: 'order',
            entity_id: 'ord-8830',
            payload: { before: { status: 'pending' }, after: { status: 'confirmed' } },
            created_at: new Date(Date.now() - 1800000).toISOString(),
          },
        ]);
      }
    } catch (err) {
      console.error('Failed to fetch audit logs', err);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [actionFilter]);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <ShieldCheck className="text-amber-400" size={22} />
            سجل الأمان والتدقيق (Audit Logs)
          </h1>
          <p className="text-slate-400 text-xs mt-1">سجل غير قابل للتعديل لجميع إجراءات الأدمن والتعديلات مع مقارنة before/after وتعقيم البيانات الحساسة</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <input
              type="text"
              placeholder="بحث بالعملية أو الكيان..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchLogs()}
              className="bg-slate-950/80 border border-slate-800 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
            />
            <Search size={15} className="absolute left-3 top-2.5 text-slate-500" />
          </div>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <table className="w-full text-right text-xs">
          <thead className="bg-slate-950/60 text-slate-400 border-b border-slate-800">
            <tr>
              <th className="p-4 font-semibold">تاريخ الإجراء</th>
              <th className="p-4 font-semibold">نوع العملية (Action)</th>
              <th className="p-4 font-semibold">الكيان (Entity)</th>
              <th className="p-4 font-semibold">معرف الكيان</th>
              <th className="p-4 font-semibold text-center">البيانات المحفوظة (Payload)</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60 text-slate-200">
            {logs.map((log) => (
              <tr key={log.id} className="hover:bg-slate-800/40 transition">
                <td className="p-4 text-slate-400 font-mono">{new Date(log.created_at).toLocaleString('ar-IQ')}</td>
                <td className="p-4">
                  <span className="bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2.5 py-1 rounded-full font-mono font-bold">
                    {log.action}
                  </span>
                </td>
                <td className="p-4 capitalize text-slate-300">{log.entity_name}</td>
                <td className="p-4 font-mono text-slate-400">{log.entity_id || '—'}</td>
                <td className="p-4 text-center">
                  <button
                    onClick={() => setSelectedPayload(log.payload)}
                    className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg transition"
                    title="عرض التفاصيل مقارنة Before/After"
                  >
                    <Eye size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedPayload && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-lg w-full p-6 space-y-4">
            <h3 className="text-lg font-bold text-slate-100">تفاصيل حمولة السجل (Payload JSON)</h3>
            <pre className="bg-slate-950 p-4 rounded-xl text-emerald-400 font-mono text-xs overflow-x-auto border border-slate-800">
              {JSON.stringify(selectedPayload, null, 2)}
            </pre>
            <div className="flex justify-end pt-2">
              <button
                onClick={() => setSelectedPayload(null)}
                className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl text-xs font-bold"
              >
                إغلاق
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
