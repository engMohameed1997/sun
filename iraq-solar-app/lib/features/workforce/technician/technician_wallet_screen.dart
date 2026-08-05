import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../shared/workforce_constants.dart';

/// Technician wallet: balance, earnings, commissions and per-order transactions.
class TechnicianWalletScreen extends StatefulWidget {
  const TechnicianWalletScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianWalletScreen> createState() => _TechnicianWalletScreenState();
}

class _TechnicianWalletScreenState extends State<TechnicianWalletScreen> {
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiClient.getTechnicianWallet();
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _wallet = Map<String, dynamic>.from(res['data']?['wallet'] ?? {});
        _transactions = List<Map<String, dynamic>>.from(res['data']?['transactions'] ?? []);
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.darkNavy, Color(0xFF1E293B)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الرصيد الحالي', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  WorkforceConstants.formatIqd(_wallet?['balance_iqd'] as num?),
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statTile('إجمالي الأرباح', _wallet?['total_earned_iqd'] as num?),
                    const SizedBox(width: 12),
                    _statTile('المستحق', _wallet?['pending_payout_iqd'] as num?),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'إجمالي عمولات المنصة: ${WorkforceConstants.formatIqd(_wallet?['total_commission_iqd'] as num?)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('سجل المعاملات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          if (_transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('لا توجد معاملات بعد', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            )
          else
            ..._transactions.map(_buildTransactionTile),
        ],
      ),
    );
  }

  Widget _statTile(String label, num? value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 4),
            Text(
              WorkforceConstants.formatIqd(value),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final status = tx['payment_status']?.toString() ?? 'unpaid';
    final isSettled = status == 'settled';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: (isSettled ? AppTheme.accentGreen : AppTheme.primaryGold).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSettled ? Icons.check_circle_rounded : Icons.schedule_rounded,
              size: 18,
              color: isSettled ? AppTheme.accentGreen : AppTheme.primaryGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['order_number']?.toString() ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'عمولة ${tx['platform_commission_percent']}% ⋅ '
                  '${isSettled ? 'مُسدَّد' : 'قيد التسديد'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Text(
            WorkforceConstants.formatIqd(tx['technician_payout_iqd'] as num?),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGreen,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
