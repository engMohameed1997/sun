import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/product_image_widget.dart';
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
    final priceIQDString = p['price'] ?? p['priceIQD'] ?? '175,000 د.ع';
    final imagePath = p['image'] ?? p['assetImage'];
    final specs = p['specs'] as Map<String, dynamic>?;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text(p['name'] ?? 'تفاصيل المنتج الشمسي'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product High-Res Image Header Container
              Container(
                width: double.infinity,
                height: 280,
                color: Colors.white,
                child: Stack(
                  children: [
                    ProductImageWidget(
                      imagePath: imagePath as String?,
                      type: p['type'] as String?,
                      fit: BoxFit.cover,
                    ),
                    if (p['discountTag'] != null)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            p['discountTag'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            p['brand'] ?? 'علامة تجارية معتمدة',
                            style: const TextStyle(color: AppTheme.secondaryGold, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              p['rating'] as String? ?? '4.9 ⭐',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Title
                    Text(
                      p['name'] ?? 'منتج طاقة شمسية عالي الكفاءة',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkNavy, height: 1.3),
                    ),

                    const SizedBox(height: 14),

                    // Price Banner (IQD Only)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          priceIQDString as String,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                        ),
                        if (p['originalPriceIQD'] != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            p['originalPriceIQD'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Stock availability badge
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'متوفر بالمخزن (${p['stock'] ?? 50} قطعة) • توصيل وفحص خلال 24 ساعة',
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Specifications Breakdown
                    const Text('📐 المواصفات الفنية والهندسية:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 12),

                    if (specs != null && specs.isNotEmpty)
                      ...specs.entries.map((entry) => _buildSpecRow(entry.key, entry.value)).toList()
                    else ...[
                      _buildSpecRow('النوع:', p['type'] ?? 'منتج طاقة شمسية'),
                      _buildSpecRow('الموديل:', p['model'] ?? '—'),
                      _buildSpecRow('الماركة:', p['brand'] ?? '—'),
                      _buildSpecRow('الضمان:', p['warranty'] ?? 'غير محدد'),
                    ],

                    const Divider(height: 32),

                    // Merchant Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.darkNavy,
                            child: Icon(Icons.storefront_rounded, color: AppTheme.primaryGold, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(p['store'] as String? ?? 'متجر غير محدد', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
                                    if (p['is_verified'] == true || p['verified'] == true) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                                      const SizedBox(width: 2),
                                      const Text('متجر موثّق', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(p['store_description'] as String? ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              AppNotification.showSuccess(context, 'جاري الاتصال بـ ${p['store']} عبر الواتساب...');
                            },
                            icon: const Icon(Icons.chat_rounded, size: 16),
                            label: const Text('واتساب', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: () {
                                  if (_quantity > 1) setState(() => _quantity--);
                                },
                              ),
                              Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
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
                                  final priceRaw = p['price_iqd'] ?? 175000;
                                  CartService.instance.addItem(
                                    id: p['id'] ?? p['name'],
                                    title: p['name'] ?? 'منتج شمسي',
                                    storeName: p['store'] ?? 'متجر طاقة معتمد',
                                    storeId: p['store_id']?.toString() ?? '',
                                    branchId: p['branch_id']?.toString(),
                                    priceIQD: priceRaw is int ? priceRaw : 175000,
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
                                elevation: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isAddedToCart ? Icons.shopping_bag_rounded : Icons.add_shopping_cart_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isAddedToCart ? 'السلة' : 'إضافة إلى السلة',
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

  Widget _buildSpecRow(String label, dynamic val) {
    final valStr = val?.toString() ?? '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(valStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
          ],
        ),
      ),
    );
  }
}
