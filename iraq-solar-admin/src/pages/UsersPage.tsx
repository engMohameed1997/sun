import React, { useState, useEffect } from 'react';
import { Users, Plus, Search } from 'lucide-react';
import { api } from '../services/api';
import type { User, Role } from '../types';

export const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [roleFilter, setRoleFilter] = useState('');
  const [search, setSearch] = useState('');
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Form State
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<Role>('engineer');
  const [governorate] = useState('بغداد');
  const [city] = useState('');

  const fetchUsers = async () => {
    try {
      const res = await api.get(`/admin/users?role=${roleFilter}&search=${search}`);
      if (res.data?.data?.users) {
        setUsers(res.data.data.users);
      }
    } catch (err) {
      console.error('Failed to fetch users', err);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [roleFilter]);

  const handleToggleActive = async (id: string, currentActive: boolean) => {
    try {
      await api.put(`/admin/users/${id}/status`, { is_active: !currentActive });
      fetchUsers();
    } catch (err) {
      alert('حدث خطأ أثناء تغيير حالة المستخدم');
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.post('/admin/users', {
        full_name: fullName,
        phone,
        password,
        role,
        governorate,
        city,
      });
      setIsModalOpen(false);
      fetchUsers();
    } catch (err: any) {
      const msg = err.response?.data?.message || err.response?.data?.error || 'فشل إضافة المستخدم';
      alert(msg);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 p-5 rounded-2xl">
        <div>
          <h1 className="text-xl font-bold text-slate-100 flex items-center gap-2">
            <Users className="text-amber-400" size={22} />
            إدارة المستخدمين والأدوار
          </h1>
          <p className="text-slate-400 text-xs mt-1">إضافة أدمن، تجار، مهندسين وفنيين، مع التحكم الكامل بالتفعيل والتعطيل</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="relative">
            <input
              type="text"
              placeholder="بحث بالاسم أو رقم الهاتف..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchUsers()}
              className="bg-slate-950/80 border border-slate-800 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
            />
            <Search size={15} className="absolute left-3 top-2.5 text-slate-500" />
          </div>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="bg-slate-950/80 border border-slate-800 rounded-xl px-3.5 py-2 text-xs text-slate-200 focus:outline-none focus:border-amber-500"
          >
            <option value="">كافة الأدوار</option>
            <option value="admin">أدمن</option>
            <option value="merchant">تاجر</option>
            <option value="engineer">مهندس</option>
            <option value="installer">فني تركيب</option>
            <option value="customer">زبون</option>
          </select>

          <button
            onClick={() => setIsModalOpen(true)}
            className="bg-gradient-to-r from-amber-500 to-amber-600 text-slate-950 font-bold px-4 py-2 rounded-xl text-xs flex items-center gap-1.5 shadow-lg shadow-amber-500/20"
          >
            <Plus size={16} /> إضافة حساب جديد
          </button>
        </div>
      </div>

      <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden shadow-xl">
        <table className="w-full text-right text-xs">
          <thead className="bg-slate-950/60 text-slate-400 border-b border-slate-800">
            <tr>
              <th className="p-4 font-semibold">المستخدم</th>
              <th className="p-4 font-semibold">الدور</th>
              <th className="p-4 font-semibold">المحافظة والمدينة</th>
              <th className="p-4 font-semibold">التواصل</th>
              <th className="p-4 font-semibold">الحالة</th>
              <th className="p-4 font-semibold text-center">الإجراءات</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60 text-slate-200">
            {users.map((u) => (
              <tr key={u.id} className="hover:bg-slate-800/40 transition">
                <td className="p-4 font-bold text-slate-100">{u.full_name}</td>
                <td className="p-4">
                  <span className="bg-slate-800 border border-slate-700 text-amber-400 px-2.5 py-1 rounded-full font-semibold capitalize">
                    {u.role}
                  </span>
                </td>
                <td className="p-4 text-slate-400">{u.governorate} - {u.city}</td>
                <td className="p-4 font-mono text-slate-300">{u.phone}</td>
                <td className="p-4">
                  {u.is_active ? (
                    <span className="text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">نشط</span>
                  ) : (
                    <span className="text-rose-400 bg-rose-500/10 px-2 py-0.5 rounded-full border border-rose-500/20">معطل</span>
                  )}
                </td>
                <td className="p-4 text-center">
                  <button
                    onClick={() => handleToggleActive(u.id, u.is_active)}
                    className={`px-3 py-1 rounded-lg font-bold transition ${u.is_active ? 'bg-rose-500/10 text-rose-400 border border-rose-500/30' : 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                      }`}
                  >
                    {u.is_active ? 'تعطيل الحساب' : 'تفعيل'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-slate-950/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl max-w-md w-full p-6 space-y-4 text-xs">
            <h3 className="text-lg font-bold text-slate-100">إضافة حساب مستخدم جديد</h3>
            <form onSubmit={handleCreateUser} className="space-y-3">
              <div>
                <label className="block text-slate-400 mb-1">الاسم الكامل</label>
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                />
              </div>
              <div>
                <label className="block text-slate-400 mb-1">رقم الهاتف</label>
                <input
                  type="text"
                  required
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">كلمة المرور</label>
                <input
                  type="password"
                  required
                  minLength={6}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1">الدور والصلاحية</label>
                <select
                  value={role}
                  onChange={(e) => setRole(e.target.value as Role)}
                  className="w-full bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-slate-100"
                >
                  <option value="admin">أدمن تحكم كامل</option>
                  <option value="merchant">تاجر معتمد</option>
                  <option value="engineer">مهندس طاقة</option>
                  <option value="installer">فني تركيبات</option>
                </select>
              </div>

              <div className="flex justify-end gap-2 pt-3 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 text-slate-300 rounded-xl font-bold"
                >
                  إلغاء
                </button>
                <button type="submit" className="px-5 py-2 bg-amber-500 text-slate-950 rounded-xl font-bold">
                  إضافة الحساب
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
