import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../workforce/technician/technician_dashboard_screen.dart';
import 'home_screen.dart';
import '../../../calculator/presentation/screens/calculator_screen.dart';
import '../../../products/presentation/screens/catalog_screen.dart';
import '../../../installers/presentation/screens/installers_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  StreamSubscription<WSMessage>? _wsSub;

  /// Roles that get the technician workspace instead of the customer shell.
  static const Set<String> _technicianRoles = {'installer', 'engineer'};

  bool _isResolvingRole = true;
  bool _isTechnician = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _resolveRole();

    // Listen for incoming notifications & order status changes and show SnackBar
    _wsSub = WebSocketService.instance.messageStream.listen((msg) {
      if ((msg.event == 'notification.created' || msg.event == 'order.status_changed') && mounted) {
        String title = 'إشعار جديد 🔔';
        String body = '';

        if (msg.isNotification || msg.event == 'notification.created') {
          title = msg.payload['title']?.toString() ?? 'إشعار جديد';
          body = msg.payload['body']?.toString() ?? '';
        } else {
          title = 'تحديث حالة الطلب 📦';
          final toStatus = msg.payload['to_status']?.toString() ?? '';
          final notes = msg.payload['notes']?.toString() ?? '';
          body = 'تم تغيير حالة طلبك${toStatus.isNotEmpty ? ' إلى $toStatus' : ''}${notes.isNotEmpty ? ' - $notes' : ''}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppTheme.primaryGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (body.toString().isNotEmpty)
                        Text(
                          body.toString(),
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.darkNavy,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'عرض',
              textColor: AppTheme.primaryGold,
              onPressed: () {
                // Navigate to notifications tab or screen
                setState(() => _currentIndex = 0);
              },
            ),
          ),
        );
      }
    });
  }

  /// Reads the cached user role to decide which shell to render.
  Future<void> _resolveRole() async {
    final user = await AuthStorageService.getUser();
    if (!mounted) return;
    setState(() {
      _isTechnician = _technicianRoles.contains(user?['role']?.toString());
      _isResolvingRole = false;
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  void _onTabSelect(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolvingRole) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }

    if (_isTechnician) {
      return const TechnicianDashboardScreen();
    }

    final List<Widget> screens = [
      SuperQiHomeScreen(
        onNavigateTab: _onTabSelect,
      ),
      const SolarCatalogScreen(),
      const SolarCalculatorScreen(),
      const SolarInstallersScreen(),
      const SolarSettingsScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),

            // Super Qi Style Persistent Floating Navigation Bar (5 Items)
            Positioned(
              left: 14,
              right: 14,
              bottom: 16,
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: AppTheme.darkNavy,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkNavy.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
                    _buildNavItem(1, Icons.storefront_rounded, 'المتاجر'),
                    _buildNavItem(2, Icons.calculate_rounded, 'الحاسبة'),
                    _buildNavItem(3, Icons.engineering_rounded, 'الفنيين'),
                    _buildNavItem(4, Icons.settings_rounded, 'الإعدادات'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
