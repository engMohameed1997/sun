import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/widgets/app_toast.dart';
import 'order_details_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // User Registration & Profile Data
  final TextEditingController _fullNameController = TextEditingController(text: 'محمد علي حسين العبيدي');
  final TextEditingController _phoneController = TextEditingController(text: '07701234567');
  final TextEditingController _districtController = TextEditingController(text: 'حي الكرادة - شارع 14 محلة 903 (قرب ساحة الواثق)');

  // Governorate Selection & Merchant Delivery Fees Map (بالدينار العراقي)
  String _selectedGovernorate = 'بغداد';
  final Map<String, int> _governorateDeliveryFees = {
    'بغداد': 15000,
    'البصرة': 35000,
    'أربيل': 30000,
    'النجف الأشرف': 20000,
    'كربلاء المقدسة': 20000,
    'نينوى (الموصل)': 35000,
    'كركوك': 30000,
    'ذي قار': 25000,
    'بابل': 20000,
    'السليمانية': 30000,
    'دهوك': 35000,
    'الانبار': 25000,
    'ديالى': 20000,
    'ميسان': 25000,
    'المثنى': 25000,
    'القادسية': 20000,
    'واسط': 20000,
    'صلاح الدين': 30000,
  };

  // Payment Method
  String _selectedPaymentMethod = 'cash_on_delivery';

  // Coupon Code State
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCouponCode;
  int _couponDiscountIQD = 0;
  String? _couponStatusMessage;

  int get _subtotalIQD => CartService.instance.subtotalIQD;
  int get _deliveryIQD => _governorateDeliveryFees[_selectedGovernorate] ?? 25000;

  int get _totalIQD {
    int total = _subtotalIQD + _deliveryIQD - _couponDiscountIQD;
    return total < 0 ? 0 : total;
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      if (code == 'IRAQ10') {
        _appliedCouponCode = code;
        _couponDiscountIQD = (_subtotalIQD * 0.10).toInt();
        _couponStatusMessage = 'تم تطبيق كوبون خصم 10% بنجاح! ⚡';
      } else if (code == 'SOLAR50') {
        _appliedCouponCode = code;
        _couponDiscountIQD = 50000;
        _couponStatusMessage = 'تم تطبيق خصم 50,000 د.ع بنجاح! 🏷️';
      } else if (code == 'FREEINSPECT') {
        _appliedCouponCode = code;
        _couponDiscountIQD = _deliveryIQD;
        _couponStatusMessage = 'تم تطبيق كوبون المعاينة والتوصيل المجاني! 🚚';
      } else {
        _appliedCouponCode = null;
        _couponDiscountIQD = 0;
        _couponStatusMessage = 'رمز الكوبون غير صالح أو منتهي الصلاحية';
      }
    });
  }

  String _formatIQD(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('إكمال الشراء والتوصيل 🚚'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryGold, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إكمال طلب التوصيل والمعاينة الفنية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${CartService.instance.totalItemsCount} عناصر إجمالية بالسلة بقيمة ${_formatIQD(_subtotalIQD)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. User Registration & Identity Profile Form
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person_pin_rounded, color: AppTheme.primaryGold, size: 22),
                        SizedBox(width: 8),
                        Text('تفاصيل المشتري وعنوان التوصيل بالعراق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الثلاثي للمشتري',
                        hintText: 'مثال: محمد علي حسين',
                        prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف للتأكيد (07xxxxxxxx)',
                        prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(height: 12),

                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'المحافظة (لتحديد أجور التوصيل المعتمدة من المتجر)',
                        prefixIcon: Icon(Icons.map_rounded, color: AppTheme.primaryGold),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGovernorate,
                          isExpanded: true,
                          isDense: true,
                          items: _governorateDeliveryFees.keys.map((gov) {
                            final fee = _governorateDeliveryFees[gov];
                            return DropdownMenuItem<String>(
                              value: gov,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(gov, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
                                  Text('التوصيل: ${_formatIQD(fee!)}', style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedGovernorate = val;
                                if (_appliedCouponCode == 'FREEINSPECT') {
                                  _couponDiscountIQD = _deliveryIQD;
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان التفصيلي وأقرب نقطة دالة',
                        hintText: 'مثال: الكرادة محلة 903 شارع 14 قرب ساحة الواثق',
                        prefixIcon: Icon(Icons.home_work_rounded, color: AppTheme.primaryGold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Coupon & Discount Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.confirmation_number_rounded, color: AppTheme.primaryGold, size: 22),
                        SizedBox(width: 8),
                        Text('كوبونات ورموز الخصم (Promotions):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'أدخل الكوبون (مثال: IRAQ10)',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _applyCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('تطبيق الكوبون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),

                    if (_couponStatusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _couponStatusMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _appliedCouponCode != null ? AppTheme.accentGreen : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Payment Method Selection
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('طريقة التسديد والإنفاق في العراق:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                    const SizedBox(height: 10),
                    _buildPaymentRadio('cash_on_delivery', 'الدفع بالدينار العراقي عند الاستلام والمعاينة', Icons.payments_rounded),
                    _buildPaymentRadio('zain_cash', 'محفظة زين كاش الرقمية (ZainCash)', Icons.account_balance_wallet_rounded),
                    _buildPaymentRadio('qi_card', 'بطاقة ماستر كارد / بطاقة سوبر كي Qi Card', Icons.credit_card_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Order Cost Summary Breakdown Card (IQD Only)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkNavy,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.darkNavy.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('مجموع القطع المضافة:', style: TextStyle(color: Colors.white70)),
                        Text(_formatIQD(_subtotalIQD), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('أجور التوصيل إلى $_selectedGovernorate:', style: const TextStyle(color: Colors.white70)),
                        Text(_formatIQD(_deliveryIQD), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    if (_couponDiscountIQD > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('خصم الكوبون (${_appliedCouponCode}):', style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
                          Text('- ${_formatIQD(_couponDiscountIQD)}', style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],

                    const Divider(color: Colors.white30, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المجموع الإجمالي الكلي بالدينار:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          _formatIQD(_totalIQD),
                          style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Final Order Confirmation Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_fullNameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
                            AppNotification.showError(
                              context,
                              'يرجى كتابة الاسم الثلاثي ورقم الهاتف لتأكيد الطلب',
                            );
                            return;
                          }

                          final paymentLabel = _selectedPaymentMethod == 'cash_on_delivery'
                              ? 'الدفع نقداً بالدينار عند الاستلام والمعاينة'
                              : _selectedPaymentMethod == 'zain_cash'
                                  ? 'زين كاش (ZainCash)'
                                  : 'بطاقة كي كارد / سوبر كي';

                          final token = await AuthStorageService.getToken();
                          final orderData = {
                            'total_amount_usd': (_totalIQD / 1500.0),
                            'shipping_address': 'محافظة $_selectedGovernorate - ${_districtController.text}',
                            'payment_method': _selectedPaymentMethod,
                            'items': CartService.instance.items.map((i) => {
                              'title': i.title,
                              'quantity': i.qty,
                              'price_iqd': i.priceIQD,
                            }).toList(),
                          };

                          if (token != null && token.isNotEmpty) {
                            await ApiClient.createOrder(token, orderData);
                          }

                          final createdOrderId = '#IQ-2026-${(1000 + (DateTime.now().millisecondsSinceEpoch % 8999))}';
                          CartService.instance.clearCart();

                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsScreen(
                                orderId: createdOrderId,
                                totalAmountIQD: _formatIQD(_totalIQD),
                                paymentMethod: paymentLabel,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('تأكيد الطلب ومتابعة الشحن والتثبيت 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(String value, String label, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
      activeColor: AppTheme.primaryGold,
      title: Row(
        children: [
          Icon(icon, color: AppTheme.darkNavy, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy))),
        ],
      ),
    );
  }
}
