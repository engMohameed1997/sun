import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class SolarRegisterScreen extends StatefulWidget {
  const SolarRegisterScreen({Key? key}) : super(key: key);

  @override
  State<SolarRegisterScreen> createState() => _SolarRegisterScreenState();
}

class _SolarRegisterScreenState extends State<SolarRegisterScreen> {
  final String _selectedRole = 'customer';
  final _nameController = TextEditingController(text: 'أحمد علي العبيدي');
  final _emailController = TextEditingController(text: 'ahmed.engineer@iraqsolar.iq');
  final _phoneController = TextEditingController(text: '07701234567');
  final _passwordController = TextEditingController(text: 'SecurePass123!');
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      AppNotification.showError(context, 'يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    setState(() => _isLoading = true);

    final res = await ApiClient.registerUser(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      if (res['token'] != null) {
        await AuthStorageService.saveToken(res['token'].toString());
      }
      if (res['user'] != null && res['user'] is Map<String, dynamic>) {
        await AuthStorageService.saveUser(res['user']);
      }
      AppNotification.showSuccess(context, res['message'] ?? 'تم إنشاء الحساب وتسجيل التوكن بنجاح 🎉');
      Navigator.of(context).pop();
    } else {
      AppNotification.showError(context, res['message'] ?? 'فشل إنشاء الحساب');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.darkNavy,
        appBar: AppBar(
          title: const Text('تسجيل حساب جديد'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الاسم الكامل:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'أحمد علي العبيدي',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('البريد الإلكتروني:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'ahmed@iraqsolar.iq',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('رقم الهاتف العراقي:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '07701234567',
                        prefixIcon: Icon(Icons.phone_rounded, color: AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('كلمة المرور:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('إنشاء الحساب وتوليد التوكن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
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
}
