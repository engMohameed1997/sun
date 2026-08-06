import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../shared/workforce_constants.dart';
import 'dispatch_queue_screen.dart';
import 'job_detail_screen.dart';
import 'technician_lead_screen.dart';
import 'technician_profile_screen.dart';
import 'technician_wallet_screen.dart';

/// Home shell for technicians (installer / engineer roles).
///
/// Tabs: new dispatch offers, current jobs, wallet, private leads.
/// A persistent availability switch controls whether the dispatch engine
/// can send this technician new work.
class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  int _tabIndex = 0;
  Map<String, dynamic>? _technician;
  String _availability = 'offline';
  bool _isUpdatingAvailability = false;
  final GlobalKey<_TechnicianAssignmentsViewState> _assignmentsKey = GlobalKey();
  StreamSubscription<WSMessage>? _wsSub;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _wsSub = WebSocketService.instance.messageStream.listen((msg) {
      if (!mounted) return;
      if (msg.event == 'new_dispatch' || msg.type == 'dispatch' || msg.event.startsWith('service_order')) {
        _assignmentsKey.currentState?.reload();
        AppNotification.showInfo(
          context,
          '⚡ تم إضافة طلب خدمة جديد إلى حسابك. يرجى فحص عروض العمل وطلباتك المكلفة.',
          title: 'إشعار مهمة جديد',
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final res = await ApiClient.getTechnicianProfile();
    if (!mounted) return;
    if (res['success'] == true) {
      final tech = Map<String, dynamic>.from(res['data']?['technician'] ?? {});
      setState(() {
        _technician = tech;
        _availability = tech['availability_status']?.toString() ?? 'offline';
      });
    }
  }

  Future<void> _setAvailability(String status) async {
    setState(() => _isUpdatingAvailability = true);
    final res = await ApiClient.updateAvailability(status: status);
    if (!mounted) return;
    setState(() {
      _isUpdatingAvailability = false;
      if (res['success'] == true) _availability = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? ''),
        backgroundColor: res['success'] == true ? AppTheme.accentGreen : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DispatchQueueScreen(onAccepted: () => _assignmentsKey.currentState?.reload()),
      _TechnicianAssignmentsView(key: _assignmentsKey),
      const TechnicianWalletScreen(),
      const TechnicianLeadScreen(),
      const TechnicianProfileScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: IndexedStack(index: _tabIndex, children: tabs)),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryGold.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.inbox_rounded), label: 'مهام جديدة'),
            NavigationDestination(icon: Icon(Icons.assignment_rounded), label: 'مهامي'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_rounded), label: 'المحفظة'),
            NavigationDestination(icon: Icon(Icons.person_add_alt_1_rounded), label: 'عملائي'),
            NavigationDestination(icon: Icon(Icons.person_rounded), label: 'ملفي'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryGold.withOpacity(0.15),
                child: const Icon(Icons.engineering_rounded, color: AppTheme.primaryGold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _technician?['full_name']?.toString() ?? 'الفني',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppTheme.primaryGold),
                        const SizedBox(width: 3),
                        Text(
                          '${(_technician?['rating'] as num?)?.toStringAsFixed(1) ?? '0.0'} ⋅ '
                          '${_technician?['completed_jobs_count'] ?? 0} عملية',
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        if (_technician?['level_name_ar'] != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _technician!['level_name_ar'].toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['available', 'busy', 'vacation', 'offline'].map((status) {
              final isActive = _availability == status;
              final color = WorkforceConstants.availabilityColor(status);
              return Expanded(
                child: GestureDetector(
                  onTap: _isUpdatingAvailability ? null : () => _setAvailability(status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.22) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? color : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          WorkforceConstants.availabilityLabels[status] ?? status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// List of jobs the technician has already accepted.
class _TechnicianAssignmentsView extends StatefulWidget {
  const _TechnicianAssignmentsView({Key? key}) : super(key: key);

  @override
  State<_TechnicianAssignmentsView> createState() => _TechnicianAssignmentsViewState();
}

class _TechnicianAssignmentsViewState extends State<_TechnicianAssignmentsView> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (mounted) setState(() => _isLoading = true);
    final res = await ApiClient.getTechnicianAssignments();
    if (!mounted) return;
    setState(() {
      _assignments = res['success'] == true
          ? List<Map<String, dynamic>>.from(res['data'] ?? [])
          : <Map<String, dynamic>>[];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    if (_assignments.isEmpty) {
      return RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.assignment_outlined, size: 64, color: Color(0xFFCBD5E1)),
            SizedBox(height: 16),
            Text(
              'لا توجد مهام مسندة إليك',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _assignments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final assignment = _assignments[index];
          final order = Map<String, dynamic>.from(assignment['order'] ?? {});
          final status = order['status']?.toString() ?? '';
          final orderType = order['order_type']?.toString() ?? '';

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(orderId: order['id'].toString()),
                ),
              );
              reload();
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
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
                          '${WorkforceConstants.orderTypeLabels[orderType] ?? orderType} ⋅ '
                          '${order['order_number'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order['customer_name'] ?? 'زبون'} ⋅ ${order['governorate_name'] ?? ''}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: WorkforceConstants.statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      WorkforceConstants.technicianStatusLabels[status] ?? status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: WorkforceConstants.statusColor(status),
                      ),
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
