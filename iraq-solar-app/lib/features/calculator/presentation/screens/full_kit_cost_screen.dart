import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/presentation/screens/catalog_screen.dart';

class FullKitCostScreen extends StatefulWidget {
  const FullKitCostScreen({Key? key}) : super(key: key);

  @override
  State<FullKitCostScreen> createState() => _FullKitCostScreenState();
}

class _FullKitCostScreenState extends State<FullKitCostScreen> {
  final _kwController = TextEditingController(text: '5.0');
  final _kwhController = TextEditingController(text: '10.0');
  bool _includeInstallation = true;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  String _formatIqd(dynamic amount) {
    if (amount == null) return '0 د.ع';
    final val = (amount is num) ? amount.toInt() : int.tryParse(amount.toString()) ?? 0;
    return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع';
  }

  Future<void> _calculate() async {
    final kw = double.tryParse(_kwController.text) ?? 0;
    final kwh = double.tryParse(_kwhController.text) ?? 0;
    if (kw <= 0) return;

    final isAuth = await AuthGuard.requireAuth(
      context,
      reasonMessage: 'يرجى تسجيل الدخول أو إنشاء حساب مجاني لحساب تفاصيل تكلفة البكج والتجميعة وتأكيد السعر النهائي.',
    );
    if (!isAuth) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateFullKitCost(systemSizekW: kw, batterykWh: kwh, includeInstallation: _includeInstallation);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final equipIQD = ((kw * 450.0) + (kwh * 220.0)) * 1500.0;
      final installIQD = _includeInstallation ? ((kw * 80.0) + 150.0) * 1500.0 : 0.0;
      final totalIQD = equipIQD + installIQD;
      data = {
        'estimated_total_iqd': totalIQD,
        'equipment_cost_iqd': equipIQD,
        'installation_cost_iqd': installIQD,
        'matching_kit_summary': 'منظومة طاقة شمسية متكاملة قدرة ${kw} kW مع بطاريات ${kwh} kWh',
      };
    }

    setState(() {
      _isLoading = false;
      _result = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('حاسبة الكلفة الكاملة وتصفح المتاجر'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.redAccent.shade700, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🛒 احسب التكلفة واشترِ المنظومة بالدينار!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('تتيح لك هذه الحاسبة تقدير سعر الأجهزة والتركيب بالدينار العراقي، وتحويلك فوراً للمتاجر المتوفرة.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    TextField(controller: _kwController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قدرة المنظومة والانفرتر بالـ kW')),
                    const SizedBox(height: 12),
                    TextField(controller: _kwhController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعة البطاريات بالـ kWh')),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('إضافة تكلفة أجرة وشغل التركيب والتوصيل الميداني'),
                      value: _includeInstallation,
                      activeColor: Colors.redAccent,
                      onChanged: (val) => setState(() => _includeInstallation = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب الكلفة ومطابقة المتاجر بالدينار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.redAccent, width: 2)),
                  child: Column(
                    children: [
                      const Text('📊 التكلفة التقديرية بالدينار العراقي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('التكلفة الإجمالية التقديرية:', _formatIqd(_result!['estimated_total_iqd'] ?? (_result!['estimated_total_usd'] * 1500))),
                      _row('تكلفة الأجهزة والمعدات الشائعة:', _formatIqd(_result!['equipment_cost_iqd'] ?? (_result!['equipment_cost_usd'] * 1500))),
                      _row('أجور الفحص والتركيب الميداني:', _formatIqd(_result!['installation_cost_iqd'] ?? (_result!['installation_cost_usd'] * 1500))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SolarCatalogScreen()));
                        },
                        icon: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white),
                        label: const Text('🛒 اعرض المتاجر التي تبيع هذه المنظومة بالدينار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy, minimumSize: const Size.fromHeight(50)),
                      ),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
        ],
      ),
    );
  }
}
