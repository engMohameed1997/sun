import React, { useState, useEffect } from 'react';
import DataTable from '../components/shared/DataTable';
import SearchFilterBar from '../components/shared/SearchFilterBar';
import { formatDateTime } from '../utils/formatters';
import { getAuditLogs } from '../api/adminApi';
import { FileText, RefreshCw } from 'lucide-react';
import toast from 'react-hot-toast';

const AuditLogPage = () => {
  const [logs, setLogs] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState({ action: '' });

  const fetchLogs = async () => {
    setIsLoading(true);
    try {
      const res = await getAuditLogs({ search, action: filters.action || undefined });
      const data = res.data?.data?.logs || res.data?.data || res.data || [];
      setLogs(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Error fetching audit logs:', error);
      toast.error('فشل في جلب سجل التدقيق');
      setLogs([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [search, filters]);

  const getActionBadge = (action) => {
    const actionMap = {
      create: { bg: 'bg-green-100 text-green-700', label: 'إنشاء' },
      update: { bg: 'bg-blue-100 text-blue-700', label: 'تعديل' },
      delete: { bg: 'bg-red-100 text-red-700', label: 'حذف' },
      login: { bg: 'bg-purple-100 text-purple-700', label: 'تسجيل دخول' },
      status_change: { bg: 'bg-amber-100 text-amber-700', label: 'تغيير حالة' },
    };
    const match = actionMap[action] || { bg: 'bg-gray-100 text-gray-700', label: action };
    return <span className={`px-2 py-1 rounded text-xs font-medium ${match.bg}`}>{match.label}</span>;
  };

  const columns = [
    { 
      header: 'المستخدم', 
      accessor: 'user_id', 
      render: r => <span className="font-bold text-gray-800">{r.user_id ? r.user_id.substring(0, 8) + '...' : 'نظام'}</span> 
    },
    { 
      header: 'الإجراء', 
      accessor: 'action', 
      render: r => getActionBadge(r.action)
    },
    { 
      header: 'القسم', 
      accessor: 'entity_name',
      render: r => <span className="text-gray-600">{r.entity_name || '-'}</span>
    },
    { 
      header: 'معرف العنصر', 
      accessor: 'entity_id',
      render: r => r.entity_id ? <span className="font-mono text-xs text-gray-500">{r.entity_id.substring(0, 8)}...</span> : '-'
    },
    { 
      header: 'التفاصيل', 
      accessor: 'payload',
      render: r => {
        if (!r.payload) return '-';
        const text = typeof r.payload === 'string' ? r.payload : JSON.stringify(r.payload);
        return <span className="text-sm text-gray-500 truncate block max-w-xs" title={text}>{text.substring(0, 50)}{text.length > 50 ? '...' : ''}</span>;
      }
    },
    { 
      header: 'التاريخ والوقت', 
      accessor: 'created_at', 
      render: r => <span className="text-sm text-gray-500">{formatDateTime(r.created_at)}</span>
    }
  ];

  return (
    <div className="animate-slide-in">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center gap-2">
          <FileText className="text-primary-gold" size={28} />
          <h2 className="text-2xl font-bold text-dark-navy">سجل التدقيق (Audit Log)</h2>
        </div>
        <button onClick={fetchLogs} className="btn btn-outline">
          <RefreshCw size={18} /> تحديث
        </button>
      </div>

      <SearchFilterBar 
        searchQuery={search} 
        onSearchChange={setSearch}
        filters={[
          { key: 'action', placeholder: 'جميع الإجراءات', value: filters.action, options: [
            { value: 'create', label: 'إنشاء' },
            { value: 'update', label: 'تعديل' },
            { value: 'delete', label: 'حذف' },
            { value: 'login', label: 'تسجيل دخول' },
            { value: 'status_change', label: 'تغيير حالة' }
          ]}
        ]}
        onFilterChange={(k, v) => setFilters(prev => ({ ...prev, [k]: v }))}
        onClear={() => { setSearch(''); setFilters({ action: '' }); }}
      />

      <DataTable columns={columns} data={logs} isLoading={isLoading} />
    </div>
  );
};
export default AuditLogPage;
