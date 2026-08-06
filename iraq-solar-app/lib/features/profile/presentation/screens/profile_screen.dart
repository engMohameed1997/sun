import 'package:flutter/material.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/auth_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/screens/main_navigation_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_calculations_screen.dart';
import 'my_orders_history_screen.dart';
import '../../../workforce/customer/service_orders_list_screen.dart';
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
  String _userPhone = '';
  int _ordersCount = 0;
  int _savedCount = 0;
  int _favStoresCount = 0;
  bool _isLoading = true;
  bool _isLoggedIn = false;

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
      // 1. Fetch User Profile
      final res = await ApiClient.getUserProfile();
      if (res['success'] == true && res['data'] != null && mounted) {
        final data = res['data'];
        setState(() {
          _userName = data['full_name'] ?? _userName;
          _userPhone = data['phone'] ?? _userPhone;
          _userRole = data['role'] == 'engineer' ? 'مهندس' : (data['role'] == 'installer' ? 'فني' : 'زبون معتمد');
        });
      }

      // 2. Fetch User Orders Count
      final ordersRes = await ApiClient.getUserOrders(token);
      if (ordersRes['success'] == true && ordersRes['data'] is List && mounted) {
        final ordersList = ordersRes['data'] as List;
        setState(() {
          _ordersCount = ordersList.length;
        });
      }

      // 3. Fetch Saved Calculations Count
      final calcsRes = await ApiClient.getSavedCalculations();
      if (calcsRes['success'] == true && calcsRes['data'] is List && mounted) {
        final calcsList = calcsRes['data'] as List;
        setState(() {
          _savedCount = calcsList.length;
        });
      }

      // 4. Fetch Active Stores Count
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
          content: const Text('هل أنت أؤكد رغبتك في تسجيل الخروج من تطبيق العراق سولار؟'),
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
                AppNotification.showInfo(context, 'تم تسجيل الخروج بنجاح ');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                  (route) => false,
                );
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
              // User Card Header / Guest Banner
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
                              if (_userPhone.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(_userPhone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_isLoggedIn ? 'نوع الحساب: $_userRole' : 'وضع الزائر (Guest)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        if (_isLoggedIn)
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
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
                    if (_isLoggedIn) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),

                      // Quick Stats Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('$_savedCount', 'التصاميم المحفوظة'),
                          _buildStatItem('$_ordersCount', 'سجل الطلبات'),
                          _buildStatItem('$_favStoresCount', 'المتاجر المفضلة'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Account Menu List
              _buildMenuItem(
                Icons.person_outline_rounded,
                'تعديل البيانات الشخصية والعنوان',
                'اسم المستخدم، الهواتف والمحافظة',
                () async {
                  final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لتعديل وحفظ بياناتك الشخصية وعنوان التوصيل.');
                  if (isAuth && mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  }
                },
              ),
              _buildMenuItem(
                Icons.calculate_outlined,
                'الحسابات والتصاميم المحفوظة',
                'سجل حجم المنظومات والتوفير ROI',
                () async {
                  final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لاستعراض تصاميم المنظومات الشمسية المحفوظة في حسابك.');
                  if (isAuth && mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedCalculationsScreen())).then((_) => _loadProfile());
                  }
                },
              ),
              _buildMenuItem(
                Icons.handyman_outlined,
                'طلبات الخدمات والفنيين',
                'متابعة حالة التركيب، الصيانة، وتعيين الفنيين',
                () async {
                  final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لمتابعة طلبات الخدمات والفنيين.');
                  if (isAuth && mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceOrdersListScreen())).then((_) => _loadProfile());
                  }
                },
              ),
              _buildMenuItem(
                Icons.shopping_bag_outlined,
                'طلبات المنتجات والمشتريات',
                'متابعة حالة الشحن والتوصيل للألواح والمعدات',
                () async {
                  final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لمتابعة طلبات الشراء والتوصيل.');
                  if (isAuth && mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersHistoryScreen())).then((_) => _loadProfile());
                  }
                },
              ),
              _buildMenuItem(
                Icons.storefront_outlined,
                'المتاجر المعتمدة المفضلة',
                'متابعة تجار الطاقة والمجهزين',
                () async {
                  final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول لمتابعة المتاجر المفضلة لديك وتلقي العروض.');
                  if (isAuth && mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteStoresScreen()));
                  }
                },
              ),
              _buildMenuItem(
                Icons.security_outlined,
                'الأمان وكلمة المرور والحماية',
                'بصمة الإصبع 2FA وتشفير الجلسة',
                () async {
                  final isAuth = await AuthGuard.requireAuth(context, reasonMessage: 'يرجى تسجيل الدخول للوصول لإعدادات الأمان وحماية الحساب.');
                  if (isAuth && mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
                  }
                },
              ),
              _buildMenuItem(
                Icons.headset_mic_outlined,
                'الدعم الفني والخدمة الهندسة',
                'المحادثة المباشرة والأسئلة الشائعة',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportHelpScreen())),
              ),
              if (_isLoggedIn) ...[
                const SizedBox(height: 10),
                _buildMenuItem(
                  Icons.logout_rounded,
                  'تسجيل الخروج من الحساب',
                  'إغلاق الجلسة بشكل آمن',
                  _confirmLogout,
                  isDestructive: true,
                ),
              ],
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
