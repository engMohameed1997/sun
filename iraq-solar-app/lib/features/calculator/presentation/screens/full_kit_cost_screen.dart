import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/presentation/screens/catalog_screen.dart';
import '../../../products/presentation/screens/product_detail_screen.dart';
import '../../../workforce/customer/create_service_order_screen.dart';

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
        'calculation': {
          'estimated_cost': {
            'median_total_iqd': totalIQD,
            'min_total_iqd': totalIQD * 0.88,
            'max_total_iqd': totalIQD * 1.12,
            'equipment_iqd': equipIQD,
            'installation_iqd': installIQD,
          }
        }
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent.shade700, AppTheme.darkNavy],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
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
                          Text('حاسبة بيع ذكية: تحسب القدرة والكميات فيزياءً، ثم تبحث عن أفضل الأجهزة المتاحة بالمتاجر فوراً.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                _buildCalculationResultCard(),
                const SizedBox(height: 20),
                _buildRecommendationsSection(),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationResultCard() {
    final calc = _result!['calculation'];
    final est = (calc != null && calc['estimated_cost'] != null) ? calc['estimated_cost'] : _result!;
    final median = est['median_total_iqd'] ?? _result!['estimated_total_iqd'];
    final minVal = est['min_total_iqd'] ?? (median != null ? (median * 0.88) : 0);
    final maxVal = est['max_total_iqd'] ?? (median != null ? (median * 1.12) : 0);
    final equip = est['equipment_iqd'] ?? _result!['equipment_cost_iqd'];
    final install = est['installation_iqd'] ?? _result!['installation_cost_iqd'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.redAccent, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppTheme.darkNavy),
              SizedBox(width: 8),
              Text('📊 التكلفة التقديرية والنطاق السعري', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
            ],
          ),
          const Divider(height: 24),
          _row('التكلفة الإجمالية المتوقعة:', _formatIqd(median)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('نطاق أسعار المتاجر بالعراق:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                Text('${_formatIqd(minVal)} - ${_formatIqd(maxVal)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
              ],
            ),
          ),
          _row('تكلفة الأجهزة والمعدات الشائعة:', _formatIqd(equip)),
          _row('أجور الفحص والتركيب الميداني:', _formatIqd(install)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final kw = double.tryParse(_kwController.text) ?? 5.0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateServiceOrderScreen(
                    initialOrderType: 'installation',
                    systemSizeKw: kw,
                    calculatorResult: _result,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.engineering_rounded, color: Colors.white),
            label: const Text('⚡ اطلب فني معتمد للتركيب (توزيع تلقائي)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkNavy,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SolarCatalogScreen()));
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded, color: AppTheme.darkNavy),
            label: const Text('🛒 اعرض كافة المنتجات المتاحة بالمتجر', style: TextStyle(color: AppTheme.darkNavy, fontWeight: FontWeight.bold, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              side: const BorderSide(color: AppTheme.darkNavy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final recs = _result!['recommendations'];
    if (recs == null) return const SizedBox.shrink();

    final List panels = recs['recommended_panels'] ?? [];
    final List inverters = recs['recommended_inverters'] ?? [];
    final List batteries = recs['recommended_batteries'] ?? [];

    final allRecs = [...panels, ...inverters, ...batteries];

    if (allRecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '🌟 المنتجات والأجهزة المطابقة المتوفرة بالمتاجر:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allRecs.length,
          itemBuilder: (context, index) {
            final item = allRecs[index];
            final title = item['product_name']?.toString() ?? 'منتج مطابق';
            final store = item['store_name']?.toString() ?? 'متجر معتمد';
            final score = item['score'] ?? 95;
            final qty = item['required_quantity'] ?? 1;
            final totalPrice = item['total_price_iqd'] ?? 0;
            final reasons = (item['match_reasons'] is List) ? List<String>.from(item['match_reasons']) : [];
            final prodId = item['product_id']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text('$score% مطابقة', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('المتجر: $store', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text('الكمية المطلوبة: $qty | الإجمالي: ${_formatIqd(totalPrice)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    if (reasons.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: reasons.map((r) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text('✓ $r', style: TextStyle(fontSize: 10, color: Colors.blue.shade900)),
                        )).toList(),
                      ),
                    ]
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  if (prodId.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item)));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SolarCatalogScreen()));
                  }
                },
              ),
            );
          },
        ),
      ],
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
