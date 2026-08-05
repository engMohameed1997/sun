import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/workforce_constants.dart';

/// Full job details available only after the technician accepts the dispatch.
///
/// While the job status is `on_the_way`, a periodic GPS ping is sent so the
/// customer can see the technician approaching.
class JobDetailScreen extends StatefulWidget {
  final String orderId;
  const JobDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _media = [];
  Map<String, dynamic>? _pricing;
  bool _isLoading = true;
  Timer? _trackingTimer;

  static const List<Map<String, String>> _statusFlow = [
    {'status': 'on_the_way', 'label': 'في الطريق'},
    {'status': 'arrived', 'label': 'وصلت'},
    {'status': 'working', 'label': 'بدأت العمل'},
    {'status': 'completed', 'label': 'تم الإنجاز'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await ApiClient.getJobDetail(widget.orderId);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = res['data'] ?? {};
      setState(() {
        _order = Map<String, dynamic>.from(data['order'] ?? {});
        _tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
        _media = List<Map<String, dynamic>>.from(data['media'] ?? []);
        _pricing = data['pricing'] != null ? Map<String, dynamic>.from(data['pricing']) : null;
        _isLoading = false;
      });
      _syncTrackingTimer();
    } else {
      setState(() => _isLoading = false);
      _showMessage(res['message']?.toString() ?? 'تعذر جلب تفاصيل المهمة', success: false);
    }
  }

  /// Starts/stops the periodic GPS ping based on the current job status.
  void _syncTrackingTimer() {
    final status = _order?['status']?.toString();
    if (status == 'on_the_way') {
      _trackingTimer ??= Timer.periodic(const Duration(seconds: 45), (_) => _pushTracking());
    } else {
      _trackingTimer?.cancel();
      _trackingTimer = null;
    }
  }

  Future<void> _pushTracking() async {
    final lat = _order?['lat'];
    final lng = _order?['lng'];
    if (lat == null || lng == null) return;
    await ApiClient.updateTracking(
      orderId: widget.orderId,
      lat: (lat as num).toDouble(),
      lng: (lng as num).toDouble(),
      status: 'on_the_way',
    );
  }

  Future<void> _updateStatus(String status) async {
    if (status == 'completed') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد الإنجاز'),
          content: const Text('سيتم إغلاق المهمة وإضافة الأجر إلى محفظتك. هل أنت متأكد؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final res = await ApiClient.updateAssignmentStatus(widget.orderId, status);
    if (!mounted) return;
    _showMessage(res['message']?.toString() ?? '', success: res['success'] == true);
    if (res['success'] == true) await _load();
  }

  Future<void> _toggleTask(Map<String, dynamic> task) async {
    final res = await ApiClient.toggleJobTask(widget.orderId, task['id'].toString());
    if (res['success'] == true) await _load();
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة ملاحظة'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'اكتب ملاحظتك...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('حفظ')),
        ],
      ),
    );
    if (note == null || note.trim().isEmpty) return;

    final res = await ApiClient.uploadJobMedia(orderId: widget.orderId, type: 'note', content: note.trim());
    if (!mounted) return;
    _showMessage(res['message']?.toString() ?? '', success: res['success'] == true);
    if (res['success'] == true) await _load();
  }

  Future<void> _markCustomerUnavailable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('الزبون غير متجاوب'),
        content: const Text('سيتم تسجيل الحالة مع موقعك الحالي كإثبات لحمايتك. متابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await ApiClient.markCustomerUnavailable(
      orderId: widget.orderId,
      content: 'الزبون غير متجاوب',
      lat: (_order?['lat'] as num?)?.toDouble(),
      lng: (_order?['lng'] as num?)?.toDouble(),
    );
    if (!mounted) return;
    _showMessage(res['message']?.toString() ?? '', success: res['success'] == true);
    if (res['success'] == true) await _load();
  }

  void _showMessage(String message, {required bool success}) {
    if (message.isEmpty) return;
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
        appBar: AppBar(title: Text(_order?['order_number']?.toString() ?? 'تفاصيل المهمة')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : _order == null
                ? const Center(child: Text('تعذر جلب تفاصيل المهمة'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildStatusActions(),
                        const SizedBox(height: 16),
                        _buildTasksCard(),
                        const SizedBox(height: 16),
                        _buildMediaCard(),
                        const SizedBox(height: 16),
                        _buildProtectionCard(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final orderType = _order?['order_type']?.toString() ?? '';
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                WorkforceConstants.orderTypeIcons[orderType] ?? Icons.work_rounded,
                color: AppTheme.primaryGold,
              ),
              const SizedBox(width: 10),
              Text(
                WorkforceConstants.orderTypeLabels[orderType] ?? orderType,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: WorkforceConstants.statusColor(_order?['status']?.toString() ?? '').withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  WorkforceConstants.technicianStatusLabels[_order?['status']?.toString()] ??
                      _order?['status']?.toString() ??
                      '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: WorkforceConstants.statusColor(_order?['status']?.toString() ?? ''),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.person_rounded, _order?['customer_name']?.toString() ?? 'زبون'),
          if (_order?['customer_phone'] != null)
            _infoRow(Icons.phone_rounded, _order!['customer_phone'].toString()),
          _infoRow(
            Icons.location_on_rounded,
            '${_order?['governorate_name'] ?? ''} ⋅ ${_order?['address'] ?? '—'}',
          ),
          if (_order?['system_size_kw'] != null)
            _infoRow(Icons.bolt_rounded, 'حجم المنظومة: ${_order!['system_size_kw']} kW'),
          if ((_order?['description']?.toString() ?? '').isNotEmpty)
            _infoRow(Icons.notes_rounded, _order!['description'].toString()),
          if (_pricing != null) ...[
            const Divider(color: Colors.white24, height: 24),
            Text(
              'أجرك: ${WorkforceConstants.formatIqd(_pricing!['technician_payout_iqd'] as num?)}',
              style: const TextStyle(
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'قيمة الخدمة ${WorkforceConstants.formatIqd(_pricing!['base_price_iqd'] as num?)} '
              '⋅ عمولة المنصة ${_pricing!['platform_commission_percent']}%',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    final current = _order?['status']?.toString() ?? '';
    if (current == 'completed' || current == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحديث حالة التنفيذ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusFlow.map((step) {
              final isCurrent = current == step['status'];
              return ElevatedButton(
                onPressed: isCurrent ? null : () => _updateStatus(step['status']!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent ? const Color(0xFFE2E8F0) : AppTheme.primaryGold,
                  foregroundColor: isCurrent ? const Color(0xFF64748B) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(step['label']!, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('قائمة مهام التنفيذ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (_tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('لا توجد مهام', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            )
          else
            ..._tasks.map(
              (task) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppTheme.accentGreen,
                value: task['is_completed'] == true,
                onChanged: (_) => _toggleTask(task),
                title: Text(
                  task['title']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    decoration: task['is_completed'] == true ? TextDecoration.lineThrough : null,
                    color: task['is_completed'] == true ? const Color(0xFF94A3B8) : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('التوثيق والملاحظات', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addNote,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('ملاحظة', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (_media.isEmpty)
            const Text('لا توجد مرفقات بعد', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
          else
            ..._media.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      m['type'] == 'note' ? Icons.sticky_note_2_rounded : Icons.image_rounded,
                      size: 16,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m['content']?.toString() ?? m['url']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProtectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حماية الفني',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
          ),
          const SizedBox(height: 4),
          const Text(
            'إذا لم يتجاوب الزبون بعد وصولك، سجّل الحالة مع موقعك كإثبات.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _markCustomerUnavailable,
            icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18),
            label: const Text('الزبون غير متجاوب'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
