import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/workforce_constants.dart';

/// Customer tracking view for a service order.
///
/// Privacy rules: the customer only sees the technician's first name, rating,
/// project count and level — never a phone number.
class ServiceOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const ServiceOrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<ServiceOrderDetailScreen> createState() => _ServiceOrderDetailScreenState();
}

class _ServiceOrderDetailScreenState extends State<ServiceOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiClient.getServiceOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) _order = Map<String, dynamic>.from(res['data'] ?? {});
      _isLoading = false;
    });
  }

  Future<void> _openReviewSheet() async {
    int quality = 5;
    int punctuality = 5;
    int speed = 5;
    final commentController = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('قيّم الخدمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _ratingRow('جودة العمل', quality, (v) => setModalState(() => quality = v)),
              _ratingRow('الالتزام بالموعد', punctuality, (v) => setModalState(() => punctuality = v)),
              _ratingRow('سرعة الإنجاز', speed, (v) => setModalState(() => speed = v)),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'ملاحظاتك (اختياري)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('إرسال التقييم'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted != true) return;

    final res = await ApiClient.submitServiceReview(
      orderId: widget.orderId,
      qualityRating: quality,
      punctualityRating: punctuality,
      speedRating: speed,
      comment: commentController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? ''),
        backgroundColor: res['success'] == true ? AppTheme.accentGreen : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (res['success'] == true) _load();
  }

  static Widget _ratingRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13))),
          ...List.generate(
            5,
            (i) => IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => onChanged(i + 1),
              icon: Icon(
                i < value ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppTheme.primaryGold,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: Text(_order?['order_number']?.toString() ?? 'تتبع الطلب')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : _order == null
                ? const Center(child: Text('تعذر جلب الطلب'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        if (_order!['technician'] != null) ...[
                          _buildTechnicianCard(),
                          const SizedBox(height: 16),
                        ],
                        _buildTimelineCard(),
                        if (_order!['status'] == 'completed') ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openReviewSheet,
                              icon: const Icon(Icons.star_rounded),
                              label: const Text('قيّم الخدمة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _order?['status']?.toString() ?? '';
    final orderType = _order?['order_type']?.toString() ?? '';
    return Container(
      decoration: BoxDecoration(color: AppTheme.darkNavy, borderRadius: BorderRadius.circular(20)),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _order?['status_label_ar']?.toString() ??
                WorkforceConstants.customerStatusLabels[status] ??
                status,
            style: TextStyle(
              color: WorkforceConstants.statusColor(status),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_order?['governorate_name'] ?? ''} ⋅ ${_order?['address'] ?? ''}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (_order?['tracking'] != null) ...[
            const Divider(color: Colors.white24, height: 24),
            Row(
              children: [
                const Icon(Icons.near_me_rounded, color: AppTheme.accentGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الفني في الطريق إليك — يتم تحديث موقعه لحظياً',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTechnicianCard() {
    final tech = Map<String, dynamic>.from(_order!['technician']);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryGold.withOpacity(0.12),
            child: const Icon(Icons.engineering_rounded, color: AppTheme.primaryGold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tech['first_name']?.toString() ?? 'فني معتمد',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (tech['level_name_ar'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tech['level_name_ar'].toString(),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppTheme.primaryGold),
                    const SizedBox(width: 3),
                    Text(
                      '${(tech['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} ⋅ '
                      '${tech['completed_jobs_count'] ?? 0} مشروع منجز',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'التواصل يتم عبر المنصة لحمايتك',
                  style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final timeline = List<Map<String, dynamic>>.from(_order?['timeline'] ?? []);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مسار الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (timeline.isEmpty)
            const Text('لا يوجد سجل بعد', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
          else
            ...timeline.map((event) {
              final status = event['status']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: WorkforceConstants.statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            WorkforceConstants.customerStatusLabels[status] ?? status,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            event['created_at']?.toString().split('T').first ?? '',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
