import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class SolarLoginScreen extends StatefulWidget {
  const SolarLoginScreen({Key? key}) : super(key: key);

  @override
  State<SolarLoginScreen> createState() => _SolarLoginScreenState();
}

class _SolarLoginScreenState extends State<SolarLoginScreen> {
  final _emailController = TextEditingController(text: 'ahmed.engineer@iraqsolar.iq');
  final _passwordController = TextEditingController(text: 'SecurePass123!');
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppNotification.showError(context, 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiClient.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

import '../../../../core/services/auth_storage.dart';

    if (res['success'] == true) {
      if (res['token'] != null) {
        await AuthStorageService.saveToken(res['token'].toString());
      }
      if (res['user'] != null && res['user'] is Map<String, dynamic>) {
        await AuthStorageService.saveUser(res['user']);
      }
      AppNotification.showSuccess(context, res['message'] ?? 'تم تسجيل الدخول بنجاح 🎉');
      Navigator.of(context).pop();
    } else {
      AppNotification.showError(context, res['message'] ?? 'فشل تسجيل الدخول');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.darkNavy,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
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
                const Center(
                  child: Text(
                    'سجل الدخول لإدارة منظوماتك وحسابات الأحمال',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 40),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('البريد الإلكتروني:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'user@iraqsolar.iq',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('كلمة المرور:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
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
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('تسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
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
