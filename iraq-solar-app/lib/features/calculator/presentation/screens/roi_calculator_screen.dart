import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class RoiCalculatorScreen extends StatefulWidget {
  const RoiCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<RoiCalculatorScreen> createState() => _RoiCalculatorScreenState();
}

class _RoiCalculatorScreenState extends State<RoiCalculatorScreen> {
  final _genController = TextEditingController(text: '225000');
  final _costController = TextEditingController(text: '4500000');
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  String _formatIqd(dynamic amount) {
    if (amount == null) return '0 د.ع';
    final val = (amount is num) ? amount.toInt() : int.tryParse(amount.toString()) ?? 0;
    return '${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع';
  }

  Future<void> _calculate() async {
    final genIQD = double.tryParse(_genController.text) ?? 0;
    final costIQD = double.tryParse(_costController.text) ?? 0;
    if (costIQD <= 0) {
      AppNotification.showError(context, 'يرجى إدخال سعر المنظومة بالدينار العراقي');
      return;
    }
    setState(() => _isLoading = true);

    final res = await ApiClient.calculateROI(
      monthlyGeneratorFeeIQD: genIQD,
      monthlyGridFeeIQD: 0,
      systemCostIQD: costIQD,
    );

    Map<String, dynamic> data;
    if (res['success'] == true && res['data'] != null) {
      data = res['data'];
    } else {
      final monthly = genIQD <= 0 ? 225000.0 : genIQD;
      final annual = monthly * 12.0;
      final payback = double.parse((costIQD / annual).toStringAsFixed(1));
      final fiveYr = (annual * 5.0) - costIQD;
      final tenYr = (annual * 10.0) - costIQD;
      data = {
        'monthly_savings_iqd': monthly,
        'annual_savings_iqd': annual,
        'payback_period_years': payback,
        'five_year_savings_iqd': fiveYr,
        'ten_year_savings_iqd': tenYr,
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
          title: const Text('حاسبة التوفير واسترجاع رأس المال (ROI)'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.green.shade800, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.savings_rounded, color: Colors.white, size: 40),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('شكد توفر من تركب شمسي بالدينار؟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 4),
                          Text('احسب التوفير الشهري والسنوي وموعد استرداد سعر شراء المنظومة الشمسية بالدينار العراقي.', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                    TextField(
                      controller: _genController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'اشتراك المولد الأهلي الشهري بالدينار العراقي (د.ع)', prefixIcon: Icon(Icons.monetization_on, color: Colors.green), suffixText: 'د.ع'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سعر شراء المنظومة بالدينار العراقي (د.ع)', prefixIcon: Icon(Icons.price_change, color: Colors.green), suffixText: 'د.ع'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculate,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('احسب التوفير ومدة الاسترداد بالدينار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.green, width: 2),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      const Text('📊 التتقرير المالي للتوفير بالدينار العراقي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      const Divider(height: 24),
                      _row('التوفير الشهري المباشر من اشتراك المولد:', _formatIqd(_result!['monthly_savings_iqd'])),
                      _row('التوفير السنوي الإجمالي:', _formatIqd(_result!['annual_savings_iqd'])),
                      _row('مدة استرجاع رأس المال بالكامل:', '${_result!['payback_period_years']} سنة'),
                      _row('صافي أرباحك وتوفيرك بعد 5 سنوات:', _formatIqd(_result!['five_year_savings_iqd'])),
                      _row('صافي توفيرك الكلي بعد 10 سنوات:', _formatIqd(_result!['ten_year_savings_iqd'])),
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
