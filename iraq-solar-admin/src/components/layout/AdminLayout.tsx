import React, { useState, useEffect } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  ShoppingCart,
  Package,
  Layers,
  Star,
  Store,
  Users,
  Image as ImageIcon,
  ShieldCheck,
  Settings,
  LogOut,
  Bell,
  Sun,
  Menu,
  X,
  AlertTriangle
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { api } from '../../services/api';

interface AdminLayoutProps {
  children: React.ReactNode;
}

export const AdminLayout: React.FC<AdminLayoutProps> = ({ children }) => {
  const { user, logout, hasPermission } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [unreadNotifications, setUnreadNotifications] = useState(0);
  const [pendingOrdersCount, setPendingOrdersCount] = useState(0);

  useEffect(() => {
    // Fetch initial stats for pending orders badge
    api.get('/admin/stats').then((res) => {
      if (res.data?.data?.pending_orders) {
        setPendingOrdersCount(res.data.data.pending_orders);
      }
    }).catch(() => {});

    // Fetch real unread notification count from API
    api.get('/notifications/unread-count').then((res) => {
      if (res.data?.data?.unread_count !== undefined) {
        setUnreadNotifications(res.data.data.unread_count);
      }
    }).catch(() => {});
  }, []);

  const navItems = [
    {
      label: 'الرئيسية والإحصائيات',
      path: '/',
      icon: LayoutDashboard,
      perm: 'stats.view' as const,
    },
    {
      label: 'إدارة الطلبات',
      path: '/orders',
      icon: ShoppingCart,
      perm: 'orders.manage' as const,
      badge: pendingOrdersCount > 0 ? pendingOrdersCount : undefined,
    },
    {
      label: 'المنتجات والمخزون',
      path: '/products',
      icon: Package,
      perm: 'products.own' as const,
    },
    {
      label: 'تصنيفات المنتجات',
      path: '/categories',
      icon: Layers,
      perm: 'products.manage' as const,
    },
    {
      label: 'الماركات (Brands)',
      path: '/brands',
      icon: Star,
      perm: 'products.manage' as const,
    },
    {
      label: 'المتاجر والتوثيق',
      path: '/stores',
      icon: Store,
      perm: 'stores.verify' as const,
    },
    {
      label: 'إدارة المستخدمين',
      path: '/users',
      icon: Users,
      perm: 'users.manage' as const,
    },
    {
      label: 'البنرات والمحافظات',
      path: '/banners',
      icon: ImageIcon,
      perm: 'banners.manage' as const,
    },
    {
      label: 'سجل التدقيق والأمان',
      path: '/audit-logs',
      icon: ShieldCheck,
      perm: 'audit.view' as const,
    },
    {
      label: 'إعدادات النظام',
      path: '/settings',
      icon: Settings,
      perm: 'settings.manage' as const,
    },
  ];

  const filteredNavItems = navItems.filter((item) => hasPermission(item.perm));

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col dir-rtl">
      {/* Top Header Bar */}
      <header className="h-16 bg-slate-900 border-b border-slate-800 flex items-center justify-between px-4 sticky top-0 z-40">
        <div className="flex items-center gap-3">
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 md:hidden"
          >
            {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>

          <Link to="/" className="flex items-center gap-2.5 font-bold text-lg text-amber-500">
            <div className="w-9 h-9 rounded-xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-500">
              <Sun size={22} className="animate-spin-slow" />
            </div>
            <span className="bg-gradient-to-r from-amber-400 to-amber-200 bg-clip-text text-transparent">
              Iraq Solar Admin
            </span>
          </Link>
        </div>

        <div className="flex items-center gap-4">
          {/* Realtime Notification Bell */}
          <button
            title="الإشعارات اللحظية"
            className="relative p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
          >
            <Bell size={20} />
            {unreadNotifications > 0 && (
              <span className="absolute top-1 right-1 w-5 h-5 bg-rose-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center border-2 border-slate-900 animate-pulse">
                {unreadNotifications}
              </span>
            )}
          </button>

          {/* User Profile info */}
          <div className="flex items-center gap-3 border-r border-slate-800 pr-4">
            <div className="w-8 h-8 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-amber-400 font-bold text-sm">
              {user?.full_name?.charAt(0) || 'أ'}
            </div>
            <div className="hidden sm:block text-xs">
              <div className="font-semibold text-slate-200">{user?.full_name || 'مستخدم'}</div>
              <div className="text-amber-400/90 capitalize font-medium">
                {user?.role === 'admin' ? 'أدمن النظام' : 'تاجر معتمد'}
              </div>
            </div>

            <button
              onClick={handleLogout}
              title="تسجيل الخروج"
              className="p-2 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition"
            >
              <LogOut size={18} />
            </button>
          </div>
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <aside
          className={`fixed inset-y-0 right-0 z-30 w-64 bg-slate-900 border-l border-slate-800 transform transition-transform duration-200 ease-in-out md:static md:translate-x-0 ${
            sidebarOpen ? 'translate-x-0' : 'translate-x-full md:translate-x-0'
          }`}
        >
          <div className="p-4 space-y-1">
            <div className="px-3 py-2 text-[11px] font-semibold text-slate-500 uppercase tracking-wider">
              القائمة الرئيسية
            </div>

            {filteredNavItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;
              return (
                <Link
                  key={item.path}
                  to={item.path}
                  onClick={() => setSidebarOpen(false)}
                  className={`flex items-center justify-between px-3 py-2.5 rounded-xl font-medium text-sm transition ${
                    isActive
                      ? 'bg-amber-500/10 text-amber-400 border border-amber-500/30'
                      : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon size={18} className={isActive ? 'text-amber-400' : 'text-slate-400'} />
                    <span>{item.label}</span>
                  </div>
                  {item.badge !== undefined && (
                    <span className="bg-rose-500/20 text-rose-300 border border-rose-500/30 text-xs px-2 py-0.5 rounded-full font-bold">
                      {item.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </div>

          <div className="absolute bottom-4 left-4 right-4 p-3 rounded-xl bg-slate-800/40 border border-slate-800 text-xs text-slate-400">
            <div className="flex items-center gap-2 text-slate-300 font-medium mb-1">
              <AlertTriangle size={14} className="text-amber-400" />
              حالة النظام
            </div>
            <div>السيرفر: متصل 🟢</div>
            <div>Database: PostgreSQL</div>
          </div>
        </aside>

        {/* Main Content Viewport */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 bg-slate-950">
          {children}
        </main>
      </div>
    </div>
  );
};
