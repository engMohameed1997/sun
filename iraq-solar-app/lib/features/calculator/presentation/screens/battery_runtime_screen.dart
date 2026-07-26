import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class BatteryRuntimeScreen extends StatefulWidget {
  const BatteryRuntimeScreen({Key? key}) : super(key: key);

  @override
  State<BatteryRuntimeScreen> createState() => _BatteryRuntimeScreenState();
}

class _BatteryRuntimeScreenState extends State<BatteryRuntimeScreen> {
  final _capController = TextEditingController(text: '10');
  final _loadController = TextEditingController(text: '2.0');
  String _type = 'lithium';
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final cap = double.tryParse(_capController.text) ?? 0;
    final load = double.tryParse(_loadController.text) ?? 0;
    if (cap <= 0 || load <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateBatteryRuntime(batteryCapacitykWh: cap, batteryType: _type, currentLoadkW: load);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      double dod = 0.90;
      if (_type == 'gel') dod = 0.60;
      if (_type == 'lead_acid') dod = 0.50;
      final usable = cap * dod;
      final hours = double.parse((usable / load).toStringAsFixed(1));
      data = {
        'runtime_hours': hours,
        'usable_capacity_kwh': double.parse(usable.toStringAsFixed(2)),
        'depth_of_discharge_percent': (dod * 100).toInt(),
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
          title: const Text('حاسبة ساعات تشغيل البطارية'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.blue.shade900, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.battery_charging_full_rounded, color: AppTheme.primaryGold, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('كم ساعة تبقى الكهرباء؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('احسب الساعات المتبقية لتغذية الأحمال بحسب سعة ونوع بطاريات المنظومة.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    TextField(controller: _capController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعة البطاريات الإجمالية (kWh)')),
                    const SizedBox(height: 12),
                    TextField(controller: _loadController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الحمل الكهربائي المشغل حالياً (kW)')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'نوع البطارية والتكنولوجيا'),
                      items: const [
                        DropdownMenuItem(value: 'lithium', child: Text('بطارية ليثيوم LiFePO4 (تفريغ آمن 90%)')),
                        DropdownMenuItem(value: 'gel', child: Text('بطارية جيل Gel (تفريغ آمن 60%)')),
                        DropdownMenuItem(value: 'lead_acid', child: Text('بطارية رصاص Lead Acid (تفريغ آمن 50%)')),
                      ],
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب ساعات التغذية المستمرة فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue.shade900, width: 2)),
                  child: Column(
                    children: [
                      const Text('🔋 результат الاستمرارية والسعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('ساعات الكهرباء المستمرة المتوقعة:', '${_result!['runtime_hours']} ساعة'),
                      _row('السعة الفعلية المستفاد منها:', '${_result!['usable_capacity_kwh']} kWh'),
                      _row('عمق التفريغ المسموح به DoD:', '${_result!['depth_of_discharge_percent']}%'),
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
