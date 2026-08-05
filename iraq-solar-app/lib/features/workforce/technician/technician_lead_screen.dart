import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/workforce_constants.dart';

/// Lets a technician submit a private customer they found outside the platform.
/// Admin reviews it, and on approval the technician gets first priority.
class TechnicianLeadScreen extends StatefulWidget {
  const TechnicianLeadScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianLeadScreen> createState() => _TechnicianLeadScreenState();
}

class _TechnicianLeadScreenState extends State<TechnicianLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();

  String _orderType = 'installation';
  int? _governorateId;
  List<Map<String, dynamic>> _governorates = [];
  List<Map<String, dynamic>> _leads = [];
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiClient.getGovernorates(),
      ApiClient.getTechnicianLeads(),
    ]);
    if (!mounted) return;
    setState(() {
      if (results[0]['success'] == true) {
        _governorates = List<Map<String, dynamic>>.from(results[0]['data'] ?? []);
      }
      if (results[1]['success'] == true) {
        _leads = List<Map<String, dynamic>>.from(results[1]['data'] ?? []);
      }
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final res = await ApiClient.createTechnicianLead(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      orderType: _orderType,
      description: _descriptionController.text.trim(),
      systemSizeKw: double.tryParse(_sizeController.text.trim()),
      governorateId: _governorateId,
      address: _addressController.text.trim(),
      estimatedPriceIqd: double.tryParse(_priceController.text.trim()),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? ''),
        backgroundColor: res['success'] == true ? AppTheme.accentGreen : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (res['success'] == true) {
      _formKey.currentState!.reset();
      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();
      _descriptionController.clear();
      _sizeController.clear();
      _priceController.clear();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إضافة عميل خاص', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Text(
                  'أرسل بيانات عميل وصل إليك خارج التطبيق — بعد موافقة الإدارة يتحول لطلب رسمي وتأخذ أنت الأولوية.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.6),
                ),
                const SizedBox(height: 16),
                _field(_nameController, 'اسم العميل *', required: true),
                _field(_phoneController, 'رقم الهاتف *', required: true, keyboard: TextInputType.phone),
                DropdownButtonFormField<String>(
                  value: _orderType,
                  decoration: const InputDecoration(labelText: 'نوع العمل'),
                  items: WorkforceConstants.orderTypeLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _orderType = v ?? 'installation'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _governorateId,
                  decoration: const InputDecoration(labelText: 'المحافظة'),
                  items: _governorates
                      .map((g) => DropdownMenuItem<int>(
                            value: g['id'] as int,
                            child: Text(g['name_ar']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _governorateId = v),
                ),
                const SizedBox(height: 12),
                _field(_addressController, 'العنوان'),
                _field(_sizeController, 'حجم المنظومة (kW)', keyboard: TextInputType.number),
                _field(_priceController, 'السعر المقترح (د.ع)', keyboard: TextInputType.number),
                _field(_descriptionController, 'وصف العمل', maxLines: 3),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_isSubmitting ? 'جارٍ الإرسال...' : 'إرسال للمراجعة'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('طلباتي المرسلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        if (_leads.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('لم ترسل أي طلب بعد', style: TextStyle(color: Color(0xFF94A3B8)))),
          )
        else
          ..._leads.map(_buildLeadTile),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }

  Widget _buildLeadTile(Map<String, dynamic> lead) {
    final status = lead['status']?.toString() ?? 'pending_review';
    final color = status == 'converted' || status == 'approved'
        ? AppTheme.accentGreen
        : status == 'rejected'
            ? const Color(0xFFEF4444)
            : AppTheme.primaryGold;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead['customer_name']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${WorkforceConstants.orderTypeLabels[lead['order_type']] ?? ''} ⋅ '
                  '${lead['customer_phone'] ?? ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              WorkforceConstants.leadStatusLabels[status] ?? status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
