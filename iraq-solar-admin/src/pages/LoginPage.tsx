import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Sun, Lock, AlertCircle, ArrowLeft, Phone } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';

export const LoginPage: React.FC = () => {
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const res = await api.post('/auth/login', { Phone, password });
      const { token, user } = res.data.data || res.data;
      if (!['admin', 'merchant'].includes(user.role)) {
        setError('حسابك غير مصرح له بالدخول لـ Admin Dashboard');
        setLoading(false);
        return;
      }
      login(token, user);
      navigate('/');
    } catch (err: any) {
      setError(err.response?.data?.message || err.response?.data?.error || 'فشل تسجيل الدخول. يرجى التأكد من البيانات الحسابية.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4 dir-rtl relative overflow-hidden">
      {/* Background Decorative Glow */}
      <div className="absolute -top-40 -right-40 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -left-40 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-slate-900/90 border border-slate-800 backdrop-blur-xl rounded-2xl p-8 shadow-2xl relative z-10">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-400 mb-4">
            <Sun size={36} />
          </div>
          <h1 className="text-2xl font-bold text-slate-100">Iraq Solar Dashboard</h1>
          <p className="text-slate-400 text-sm mt-1">لوحة التحكم المركزية للأدمن والتجار المعتمَدين</p>
        </div>

        {error && (
          <div className="mb-6 p-4 bg-rose-500/10 border border-rose-500/30 rounded-xl text-rose-400 text-sm flex items-start gap-3">
            <AlertCircle size={18} className="shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-2">كلمة المرور</label>
            <div className="relative">
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-slate-950/70 border border-slate-800 rounded-xl px-4 py-3 pl-10 text-sm text-slate-100 placeholder-slate-600 focus:outline-none focus:border-amber-500 transition"
              />
              <Lock size={18} className="absolute left-3 top-3.5 text-slate-500" />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-slate-950 font-bold py-3.5 px-4 rounded-xl transition flex items-center justify-center gap-2 shadow-lg shadow-amber-500/20 disabled:opacity-50 cursor-pointer"
          >
            {loading ? (
              <span className="inline-block animate-spin font-bold">↻ جارٍ الدخول...</span>
            ) : (
              <>
                <span>تسجيل الدخول</span>
                <ArrowLeft size={18} />
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};
