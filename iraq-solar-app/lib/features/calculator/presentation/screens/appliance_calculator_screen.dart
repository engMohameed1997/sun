import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class ApplianceCalculatorScreen extends StatefulWidget {
  const ApplianceCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<ApplianceCalculatorScreen> createState() => _ApplianceCalculatorScreenState();
}

class _ApplianceCalculatorScreenState extends State<ApplianceCalculatorScreen> {
  final _nameController = TextEditingController(text: 'مكيف 1.5 طن (Inverter)');
  final _wattController = TextEditingController(text: '1800');
  final _hoursController = TextEditingController(text: '8');
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final watt = double.tryParse(_wattController.text) ?? 0;
    final hours = double.tryParse(_hoursController.text) ?? 0;
    if (watt <= 0 || hours <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateApplianceConsumption(applianceName: _nameController.text, wattage: watt, quantity: 1, dailyHours: hours);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final hourly = watt / 1000.0;
      final daily = hourly * hours;
      final monthly = daily * 30.0;
      data = {
        'hourly_kwh': double.parse(hourly.toStringAsFixed(3)),
        'daily_kwh': double.parse(daily.toStringAsFixed(2)),
        'monthly_kwh': double.parse(monthly.toStringAsFixed(1)),
        'appliance': _nameController.text,
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
          title: const Text('حاسبة استهلاك الأجهزة الكهربائية'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.purple.shade900, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.power_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('شنو أكثر جهاز يستهلك عندك؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('احسب استهلاك المكيف، الثلاجة، أو أي جهاز آخر بالساعة واليوم والشهر.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الجهاز (مثلاً: مكيف 1.5 طن)')),
                    const SizedBox(height: 12),
                    TextField(controller: _wattController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الاستهلاك بالواط (Watts)')),
                    const SizedBox(height: 12),
                    TextField(controller: _hoursController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ساعات التشغيل اليومية')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب استهلاك الجهاز فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.purple, width: 2)),
                  child: Column(
                    children: [
                      Text('⚡ التقرير الحسابي لـ: ${_result!['appliance']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('الاستهلاك بالساعة الواحدة:', '${_result!['hourly_kwh']} kWh'),
                      _row('الاستهلاك اليومي الإجمالي:', '${_result!['daily_kwh']} kWh/يوم'),
                      _row('الاستهلاك الشهري التقديري:', '${_result!['monthly_kwh']} kWh/شهر'),
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
