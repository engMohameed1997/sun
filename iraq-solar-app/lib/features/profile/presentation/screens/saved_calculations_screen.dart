import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class SavedCalculationsScreen extends StatefulWidget {
  const SavedCalculationsScreen({Key? key}) : super(key: key);

  @override
  State<SavedCalculationsScreen> createState() => _SavedCalculationsScreenState();
}

class _SavedCalculationsScreenState extends State<SavedCalculationsScreen> {
  final List<Map<String, dynamic>> _calculations = [];

  void _deleteCalculation(int index) {
    final item = _calculations[index];
    setState(() {
      _calculations.removeAt(index);
    });
    AppNotification.showSuccess(context, 'تم حذف تصميم "${item['title']}" من المحفوظات');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('التصاميم والحسابات المحفوظة'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: _calculations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_rounded, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا توجد حسابات محفوظة حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _calculations.length,
                itemBuilder: (context, index) {
                  final item = _calculations[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                              child: Text(item['type'], style: const TextStyle(color: AppTheme.darkNavy, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Text(item['date'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy)),
                        const SizedBox(height: 6),
                        Text(item['details'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['costIQD'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share_rounded, color: AppTheme.darkNavy, size: 20),
                                  onPressed: () {
                                    AppNotification.showInfo(context, 'تم نسخ رابط تقرير "${item['title']}" للمشاركة');
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  onPressed: () => _deleteCalculation(index),
                                ),
                              ],
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
