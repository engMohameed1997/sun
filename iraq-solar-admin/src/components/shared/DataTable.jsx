import React from 'react';
import { ChevronRight, ChevronLeft, Search } from 'lucide-react';
import { TableSkeleton } from './LoadingSkeleton';
import EmptyState from './EmptyState';

const DataTable = ({ 
  columns, 
  data, 
  isLoading, 
  pagination, 
  onPageChange,
  emptyMessage = 'لا توجد بيانات'
}) => {
  if (isLoading) {
    return <TableSkeleton rows={5} cols={columns.length} />;
  }

  if (!data || data.length === 0) {
    return <EmptyState title={emptyMessage} />;
  }

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col">
      <div className="overflow-x-auto">
        <table className="w-full text-right border-collapse">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-200">
              {columns.map((col, i) => (
                <th key={i} className="py-4 px-6 text-sm font-bold text-gray-700">
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.map((row, rowIndex) => (
              <tr 
                key={row.id || rowIndex} 
                className="border-b border-gray-100 hover:bg-amber-50/30 transition-colors"
              >
                {columns.map((col, colIndex) => (
                  <td key={colIndex} className="py-4 px-6 text-sm text-gray-600">
                    {col.render ? col.render(row) : row[col.accessor]}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {pagination && pagination.totalPages > 1 && (
        <div className="border-t border-gray-200 p-4 flex items-center justify-between bg-gray-50/50">
          <div className="text-sm text-gray-500">
            إجمالي السجلات: <span className="font-bold text-gray-700">{pagination.totalItems}</span>
          </div>
          
          <div className="flex gap-1">
            <button 
              onClick={() => onPageChange(pagination.page - 1)}
              disabled={pagination.page === 1}
              className="p-2 rounded-lg border bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <ChevronRight size={18} />
            </button>
            
            <div className="flex items-center px-4 font-medium text-gray-700">
              {pagination.page} / {pagination.totalPages}
            </div>

            <button 
              onClick={() => onPageChange(pagination.page + 1)}
              disabled={pagination.page === pagination.totalPages}
              className="p-2 rounded-lg border bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <ChevronLeft size={18} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default DataTable;
