import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Users, Store, ShoppingCart, Package, Image as ImageIcon, MapPin, BarChart3, Shield, Bell, Settings } from 'lucide-react';
import './Sidebar.css';

const navItems = [
  { path: '/', icon: <LayoutDashboard size={20} />, label: 'لوحة القيادة' },
  { path: '/users', icon: <Users size={20} />, label: 'المستخدمين' },
  { path: '/stores', icon: <Store size={20} />, label: 'المتاجر' },
  { path: '/orders', icon: <ShoppingCart size={20} />, label: 'الطلبات' },
  { path: '/products', icon: <Package size={20} />, label: 'المنتجات' },
  { path: '/banners', icon: <ImageIcon size={20} />, label: 'الإعلانات' },
  { path: '/governorates', icon: <MapPin size={20} />, label: 'المحافظات' },
  { path: '/stats', icon: <BarChart3 size={20} />, label: 'الإحصائيات' },
  { path: '/audit', icon: <Shield size={20} />, label: 'سجل التدقيق' },
  { path: '/notifications', icon: <Bell size={20} />, label: 'الإشعارات' },
  { path: '/settings', icon: <Settings size={20} />, label: 'الإعدادات' },
];

const Sidebar = () => {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <h2>شمسي العراق</h2>
        <p>لوحة التحكم</p>
      </div>
      <nav className="sidebar-nav">
        <ul>
          {navItems.map((item) => (
            <li key={item.path}>
              <NavLink 
                to={item.path} 
                className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}
              >
                {item.icon}
                <span>{item.label}</span>
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>
    </aside>
  );
};

export default Sidebar;
