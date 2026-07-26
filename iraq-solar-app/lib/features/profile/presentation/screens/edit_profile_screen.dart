import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'أحمد علي العبيدي');
  final _emailController = TextEditingController(text: 'ahmed.engineer@iraqsolar.iq');
  final _phoneController = TextEditingController(text: '07701234567');
  final _addressController = TextEditingController(text: 'بغداد - المنصور محلة 609');
  String _selectedCity = 'بغداد';
  String _preferredSystem = 'منظومة هجينة Hybrid 10 kW';
  bool _isLoading = false;

  final List<String> _cities = ['بغداد', 'البصرة', 'أربيل', 'النجف الأشرف', 'كربلاء المقدسة', 'الموصل', 'السليمانية', 'بابل'];

  void _saveProfile() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotification.showSuccess(context, 'تم تحديث بيانات الملف الشخصي بنجاح 👤');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('تعديل البيانات الشخصية'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar edit
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.darkNavy,
                        border: Border.all(color: AppTheme.primaryGold, width: 3),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 50),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppTheme.primaryGold, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Inputs Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'الاسم الثلاثي الكامل', prefixIcon: Icon(Icons.person_outline, color: AppTheme.darkNavy)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_outlined, color: AppTheme.darkNavy)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'رقم الهاتف (العراق)', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.darkNavy)),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: const InputDecoration(labelText: 'المحافظة الحالية', prefixIcon: Icon(Icons.location_city_outlined, color: AppTheme.darkNavy)),
                      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCity = val!),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'عنوان السكن الميداني التفصيلي', prefixIcon: Icon(Icons.home_outlined, color: AppTheme.darkNavy)),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _preferredSystem,
                      decoration: const InputDecoration(labelText: 'نوع المنظومة الشمسية المستهدفة', prefixIcon: Icon(Icons.solar_power_outlined, color: AppTheme.darkNavy)),
                      items: const [
                        DropdownMenuItem(value: 'منظومة هجينة Hybrid 10 kW', child: Text('منظومة هجينة Hybrid 10 kW')),
                        DropdownMenuItem(value: 'منظومة هجينة Hybrid 5 kW', child: Text('منظومة هجينة Hybrid 5 kW')),
                        DropdownMenuItem(value: 'منظومة مستقلة Off-Grid 15 kW', child: Text('منظومة مستقلة Off-Grid 15 kW')),
                        DropdownMenuItem(value: 'حساب مستثمر / تاجر', child: Text('حساب مستثمر / تاجر')),
                      ],
                      onChanged: (val) => setState(() => _preferredSystem = val!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save_rounded, color: Colors.white),
                        label: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('حفظ البيانات الشخصية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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
