import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/workforce_constants.dart';
import 'job_detail_screen.dart';

/// Live queue of dispatch offers sent to the technician.
///
/// Before accepting, the technician only sees limited details plus the
/// estimated payout and the reason they were selected.
class DispatchQueueScreen extends StatefulWidget {
  final VoidCallback? onAccepted;
  const DispatchQueueScreen({Key? key, this.onAccepted}) : super(key: key);

  @override
  State<DispatchQueueScreen> createState() => _DispatchQueueScreenState();
}

class _DispatchQueueScreenState extends State<DispatchQueueScreen> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  String? _busyDispatchId;
  Timer? _tick;
  StreamSubscription<WSMessage>? _wsSub;

  @override
  void initState() {
    super.initState();
    _load();

    // Refresh the countdown labels every second.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Real-time: a new dispatch offer arrives without pull-to-refresh.
    _wsSub = WebSocketService.instance.messageStream.listen((msg) {
      if (msg.event == 'new_dispatch' && mounted) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    final res = await ApiClient.getDispatchQueue();
    if (!mounted) return;
    setState(() {
      _offers = res['success'] == true
          ? List<Map<String, dynamic>>.from(res['data'] ?? [])
          : <Map<String, dynamic>>[];
      _isLoading = false;
    });
  }

  Future<void> _accept(Map<String, dynamic> offer) async {
    setState(() => _busyDispatchId = offer['dispatch_id']?.toString());
    final res = await ApiClient.acceptDispatch(offer['dispatch_id'].toString());
    if (!mounted) return;
    setState(() => _busyDispatchId = null);

    _showMessage(res['message']?.toString() ?? '', success: res['success'] == true);
    if (res['success'] == true) {
      widget.onAccepted?.call();
      await _load();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobDetailScreen(orderId: offer['order_id'].toString()),
        ),
      );
    } else {
      await _load();
    }
  }

  Future<void> _reject(Map<String, dynamic> offer) async {
    setState(() => _busyDispatchId = offer['dispatch_id']?.toString());
    final res = await ApiClient.rejectDispatch(offer['dispatch_id'].toString());
    if (!mounted) return;
    setState(() => _busyDispatchId = null);
    _showMessage(res['message']?.toString() ?? '', success: res['success'] == true);
    await _load();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    if (_offers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.inbox_rounded, size: 64, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'لا توجد مهام جديدة حالياً',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
            SizedBox(height: 6),
            Text(
              'تأكد أن حالتك "متوفر" ليصلك التوزيع التلقائي',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildOfferCard(_offers[index]),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    final orderType = offer['order_type']?.toString() ?? '';
    final expiresAt = DateTime.tryParse(offer['expires_at']?.toString() ?? '');
    final remaining = expiresAt != null ? expiresAt.difference(DateTime.now()) : null;
    final isBusy = _busyDispatchId == offer['dispatch_id']?.toString();
    final reason = offer['selection_reason_ar']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  WorkforceConstants.orderTypeIcons[orderType] ?? Icons.work_rounded,
                  color: AppTheme.primaryGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WorkforceConstants.orderTypeLabels[orderType] ?? orderType,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${offer['governorate_name'] ?? ''}'
                      '${offer['district_name'] != null ? ' ⋅ ${offer['district_name']}' : ''}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (remaining != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: remaining.inSeconds < 60
                        ? const Color(0xFFEF4444).withOpacity(0.12)
                        : AppTheme.darkNavy.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: remaining.inSeconds < 60 ? const Color(0xFFEF4444) : AppTheme.darkNavy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        WorkforceConstants.formatCountdown(remaining),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: remaining.inSeconds < 60 ? const Color(0xFFEF4444) : AppTheme.darkNavy,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (offer['system_size_kw'] != null)
                _chip('${offer['system_size_kw']} kW', Icons.bolt_rounded),
              if (offer['priority'] != null && offer['priority'] != 'normal')
                _chip('أولوية ${offer['priority']}', Icons.priority_high_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الأجر المتوقع', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(
                  WorkforceConstants.formatIqd(offer['estimated_payout_iqd'] as num?),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGreen,
                  ),
                ),
                const Text(
                  'التفاصيل الكاملة تظهر بعد القبول',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : () => _accept(offer),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(isBusy ? 'جارٍ...' : 'قبول المهمة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => _reject(offer),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('رفض'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
        ],
      ),
    );
  }
}
