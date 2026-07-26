import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class BreakersFusesScreen extends StatefulWidget {
  const BreakersFusesScreen({Key? key}) : super(key: key);

  @override
  State<BreakersFusesScreen> createState() => _BreakersFusesScreenState();
}

class _BreakersFusesScreenState extends State<BreakersFusesScreen> {
  final _iscController = TextEditingController(text: '13.5');
  final _acAmpsController = TextEditingController(text: '22.0');
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    final isc = double.tryParse(_iscController.text) ?? 0;
    final ac = double.tryParse(_acAmpsController.text) ?? 0;
    if (isc <= 0 || ac <= 0) return;
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateBreakersFuses(arrayIsc: isc, inverterOutputAmps: ac);

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final dcBrk = ((isc * 1.25) / 5.0).ceil() * 5.0;
      final acBrk = ((ac * 1.25) / 5.0).ceil() * 5.0;
      final fuse = (isc * 1.56).ceil();
      data = {
        'dc_breaker_amps': dcBrk,
        'ac_breaker_amps': acBrk,
        'string_fuse_amps': fuse,
        'spd_recommended_type': 'Type 2 DC 1000V Surge Protective Device (SPD)',
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
          title: const Text('حاسبة Breaker & Fuse للفني'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.amber.shade900, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🛡️ حماية المنظومة والقواطع والفيوزات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('حساب أمبيرية قواطع التيار المستمر والمتردد وتأمين حماية الصواعق والماسات.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    TextField(controller: _iscController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'تيار القصر للمصفوفة Isc (Amps)')),
                    const SizedBox(height: 12),
                    TextField(controller: _acAmpsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'أقصى تيار للعاكس AC Amps')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب أمبيرية القواطع والفيوزات فوراً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.amber.shade900, width: 2)),
                  child: Column(
                    children: [
                      const Text('🛡️ مواصفات القواطع الموصى بها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('قاطع الـ DC Breaker:', '${_result!['dc_breaker_amps']} Amps'),
                      _row('قاطع الـ AC Breaker:', '${_result!['ac_breaker_amps']} Amps'),
                      _row('فيوز السلسلة String Fuse:', '${_result!['string_fuse_amps']} Amps'),
                      _row('حماية الصواعق SPD المقترحة:', '${_result!['spd_recommended_type']}'),
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
