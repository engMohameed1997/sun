import React from 'react';

const StatusBadge = ({ status, label }) => {
  const colors = {
    pending: { bg: '#FEF3C7', text: '#D97706' }, // Warning/Yellow
    confirmed: { bg: '#DBEAFE', text: '#2563EB' }, // Blue
    processing: { bg: '#FFEDD5', text: '#EA580C' }, // Orange
    completed: { bg: '#D1FAE5', text: '#059669' }, // Green
    cancelled: { bg: '#FEE2E2', text: '#DC2626' }, // Red
    active: { bg: '#D1FAE5', text: '#059669' }, // Green
    inactive: { bg: '#F1F5F9', text: '#64748B' }, // Gray
  };

  const style = colors[status] || colors.inactive;

  return (
    <span style={{ 
      backgroundColor: style.bg, 
      color: style.text,
      padding: '0.25rem 0.75rem',
      borderRadius: '9999px',
      fontSize: '0.875rem',
      fontWeight: '600',
      display: 'inline-flex',
      alignItems: 'center',
      whiteSpace: 'nowrap'
    }}>
      {label || status}
    </span>
  );
};

export default StatusBadge;
