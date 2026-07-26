import React from 'react';
import { Search, Bell, LogOut, User } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import './TopBar.css';

const TopBar = ({ title }) => {
  const { user, logout } = useAuth();

  return (
    <header className="topbar glass">
      <div className="topbar-left">
        <h1 className="page-title">{title || 'لوحة التحكم'}</h1>
      </div>
      
      <div className="topbar-right">
        <div className="search-box">
          <Search size={18} className="search-icon" />
          <input type="text" placeholder="بحث سريع..." className="search-input" />
        </div>
        
        <button className="icon-btn notification-btn">
          <Bell size={20} />
          <span className="badge-dot"></span>
        </button>
        
        <div className="user-profile">
          <div className="avatar">
            <User size={20} />
          </div>
          <div className="user-info">
            <span className="user-name">{user?.name || 'مدير النظام'}</span>
            <span className="user-role">المدير العام</span>
          </div>
          <button className="icon-btn logout-btn" onClick={logout} title="تسجيل الخروج">
            <LogOut size={20} />
          </button>
        </div>
      </div>
    </header>
  );
};

export default TopBar;
