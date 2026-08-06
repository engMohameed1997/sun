import 'package:flutter/material.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/auth_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../products/presentation/screens/promotions_catalog_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_calculations_screen.dart';
import 'my_orders_history_screen.dart';
import 'favorite_stores_screen.dart';
import 'security_settings_screen.dart';
import 'support_help_screen.dart';
import '../../../home/presentation/screens/notifications_screen.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';

class SolarSettingsScreen extends StatefulWidget {
  const SolarSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SolarSettingsScreen> createState() => _SolarSettingsScreenState();
}

class _SolarSettingsScreenState extends State<SolarSettingsScreen> {
  String _userRole = 'زبون معتمد';
  String _userName = '';
  String _userPhone = '';
  int _ordersCount = 0;
  int _savedCount = 0;
  int _favStoresCount = 0;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final isAuth = await AuthStorageService.isLoggedIn();
    final token = await AuthStorageService.getToken();
    final user = await AuthStorageService.getUser();

    if (mounted) {
      setState(() {
        _isLoggedIn = isAuth;
        if (user != null) {
          _userName = user['full_name'] ?? '';
          _userPhone = user['phone'] ?? '';
          _userRole = user['role'] == 'engineer' ? 'مهندس' : (user['role'] == 'installer' ? 'فني' : 'زبون معتمد');
        } else {
          _userName = 'زائر المنظومة الشمسية';
          _userPhone = '';
        }
        _isLoading = false;
      });
    }

    if (isAuth && token != null) {
      final res = await ApiClient.getUserProfile();
      if (res['success'] == true && res['data'] != null && mounted) {
        final data = res['data'];
        setState(() {
          _userName = data['full_name'] ?? _userName;
          _userPhone = data['phone'] ?? _userPhone;
          _userRole = data['role'] == 'engineer' ? 'مهندس' : (data['role'] == 'installer' ? 'فني' : 'زبون معتمد');
        });
      }

      final ordersRes = await ApiClient.getUserOrders(token);
      if (ordersRes['success'] == true && ordersRes['data'] is List && mounted) {
        final ordersList = ordersRes['data'] as List;
        setState(() {
          _ordersCount = ordersList.length;
        });
      }

      final calcsRes = await ApiClient.getSavedCalculations();
      if (calcsRes['success'] == true && calcsRes['data'] is List && mounted) {
        final calcsList = calcsRes['data'] as List;
        setState(() {
          _savedCount = calcsList.length;
        });
      }

      final storesRes = await ApiClient.getStores();
      if (storesRes['success'] == true && storesRes['data'] is List && mounted) {
        final storesList = storesRes['data'] as List;
        setState(() {
          _favStoresCount = storesList.length;
        });
      }
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
          content: const Text('هل أنت تأكد رغبتك في تسجيل الخروج من تطبيق العراق سولار؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                WebSocketService.instance.disconnect();
                WebSocketService.instance.resetUnread();
                await AuthStorageService.logout();
                if (!mounted) return;
                Navigator.pop(ctx);
                AppNotification.showInfo(context, 'تم تسجيل الخروج بنجاح');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
          title: const Text('الإعدادات والحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: AppTheme.darkNavy,
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. User Account Header ---
              _buildAccountHeader(),

              const SizedBox(height: 24),

              // --- 2. Discounts & Special Offers Section (قسم العروض والخصومات) ---
              _buildSectionHeader('العروض والخصومات الكبرى 🏷️'),
              const SizedBox(height: 8),
              _buildSettingsTile(
                icon: Icons.local_offer_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'كتالوج العروض والتخفيضات المميزة',
                subtitle: 'خصومات المنظومات، الألواح، والبطاريات المتاحة حالياً',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PromotionsCatalogScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // --- 3. Profile & Orders Section (إدارة الحساب والملف الشخصي) ---
              _buildSectionHeader('إدارة الملف الشخصي والحساب 👤'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTileItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppTheme.primaryGold,
                      title: 'بيانات الملف الشخصي والعنوان',
                      subtitle: 'تعديل الاسم، رقم الهاتف، والمحافظة',
                      onTap: () async {
                        final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لتعديل بياناتك الشخصية وعنوان التوصيل.');
                        if (isAuth && mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => _loadProfile());
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _buildSettingsTileItem(
                      icon: Icons.shopping_bag_outlined,
                      iconColor: AppTheme.darkNavy,
                      title: 'سجل الطلبات والمنظومات',
                      subtitle: 'متابعة حالات الشراء والتوصيل والتركيب',
                      onTap: () async {
                        final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لمتابعة سجل طلباتك.');
                        if (isAuth && mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersHistoryScreen())).then((_) => _loadProfile());
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _buildSettingsTileItem(
                      icon: Icons.bookmark_outline_rounded,
                      iconColor: Colors.purpleAccent,
                      title: 'التصاميم والحسابات المحفوظة',
                      subtitle: 'سجل حسابات القدرة والأحمال الشمسية',
                      onTap: () async {
                        final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول للوصول للحسابات والتصاميم المحفوظة.');
                        if (isAuth && mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCalculationsScreen())).then((_) => _loadProfile());
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _buildSettingsTileItem(
                      icon: Icons.storefront_outlined,
                      iconColor: Colors.orangeAccent,
                      title: 'المتاجر المعتمدة المفضلة',
                      subtitle: 'قائمة التجار والشركات المفضلة لديك',
                      onTap: () async {
                        final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لمتابعة المتاجر المفضلة لديك.');
                        if (isAuth && mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteStoresScreen()));
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 4. App Settings & Security Section (إعدادات التطبيق والأمان) ---
              _buildSectionHeader('إعدادات التطبيق والأمان ⚙️'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTileItem(
                      icon: Icons.security_outlined,
                      iconColor: Colors.teal,
                      title: 'الأمان وكلمة المرور',
                      subtitle: 'حماية الحساب، تغيير كلمة السر وتشفير الجلسات',
                      onTap: () async {
                        final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لإصدار إعدادات الأمان.');
                        if (isAuth && mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _buildSettingsTileItem(
                      icon: Icons.notifications_none_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'إشعارات التطبيق والعروض',
                      subtitle: 'مركز الإشعارات والتنبيهات المباشرة',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      },
                    ),
                    const Divider(height: 1, indent: 56, endIndent: 16),
                    _buildSettingsTileItem(
                      icon: Icons.headset_mic_outlined,
                      iconColor: Colors.indigoAccent,
                      title: 'الدعم الفني والخدمة الهندسة',
                      subtitle: 'تواصل مباشر مع مهندسي العراق سولار',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportHelpScreen()));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 5. Logout Button (تسجيل الخروج) ---
              if (_isLoggedIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text('تسجيل الخروج من الحساب', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // App Version Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'منصة العراق سولار - Super Qi',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الإصدار v2.4.0 • جميع الحقوق محفوظة',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.darkNavy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_userPhone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(_userPhone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isLoggedIn ? 'نوع الحساب: $_userRole' : 'وضع الزائر (Guest)',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => _loadProfile());
                  },
                ),
            ],
          ),
          if (!_isLoggedIn) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final loginSuccess = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const SolarLoginScreen()),
                );
                if (loginSuccess == true) {
                  _loadProfile();
                }
              },
              icon: const Icon(Icons.login_rounded, color: Colors.white),
              label: const Text('تسجيل الدخول / إنشاء حساب جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSettingsTileItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.grey),
      ),
    );
  }
}
