import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/product_image_widget.dart';
import '../../../merchant/presentation/screens/store_detail_screen.dart';

class PromotionsCatalogScreen extends StatefulWidget {
  const PromotionsCatalogScreen({Key? key}) : super(key: key);

  @override
  State<PromotionsCatalogScreen> createState() => _PromotionsCatalogScreenState();
}

class _PromotionsCatalogScreenState extends State<PromotionsCatalogScreen> {
  int _selectedCategoryIndex = 0;
  List<Map<String, dynamic>> _discountedProducts = [];
  List<String> _categories = ['الكل'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  Future<void> _fetchPromotions() async {
    final productsRes = await ApiClient.getProducts();
    final storesRes = await ApiClient.getStores();
    final catRes = await ApiClient.getCategories();

    // Build store map
    Map<String, Map<String, dynamic>> storeMap = {};
    if (storesRes['data'] != null) {
      List storesList = [];
      if (storesRes['data'] is Map) {
        storesList = (storesRes['data'] as Map<String, dynamic>)['stores'] as List? ?? [];
      } else if (storesRes['data'] is List) {
        storesList = storesRes['data'] as List;
      }
      for (final s in storesList) {
        final sm = s as Map<String, dynamic>;
        storeMap[sm['id']?.toString() ?? ''] = sm;
      }
    }

    // Build category names map
    Map<int, String> categoryNames = {};
    if (catRes['data'] != null && catRes['data'] is List) {
      for (final cat in catRes['data'] as List) {
        final cm = cat as Map<String, dynamic>;
        categoryNames[cm['id'] as int] = cm['name'] as String;
      }
    }

    if (mounted) {
      setState(() {
        if (productsRes['data'] != null && productsRes['data'] is List) {
          final list = productsRes['data'] as List;
          _discountedProducts = list.map((item) {
            final m = item as Map<String, dynamic>;
            final priceRaw = (m['price_iqd'] ?? 0).toInt();
            final priceFormatted = '${priceRaw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},')} د.ع';
            final rawSpecs = m['specifications'];
            final specsMap = rawSpecs != null && rawSpecs is Map
                ? Map<String, dynamic>.from(rawSpecs)
                : <String, dynamic>{};
            final warrantyVal = specsMap['الضمان']?.toString() ?? '';
            final catId = m['category_id'];
            final catName = catId != null ? (categoryNames[catId] ?? 'تصنيف $catId') : 'منظومات شمسية';
            final storeId = m['store_id']?.toString() ?? '';
            final storeInfo = storeMap[storeId];
            final storeName = storeInfo?['name']?.toString() ?? 'متجر غير محدد';
            final storeRating = storeInfo?['rating'];
            final ratingStr = storeRating != null ? '$storeRating ⭐' : '—';
            final storePhone = storeInfo?['phone']?.toString() ?? '07700000000';
            final rawImg = ApiClient.resolveImageUrl(m['images']) ?? ApiClient.resolveImageUrl(m['image_url']) ?? ApiClient.resolveImageUrl(m['image']);
            return {
              'id': m['id']?.toString() ?? '',
              'name': m['name'] ?? '',
              'brand': m['brand_name'] ?? 'ماركة معتمدة',
              'model': m['model'] ?? '',
              'category': catName,
              'price': priceFormatted,
              'priceIQD': priceFormatted,
              'price_iqd': priceRaw,
              'warranty': warrantyVal,
              'stock': m['stock_quantity'] ?? 50,
              'type': m['type'] ?? 'panel',
              'specs': specsMap,
              'image': rawImg ?? 'assets/images/solar_panel_longi.jpg',
              'imageUrl': rawImg,
              'store': storeName,
              'storeData': storeInfo ?? {
                'id': storeId,
                'name': storeName,
                'rating': ratingStr,
                'city': storePhone,
                'phone': storePhone,
              },
            };
          }).toList();

          // Build dynamic categories from products
          final seenCats = <String>{};
          _categories = ['الكل'];
          for (final p in _discountedProducts) {
            final cat = p['category'] as String;
            if (!seenCats.contains(cat)) {
              seenCats.add(cat);
              _categories.add(cat);
            }
          }
        } else {
          _discountedProducts = [];
        }
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredOffers {
    if (_selectedCategoryIndex == 0) return _discountedProducts;
    final selectedCat = _categories[_selectedCategoryIndex];
    return _discountedProducts.where((p) => p['category'] == selectedCat).toList();
  }

  void _navigateToStore(Map<String, dynamic> storeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreDetailScreen(storeData: storeData),
      ),
    );
  }

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
          title: const Text(
            'عروض وخصومات المتاجر الحصرية 🏷️',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: Column(
          children: [
            // Top Promo Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppTheme.darkNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_offer_rounded, color: AppTheme.primaryGold, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'تخفيضات وعروض الطاقة الشمسية ☀️',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'فقط المنتجات التي قام أصحاب المتاجر بتخفيض أسعارها وتقديم خصم مباشر عليها',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Category Filter Bar
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryGold : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.darkNavy,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Offers List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                  : _filteredOffers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text('لا توجد منتجات في قسم ${_categories[_selectedCategoryIndex]}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOffers.length,
                          itemBuilder: (context, index) {
                            final offer = _filteredOffers[index];
                            final storeData = offer['storeData'] as Map<String, dynamic>;

                            return GestureDetector(
                              onTap: () => _navigateToStore(storeData),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.primaryGold.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Title & Icon
                                     Row(
                                       children: [
                                         ClipRRect(
                                           borderRadius: BorderRadius.circular(16),
                                           child: SizedBox(
                                             width: 64,
                                             height: 64,
                                             child: ProductImageWidget(
                                               imagePath: offer['image'] as String?,
                                               type: offer['type'] as String?,
                                             ),
                                           ),
                                         ),
                                         const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                offer['name'] as String,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${offer['brand'] ?? ''} • ${offer['model'] ?? ''}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    // Price Row
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundLight,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('التصنيف:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                offer['category'] as String,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('السعر:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                offer['price'] as String,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // Merchant Store Badge & Direct Navigation Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront_rounded, color: AppTheme.darkNavy, size: 18),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  storeData['name'] as String,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy),
                                                ),
                                                Text(
                                                  storeData['phone'] as String,
                                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.darkNavy,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Row(
                                            children: [
                                              Text('الانتقال للمتجر والتسوق', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              SizedBox(width: 4),
                                              Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGold, size: 14),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
