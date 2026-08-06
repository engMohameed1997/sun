import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import 'register_screen.dart';

class SolarLoginScreen extends StatefulWidget {
  const SolarLoginScreen({Key? key}) : super(key: key);

  @override
  State<SolarLoginScreen> createState() => _SolarLoginScreenState();
}

class _SolarLoginScreenState extends State<SolarLoginScreen> {
  final _phoneController = TextEditingController(text: '07700000000');
  final _passwordController = TextEditingController(text: 'SecurePass123!');
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      AppNotification.showError(context, 'يرجى إدخال رقم الهاتف وكلمة المرور');
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiClient.loginUser(
      phone: phone,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final data = (res['data'] != null && res['data'] is Map<String, dynamic>) ? res['data'] : res;
      final token = data['token'] ?? res['token'];
      final refreshToken = data['refresh_token'] ?? res['refresh_token'];
      final user = data['user'] ?? res['user'];

      if (token != null) {
        await AuthStorageService.saveToken(token.toString());
      }
      if (refreshToken != null) {
        await AuthStorageService.saveRefreshToken(refreshToken.toString());
      }
      if (user != null && user is Map<String, dynamic>) {
        await AuthStorageService.saveUser(Map<String, dynamic>.from(user));
      } else {
        await AuthStorageService.saveUser({
          'full_name': 'مستخدم المنظومة الشمسية',
          'phone': phone,
          'role': 'customer',
        });
      }
      await ApiClient.fetchAndSaveUserProfile();
      try {
        WebSocketService.instance.connect();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'تم تسجيل الدخول بنجاح 🎉'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
      }
    } else {
      if (mounted) {
        AppNotification.showError(context, res['message'] ?? 'فشل تسجيل الدخول: رقم الهاتف أو كلمة المرور غير صحيحة');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.darkNavy,
        appBar: AppBar(
          backgroundColor: AppTheme.darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(Icons.wb_sunny_rounded, color: AppTheme.primaryGold, size: 70),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'تطبيق منصة الطاقة الشمسية بالعراق',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'تسجيل الدخول باستخدام رقم الهاتف والرمز الخاص بك',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 32),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('رقم الهاتف / الموبايل:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '07700000000',
                          prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('كلمة المرور / الرمز:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGold),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('ليس لديك حساب بعد؟ ', style: TextStyle(color: Colors.black87, fontSize: 13)),
                          GestureDetector(
                            onTap: () async {
                              final regSuccess = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                              if (regSuccess == true && mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            child: const Text(
                              'إنشاء حساب جديد',
                              style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
