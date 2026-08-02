import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/network/api_client.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _biometricEnabled = true;
  bool _twoFactorEnabled = true;
  bool _isLoading = false;

  void _changePassword() async {
    if (_oldPassController.text.isEmpty) {
      AppNotification.showError(context, 'يرجى كتابة كلمة المرور الحالية');
      return;
    }
    if (_newPassController.text.isEmpty) {
      AppNotification.showError(context, 'يرجى كتابة كلمة المرور الجديدة');
      return;
    }
    if (_newPassController.text.length < 6) {
      AppNotification.showError(context, 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل');
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      AppNotification.showError(context, 'كلمة المرور الجديدة غير متطابقة');
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiClient.changePassword(
      oldPassword: _oldPassController.text,
      newPassword: _newPassController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (res['success'] == true) {
        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        AppNotification.showSuccess(context, 'تم تغيير كلمة المرور بنجاح 🔒');
      } else {
        AppNotification.showError(context, res['message'] ?? 'فشل تغيير كلمة المرور');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('الأمان وتأمين الحساب'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Toggle Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('التوثيق بالبصمة / FaceID', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      subtitle: const Text('دخول سريع وآمن للتطبيق باستخدام بصمة الأصبع أو الوجه'),
                      value: _biometricEnabled,
                      activeColor: AppTheme.primaryGold,
                      onChanged: (val) {
                        setState(() => _biometricEnabled = val);
                        AppNotification.showInfo(context, val ? 'تم تفعيل دخول البصمة' : 'تم إلغاء تفعيل البصمة');
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('التحقق بخطوتين (2FA)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      subtitle: const Text('إرسال رمز تحقق للواتساب أو SMS عند تسجيل الدخول'),
                      value: _twoFactorEnabled,
                      activeColor: AppTheme.primaryGold,
                      onChanged: (val) {
                        setState(() => _twoFactorEnabled = val);
                        AppNotification.showInfo(context, val ? 'تم تفعيل التحقق بخطوتين 2FA' : 'تم تعطيل التحقق بخطوتين');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Change Password Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _oldPassController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.darkNavy)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPassController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', prefixIcon: Icon(Icons.lock_reset_rounded, color: AppTheme.darkNavy)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPassController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة', prefixIcon: Icon(Icons.check_circle_outline, color: AppTheme.darkNavy)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('تحديث كلمة المرور وتحديث التشفير', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
