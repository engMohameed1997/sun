import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../cart/presentation/screens/order_details_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

// ─── Order status helpers ────────────────────────────────────────────────────

class _StatusCfg {
  final String label;
  final String emoji;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatusCfg({
    required this.label,
    required this.emoji,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

_StatusCfg _statusCfg(String s) {
  switch (s) {
    case 'confirmed':
      return const _StatusCfg(label: 'مؤكد', emoji: '✅', color: Color(0xFF3B82F6), bg: Color(0xFFEFF6FF), icon: Icons.check_circle_rounded);
    case 'processing':
      return const _StatusCfg(label: 'قيد التجهيز', emoji: '🔄', color: Color(0xFF8B5CF6), bg: Color(0xFFF5F3FF), icon: Icons.local_shipping_rounded);
    case 'completed':
      return const _StatusCfg(label: 'مكتمل', emoji: '📦', color: Color(0xFF10B981), bg: Color(0xFFECFDF5), icon: Icons.inventory_2_rounded);
    case 'cancelled':
      return const _StatusCfg(label: 'ملغي', emoji: '❌', color: Color(0xFFEF4444), bg: Color(0xFFFEF2F2), icon: Icons.cancel_rounded);
    default:
      return const _StatusCfg(label: 'قيد الانتظار', emoji: '⏳', color: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB), icon: Icons.hourglass_top_rounded);
  }
}

String _formatIQD(num v) {
  return '${v.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} د.ع';
}

String _formatDate(String? raw) {
  if (raw == null) return '';
  try {
    final dt = DateTime.parse(raw);
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return raw.split('T').first;
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class MyOrdersHistoryScreen extends StatefulWidget {
  const MyOrdersHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersHistoryScreen> createState() => _MyOrdersHistoryScreenState();
}

class _MyOrdersHistoryScreenState extends State<MyOrdersHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _rawOrders = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isUnauthenticated = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _hasError = false; _isUnauthenticated = false; });
    var token = await AuthStorageService.getToken();
    if (token == null || token.isEmpty) {
      final refreshed = await ApiClient.refreshTokenApi();
      if (refreshed) {
        token = await AuthStorageService.getToken();
      }
    }
    if (token == null || token.isEmpty) {
      setState(() { _isLoading = false; _isUnauthenticated = true; _hasError = false; });
      return;
    }
    try {
      final res = await ApiClient.getUserOrders(token);
      if (res['success'] == true) {
        final data = res['data'];
        final List<Map<String, dynamic>> ordersList = (data != null && data is List)
            ? (data as List).cast<Map<String, dynamic>>()
            : [];
        setState(() {
          _rawOrders = ordersList;
          _isLoading = false;
          _hasError = false;
          _isUnauthenticated = false;
        });
      } else if (res['error_code'] == 'UNAUTHORIZED' ||
                 res['error'] != null ||
                 res['message']?.toString().contains('غير مصرح') == true ||
                 res['message']?.toString().contains('Authorization') == true) {
        setState(() { _isLoading = false; _isUnauthenticated = true; _hasError = false; });
      } else {
        setState(() { _isLoading = false; _hasError = true; _isUnauthenticated = false; });
      }
    } catch (_) {
      setState(() { _isLoading = false; _hasError = true; _isUnauthenticated = false; });
    }
  }

  List<Map<String, dynamic>> _filtered(String? status) {
    return _rawOrders.where((o) {
      final matchStatus = status == null || o['status'] == status;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          (o['id']?.toString().toLowerCase().contains(q) ?? false) ||
          (o['customer_name']?.toString().toLowerCase().contains(q) ?? false) ||
          (o['store_name']?.toString().toLowerCase().contains(q) ?? false);
      return matchStatus && matchSearch;
    }).toList();
  }

  void _openDetails(Map<String, dynamic> o) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(
          orderId: o['id']?.toString() ?? '',
        ),
      ),
    ).then((_) => _loadOrders()); // refresh on return
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('سجل الطلبات'),
          backgroundColor: AppTheme.darkNavy,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadOrders,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(98),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'بحث برقم الطلب أو المتجر...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                // Status tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryGold,
                  indicatorWeight: 3,
                  isScrollable: true,
                  labelColor: AppTheme.primaryGold,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(text: 'الكل (${_rawOrders.length})'),
                    Tab(text: 'انتظار (${_filtered('pending').length})'),
                    Tab(text: 'مؤكد (${_filtered('confirmed').length})'),
                    Tab(text: 'جاري (${_filtered('processing').length})'),
                    Tab(text: 'مكتمل (${_filtered('completed').length})'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : _isUnauthenticated
                ? _buildAuthRequired()
                : _hasError
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(null),
                          _buildList('pending'),
                          _buildList('confirmed'),
                          _buildList('processing'),
                          _buildList('completed'),
                        ],
                      ),
      ),
    );
  }

  Widget _buildAuthRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, size: 42, color: AppTheme.primaryGold),
            ),
            const SizedBox(height: 16),
            const Text(
              'تسجيل الدخول مطلوب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.darkNavy),
            ),
            const SizedBox(height: 8),
            const Text(
              'يرجى تسجيل الدخول أو إنشاء حساب جديد لاستعراض سجل طلبات الشراء والمنظومات وحالتها الميدانية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final success = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const SolarLoginScreen()),
                );
                if (success == true || mounted) {
                  _loadOrders();
                }
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('تسجيل الدخول / إنشاء حساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('تعذّر الاتصال بالسيرفر', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
          const SizedBox(height: 6),
          const Text('تحقق من اتصالك بالإنترنت وحاول مرة أخرى', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadOrders,
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
    );
  }

  Widget _buildList(String? status) {
    final orders = _filtered(status);
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('لا توجد طلبات في هذه الفئة', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
            const SizedBox(height: 4),
            const Text('استعرض المتاجر والمنتجات لإضافة منتجاتك وتأكيد طلبات الشراء.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.storefront_rounded, size: 18),
              label: const Text('تصفح المتاجر والمنتجات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    final status = o['status']?.toString() ?? 'pending';
    final cfg = _statusCfg(status);
    final orderId = o['id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase();
    final amount = (o['total_amount_iqd'] as num?) ?? 0;
    final storeName = o['store_name']?.toString() ?? o['store']?.toString() ?? 'المتجر';
    final branchName = o['branch_name']?.toString();
    final items = (o['items'] as List?)?.length ?? 1;
    final date = _formatDate(o['created_at']?.toString());
    final canCancel = status == 'pending' || status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.darkNavy.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryGold, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy, fontFamily: 'monospace')),
                        Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cfg.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cfg.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cfg.icon, color: cfg.color, size: 12),
                      const SizedBox(width: 4),
                      Text('${cfg.emoji} ${cfg.label}', style: TextStyle(color: cfg.color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store & Branch
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppTheme.primaryGold, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        storeName + (branchName != null ? ' — $branchName' : ''),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Amount & Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الإجمالي:', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text(_formatIQD(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 17)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkNavy.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$items منتج', style: const TextStyle(fontSize: 12, color: AppTheme.darkNavy, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDetails(o),
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: const Text('تفاصيل الطلب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    if (canCancel) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _confirmCancel(orderId),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد الإلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل تريد فعلاً إلغاء هذا الطلب؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('نعم، إلغاء', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    final token = await AuthStorageService.getToken();
    if (token == null) return;

    final res = await ApiClient.cancelOrder(token, orderId);
    if (!mounted) return;
    if (res['success'] == true) {
      AppNotification.showSuccess(context, 'تم إلغاء الطلب بنجاح');
      _loadOrders();
    } else {
      AppNotification.showError(context, res['message']?.toString() ?? 'فشل إلغاء الطلب');
    }
  }
}
