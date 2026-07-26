import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _allNotifications = [
    {
      'id': '1',
      'title': 'تأكيد طلب المنظومة الشمسية',
      'body': 'تم قبول طلبك لشراء انفيرتر Deye 8kW بطارية ليثيوم من متجر بغداد للطاقة. جاري التجهيز.',
      'time': 'منذ 15 دقيقة',
      'category': 'orders',
      'icon': Icons.shopping_bag_rounded,
      'iconColor': AppTheme.primaryGold,
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'خصم خاص 15% على بطاريات LiFePO4',
      'body': 'يقدم متجر دجلة للحلول الشمسية خصماً حصرياً على بطاريات Felicity 10.2kWh حتى نهاية الأسبوع.',
      'time': 'منذ ساعتين',
      'category': 'offers',
      'icon': Icons.local_offer_rounded,
      'iconColor': Color(0xFFEC4899),
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'تنبيه طقس شمسي: ارتفاع درجات الحرارة',
      'body': 'درجات الحرارة المتوقعة في بغداد اليوم 46°م. نوصي بتنظيف الألواح وتفقد تهوية الانفيرتر.',
      'time': 'اليوم 08:30 ص',
      'category': 'system',
      'icon': Icons.wb_sunny_rounded,
      'iconColor': Color(0xFFF59E0B),
      'isRead': true,
    },
    {
      'id': '4',
      'title': 'تقرير فحص الفني الميداني جاهز',
      'body': 'أكمل م. كرار العبيدي التقرير الفني الميداني لمنظومتك في الكرادة. انقر لمعاينة التقرير.',
      'time': 'أمس 04:15 م',
      'category': 'orders',
      'icon': Icons.engineering_rounded,
      'iconColor': AppTheme.accentGreen,
      'isRead': true,
    },
    {
      'id': '5',
      'title': 'عرض تركيب مجاني داخل البصرة',
      'body': 'احصل على تركيب ومعاينة هندسية مجانية عند طلب أي منظومة 5kW وأكثر من متجر البصرة سولار.',
      'time': 'منذ يومين',
      'category': 'offers',
      'icon': Icons.build_rounded,
      'iconColor': Color(0xFF3B82F6),
      'isRead': true,
    },
    {
      'id': '6',
      'title': 'تحديث التطبيق والنظام',
      'body': 'تمت إضافة ميزة حساب الاسترداد المالي ROI المتقدمة داخل حاسبة الأحمال العراقية.',
      'time': 'منذ 3 أيام',
      'category': 'system',
      'icon': Icons.system_security_update_good_rounded,
      'iconColor': AppTheme.darkNavy,
      'isRead': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _allNotifications) {
        n['isRead'] = true;
      }
    });
    AppNotification.showSuccess(
      context,
      'تم تعليم جميع الإشعارات كقروءة بنجاح 🔔',
    );
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
              if (_unreadCount > 0) ...[
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
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNotificationList(_getFilteredNotifications('all')),
            _buildNotificationList(_getFilteredNotifications('orders')),
            _buildNotificationList(_getFilteredNotifications('offers')),
            _buildNotificationList(_getFilteredNotifications('system')),
          ],
        ),
      ),
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

    return ListView.builder(
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
                              setState(() {
                                item['isRead'] = true;
                              });
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
    );
  }
}
