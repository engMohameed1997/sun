import React, { createContext, useContext, useState, useEffect } from 'react';
import type { User, Permission, Role } from '../types';
import { api } from '../services/api';

const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  admin: [
    'users.manage',
    'orders.manage',
    'products.manage',
    'products.own',
    'banners.manage',
    'stores.verify',
    'delivery.manage',
    'settings.manage',
    'stats.view',
    'audit.view',
  ],
  merchant: ['products.own'],
  customer: [],
  engineer: [],
  installer: [],
};

interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (token: string, user: User) => void;
  logout: () => void;
  hasPermission: (perm: Permission) => boolean;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(() => {
    const saved = localStorage.getItem('iraq_solar_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('iraq_solar_token'));
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    if (token && !user) {
      api.get('/user/profile')
        .then((res) => {
          const u = res.data;
          setUser(u);
          localStorage.setItem('iraq_solar_user', JSON.stringify(u));
        })
        .catch(() => {
          logout();
        })
        .finally(() => setIsLoading(false));
    } else {
      setIsLoading(false);
    }
  }, [token]);

  const login = (newToken: string, newUser: User) => {
    setToken(newToken);
    setUser(newUser);
    localStorage.setItem('iraq_solar_token', newToken);
    localStorage.setItem('iraq_solar_user', JSON.stringify(newUser));
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    localStorage.removeItem('iraq_solar_token');
    localStorage.removeItem('iraq_solar_user');
  };

  const hasPermission = (perm: Permission): boolean => {
    if (!user) return false;
    const userRole = user.role;
    const perms = ROLE_PERMISSIONS[userRole] || [];
    return perms.includes(perm);
  };

  return (
    <AuthContext.Provider value={{ user, token, login, logout, hasPermission, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
