import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../cart/presentation/screens/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isAddedToCart = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final priceUSD = (p['price_usd'] ?? 115.0) as num;
    final totalPrice = priceUSD * _quantity;
    final priceIQD = (totalPrice * 1530).toInt(); // Standard 1 USD ~ 1530 IQD

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(p['name'] ?? 'تفاصيل المنتج الشمسي'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Display Container
              Container(
                width: double.infinity,
                height: 240,
                color: Colors.white,
                child: Center(
                  child: Icon(
                    p['type'] == 'inverter'
                        ? Icons.bolt_rounded
                        : p['type'] == 'battery'
                            ? Icons.battery_charging_full_rounded
                            : Icons.solar_power_rounded,
                    color: AppTheme.primaryGold,
                    size: 110,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p['brand'] ?? 'علامة تجارية معتمدة',
                            style: const TextStyle(color: AppTheme.secondaryGold, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text('4.9 (42 تقييم)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      p['name'] ?? 'لوح طاقة شمسية high-efficiency',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                    ),

                    const SizedBox(height: 12),

                    // Price Banner (IQD Only)
                    Row(
                      children: [
                        Text(
                          '${(priceIQD).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Specifications Breakdown
                    const Text('المواصفات الفنية والهندسية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 12),
                    _buildSpecRow('الضمان المصنعي:', p['warranty'] ?? '25 سنة ضمان كفاءة الأداء'),
                    _buildSpecRow('التقنية:', 'N-Type TOPCon Tier-1'),
                    _buildSpecRow('الكفاءة:', '21.5% High Efficiency'),
                    _buildSpecRow('حالة التوفر:', 'متوفر في مستودع المتجر (${p['stock'] ?? 150} قطعة)'),

                    const Divider(height: 32),

                    // Merchant Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppTheme.darkNavy,
                            child: Icon(Icons.storefront_rounded, color: AppTheme.primaryGold),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['brand'] ?? 'متجر بغداد للطاقة الشمسية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('مورد معتمد في العراق • الكرادة', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('تواصل', style: TextStyle(color: AppTheme.darkNavy)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Quantity & Add to Cart / Checkout Action Button
                    Row(
                      children: [
                        // Quantity selector
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (_quantity > 1) setState(() => _quantity--);
                                },
                              ),
                              Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Dynamic Action Button (إضافة إلى السلة -> إكمال الشراء)
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_isAddedToCart) {
                                  // Direct navigation to Cart Screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SolarCartScreen()),
                                  );
                                } else {
                                  // Add to cart & toggle state
                                  CartService.instance.addItem(
                                    id: p['name'] ?? 'product_item',
                                    title: p['name'] ?? 'منتج شمسي',
                                    storeName: p['brand'] ?? 'متجر طاقة معتمد',
                                    priceIQD: priceIQD ~/ _quantity,
                                    qty: _quantity,
                                  );

                                  setState(() {
                                    _isAddedToCart = true;
                                  });

                                  AppNotification.showSuccess(
                                    context,
                                    'تمت إضافة ${p['name']} إلى سلة الشراء بنجاح 🛒',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isAddedToCart ? AppTheme.darkNavy : AppTheme.primaryGold,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isAddedToCart ? Icons.shopping_bag_rounded : Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isAddedToCart ? 'إكمال الشراء (عرض السلة) 🛒' : 'إضافة إلى السلة',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  Widget _buildSpecRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
        ],
      ),
    );
  }
}
