import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/workforce_constants.dart';
import 'create_service_order_screen.dart';
import 'service_order_detail_screen.dart';

/// The customer's service order history with live status labels.
class ServiceOrdersListScreen extends StatefulWidget {
  const ServiceOrdersListScreen({Key? key}) : super(key: key);

  @override
  State<ServiceOrdersListScreen> createState() => _ServiceOrdersListScreenState();
}

class _ServiceOrdersListScreenState extends State<ServiceOrdersListScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    final res = await ApiClient.getMyServiceOrders();
    if (!mounted) return;
    setState(() {
      _orders = res['success'] == true
          ? List<Map<String, dynamic>>.from(res['data'] ?? [])
          : <Map<String, dynamic>>[];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(title: const Text('طلبات الخدمة')),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateServiceOrderScreen()),
            );
            _load();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('طلب خدمة'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : _orders.isEmpty
                ? RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 140),
                        Icon(Icons.handyman_outlined, size: 64, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات خدمة بعد',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'اطلب فنياً معتمداً وسيتم تعيينه تلقائياً',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _buildOrderTile(_orders[index]),
                    ),
                  ),
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? '';
    final orderType = order['order_type']?.toString() ?? '';
    final technician = order['technician'] as Map<String, dynamic>?;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceOrderDetailScreen(orderId: order['id'].toString()),
          ),
        );
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    WorkforceConstants.orderTypeIcons[orderType] ?? Icons.work_rounded,
                    color: AppTheme.primaryGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WorkforceConstants.orderTypeLabels[orderType] ?? orderType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        order['order_number']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: WorkforceConstants.statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order['status_label_ar']?.toString() ??
                        WorkforceConstants.customerStatusLabels[status] ??
                        status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: WorkforceConstants.statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            if (technician != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.engineering_rounded, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(
                    'الفني ${technician['first_name'] ?? ''} ⋅ '
                    '${(technician['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'}★',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
