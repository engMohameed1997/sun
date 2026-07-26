import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class SolarProductionScreen extends StatefulWidget {
  const SolarProductionScreen({Key? key}) : super(key: key);

  @override
  State<SolarProductionScreen> createState() => _SolarProductionScreenState();
}

class _SolarProductionScreenState extends State<SolarProductionScreen> {
  String _province = 'بغداد';
  final _kwController = TextEditingController(text: '5.0');
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final kw = double.tryParse(_kwController.text) ?? 0;
    if (kw <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateSolarProduction(province: _province, systemSizekW: kw);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      double psh = 5.5;
      double tilt = 33.0;
      if (_province == 'البصرة') { psh = 5.8; tilt = 30.0; }
      if (_province == 'أربيل') { psh = 5.2; tilt = 36.0; }
      if (_province == 'النجف') { psh = 5.6; tilt = 32.0; }

      final daily = kw * psh * 0.82;
      final monthly = daily * 30.0;
      final annual = daily * 365.0;
      data = {
        'province': _province,
        'optimal_tilt_angle': tilt,
        'daily_avg_kwh': double.parse(daily.toStringAsFixed(2)),
        'monthly_production_kwh': double.parse(monthly.toStringAsFixed(1)),
        'annual_production_kwh': double.parse(annual.toStringAsFixed(1)),
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
          title: const Text('حاسبة Solar Production حسب المحافظة'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.brown.shade800, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.map_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('☀️ الإنتاجية الشمسية في المحافظات العراقية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('حساب الإنتاج اليومي والشهري والسنوي المتوقع وزاوية التثبيت المثالية حسب المحافظة.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    DropdownButtonFormField<String>(
                      value: _province,
                      decoration: const InputDecoration(labelText: 'اختر المحافظة العراقية'),
                      items: const [
                        DropdownMenuItem(value: 'بغداد', child: Text('بغداد (33° زاوية تثبيت)')),
                        DropdownMenuItem(value: 'البصرة', child: Text('البصرة (30° زاوية تثبيت)')),
                        DropdownMenuItem(value: 'أربيل', child: Text('أربيل / دهوك / السليمانية (36° زاوية تثبيت)')),
                        DropdownMenuItem(value: 'النجف', child: Text('النجف / كربلاء / بابل (32° زاوية تثبيت)')),
                      ],
                      onChanged: (val) => setState(() => _province = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _kwController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قدرة المنظومة الشمسية بالـ kW')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب الإنتاج والزاوية المثالية فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.brown, width: 2)),
                  child: Column(
                    children: [
                      Text('☀️ تقرير الإنتاجية لـ: ${_result!['province']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('زاوية التثبيت المثالية للألواح:', '${_result!['optimal_tilt_angle']}° اتجاه الجنوب الجغرافي'),
                      _row('الإنتاج اليومي المتوقع:', '${_result!['daily_avg_kwh']} kWh / يوم'),
                      _row('الإنتاج الشهري المتوقع:', '${_result!['monthly_production_kwh']} kWh / شهر'),
                      _row('الإنتاج السنوي الكلي المتوقع:', '${_result!['annual_production_kwh']} kWh / سنة'),
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
