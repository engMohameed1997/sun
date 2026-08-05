import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../products/presentation/screens/catalog_screen.dart';
import '../../../workforce/customer/create_service_order_screen.dart';

class SizingCalculatorScreen extends StatefulWidget {
  const SizingCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<SizingCalculatorScreen> createState() => _SizingCalculatorScreenState();
}

class _SizingCalculatorScreenState extends State<SizingCalculatorScreen> {
  final _dailyKwhController = TextEditingController(text: '25');
  double _peakSunHours = 5.5;
  int _autonomyDays = 1;
  int _panelWattage = 550;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  String _formatIqd(dynamic amount) {
    if (amount == null) return '0 د.ع';
    final val = (amount is num) ? amount.toInt() : int.tryParse(amount.toString()) ?? 0;
    return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع';
  }

  Future<void> _calculate() async {
    final daily = double.tryParse(_dailyKwhController.text) ?? 0;
    if (daily <= 0) {
      AppNotification.showError(context, 'يرجى إدخال قيمة استهلاك يومية صالحة');
      return;
    }

    final isAuth = await AuthGuard.requireAuth(
      context,
      reasonMessage: 'يرجى تسجيل الدخول أو إنشاء حساب مجاني لعرض تقرير النتيجة وحساب تكلفة المنظومة بالكامل.',
    );
    if (!isAuth) return;

    setState(() => _isLoading = true);

    final res = await ApiClient.calculateSystem(
      dailykWh: daily,
      peakSunHours: _peakSunHours,
      autonomyDays: _autonomyDays,
      panelWattage: _panelWattage,
    );

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final arrayKw = (daily / _peakSunHours) * 1.25;
      final panelCount = (arrayKw / (_panelWattage / 1000.0)).ceil();
      final actualKw = double.parse((panelCount * (_panelWattage / 1000.0)).toStringAsFixed(2));
      final inverterKw = (actualKw * 1.2).clamp(3.0, 50.0);
      final batteryKwh = double.parse((daily * _autonomyDays * 1.25).toStringAsFixed(1));
      final costIqd = ((actualKw * 650) + (batteryKwh * 250)) * 1500;
      data = {
        'system_size_kw': actualKw,
        'required_panel_count': panelCount,
        'recommended_inverter_kw': double.parse(inverterKw.toStringAsFixed(1)),
        'recommended_battery_kwh': batteryKwh,
        'estimated_cost_iqd': costIqd,
        'daily_generation_kwh': double.parse((actualKw * _peakSunHours).toStringAsFixed(1)),
        'co2_saved_tons_per_year': double.parse((actualKw * _peakSunHours * 365 * 0.0007).toStringAsFixed(2)),
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
          title: const Text('حاسبة حجم المنظومة الشمسية الشاملة'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppTheme.darkNavy, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: AppTheme.primaryGold, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تقدير المنظومة بالدينار العراقي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('أدخل معدل الاستهلاك اليومي للحصول على حجم الانفيرتر والألواح والتكلفة بالدينار.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الاستهلاك اليومي (kWh / يوم):', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dailyKwhController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'مثلاً: 25', suffixText: 'kWh', prefixIcon: Icon(Icons.flash_on, color: AppTheme.primaryGold)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ساعات الذروة الشمسية:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                        Text('$_peakSunHours ساعات (العراق)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                      ],
                    ),
                    Slider(
                      value: _peakSunHours,
                      min: 4.0,
                      max: 7.0,
                      divisions: 6,
                      activeColor: AppTheme.primaryGold,
                      onChanged: (val) => setState(() => _peakSunHours = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _panelWattage,
                      decoration: const InputDecoration(labelText: 'قدرة اللوح الشمسي المراد تركيبه'),
                      items: const [
                        DropdownMenuItem(value: 550, child: Text('لوح 550 واط (Tier-1 Mono PERC)')),
                        DropdownMenuItem(value: 600, child: Text('لوح 600 واط (N-Type Bifacial)')),
                        DropdownMenuItem(value: 670, child: Text('لوح 670 واط (Industrial Output)')),
                      ],
                      onChanged: (val) => setState(() => _panelWattage = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب التوصية الهندسية فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) _buildResultView(_result!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultView(Map<String, dynamic> data) {
    final costIqd = data['estimated_cost_iqd'] ?? ((data['estimated_cost_usd'] ?? 2500) * 1500);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryGold, width: 2),
        boxShadow: [BoxShadow(color: AppTheme.primaryGold.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppTheme.primaryGold, size: 28),
              SizedBox(width: 8),
              Text('نتائج التوصية الهندسية المعتمدة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
            ],
          ),
          const Divider(height: 24),
          _row('قدرة المنظومة الشمسية الكلية:', '${data['system_size_kw']} kW'),
          _row('عدد الألواح المطلوبة (${_panelWattage}W):', '${data['required_panel_count']} لوح'),
          _row('سعة الانفرتر الموصى به:', '${data['recommended_inverter_kw']} kW'),
          _row('سعة بطاريات الليثيوم LiFePO4:', '${data['recommended_battery_kwh']} kWh'),
          _row('الإنتاجية اليومية التقديرية:', '${data['daily_generation_kwh']} kWh/يوم'),
          _row('الحد من انبعاثات الكربون:', '${data['co2_saved_tons_per_year']} طن/سنة'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('التكلفة التقريبية بالدينار العراقي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy)),
              Text(_formatIqd(costIqd), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateServiceOrderScreen(
                    initialOrderType: 'installation',
                    systemSizeKw: (data['system_size_kw'] as num?)?.toDouble(),
                    calculatorResult: data,
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
            icon: const Icon(Icons.shopping_cart_rounded, color: AppTheme.darkNavy),
            label: const Text('🛒 تصفح المتاجر والمنتجات المتوفرة للمنظومة', style: TextStyle(color: AppTheme.darkNavy, fontWeight: FontWeight.bold, fontSize: 14)),
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
