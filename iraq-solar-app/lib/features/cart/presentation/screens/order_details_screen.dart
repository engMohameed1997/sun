import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../merchant/presentation/widgets/store_chat_dialog.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final String totalAmountIQD;
  final String paymentMethod;

  const OrderDetailsScreen({
    Key? key,
    this.orderId = '#IQ-2026-8849',
    this.totalAmountIQD = '5,810,000 د.ع',
    this.paymentMethod = 'الدفع عند الاستلام والمعاينة',
  }) : super(key: key);

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
          title: Text(
            'تفاصيل وتتبع الطلب $orderId',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Order Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.darkNavy, Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.darkNavy.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('جاري المعالجة والتجهيز 🔄', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        Text(
                          orderId,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'تم تأكيد الطلب من متجر بغداد للطاقة الشمولية',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'التاريخ: اليوم 01:45 م • وقت التوصيل المتوقع: غداً خلال 24 ساعة',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Order Live Status Timeline
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مراحل تتبع الطلب والتركيب الميداني:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                    const SizedBox(height: 16),
                    _buildTimelineStep('تم تقديم الطلب بنجاح', 'اليوم 01:45 م', true, true),
                    _buildTimelineStep('تم التأكيد من المتجر وتجهيز الفاتورة', 'اليوم 01:50 م', true, true),
                    _buildTimelineStep('جاري فحص الألواح وتجهيز البطاريات', 'جارٍ العمل الآن...', true, false),
                    _buildTimelineStep('قيد التوصيل الشاحنة للمحافظة (بغداد)', 'متوقع غداً 10:00 ص', false, false),
                    _buildTimelineStep('الفحص الهندسي والتركيب الميداني', 'متوقع غداً 02:00 م', false, false),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Purchased Items List (Prices strictly in IQD)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('المنتجات والقطع المطلوبة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                    const SizedBox(height: 12),
                    _buildOrderItemRow('لوح طاقة شمسية LONGi 550W (عدد 10)', '1,750,000 د.ع'),
                    _buildOrderItemRow('انفيرتر هجين Deye 8kW Three Phase (عدد 1)', '1,875,000 د.ع'),
                    _buildOrderItemRow('بطارية ليثيوم Felicity 10.2kWh (عدد 1)', '2,175,000 د.ع'),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('أجور النقل والتركيب:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const Text('35,000 د.ع', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الإجمالي الكلي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                        Text(totalAmountIQD, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Delivery Address & Payment Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('معلومات التوصيل والدفع:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('العنوان: بغداد - الكرادة - محلة 903 شارع 14', style: TextStyle(fontSize: 13, color: AppTheme.darkNavy)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        const Text('رقم المستلم: 07701234567', style: TextStyle(fontSize: 13, color: AppTheme.darkNavy)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.payment_rounded, color: AppTheme.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        Text('طريقة التسديد: $paymentMethod', style: const TextStyle(fontSize: 13, color: AppTheme.darkNavy)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons: Contact Merchant Chat & Call
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        StoreChatDialog.show(context, storeName: 'متجر بغداد للطاقة الشمولية', storeCity: 'بغداد - الكرادة');
                      },
                      icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                      label: const Text('محادثة المتجر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AppNotification.showInfo(
                          context,
                          'جاري الاتصال بالسائق والمجهز الميداني... 📞',
                        );
                      },
                      icon: const Icon(Icons.call_rounded, color: AppTheme.darkNavy, size: 18),
                      label: const Text('اتصال بالسائق', style: TextStyle(color: AppTheme.darkNavy, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppTheme.darkNavy, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String title, String time, bool isCompleted, bool isPast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isPast ? AppTheme.accentGreen : AppTheme.primaryGold)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? (isPast ? Icons.check : Icons.autorenew_rounded) : Icons.circle_outlined,
                color: Colors.white,
                size: 14,
              ),
            ),
            Container(
              width: 2,
              height: 34,
              color: isPast ? AppTheme.accentGreen : Colors.grey.shade300,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted ? AppTheme.darkNavy : Colors.grey.shade500,
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: isCompleted ? AppTheme.primaryGold : Colors.grey.shade400),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemRow(String name, String priceIQD) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: AppTheme.darkNavy), maxLines: 1)),
          Text(priceIQD, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 13)),
        ],
      ),
    );
  }
}
