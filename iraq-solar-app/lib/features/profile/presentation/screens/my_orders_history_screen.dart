import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/screens/order_details_screen.dart';

class MyOrdersHistoryScreen extends StatefulWidget {
  const MyOrdersHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersHistoryScreen> createState() => _MyOrdersHistoryScreenState();
}

class _MyOrdersHistoryScreenState extends State<MyOrdersHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserOrdersFromApi();
  }

  Future<void> _loadUserOrdersFromApi() async {
    final token = await AuthStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      final res = await ApiClient.getUserOrders(token);
      if (res['success'] == true && res['data'] != null && res['data'] is List) {
        final List fetched = res['data'];
        if (fetched.isNotEmpty) {
          final List<Map<String, dynamic>> parsed = [];
          for (var o in fetched) {
            final usd = (o['total_amount_usd'] is num) ? (o['total_amount_usd'] as num).toDouble() : 0.0;
            final iqd = (usd * 1500).toInt();
            parsed.add({
              'id': o['id']?.toString().substring(0, 8) ?? 'IQ-SOLAR',
              'date': o['created_at']?.toString().split('T')[0] ?? '2026-07-26',
              'status': o['status'] == 'pending' ? 'قيد المعالجة والتركيب 🚚' : 'تم التسليم بنجاح ✅',
              'statusColor': o['status'] == 'pending' ? Colors.orange.shade800 : Colors.green.shade700,
              'totalIQD': '${iqd.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع',
              'itemsCount': 1,
              'storeName': 'سولار العراق الرئيسي',
              'items': 'منظومة طاقة شمسية متكاملة',
              'paymentMethod': o['payment_method']?.toString() ?? 'cash_on_delivery',
            });
          }
          if (mounted) {
            setState(() {
              _orders.addAll(parsed);
              _isLoadingOrders = false;
            });
            return;
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingOrders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('سجل الطلبات والمنظومات المشتراة'),
          backgroundColor: AppTheme.darkNavy,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryGold,
            tabs: [
              Tab(text: 'الكل (${_orders.length})'),
              Tab(text: 'النشطة (${_orders.where((o) => o['statusColor'] == Colors.orange.shade800).length})'),
              Tab(text: 'المكتملة (${_orders.where((o) => o['statusColor'] == Colors.green.shade700).length})'),
            ],
          ),
        ),
        body: _isLoadingOrders
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
            : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('لا توجد طلبات حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                      ],
                    ),
                  )
                : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('طلب رقم #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (order['statusColor'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(order['status'], style: TextStyle(color: order['statusColor'], fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('المتجر المزود: ${order['storeName']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(order['items'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الإجمالي الشامل:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(order['totalIQD'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailsScreen(
                                orderId: order['id'],
                                totalAmountIQD: order['totalIQD'],
                                paymentMethod: order['paymentMethod'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('تفاصيل الطلب', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
