import { format } from 'date-fns';
import { ar } from 'date-fns/locale';
import { ROLE_NAMES, ORDER_STATUSES, PRODUCT_TYPES, PAYMENT_METHODS, PAYMENT_STATUSES } from './constants';

export const formatIQD = (amount) => {
  if (amount === null || amount === undefined) return '0 دينار';
  return new Intl.NumberFormat('ar-IQ').format(amount) + ' دينار';
};

export const formatDate = (dateString) => {
  if (!dateString) return '';
  return format(new Date(dateString), 'dd/MM/yyyy', { locale: ar });
};

export const formatDateTime = (dateString) => {
  if (!dateString) return '';
  return format(new Date(dateString), 'dd/MM/yyyy HH:mm', { locale: ar });
};

export const getStatusColor = (status) => {
  const map = {
    pending: 'badge-pending',
    confirmed: 'badge-confirmed',
    processing: 'badge-processing',
    completed: 'badge-completed',
    cancelled: 'badge-cancelled'
  };
  return map[status] || 'badge-inactive';
};

export const getRoleName = (role) => ROLE_NAMES[role] || role;
export const getStatusName = (status) => ORDER_STATUSES[status] || status;

export const getPlaceholderImage = (text = 'صورة إعلانية', width = 600, height = 200) => {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
    <rect width="100%" height="100%" fill="#0F172A"/>
    <rect x="10" y="10" width="${width - 20}" height="${height - 20}" fill="none" stroke="#F59E0B" stroke-width="2" stroke-dasharray="6,6" rx="8"/>
    <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="#F59E0B" font-family="sans-serif" font-size="18" font-weight="bold">${text}</text>
  </svg>`;
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
};

export const formatUSD = (amount) => {
  if (amount === null || amount === undefined) return '$0.00';
  return '$' + Number(amount).toFixed(2);
};

export const getProductTypeName = (type) => PRODUCT_TYPES[type] || type;
export const getPaymentMethodName = (method) => PAYMENT_METHODS[method] || method;
export const getPaymentStatusName = (status) => PAYMENT_STATUSES[status] || status;
