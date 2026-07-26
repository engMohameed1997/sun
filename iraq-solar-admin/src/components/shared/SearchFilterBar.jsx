import React from 'react';
import { Search, X } from 'lucide-react';

const SearchFilterBar = ({ 
  searchQuery = '', 
  onSearchChange, 
  filters = [], 
  activeFilters = {},
  onFilterChange, 
  onClear,
  onClearFilters,
  placeholder = 'بحث...' 
}) => {
  const handleClear = onClear || onClearFilters || (() => {});

  const getOptionsArray = (options) => {
    if (Array.isArray(options)) return options;
    if (options && typeof options === 'object') {
      return Object.entries(options).map(([val, label]) => ({
        value: val,
        label: typeof label === 'string' ? label : String(label)
      }));
    }
    return [];
  };

  return (
    <div className="flex flex-wrap gap-4 items-center bg-white p-4 rounded-xl shadow-sm border border-gray-100 mb-6">
      <div className="relative flex-1 min-w-[250px]">
        <Search className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
        <input 
          type="text" 
          value={searchQuery}
          onChange={(e) => onSearchChange && onSearchChange(e.target.value)}
          placeholder={placeholder}
          className="w-full pl-4 pr-10 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-primary-gold focus:ring-1 focus:ring-primary-gold transition-colors text-dark-navy"
        />
      </div>
      
      {Array.isArray(filters) && filters.map((filter, index) => {
        const filterKey = filter.key || filter.id || `filter-${index}`;
        const filterValue = filter.value !== undefined ? filter.value : (activeFilters[filterKey] || '');
        const optionsList = getOptionsArray(filter.options);
        const labelPlaceholder = filter.placeholder || filter.label || 'اختر...';

        return (
          <select 
            key={filterKey}
            value={filterValue}
            onChange={(e) => onFilterChange && onFilterChange(filterKey, e.target.value)}
            className="py-2 px-4 border border-gray-200 rounded-lg focus:outline-none focus:border-primary-gold bg-white min-w-[150px] text-dark-navy text-sm"
          >
            <option value="">{labelPlaceholder}</option>
            {optionsList.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        );
      })}

      <button 
        type="button"
        onClick={handleClear}
        className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors flex items-center gap-1"
        title="مسح الفلاتر"
      >
        <X size={18} />
      </button>
    </div>
  );
};

export default SearchFilterBar;
