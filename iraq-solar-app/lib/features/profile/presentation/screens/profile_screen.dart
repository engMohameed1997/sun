import 'package:flutter/material.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import 'edit_profile_screen.dart';
import 'saved_calculations_screen.dart';
import 'my_orders_history_screen.dart';
import 'favorite_stores_screen.dart';
import 'security_settings_screen.dart';
import 'support_help_screen.dart';
import '../../../../core/network/api_client.dart';

class SolarProfileScreen extends StatefulWidget {
  const SolarProfileScreen({Key? key}) : super(key: key);

  @override
  State<SolarProfileScreen> createState() => _SolarProfileScreenState();
}

class _SolarProfileScreenState extends State<SolarProfileScreen> {
  String _userRole = 'زبون معتمد';
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthStorageService.getUser();
    if (user != null && mounted) {
      setState(() {
        _userName = user['full_name'] ?? '';
        _userEmail = user['email'] ?? '';
        _userRole = user['role'] == 'engineer' ? 'مهندس' : (user['role'] == 'installer' ? 'فني' : 'زبون معتمد');
        _isLoading = false;
      });
    }

    final res = await ApiClient.getUserProfile();
    if (res['success'] == true && res['data'] != null && mounted) {
      final data = res['data'];
      setState(() {
        _userName = data['full_name'] ?? _userName;
        _userEmail = data['email'] ?? _userEmail;
        _userRole = data['role'] == 'engineer' ? 'مهندس' : (data['role'] == 'installer' ? 'فني' : 'زبون معتمد');
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
          content: const Text('هل أنت أؤكد رغبتك في تسجيل الخروج من تطبيق العراق سولار؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthStorageService.logout();
                if (!mounted) return;
                Navigator.pop(ctx);
                AppNotification.showInfo(context, 'تم تسجيل الخروج بنجاح 👋');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('إدارة الحساب والملف الشخصي'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User Card Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkNavy,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.darkNavy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(_userEmail, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('نوع الحساب: $_userRole', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),

                    // Quick Stats Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('-', 'التصاميم المحفوظة'),
                        _buildStatItem('-', 'سجل الطلبات'),
                        _buildStatItem('-', 'المتاجر المفضلة'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Account Menu List
              _buildMenuItem(
                Icons.person_outline_rounded,
                'تعديل البيانات الشخصية والعنوان',
                'اسم المستخدم، الهواتف والمحافظة',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              ),
              _buildMenuItem(
                Icons.calculate_outlined,
                'الحسابات والتصاميم المحفوظة',
                'سجل حجم المنظومات والتوفير ROI',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCalculationsScreen())),
              ),
              _buildMenuItem(
                Icons.shopping_bag_outlined,
                'سجل الطلبات والمنظومات',
                'متابعة حالة التوصيل والتشغيل الميداني',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersHistoryScreen())),
              ),
              _buildMenuItem(
                Icons.storefront_outlined,
                'المتاجر المعتمدة المفضلة',
                'متابعة تجار الطاقة والمجهزين',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteStoresScreen())),
              ),
              _buildMenuItem(
                Icons.security_outlined,
                'الأمان وكلمة المرور والحماية',
                'بصمة الإصبع 2FA وتشفير الجلسة',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen())),
              ),
              _buildMenuItem(
                Icons.headset_mic_outlined,
                'الدعم الفني والخدمة الهندسة',
                'المحادثة المباشرة والأسئلة الشائعة',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportHelpScreen())),
              ),
              const SizedBox(height: 10),
              _buildMenuItem(
                Icons.logout_rounded,
                'تسجيل الخروج من الحساب',
                'إغلاق الجلسة بشكل آمن',
                _confirmLogout,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border.all(color: isDestructive ? Colors.red.withOpacity(0.2) : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.shade50 : AppTheme.darkNavy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: isDestructive ? Colors.red : AppTheme.darkNavy, size: 22),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDestructive ? Colors.red : AppTheme.darkNavy)),
          subtitle: Text(subtitle, style: TextStyle(color: isDestructive ? Colors.red.shade300 : Colors.grey.shade600, fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}
