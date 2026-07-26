import React, { useState } from 'react';
import { Store, ShieldAlert, ArrowLeft, X } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';

const initialAlerts = [
  {
    id: 1,
    type: 'warning',
    icon: Store,
    title: '3 متاجر جديدة تنتظر التفعيل والاعتماد',
    desc: 'متجر شمس بغداد، متجر دجلة للطاقة، ومتجر الجنوب الشمسي قدموا طلبات الانضمام.',
    actionText: 'مراجعة المتاجر',
    link: '/stores?filter=pending'
  },
  {
    id: 2,
    type: 'danger',
    icon: ShieldAlert,
    title: 'تحذير مخزون: انخفاض إنفرترات 5kW وبطاريات ليثيوم',
    desc: 'المخزون المتوفر في 4 متاجر رئيسية قل عن 5 وحدات.',
    actionText: 'عرض المخزون',
    link: '/products?filter=low_stock'
  }
];

const QuickAlertsBanner = () => {
  const [alerts, setAlerts] = useState(initialAlerts);
  const navigate = useNavigate();

  const handleDismiss = (id) => {
    setAlerts(prev => prev.filter(a => a.id !== id));
    toast.success('تم إخفاء التنبيه');
  };

  if (alerts.length === 0) return null;

  return (
    <div className="space-y-3 mb-6">
      {alerts.map((alert) => {
        const IconComponent = alert.icon;
        const isDanger = alert.type === 'danger';
        
        return (
          <div
            key={alert.id}
            style={{
              backgroundColor: isDanger ? '#FEF2F2' : '#FFFBEB',
              borderColor: isDanger ? '#FECDD3' : '#FDE68A',
            }}
            className="p-4 rounded-xl border flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 shadow-xs"
          >
            <div className="flex items-center gap-3">
              <div 
                style={{
                  backgroundColor: isDanger ? '#FEE2E2' : '#FEF3C7',
                  color: isDanger ? '#DC2626' : '#D97706',
                }}
                className="p-2.5 rounded-lg shrink-0"
              >
                <IconComponent size={20} />
              </div>
              <div>
                <h4 
                  style={{ color: isDanger ? '#991B1B' : '#92400E' }}
                  className="font-bold text-sm m-0"
                >
                  {alert.title}
                </h4>
                <p 
                  style={{ color: isDanger ? '#B91C1C' : '#B45309' }}
                  className="text-xs mt-0.5 m-0 font-medium"
                >
                  {alert.desc}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2 self-end sm:self-center shrink-0">
              <button
                onClick={() => navigate(alert.link)}
                style={{
                  backgroundColor: isDanger ? '#DC2626' : '#D97706',
                  color: '#FFFFFF',
                }}
                className="px-3.5 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 shadow-xs hover:opacity-90 transition cursor-pointer"
              >
                <span>{alert.actionText}</span>
                <ArrowLeft size={14} />
              </button>
              <button
                onClick={() => handleDismiss(alert.id)}
                style={{ color: isDanger ? '#991B1B' : '#92400E' }}
                className="p-1.5 hover:bg-black/5 rounded-lg transition cursor-pointer"
                title="إخفاء التنبيه"
              >
                <X size={16} />
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
};

export default QuickAlertsBanner;
