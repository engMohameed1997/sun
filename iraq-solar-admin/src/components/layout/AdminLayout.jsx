import React from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Sidebar from './Sidebar';
import TopBar from './TopBar';

const routeNames = {
  '/': 'لوحة القيادة',
  '/users': 'المستخدمين',
  '/stores': 'المتاجر',
  '/orders': 'الطلبات',
  '/products': 'المنتجات',
  '/banners': 'الإعلانات',
  '/governorates': 'المحافظات',
  '/stats': 'الإحصائيات',
  '/audit': 'سجل التدقيق',
  '/notifications': 'الإشعارات',
  '/settings': 'الإعدادات',
};

const AdminLayout = () => {
  const location = useLocation();
  const title = routeNames[location.pathname] || 'لوحة التحكم';

  return (
    <div className="app-container">
      <Sidebar />
      <div className="main-content">
        <TopBar title={title} />
        <main className="page-container">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;
