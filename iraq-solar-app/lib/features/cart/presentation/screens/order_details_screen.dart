import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

// ─── Data models ────────────────────────────────────────────────────────────

class OrderStatusEntry {
  final String id;
  final String? fromStatus;
  final String toStatus;
  final String? changedByName;
  final String? notes;
  final DateTime createdAt;

  const OrderStatusEntry({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    this.changedByName,
    this.notes,
    required this.createdAt,
  });

  factory OrderStatusEntry.fromJson(Map<String, dynamic> j) => OrderStatusEntry(
        id: j['id'] ?? '',
        fromStatus: j['from_status'],
        toStatus: j['to_status'] ?? '',
        changedByName: j['changed_by_name'],
        notes: j['notes'],
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

class OrderItem {
  final String productId;
  final String productName;
  final String? productSku;
  final int quantity;
  final double unitPriceIQD;
  final double totalPriceIQD;

  const OrderItem({
    required this.productId,
    required this.productName,
    this.productSku,
    required this.quantity,
    required this.unitPriceIQD,
    required this.totalPriceIQD,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: j['product_id'] ?? '',
        productName: j['product_name'] ?? 'منتج',
        productSku: j['product_sku'],
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        unitPriceIQD: (j['unit_price_iqd'] as num?)?.toDouble() ?? 0,
        totalPriceIQD: (j['total_price_iqd'] as num?)?.toDouble() ?? 0,
      );
}

class OrderDetail {
  final String id;
  final String status;
  final double totalAmountIQD;
  final String shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  // Customer
  final String customerName;
  final String customerPhone;
  // Store
  final String? storeName;
  final String? storePhone;
  // Branch
  final String? branchName;
  final String? branchCity;
  final String? branchAddress;
  // Collections
  final List<OrderItem> items;
  final List<OrderStatusEntry> statusHistory;

  const OrderDetail({
    required this.id,
    required this.status,
    required this.totalAmountIQD,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    this.storeName,
    this.storePhone,
    this.branchName,
    this.branchCity,
    this.branchAddress,
    required this.items,
    required this.statusHistory,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> j) => OrderDetail(
        id: j['id'] ?? '',
        status: j['status'] ?? 'pending',
        totalAmountIQD: (j['total_amount_iqd'] as num?)?.toDouble() ?? 0,
        shippingAddress: j['shipping_address'] ?? '',
        paymentMethod: j['payment_method'] ?? 'cash_on_delivery',
        paymentStatus: j['payment_status'] ?? 'unpaid',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        customerName: j['customer_name'] ?? '',
        customerPhone: j['customer_phone'] ?? '',
        storeName: j['store_name'],
        storePhone: j['store_phone'],
        branchName: j['branch_name'],
        branchCity: j['branch_city'],
        branchAddress: j['branch_address'],
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        statusHistory: (j['status_history'] as List<dynamic>? ?? [])
            .map((e) => OrderStatusEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  OrderDetail copyWith({String? status, List<OrderStatusEntry>? statusHistory}) => OrderDetail(
        id: id,
        status: status ?? this.status,
        totalAmountIQD: totalAmountIQD,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        createdAt: createdAt,
        customerName: customerName,
        customerPhone: customerPhone,
        storeName: storeName,
        storePhone: storePhone,
        branchName: branchName,
        branchCity: branchCity,
        branchAddress: branchAddress,
        items: items,
        statusHistory: statusHistory ?? this.statusHistory,
      );
}

// ─── Status helpers ──────────────────────────────────────────────────────────

class _StatusInfo {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatusInfo({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

_StatusInfo _statusInfo(String s) {
  switch (s) {
    case 'confirmed':
      return const _StatusInfo(label: 'تم التأكيد', color: Color(0xFF3B82F6), bg: Color(0xFFEFF6FF), icon: Icons.check_circle_rounded);
    case 'processing':
      return const _StatusInfo(label: 'قيد التجهيز', color: Color(0xFF8B5CF6), bg: Color(0xFFF5F3FF), icon: Icons.local_shipping_rounded);
    case 'completed':
      return const _StatusInfo(label: 'مكتمل ✅', color: Color(0xFF10B981), bg: Color(0xFFECFDF5), icon: Icons.inventory_2_rounded);
    case 'cancelled':
      return const _StatusInfo(label: 'ملغي', color: Color(0xFFEF4444), bg: Color(0xFFFEF2F2), icon: Icons.cancel_rounded);
    default: // pending
      return const _StatusInfo(label: 'قيد الانتظار', color: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB), icon: Icons.hourglass_top_rounded);
  }
}

String _formatIQD(double v) {
  final s = v.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '$s د.ع';
}

String _formatDateTime(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  return 'منذ ${diff.inDays} يوم';
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  // Legacy fallback params (used when navigating from checkout without API)
  final String? totalAmountIQD;
  final String? paymentMethod;

  const OrderDetailsScreen({
    Key? key,
    required this.orderId,
    this.totalAmountIQD,
    this.paymentMethod,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderDetail? _order;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;

  // WebSocket — live status updates
  http.Client? _wsClient;
  StreamController<Map<String, dynamic>>? _wsStream;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _wsStream?.close();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() { _isLoading = true; _error = null; });
    final token = await AuthStorageService.getToken();
    if (token == null) {
      setState(() { _isLoading = false; _error = 'يرجى تسجيل الدخول أولاً'; });
      return;
    }
    try {
      final res = await ApiClient.getOrderById(token, widget.orderId);
      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _order = OrderDetail.fromJson(res['data'] as Map<String, dynamic>);
          _isLoading = false;
        });
      } else {
        // Fallback: build minimal order from params
        setState(() {
          _isLoading = false;
          _order = null;
          _error = res['message']?.toString() ?? 'لم يتم العثور على الطلب';
        });
      }
    } catch (e) {
      setState(() { _isLoading = false; _error = 'خطأ في الاتصال بالسيرفر'; });
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد الإلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل تريد فعلاً إلغاء هذا الطلب؟\nلا يمكن التراجع عن هذا الإجراء.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('نعم، إلغاء الطلب', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    setState(() => _isCancelling = true);
    final token = await AuthStorageService.getToken();
    if (token != null) {
      final res = await ApiClient.cancelOrder(token, widget.orderId);
      if (res['success'] == true) {
        if (mounted) {
          setState(() {
            _isCancelling = false;
            if (_order != null) _order = _order!.copyWith(status: 'cancelled');
          });
          AppNotification.showSuccess(context, 'تم إلغاء الطلب بنجاح');
        }
      } else {
        setState(() => _isCancelling = false);
        if (mounted) AppNotification.showError(context, res['message']?.toString() ?? 'فشل إلغاء الطلب');
      }
    } else {
      setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: AppTheme.darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'طلب #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8).toUpperCase() : widget.orderId.toUpperCase()}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              onPressed: _loadOrder,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : _order == null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error ?? 'حدث خطأ',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy),
            ),
            const SizedBox(height: 8),
            // Show fallback info if available
            if (widget.totalAmountIQD != null) ...[
              const SizedBox(height: 12),
              _infoChip(Icons.payments_rounded, 'المبلغ: ${widget.totalAmountIQD}'),
              const SizedBox(height: 6),
              _infoChip(Icons.credit_card_rounded, 'الدفع: ${widget.paymentMethod ?? 'الدفع عند الاستلام'}'),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrder,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final o = _order!;
    final si = _statusInfo(o.status);
    final canCancel = o.status == 'pending' || o.status == 'confirmed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Banner ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.darkNavy, Color(0xFF1E3A5F)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppTheme.darkNavy.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: si.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: si.color.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(si.icon, color: si.color, size: 14),
                          const SizedBox(width: 6),
                          Text(si.label, style: TextStyle(color: si.color, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Text(
                      '#${o.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  o.storeName != null ? 'طلب من متجر ${o.storeName}' : 'طلبك قيد المعالجة',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (o.branchName != null || o.branchCity != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الفرع: ${o.branchName ?? ''} ${o.branchCity != null ? '- ${o.branchCity}' : ''}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'تاريخ الطلب: ${_formatDateTime(o.createdAt)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statPill(Icons.payments_rounded, _formatIQD(o.totalAmountIQD)),
                    _statPill(
                      o.paymentStatus == 'paid' ? Icons.check_circle_rounded : Icons.pending_rounded,
                      o.paymentStatus == 'paid' ? 'مدفوع' : 'غير مدفوع',
                      color: o.paymentStatus == 'paid' ? const Color(0xFF10B981) : AppTheme.primaryGold,
                    ),
                    _statPill(Icons.inventory_2_rounded, '${o.items.length} منتج'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Status Timeline ─────────────────────────────────────────
          if (o.statusHistory.isNotEmpty) ...[
            _sectionCard(
              title: 'سجل تتبع الطلب',
              icon: Icons.timeline_rounded,
              child: Column(
                children: o.statusHistory.asMap().entries.map((entry) {
                  final i = entry.key;
                  final h = entry.value;
                  final isLast = i == o.statusHistory.length - 1;
                  final info = _statusInfo(h.toStatus);
                  return _buildTimelineEntry(h, info, isLast);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Order Items ─────────────────────────────────────────────
          if (o.items.isNotEmpty) ...[
            _sectionCard(
              title: 'المنتجات المطلوبة (${o.items.length})',
              icon: Icons.shopping_bag_rounded,
              child: Column(
                children: [
                  ...o.items.map((item) => _buildItemRow(item)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المجموع الإجمالي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                      Text(_formatIQD(o.totalAmountIQD), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Delivery & Payment ──────────────────────────────────────
          _sectionCard(
            title: 'التوصيل والدفع',
            icon: Icons.local_shipping_rounded,
            child: Column(
              children: [
                _infoRow(Icons.location_on_rounded, 'عنوان التوصيل', o.shippingAddress),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.credit_card_rounded,
                  'طريقة الدفع',
                  o.paymentMethod == 'cash_on_delivery'
                      ? 'الدفع عند الاستلام بالدينار العراقي'
                      : o.paymentMethod == 'zain_cash'
                          ? 'زين كاش (ZainCash)'
                          : o.paymentMethod,
                ),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.receipt_long_rounded,
                  'حالة الدفع',
                  o.paymentStatus == 'paid' ? 'مدفوع ✅' : o.paymentStatus == 'failed' ? 'فشل الدفع ❌' : 'في انتظار الدفع',
                ),
                if (o.storePhone != null) ...[
                  const SizedBox(height: 10),
                  _infoRow(Icons.phone_rounded, 'هاتف المتجر', o.storePhone!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action Buttons ──────────────────────────────────────────
          if (canCancel)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isCancelling ? null : _cancelOrder,
                icon: _isCancelling
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                    : const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                label: Text(
                  _isCancelling ? 'جارٍ الإلغاء...' : 'إلغاء الطلب',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry(OrderStatusEntry h, _StatusInfo info, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: info.bg,
                shape: BoxShape.circle,
                border: Border.all(color: info.color.withOpacity(0.4), width: 2),
              ),
              child: Icon(info.icon, color: info.color, size: 16),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: info.color)),
                Text(_formatDateTime(h.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(_relativeTime(h.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                if (h.changedByName != null) ...[
                  const SizedBox(height: 2),
                  Text('بواسطة: ${h.changedByName}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                ],
                if (h.notes != null && h.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(h.notes!, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.solar_power_rounded, color: AppTheme.primaryGold, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy), maxLines: 2),
                if (item.productSku != null)
                  Text('SKU: ${item.productSku}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('×${item.quantity}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(_formatIQD(item.totalPriceIQD), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGold, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: AppTheme.darkNavy),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(color: Colors.grey)),
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statPill(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? AppTheme.primaryGold, size: 13),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color ?? Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy, fontSize: 13)),
        ],
      ),
    );
  }
}
