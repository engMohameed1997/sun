import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/workforce_constants.dart';
import 'service_order_detail_screen.dart';

/// Customer-facing service request form.
///
/// The customer never picks a technician — the dispatch engine assigns
/// the best available one automatically.
class CreateServiceOrderScreen extends StatefulWidget {
  /// Pre-selected service type (e.g. 'installation' when coming from a calculator).
  final String? initialOrderType;

  /// System size carried over from a calculator result.
  final double? systemSizeKw;

  /// Raw calculator output stored with the order for the technician.
  final Map<String, dynamic>? calculatorResult;

  const CreateServiceOrderScreen({
    Key? key,
    this.initialOrderType,
    this.systemSizeKw,
    this.calculatorResult,
  }) : super(key: key);

  @override
  State<CreateServiceOrderScreen> createState() => _CreateServiceOrderScreenState();
}

class _CreateServiceOrderScreenState extends State<CreateServiceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _sizeController;

  late String _orderType;
  int? _governorateId;
  int? _districtId;
  DateTime? _preferredDate;

  List<Map<String, dynamic>> _governorates = [];
  List<Map<String, dynamic>> _districts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _orderType = widget.initialOrderType ?? 'installation';
    _sizeController = TextEditingController(
      text: widget.systemSizeKw != null ? widget.systemSizeKw!.toStringAsFixed(2) : '',
    );
    _loadGovernorates();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _loadGovernorates() async {
    final res = await ApiClient.getGovernorates();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _governorates = List<Map<String, dynamic>>.from(res['data'] ?? []);
      }
      _isLoading = false;
    });
  }

  Future<void> _loadDistricts(int governorateId) async {
    final res = await ApiClient.getDistricts(governorateId);
    if (!mounted) return;
    setState(() {
      _districts = res['success'] == true
          ? List<Map<String, dynamic>>.from(res['data'] ?? [])
          : <Map<String, dynamic>>[];
      _districtId = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_governorateId == null) {
      _showMessage('يرجى اختيار المحافظة', success: false);
      return;
    }

    final sizeText = _sizeController.text.trim();
    double? size;
    if (sizeText.isNotEmpty) {
      size = double.tryParse(sizeText);
      if (size == null) {
        _showMessage('حجم المنظومة يجب أن يكون رقماً صالحة (مثال: 5.5)', success: false);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final res = widget.calculatorResult != null
        ? await ApiClient.createServiceOrderFromCalculator(
            orderType: _orderType,
            governorateId: _governorateId!,
            calculatorResult: widget.calculatorResult!,
            districtId: _districtId,
            description: _descriptionController.text.trim(),
            systemSizeKw: size,
            address: _addressController.text.trim(),
            preferredDate: _preferredDate,
          )
        : await ApiClient.createServiceOrder(
            orderType: _orderType,
            governorateId: _governorateId!,
            districtId: _districtId,
            description: _descriptionController.text.trim(),
            systemSizeKw: size,
            address: _addressController.text.trim(),
            preferredDate: _preferredDate,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      final orderId = res['data']?['id']?.toString();
      _showMessage(res['message']?.toString() ?? 'تم استلام طلبك', success: true);
      if (orderId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ServiceOrderDetailScreen(orderId: orderId)),
        );
      } else {
        Navigator.pop(context, true);
      }
    } else {
      final msg = res['message']?.toString();
      _showMessage((msg != null && msg.trim().isNotEmpty) ? msg : 'تعذر إرسال الطلب، يرجى المحاولة لاحقاً', success: false);
    }
  }

  void _showMessage(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.accentGreen : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('طلب خدمة شمسية')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildAssuranceBanner(),
                    const SizedBox(height: 16),
                    const Text('نوع الخدمة', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTypeSelector(),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<int>(
                      value: _governorateId,
                      decoration: const InputDecoration(labelText: 'المحافظة *'),
                      items: _governorates
                          .map((g) => DropdownMenuItem<int>(
                                value: g['id'] as int,
                                child: Text(g['name_ar']?.toString() ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _governorateId = v);
                        if (v != null) _loadDistricts(v);
                      },
                      validator: (v) => v == null ? 'يرجى اختيار المحافظة' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_districts.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: _districtId,
                        decoration: const InputDecoration(labelText: 'القضاء / الناحية'),
                        items: _districts
                            .map((d) => DropdownMenuItem<int>(
                                  value: d['id'] as int,
                                  child: Text(d['name_ar']?.toString() ?? ''),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _districtId = v),
                      ),
                    if (_districts.isNotEmpty) const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'العنوان التفصيلي *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'حجم المنظومة (kW) — اختياري'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'وصف المشكلة أو المطلوب'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _preferredDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryGold,
                                  onPrimary: Colors.white,
                                  onSurface: AppTheme.darkNavy,
                                ),
                              ),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: child!,
                              ),
                            );
                          },
                        );
                        if (picked != null) setState(() => _preferredDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'التاريخ المفضل — اختياري'),
                        child: Text(
                          _preferredDate == null
                              ? 'اختر التاريخ'
                              : '${_preferredDate!.year}/${_preferredDate!.month}/${_preferredDate!.day}',
                          style: TextStyle(
                            color: _preferredDate == null ? const Color(0xFF94A3B8) : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _isSubmitting ? 'جارٍ الإرسال...' : 'إرسال الطلب',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAssuranceBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppTheme.primaryGold),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'سيتم تعيين فني معتمد تلقائياً من قِبل المنصة — لا حاجة للبحث أو الاتصال بأحد.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkforceConstants.orderTypeLabels.entries.map((entry) {
        final isActive = _orderType == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _orderType = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryGold : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? AppTheme.primaryGold : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  WorkforceConstants.orderTypeIcons[entry.key],
                  size: 16,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
