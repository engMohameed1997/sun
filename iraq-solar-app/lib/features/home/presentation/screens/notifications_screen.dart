import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/network/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final res = await ApiClient.getNotifications(page: 1, perPage: 100);
    
    if (res['success'] == true && res['data'] != null && res['data']['notifications'] != null) {
      final List<dynamic> notifs = res['data']['notifications'];
      setState(() {
        _allNotifications = notifs.map((n) {
          return _mapNotification(n as Map<String, dynamic>);
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
  
  Map<String, dynamic> _mapNotification(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    
    // category mapping
    String category = 'offers';
    if (type == 'new_order' || type == 'order_status') {
      category = 'orders';
    } else if (type == 'system') {
      category = 'system';
    }
    
    // icon mapping
    IconData icon = Icons.notifications;
    Color iconColor = AppTheme.primaryGold;
    
    if (type == 'new_order') {
      icon = Icons.shopping_bag_rounded;
      iconColor = AppTheme.primaryGold;
    } else if (type == 'order_status') {
      icon = Icons.local_shipping_rounded;
      iconColor = AppTheme.accentGreen;
    } else if (type == 'new_user') {
      icon = Icons.person_add_rounded;
      iconColor = const Color(0xFF3B82F6);
    } else if (type == 'system') {
      icon = Icons.system_security_update_good_rounded;
      iconColor = AppTheme.darkNavy;
    }

    return {
      'id': data['id'],
      'title': data['title'] ?? 'بدون عنوان',
      'body': data['body'] ?? '',
      'time': _formatTime(data['created_at']),
      'category': category,
      'icon': icon,
      'iconColor': iconColor,
      'isRead': data['is_read'] ?? false,
      'originalData': data,
    };
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
        return 'منذ ${diff.inMinutes} دقيقة';
      } else if (diff.inHours < 24) {
        if (diff.inHours == 1) return 'منذ ساعة';
        if (diff.inHours == 2) return 'منذ ساعتين';
        return 'منذ ${diff.inHours} ساعات';
      } else if (diff.inDays == 1) {
        return 'أمس';
      } else {
        return 'منذ ${diff.inDays} أيام';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markAllAsRead() async {
    final res = await ApiClient.markAllNotificationsAsRead();
    if (res['success'] == true) {
      setState(() {
        for (var n in _allNotifications) {
          n['isRead'] = true;
        }
      });
      if (mounted) {
        AppNotification.showSuccess(
          context,
          'تم تعليم جميع الإشعارات كمقروءة بنجاح 🔔',
        );
      }
    } else {
      if (mounted) {
        AppNotification.showError(context, res['message'] ?? 'فشل التحديث');
      }
    }
  }
  
  Future<void> _markAsRead(Map<String, dynamic> item) async {
    if (item['isRead'] == true) return;
    
    final res = await ApiClient.markNotificationAsRead(item['id']);
    if (res['success'] == true) {
      setState(() {
        item['isRead'] = true;
      });
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> item) async {
    final res = await ApiClient.deleteNotification(item['id']);
    if (res['success'] != true && mounted) {
      AppNotification.showError(context, res['message'] ?? 'فشل الحذف');
      _fetchNotifications(); // restore if failed
    }
  }

  List<Map<String, dynamic>> _getFilteredNotifications(String category) {
    if (category == 'all') return _allNotifications;
    return _allNotifications.where((n) => n['category'] == category).toList();
  }

  int get _unreadCount => _allNotifications.where((n) => n['isRead'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.darkNavy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Text(
                'مركز الإشعارات والتنبيهات',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (!_isLoading && !_hasError && _unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_unreadCount جديد',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!_isLoading && !_hasError && _allNotifications.isNotEmpty)
              TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all_rounded, color: AppTheme.primaryGold, size: 18),
                label: const Text(
                  'قراءة الكل',
                  style: TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppTheme.primaryGold,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryGold,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'الطلبات والمنظومات'),
              Tab(text: 'العروض والخصومات'),
              Tab(text: 'تنبيهات النظام'),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeleton();
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'عذراً، حدث خطأ أثناء جلب الإشعارات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
              ),
              child: const Text('إعادة المحاولة'),
            )
          ],
        ),
      );
    }
    
    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotificationList(_getFilteredNotifications('all')),
        _buildNotificationList(_getFilteredNotifications('orders')),
        _buildNotificationList(_getFilteredNotifications('offers')),
        _buildNotificationList(_getFilteredNotifications('system')),
      ],
    );
  }
  
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 14, color: Colors.grey.shade200),
                    const SizedBox(height: 10),
                    Container(width: double.infinity, height: 12, color: Colors.grey.shade200),
                    const SizedBox(height: 6),
                    Container(width: 200, height: 12, color: Colors.grey.shade200),
                    const SizedBox(height: 14),
                    Container(width: 60, height: 10, color: Colors.grey.shade200),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'لا يوجد إشعارات في هذا القسم حالياً',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: AppTheme.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final bool isRead = item['isRead'] ?? true;

          return Dismissible(
            key: Key(item['id']),
            background: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            onDismissed: (direction) {
              setState(() {
                _allNotifications.removeWhere((element) => element['id'] == item['id']);
              });
              _deleteNotification(item);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRead ? Colors.white : AppTheme.primaryGold.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRead ? Colors.grey.shade200 : AppTheme.primaryGold.withOpacity(0.4),
                  width: isRead ? 1 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (item['iconColor'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isRead ? AppTheme.darkNavy : Colors.black,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['body'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isRead ? Colors.grey.shade600 : Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['time'] as String,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                            GestureDetector(
                              onTap: () {
                                _markAsRead(item);
                              },
                              child: const Text(
                                'عرض التفاصيل ←',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
