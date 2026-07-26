import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('لوحة المتجر وإدارة المخزون'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Merchant Stats Grid
              Row(
                children: [
                  Expanded(child: _buildStatTile('إجمالي المنتجات', '48 قطعة', Icons.inventory_2_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatTile('المبيعات الشهرية', '21,375,000 د.ع', Icons.trending_up_rounded)),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Actions
              const Text('إجراءات المتجر:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy)),
              const SizedBox(height: 12),
              _buildActionTile('إضافة منتج أو لوح شمسي جديد', Icons.add_circle_outline_rounded),
              _buildActionTile('تحديث أسعار صرف الدولار والدينار', Icons.currency_exchange_rounded),
              _buildActionTile('إدارة الكميات المتوفرة بالمستودع', Icons.warehouse_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 28),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGold),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {},
      ),
    );
  }
}
