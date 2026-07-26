export const API_BASE_URL = '/api/v1';

export const ROLE_NAMES = {
  admin: 'مدير النظام',
  merchant: 'متجر',
  engineer: 'مهندس',
  installer: 'فني تركيب',
  customer: 'عميل'
};

export const ORDER_STATUSES = {
  pending: 'قيد الانتظار',
  confirmed: 'مؤكد',
  processing: 'قيد التجهيز',
  completed: 'مكتمل',
  cancelled: 'ملغى'
};

export const PRODUCT_TYPES = {
  panel: 'ألواح شمسية',
  inverter: 'انفرتر',
  battery: 'بطارية',
  structure: 'هياكل تثبيت',
  cable: 'كوابل',
  accessory: 'ملحقات'
};

export const PAYMENT_METHODS = {
  cash_on_delivery: 'دفع عند الاستلام',
  zain_cash: 'زين كاش',
  qi_card: 'كي كارد'
};

export const PAYMENT_STATUSES = {
  unpaid: 'غير مدفوع',
  paid: 'مدفوع',
  failed: 'فشل الدفع',
  refunded: 'مسترد'
};
