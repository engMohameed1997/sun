import React from 'react';
import { FileQuestion } from 'lucide-react';

const EmptyState = ({ title = 'لا توجد بيانات', subtitle = 'لم يتم العثور على أي سجلات مطابقة للبحث.', icon, action }) => {
  return (
    <div className="flex flex-col items-center justify-center p-12 text-center border border-dashed border-gray-300 rounded-xl bg-gray-50/50">
      <div className="text-gray-400 mb-4 bg-white p-4 rounded-full shadow-sm">
        {icon || <FileQuestion size={48} />}
      </div>
      <h3 className="text-lg font-bold text-gray-800 mb-2">{title}</h3>
      <p className="text-gray-500 mb-6 max-w-sm">{subtitle}</p>
      {action && <div>{action}</div>}
    </div>
  );
};

export default EmptyState;
