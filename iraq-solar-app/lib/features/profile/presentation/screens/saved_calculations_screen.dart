import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class SavedCalculationsScreen extends StatefulWidget {
  const SavedCalculationsScreen({Key? key}) : super(key: key);

  @override
  State<SavedCalculationsScreen> createState() => _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState extends State<SavedCalculationsScreen> {
  List<Map<String, dynamic>> _calculations = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadCalculations();
  }

  Future<void> _loadCalculations() async {
    final isAuth = await AuthStorageService.isLoggedIn();
    setState(() => _isLoggedIn = isAuth);

    if (!isAuth) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await ApiClient.getSavedCalculations();
      if (res['success'] == true && res['data'] is List) {
        setState(() {
          _calculations = (res['data'] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatIQD(num v) {
    return '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} د.ع';
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('التصاميم والحسابات المحفوظة'),
          backgroundColor: AppTheme.darkNavy,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : !_isLoggedIn
                ? _buildAuthRequired()
                : _calculations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded, size: 70, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('لا توجد حسابات شمسية محفوظة حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                            const SizedBox(height: 6),
                            const Text('يمكنك إحساب الأحمال وحفظ المنظومات من قسم الحاسبة الشمسية.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primaryGold,
                        onRefresh: _loadCalculations,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _calculations.length,
                          itemBuilder: (context, index) {
                            final item = _calculations[index];
                            final sysKw = (item['system_size_kw'] as num?) ?? 0;
                            final inverterKw = (item['recommended_inverter_kw'] as num?) ?? 0;
                            final batteryKwh = (item['recommended_battery_kwh'] as num?) ?? 0;
                            final panelCount = (item['panel_count'] as num?) ?? 0;
                            final cost = (item['estimated_cost_iqd'] as num?) ?? 0;
                            final date = _formatDate(item['created_at']?.toString());

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                        child: Text('منظومة شمسية $sysKw كيلوواط', style: const TextStyle(color: AppTheme.darkNavy, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text('منظومة طاقة شمسية متكاملة بقدرة $sysKw kW', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy)),
                                  const SizedBox(height: 6),
                                  Text('ألواح شمسية ($panelCount لوح) • انفيرتر $inverterKw kW • بنك بطاريات $batteryKwh kWh', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatIQD(cost), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                                      IconButton(
                                        icon: const Icon(Icons.share_rounded, color: AppTheme.darkNavy, size: 20),
                                        onPressed: () {
                                          AppNotification.showInfo(context, 'تم نسخ تفاصيل المنظومة للمشاركة');
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildAuthRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_person_rounded, size: 64, color: AppTheme.primaryGold),
            const SizedBox(height: 16),
            const Text('تسجيل الدخول مطلوب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.darkNavy)),
            const SizedBox(height: 8),
            const Text('يرجى تسجيل الدخول لاستعراض تصاميم المنظومات الشمسية وحسابات الأحمال المحفوظة في حسابك.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final loginSuccess = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const SolarLoginScreen()),
                );
                if (loginSuccess == true) {
                  _loadCalculations();
                }
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('تسجيل الدخول / حساب جديد'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ],
        ),
      ),
    );
  }
}
