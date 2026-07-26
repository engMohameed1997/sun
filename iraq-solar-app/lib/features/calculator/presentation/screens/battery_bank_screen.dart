import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class BatteryBankScreen extends StatefulWidget {
  const BatteryBankScreen({Key? key}) : super(key: key);

  @override
  State<BatteryBankScreen> createState() => _BatteryBankScreenState();
}

class _BatteryBankScreenState extends State<BatteryBankScreen> {
  final _voltController = TextEditingController(text: '48');
  final _kwhController = TextEditingController(text: '9.6');
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final volt = double.tryParse(_voltController.text) ?? 0;
    final kwh = double.tryParse(_kwhController.text) ?? 0;
    if (volt <= 0 || kwh <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateBatteryBank(targetVoltage: volt, targetCapacitykWh: kwh, singleBatteryVoltage: 12, singleBatteryAh: 200);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final series = (volt / 12.0).round().clamp(1, 16);
      final targetAh = (kwh * 1000.0) / volt;
      final parallel = (targetAh / 200.0).ceil().clamp(1, 10);
      final total = series * parallel;
      final actualKwh = double.parse(((total * 12.0 * 200.0) / 1000.0).toStringAsFixed(2));
      data = {
        'total_batteries_needed': total,
        'series_count': series,
        'parallel_count': parallel,
        'actual_capacity_kwh': actualKwh,
        'wiring_diagram_note': 'توصيل $series بطارية على التوالي للحصول على ${volt.toInt()}V، ثم ربط $parallel سلاسل على التوازي.',
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
          title: const Text('حاسبة Battery Bank Series/Parallel'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.cyan.shade900, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.battery_saver_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🔋 تصميم وتراصف بنك البطاريات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('حساب عدد البطاريات المطلوبة وتوزيع التوصيل على التوالي والتوازي لجهد 48V/24V.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    TextField(controller: _voltController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الجهد المستهدف للانفرتر (Volts - e.g. 48V)')),
                    const SizedBox(height: 12),
                    TextField(controller: _kwhController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعة المستهدفة الكلية (kWh)')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب التراصف وتوزيع التوصيل فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.cyan.shade900, width: 2)),
                  child: Column(
                    children: [
                      const Text('🔋 مخطط التوصيل الموصى به', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('عدد البطاريات الكلي المطلوب:', '${_result!['total_batteries_needed']} بطارية (12V 200Ah)'),
                      _row('عدد البطاريات على التوالي (Series):', '${_result!['series_count']} بطاريات'),
                      _row('عدد السلاسل على التوازي (Parallel):', '${_result!['parallel_count']} سلاسل'),
                      _row('السعة الكلية المحققة:', '${_result!['actual_capacity_kwh']} kWh'),
                      _row('شرح وتوصيل الكابلات:', '${_result!['wiring_diagram_note']}'),
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
          Expanded(child: Text(val, textAlign: TextAlign.end, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkNavy))),
        ],
      ),
    );
  }
}
