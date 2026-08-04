import React from 'react';
import { CheckCircle2, Clock, Truck, PackageCheck, XCircle, Circle } from 'lucide-react';
import type { OrderStatus, OrderStatusHistory } from '../../types';

interface OrderStatusTimelineProps {
  history: OrderStatusHistory[];
  currentStatus: OrderStatus;
}

const STATUS_CONFIG: Record<string, { label: string; icon: React.FC<any>; color: string; bg: string; border: string }> = {
  pending: {
    label: 'قيد الانتظار',
    icon: Clock,
    color: 'text-amber-400',
    bg: 'bg-amber-500/10',
    border: 'border-amber-500/40',
  },
  confirmed: {
    label: 'تم التأكيد',
    icon: CheckCircle2,
    color: 'text-blue-400',
    bg: 'bg-blue-500/10',
    border: 'border-blue-500/40',
  },
  processing: {
    label: 'قيد التجهيز',
    icon: Truck,
    color: 'text-purple-400',
    bg: 'bg-purple-500/10',
    border: 'border-purple-500/40',
  },
  completed: {
    label: 'مكتمل',
    icon: PackageCheck,
    color: 'text-emerald-400',
    bg: 'bg-emerald-500/10',
    border: 'border-emerald-500/40',
  },
  cancelled: {
    label: 'ملغي',
    icon: XCircle,
    color: 'text-rose-400',
    bg: 'bg-rose-500/10',
    border: 'border-rose-500/40',
  },
};

function formatDateTime(dateStr: string): string {
  return new Intl.DateTimeFormat('ar-IQ', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(dateStr));
}

function relativeTime(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60_000);
  if (minutes < 1) return 'الآن';
  if (minutes < 60) return `منذ ${minutes} دقيقة`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `منذ ${hours} ساعة`;
  const days = Math.floor(hours / 24);
  return `منذ ${days} يوم`;
}

export const OrderStatusTimeline: React.FC<OrderStatusTimelineProps> = ({
  history,
  currentStatus,
}) => {
  if (!history || history.length === 0) {
    return (
      <div className="text-slate-500 text-xs text-center py-4">
        لا يوجد سجل لتغييرات الحالة
      </div>
    );
  }

  return (
    <div className="relative" dir="rtl">
      {/* Vertical connector line */}
      <div className="absolute right-[18px] top-6 bottom-0 w-px bg-slate-700/60" />

      <div className="space-y-4">
        {history.map((entry, idx) => {
          const status = entry.to_status;
          const config = STATUS_CONFIG[status] || {
            label: status,
            icon: Circle,
            color: 'text-slate-400',
            bg: 'bg-slate-800',
            border: 'border-slate-700',
          };
          const Icon = config.icon;
          const isLast = idx === history.length - 1;

          return (
            <div key={entry.id} className="flex items-start gap-3 relative">
              {/* Icon bubble */}
              <div
                className={`relative z-10 flex-shrink-0 w-9 h-9 rounded-full flex items-center justify-center border ${config.bg} ${config.border} ${isLast ? 'ring-2 ring-offset-2 ring-offset-slate-900 ring-slate-700' : ''}`}
              >
                <Icon size={16} className={config.color} />
              </div>

              {/* Content */}
              <div className="flex-1 pb-2">
                <div className="flex items-center justify-between gap-2">
                  <span className={`text-sm font-bold ${config.color}`}>{config.label}</span>
                  <span className="text-[11px] text-slate-500">{relativeTime(entry.created_at)}</span>
                </div>
                <div className="text-[11px] text-slate-400 mt-0.5">{formatDateTime(entry.created_at)}</div>
                {entry.changed_by_name && (
                  <div className="text-[11px] text-slate-500 mt-0.5">
                    بواسطة: <span className="text-slate-300 font-medium">{entry.changed_by_name}</span>
                  </div>
                )}
                {entry.notes && (
                  <div className="mt-1.5 text-[11px] text-slate-400 bg-slate-800/60 border border-slate-700/60 rounded-lg px-2.5 py-1.5 leading-relaxed">
                    {entry.notes}
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Current status indicator if pending */}
      {currentStatus === 'pending' && history[history.length - 1]?.to_status !== 'pending' && (
        <div className="flex items-center gap-3 mt-4 opacity-40">
          <div className="w-9 h-9 rounded-full border border-dashed border-slate-600 flex items-center justify-center">
            <Circle size={14} className="text-slate-500" />
          </div>
          <span className="text-xs text-slate-500">في انتظار الإجراء التالي...</span>
        </div>
      )}
    </div>
  );
};
