import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class PanelsNeededScreen extends StatefulWidget {
  const PanelsNeededScreen({Key? key}) : super(key: key);

  @override
  State<PanelsNeededScreen> createState() => _PanelsNeededScreenState();
}

class _PanelsNeededScreenState extends State<PanelsNeededScreen> {
  final _monthlyKwhController = TextEditingController(text: '900');
  int _panelWattage = 600;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final monthly = double.tryParse(_monthlyKwhController.text) ?? 0;
    if (monthly <= 0) return;
    setState(() => _isLoading = true);
    final daily = monthly / 30.0;

    final res = await ApiClient.calculateSystem(dailykWh: daily, peakSunHours: 5.5, autonomyDays: 1, panelWattage: _panelWattage);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final arrayKw = (daily / 5.5) * 1.25;
      final panelCount = (arrayKw / (_panelWattage / 1000.0)).ceil();
      final actualKw = double.parse((panelCount * (_panelWattage / 1000.0)).toStringAsFixed(2));
      final inverterKw = (actualKw * 1.2).clamp(3.0, 50.0);
      data = {
        'system_size_kw': actualKw,
        'required_panel_count': panelCount,
        'recommended_inverter_kw': double.parse(inverterKw.toStringAsFixed(1)),
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
          title: const Text('حاسبة عدد الألواح بالاستهلاك الشهري'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.deepOrange.shade800, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.grid_view_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تعد كم لوح تحتاج لبناء منظومتك؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('إذا كنت تعرف استهلاكك الشهري بالكيلوواط، أدخله هنا لمعرفة عدد الألواح والقدرة الكلية.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    TextField(controller: _monthlyKwhController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الاستهلاك الشهري بالكيلوواط (مثال: 900 kWh)', suffixText: 'kWh/شهر')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _panelWattage,
                      decoration: const InputDecoration(labelText: 'قدرة اللوح المراد تركيبه'),
                      items: const [
                        DropdownMenuItem(value: 550, child: Text('ألواح 550 واط')),
                        DropdownMenuItem(value: 600, child: Text('ألواح 600 واط')),
                        DropdownMenuItem(value: 670, child: Text('ألواح 670 واط')),
                      ],
                      onChanged: (val) => setState(() => _panelWattage = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب عدد الألواح فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.deepOrange, width: 2)),
                  child: Column(
                    children: [
                      const Text('☀️ النتيجة الموصى بها للألواح', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('عدد الألواح المطلوبة:', '${_result!['required_panel_count']} لوح (${_panelWattage}W)'),
                      _row('القدرة الإجمالية للألواح:', '${_result!['system_size_kw']} kW'),
                      _row('سعة الانفرتر الموصى بها:', '${_result!['recommended_inverter_kw']} kW'),
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
