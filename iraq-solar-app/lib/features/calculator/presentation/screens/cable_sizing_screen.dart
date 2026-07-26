import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class CableSizingScreen extends StatefulWidget {
  const CableSizingScreen({Key? key}) : super(key: key);

  @override
  State<CableSizingScreen> createState() => _CableSizingScreenState();
}

class _CableSizingScreenState extends State<CableSizingScreen> {
  final _ampsController = TextEditingController(text: '25');
  final _distController = TextEditingController(text: '15');
  final _voltController = TextEditingController(text: '48');
  String _material = 'copper';
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final amps = double.tryParse(_ampsController.text) ?? 0;
    final dist = double.tryParse(_distController.text) ?? 0;
    final volt = double.tryParse(_voltController.text) ?? 0;
    if (amps <= 0 || dist <= 0 || volt <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateCableSizing(amps: amps, distance: dist, voltage: volt, wireMaterial: _material);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final rho = _material == 'copper' ? 0.01724 : 0.0282;
      final allowDropVolts = volt * 0.025;
      final calcMm2 = (2.0 * dist * amps * rho) / allowDropVolts;
      final stdSizes = [2.5, 4.0, 6.0, 10.0, 16.0, 25.0, 35.0, 50.0, 70.0];
      double std = 70.0;
      for (final s in stdSizes) {
        if (s >= calcMm2) {
          std = s;
          break;
        }
      }
      final actDropVolts = (2.0 * dist * amps * rho) / std;
      final actDropPct = (actDropVolts / volt) * 100.0;
      final lossWatts = actDropVolts * amps;
      data = {
        'recommended_cross_section_mm2': double.parse(calcMm2.toStringAsFixed(2)),
        'standard_cable_size_mm2': std,
        'actual_voltage_drop_volts': double.parse(actDropVolts.toStringAsFixed(2)),
        'actual_voltage_drop_percent': double.parse(actDropPct.toStringAsFixed(2)),
        'power_loss_watts': double.parse(lossWatts.toStringAsFixed(1)),
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
          title: const Text('حاسبة Cable Sizing & Voltage Drop للفني'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.indigo.shade900, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.cable_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📐 حساب مقطع الأسلاك وهبوط الجهد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('حساب مقطع السلك الموصى به (mm²) ونسبة هبوط الجهد (VDrop) وفقد القدرة بالواط.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _ampsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'التيار المار (Amps)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _distController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المسافة (متر)'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _voltController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'جهد النظام (Volts - e.g. 48V/230V)')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _material,
                      decoration: const InputDecoration(labelText: 'مادة الموصل السلكي'),
                      items: const [
                        DropdownMenuItem(value: 'copper', child: Text('نحاس (Copper)')),
                        DropdownMenuItem(value: 'aluminum', child: Text('ألمنيوم (Aluminum)')),
                      ],
                      onChanged: (val) => setState(() => _material = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب سمك الكابل الموصى به فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.indigo, width: 2)),
                  child: Column(
                    children: [
                      const Text('📏 النتائج الفنية لقياس السلك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('مقطع السلك المحسوب دقيقاً:', '${_result!['recommended_cross_section_mm2']} mm²'),
                      _row('السلك القياسي التجاري الموصى به:', '${_result!['standard_cable_size_mm2']} mm²'),
                      _row('هبوط الجهد الفعلي بالـ Volts:', '${_result!['actual_voltage_drop_volts']} V'),
                      _row('نسبة هبوط الجهد الفعلي %:', '${_result!['actual_voltage_drop_percent']}%'),
                      _row('فقد الطاقة بالحرارة:', '${_result!['power_loss_watts']} Watts'),
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
