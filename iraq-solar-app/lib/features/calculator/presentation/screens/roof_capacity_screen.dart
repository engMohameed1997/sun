import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class RoofCapacityScreen extends StatefulWidget {
  const RoofCapacityScreen({Key? key}) : super(key: key);

  @override
  State<RoofCapacityScreen> createState() => _RoofCapacityScreenState();
}

class _RoofCapacityScreenState extends State<RoofCapacityScreen> {
  final _lenController = TextEditingController(text: '12');
  final _widController = TextEditingController(text: '10');
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final len = double.tryParse(_lenController.text) ?? 0;
    final wid = double.tryParse(_widController.text) ?? 0;
    if (len <= 0 || wid <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateRoofCapacity(length: len, width: wid);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final total = len * wid;
      final usable = total * 0.90; // 90% usable
      final maxPanels = (usable / 2.58).floor();
      final maxKw = double.parse(((maxPanels * 550) / 1000.0).toStringAsFixed(2));
      data = {
        'total_area_m2': double.parse(total.toStringAsFixed(1)),
        'usable_area_m2': double.parse(usable.toStringAsFixed(1)),
        'max_panel_count': maxPanels,
        'max_capacity_kw': maxKw,
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
          title: const Text('حاسبة مساحة ومستوعب السطح'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.teal.shade800, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.roofing_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('شكد يستوعب سطحك ألواح؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('أدخل طول وعرض السطح لمعرفة أقصى عدد ألواح وأكبر قدرة يمكنك تركيبها.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                        Expanded(child: TextField(controller: _lenController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'طول السطح (متر)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _widController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عرض السطح (متر)'))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب استيعاب السطح للألواح فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.teal, width: 2)),
                  child: Column(
                    children: [
                      const Text('🏠 مستوعب المساحة الكلي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('مساحة السطح الإجمالية:', '${_result!['total_area_m2']} م²'),
                      _row('المساحة الصافية بعد خصم الظلال:', '${_result!['usable_area_m2']} م²'),
                      _row('أقصى عدد ألواح يستوعبه السطح:', '${_result!['max_panel_count']} لوح (550W)'),
                      _row('أقصى قدرة إجمالية بالألواح:', '${_result!['max_capacity_kw']} kW'),
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
