import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class MpptStringScreen extends StatefulWidget {
  const MpptStringScreen({Key? key}) : super(key: key);

  @override
  State<MpptStringScreen> createState() => _MpptStringScreenState();
}

class _MpptStringScreenState extends State<MpptStringScreen> {
  final _vocController = TextEditingController(text: '49.5');
  final _vmpController = TextEditingController(text: '41.2');
  final _maxVocController = TextEditingController(text: '500');
  final _minMpptController = TextEditingController(text: '120');
  final _maxMpptController = TextEditingController(text: '450');
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final voc = double.tryParse(_vocController.text) ?? 0;
    final vmp = double.tryParse(_vmpController.text) ?? 0;
    final maxVoc = double.tryParse(_maxVocController.text) ?? 0;
    final minMppt = double.tryParse(_minMpptController.text) ?? 0;
    final maxMppt = double.tryParse(_maxMpptController.text) ?? 0;
    if (voc <= 0 || vmp <= 0 || maxVoc <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateMPPTString(panelVoc: voc, panelVmp: vmp, inverterMaxVoc: maxVoc, inverterMinMPPT: minMppt, inverterMaxMPPT: maxMppt);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final maxVocCold = voc * (1.0 + (-0.0028 * (0 - 25)));
      final minVmpHot = vmp * (1.0 + (-0.0028 * (50 - 25)));
      final maxPanels = (maxVoc / maxVocCold).floor();
      final minPanels = (minMppt / minVmpHot).ceil();
      final rec = ((maxPanels + minPanels) / 2).round();
      data = {
        'max_panels_per_string': maxPanels,
        'min_panels_per_string': minPanels,
        'recommended_panels_per_string': rec,
        'max_voc_cold_est': double.parse(maxVocCold.toStringAsFixed(1)),
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
          title: const Text('حاسبة MPPT String & Temperature Derating'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.deepPurple.shade800, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('⚡ تصميم سلاسل الألواح وتأثير الحرارة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('حساب أقصى وأدنى عدد ألواح في الـ String لمنع احتراق الانفيرتر شتاءً وضمان تتبع الـ MPPT صيفاً.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                        Expanded(child: TextField(controller: _vocController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Voc للوح (V)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _vmpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Vmp للوح (V)'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _maxVocController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Voc للانفرتر (V)')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _minMpptController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min MPPT V'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _maxMpptController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max MPPT V'))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب حدود السلسلة MPPT فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.deepPurple, width: 2)),
                  child: Column(
                    children: [
                      const Text('⚡ نتيجة السلسلة الموصى بها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('أقصى عدد ألواح بالسلسلة (شتاءً 0°C):', '${_result!['max_panels_per_string']} لوح'),
                      _row('أدنى عدد ألواح بالسلسلة (صيفاً 50°C):', '${_result!['min_panels_per_string']} لوح'),
                      _row('العدد الموصى به لسلسلة متوازنة:', '${_result!['recommended_panels_per_string']} لوح'),
                      _row('أقصى جهد متوقع في أبرد أيام الشتاء:', '${_result!['max_voc_cold_est']} V'),
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
