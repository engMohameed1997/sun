import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _landmarkController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoadingGovernorates = true;
  bool _isLoadingDistricts = false;

  int? _selectedGovernorateId;
  int? _selectedDistrictId;

  List<Map<String, dynamic>> _governorates = [];
  List<Map<String, dynamic>> _districts = [];

  @override
  void initState() {
    super.initState();
    _fetchGovernorates();
  }

  Future<void> _fetchGovernorates() async {
    setState(() => _isLoadingGovernorates = true);
    try {
      final res = await ApiClient.getGovernorates();

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null && res['data'] is List) {
        final list = List<Map<String, dynamic>>.from(res['data']);
        setState(() {
          _governorates = list;
          _isLoadingGovernorates = false;
        });
        if (_governorates.isNotEmpty) {
          final firstGovId = _governorates.first['id'] is int
              ? _governorates.first['id'] as int
              : int.parse(_governorates.first['id'].toString());
          _onGovernorateChanged(firstGovId);
        }
      } else {
        setState(() {
          _governorates = [];
          _isLoadingGovernorates = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _governorates = [];
        _isLoadingGovernorates = false;
      });
    }
  }

  Future<void> _onGovernorateChanged(int? govId) async {
    if (govId == null) return;
    setState(() {
      _selectedGovernorateId = govId;
      _selectedDistrictId = null;
      _districts = [];
      _isLoadingDistricts = true;
    });

    try {
      final res = await ApiClient.getDistricts(govId);

      if (!mounted) return;

      setState(() => _isLoadingDistricts = false);

      if (res['success'] == true && res['data'] != null && res['data'] is List) {
        final list = List<Map<String, dynamic>>.from(res['data']);
        setState(() {
          _districts = list;
          if (_districts.isNotEmpty) {
            final firstDistId = _districts.first['id'] is int
                ? _districts.first['id'] as int
                : int.parse(_districts.first['id'].toString());
            _selectedDistrictId = firstDistId;
          } else {
            _selectedDistrictId = null;
          }
        });
      } else {
        setState(() {
          _districts = [];
          _selectedDistrictId = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _districts = [];
        _selectedDistrictId = null;
        _isLoadingDistricts = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final landmark = _landmarkController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty) {
      AppNotification.showError(context, 'يرجى إدخال الاسم الكامل ورقم الهاتف وكلمة المرور');
      return;
    }

    if (_selectedGovernorateId == null) {
      AppNotification.showError(context, 'يرجى اختيار المحافظة');
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic>? govMap;
    for (var g in _governorates) {
      final gId = g['id'] is int ? g['id'] as int : int.parse(g['id'].toString());
      if (gId == _selectedGovernorateId) {
        govMap = g;
        break;
      }
    }

    Map<String, dynamic>? distMap;
    if (_selectedDistrictId != null) {
      for (var d in _districts) {
        final dId = d['id'] is int ? d['id'] as int : int.parse(d['id'].toString());
        if (dId == _selectedDistrictId) {
          distMap = d;
          break;
        }
      }
    }

    final govName = govMap?['name_ar'] ?? '';
    final distName = distMap?['name_ar'] ?? '';

    final res = await ApiClient.registerUser(
      fullName: name,
      phone: phone,
      password: password,
      role: 'customer',
      governorateId: _selectedGovernorateId,
      districtId: _selectedDistrictId,
      governorate: govName,
      city: distName,
      landmark: landmark,
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
          'full_name': name,
          'phone': phone,
          'governorate': govName,
          'city': distName,
          'landmark': landmark,
          'role': 'customer',
        });
      }
      await ApiClient.fetchAndSaveUserProfile();
      if (!mounted) return;
      AppNotification.showSuccess(context, res['message'] ?? 'تم إنشاء الحساب وحفظ الموقع بنجاح 🎉');
      Navigator.of(context).pop(true);
    } else {
      if (!mounted) return;
      AppNotification.showError(context, res['message'] ?? 'فشل إنشاء الحساب: يرجى التأكد من البيانات أو تغيير رقم الهاتف');
    }
  }

  @override
  Widget build(BuildContext context) {
    final validGovValue = _governorates.any((g) => (g['id'] is int ? g['id'] as int : int.parse(g['id'].toString())) == _selectedGovernorateId)
        ? _selectedGovernorateId
        : null;

    final validDistValue = _districts.any((d) => (d['id'] is int ? d['id'] as int : int.parse(d['id'].toString())) == _selectedDistrictId)
        ? _selectedDistrictId
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.darkNavy,
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد '),
          backgroundColor: AppTheme.darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(Icons.location_city_rounded, color: AppTheme.primaryGold, size: 60),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'إنشاء حساب جديد',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'أدخل معلوماتك والمحافظة والقضاء لربط حسابك',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                      // Full Name
                      const Text('الاسم الكامل الثلاثي:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'الاسم الكامل ... ',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Phone Number
                      const Text('رقم الهاتف :', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '07XXXXXXXXXX',
                          prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      const Text('كلمة المرور :', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 16),

                      const Divider(height: 24, thickness: 1),

                      // Governorate Dropdown
                      const Row(
                        children: [
                          Icon(Icons.map_rounded, color: AppTheme.primaryGold, size: 20),
                          SizedBox(width: 6),
                          Text('المحافظة:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingGovernorates)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: validGovValue,
                          isExpanded: true,
                          hint: const Text('اختر المحافظة ...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: _governorates.map((gov) {
                            final gId = gov['id'] is int ? gov['id'] as int : int.parse(gov['id'].toString());
                            return DropdownMenuItem<int>(
                              value: gId,
                              child: Text(gov['name_ar'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) => _onGovernorateChanged(val),
                        ),
                      const SizedBox(height: 14),

                      // District Dropdown
                      const Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: AppTheme.primaryGold, size: 20),
                          SizedBox(width: 6),
                          Text('القضاء / الناحية / المنطقة:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingDistricts)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
                        )
                      else
                        DropdownButtonFormField<int?>(
                          value: validDistValue,
                          isExpanded: true,
                          hint: const Text('اختر القضاء / الناحية / المنطقة ...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: [
                            if (_districts.isEmpty)
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('غير محدد / جميع مناطق المحافظة', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              )
                            else ...[
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('غير محدد / جميع المناطق', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              ),
                              ..._districts.map((dist) {
                                final dId = dist['id'] is int ? dist['id'] as int : int.parse(dist['id'].toString());
                                return DropdownMenuItem<int?>(
                                  value: dId,
                                  child: Text(dist['name_ar'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                );
                              }),
                            ]
                          ],
                          onChanged: (val) => setState(() => _selectedDistrictId = val),
                        ),
                      const SizedBox(height: 14),

                      // Nearest Landmark
                      const Text('العنوان بالتفصيل:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _landmarkController,
                        decoration: const InputDecoration(
                          hintText: 'العنوان بالتفصيل ...',
                          prefixIcon: Icon(Icons.explore_outlined, color: AppTheme.primaryGold),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('إنشاء الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
