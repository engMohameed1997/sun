import React from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './context/AuthContext';
import { useAuth } from './hooks/useAuth';

import AdminLayout from './components/layout/AdminLayout';

import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UsersPage from './pages/users/UsersPage';
import UserDetailPage from './pages/users/UserDetailPage';
import AddUserPage from './pages/users/AddUserPage';
import StoresPage from './pages/stores/StoresPage';
import AddStorePage from './pages/stores/AddStorePage';
import OrdersPage from './pages/orders/OrdersPage';
import OrderDetailPage from './pages/orders/OrderDetailPage';
import ProductsPage from './pages/products/ProductsPage';
import BannersPage from './pages/banners/BannersPage';
import BannerFormPage from './pages/banners/BannerFormPage';
import GovernoratesPage from './pages/governorates/GovernoratesPage';
import StatsPage from './pages/StatsPage';
import AuditLogPage from './pages/AuditLogPage';
import NotificationsPage from './pages/NotificationsPage';
import SettingsPage from './pages/SettingsPage';

const ProtectedRoute = () => {
  const { isAuthenticated, loading } = useAuth();
  if (loading) return <div className="flex h-screen items-center justify-center">جاري التحميل...</div>;
  return isAuthenticated ? <Outlet /> : <Navigate to="/login" replace />;
};

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Toaster position="top-center" rtl={true} />
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<ProtectedRoute />}>
            <Route element={<AdminLayout />}>
              <Route path="/" element={<DashboardPage />} />
              {/* Users */}
              <Route path="/users" element={<UsersPage />} />
              <Route path="/users/add" element={<AddUserPage />} />
              <Route path="/users/edit/:id" element={<AddUserPage />} />
              <Route path="/users/:id" element={<UserDetailPage />} />
              {/* Stores (Merchants) */}
              <Route path="/stores" element={<StoresPage />} />
              <Route path="/stores/add" element={<AddStorePage />} />
              <Route path="/stores/edit/:id" element={<AddStorePage />} />
              {/* Orders */}
              <Route path="/orders" element={<OrdersPage />} />
              <Route path="/orders/:id" element={<OrderDetailPage />} />
              {/* Products */}
              <Route path="/products" element={<ProductsPage />} />
              {/* Banners */}
              <Route path="/banners" element={<BannersPage />} />
              <Route path="/banners/new" element={<BannerFormPage />} />
              <Route path="/banners/:id/edit" element={<BannerFormPage />} />
              {/* Other */}
              <Route path="/governorates" element={<GovernoratesPage />} />
              <Route path="/stats" element={<StatsPage />} />
              <Route path="/audit" element={<AuditLogPage />} />
              <Route path="/notifications" element={<NotificationsPage />} />
              <Route path="/settings" element={<SettingsPage />} />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
