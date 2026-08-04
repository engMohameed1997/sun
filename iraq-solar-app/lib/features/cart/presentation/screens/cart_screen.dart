import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/auth_guard.dart';
import 'checkout_screen.dart';

class SolarCartScreen extends StatefulWidget {
  const SolarCartScreen({Key? key}) : super(key: key);

  @override
  State<SolarCartScreen> createState() => _SolarCartScreenState();
}

class _SolarCartScreenState extends State<SolarCartScreen> {
  @override
  void initState() {
    super.initState();
    CartService.instance.cartChangeNotifier.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartService.instance.cartChangeNotifier.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  int get _subtotalIQD => CartService.instance.subtotalIQD;

  String _formatIQD(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع';
  }

  IconData _getProductIcon(String title) {
    if (title.contains('انفيرتر') || title.contains('Inverter') || title.contains('Deye')) {
      return Icons.bolt_rounded;
    } else if (title.contains('بطارية') || title.contains('Battery') || title.contains('Felicity')) {
      return Icons.battery_charging_full_rounded;
    } else if (title.contains('هيكل') || title.contains('تثبيت') || title.contains('كابل')) {
      return Icons.grid_on_rounded;
    }
    return Icons.solar_power_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartService.instance.items;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('سلة الشراء'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 14),
                    const Text('سلة الشراء فارغة حالياً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy)),
                    const SizedBox(height: 6),
                    Text('تصفح المتاجر لإضافة المشتريات', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cart Header Summary Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkNavy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.primaryGold, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('محتويات سلة المشتريات الشمولية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('${CartService.instance.totalItemsCount} قطع مختارة بقيمة إجمالية ${_formatIQD(_subtotalIQD)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Items List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('القطع والمكونات في السلة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                        Text('${cartItems.length} عناصر مختلفة', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Beautiful Product List Cards
                    ...cartItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildPremiumCartItemCard(index, item);
                    }).toList(),

                    const SizedBox(height: 20),

                    // Subtotal Summary Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('مجموع المشتريات بالدينار:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy, fontSize: 14)),
                              Text(_formatIQD(_subtotalIQD), style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text('أجور التوصيل والخصومات سيتم احتسابها في الخطوة التالية', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 16),

                          // Proceed to Checkout Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () async {
                                final isAuth = await AuthGuard.requireAuth(
                                  context,
                                  reasonMessage: 'يرجى تسجيل الدخول برقم الهاتف والرمز لإكمال الشراء وتحديد موقع التوصيل.',
                                );
                                if (isAuth && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(' اكمال  الشراء ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGold, size: 18),
                                ],
                              ),
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

  Widget _buildPremiumCartItemCard(int index, CartItem item) {
    final int itemTotal = item.priceIQD * item.qty;
    final iconData = _getProductIcon(item.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(color: AppTheme.darkNavy.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Thumbnail Box
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.darkNavy, Color(0xFF1E293B)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Center(
                  child: Icon(iconData, color: AppTheme.primaryGold, size: 38),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Merchant Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: AppTheme.primaryGold, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.storeName,
                            style: const TextStyle(fontSize: 11, color: AppTheme.darkNavy, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'السعر المفرد: ${_formatIQD(item.priceIQD)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                onPressed: () => CartService.instance.removeItem(index),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom Control Row: Quantity Selector Pill & Total Sum in IQD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Modern Pill Quantity Controller
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkNavy,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => CartService.instance.updateQuantity(index, item.qty - 1),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Icon(Icons.remove, color: Colors.white, size: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: AppTheme.primaryGold,
                        child: Text(
                          '${item.qty}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      InkWell(
                        onTap: () => CartService.instance.updateQuantity(index, item.qty + 1),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // Item Calculated Total Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('مجموع القطعة:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                    Text(
                      _formatIQD(itemTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
