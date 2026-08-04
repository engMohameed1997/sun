import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/product_image_widget.dart';
import '../widgets/store_chat_dialog.dart';
import '../widgets/store_banner_carousel.dart';
import '../../../products/presentation/screens/product_detail_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final Map<String, dynamic> storeData;

  const StoreDetailScreen({Key? key, required this.storeData}) : super(key: key);

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final TextEditingController _storeSearchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  bool _isFavoriteStore = false;

  List<Map<String, dynamic>> _storeCategories = [
    {'title': 'الكل', 'icon': Icons.grid_view_rounded, 'category_id': null},
  ];
  List<Map<String, dynamic>> _allStoreProducts = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    CartService.instance.cartChangeNotifier.addListener(_onCartChanged);
    _fetchStoreProducts();
  }

  Future<void> _fetchStoreProducts() async {
    final storeId = widget.storeData['id']?.toString() ?? '';
    final res = await ApiClient.getProducts();
    final catRes = await ApiClient.getCategories();

    Map<int, String> categoryNames = {};
    if (catRes['data'] != null && catRes['data'] is List) {
      for (final cat in catRes['data'] as List) {
        final cm = cat as Map<String, dynamic>;
        categoryNames[cm['id'] as int] = cm['name'] as String;
      }
    }

    if (mounted) {
      setState(() {
        if (res['data'] != null && res['data'] is List) {
          final list = res['data'] as List;
          _allStoreProducts = list.where((item) {
            final m = item as Map<String, dynamic>;
            return storeId.isEmpty || m['store_id']?.toString() == storeId;
          }).map((item) {
            final m = item as Map<String, dynamic>;
            final priceRaw = (m['price_iqd'] ?? 0).toInt();
            final priceFormatted = '${priceRaw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},')} د.ع';
            final catId = m['category_id'];
            final catName = catId != null ? (categoryNames[catId] ?? 'تصنيف $catId') : 'منظومات شمسية';
            final rawSpecs = m['specifications'];
            final specsMap = rawSpecs != null && rawSpecs is Map
                ? Map<String, dynamic>.from(rawSpecs)
                : <String, dynamic>{};
            final warrantyVal = specsMap['الضمان']?.toString() ?? '';
            final storeName = widget.storeData['name']?.toString() ?? 'متجر غير محدد';
            final storeRating = widget.storeData['rating'];
            final ratingStr = storeRating != null ? '$storeRating ⭐' : '—';
            return <String, dynamic>{
              'id': m['id']?.toString() ?? '',
              'name': m['name'] ?? '',
              'brand': m['brand_name'] ?? 'ماركة معتمدة',
              'model': m['model'] ?? '',
              'store': storeName,
              'store_id': widget.storeData['id']?.toString() ?? m['store_id']?.toString() ?? '',
              'branch_id': m['branch_id']?.toString() ?? '',
              'store_description': widget.storeData['description'] ?? '',
              'is_verified': widget.storeData['is_verified'] ?? widget.storeData['verified'] ?? false,
              'category': catName,
              'category_id': catId,
              'price': priceFormatted,
              'priceIQD': priceFormatted,
              'price_iqd': priceRaw,
              'image': 'assets/images/solar_panel_longi.jpg',
              'rating': ratingStr,
              'warranty': warrantyVal,
              'stock': m['stock_quantity'] ?? 50,
              'type': m['type'] ?? 'panel',
              'specs': specsMap,
              'isFeatured': m['is_available'] ?? false,
            };
          }).toList();

          // Build dynamic categories from products (unique, no duplicates)
          final seenCategories = <String>{};
          _storeCategories = [
            {'title': 'الكل', 'icon': Icons.grid_view_rounded, 'category_id': null},
          ];
          for (final p in _allStoreProducts) {
            final catName = p['category'] as String;
            if (!seenCategories.contains(catName)) {
              seenCategories.add(catName);
              _storeCategories.add({
                'title': catName,
                'icon': Icons.category_rounded,
                'category_id': p['category_id'],
              });
            }
          }
        }
        _isLoadingProducts = false;
      });
    }
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CartService.instance.cartChangeNotifier.removeListener(_onCartChanged);
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _allStoreProducts.where((product) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          product['category'] == _storeCategories[_selectedCategoryIndex]['title'];
      final matchesQuery = _searchQuery.isEmpty ||
          (product['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  IconData _getCategoryIcon(String title) {
    if (title.contains('ألواح') || title.contains('الواح')) return Icons.wb_sunny_rounded;
    if (title.contains('عواكس') || title.contains('انفيرتر')) return Icons.bolt_rounded;
    if (title.contains('بطاريات')) return Icons.battery_charging_full_rounded;
    if (title.contains('هياكل')) return Icons.build_circle_rounded;
    if (title.contains('كوابل') || title.contains('محولات')) return Icons.cable_rounded;
    return Icons.category_rounded;
  }

  String _formatIQD(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    final storeName = widget.storeData['name'] ?? 'متجر بغداد للطاقة الشمولية';
    final storeCity = widget.storeData['city'] ?? 'بغداد - الكرادة';
    final storeRating = widget.storeData['rating'] ?? '4.9 ⭐';
    final cartItemsCount = CartService.instance.totalItemsCount;
    final cartSubtotal = CartService.instance.subtotalIQD;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Dynamic Store Header Sliver App Bar
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppTheme.darkNavy,
                  leading: IconButton(
                    icon: const ContainerCircle(
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: ContainerCircle(
                        child: Icon(
                          _isFavoriteStore ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavoriteStore ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        setState(() => _isFavoriteStore = !_isFavoriteStore);
                        AppNotification.showSuccess(
                          context,
                          _isFavoriteStore ? 'تمت إضافة $storeName إلى المتاجر المفضلة ❤️' : 'تمت إزالة $storeName من المفضلة',
                        );
                      },
                    ),
                    IconButton(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const ContainerCircle(
                            child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                          ),
                          if (cartItemsCount > 0)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$cartItemsCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SolarCartScreen()),
                        );
                      },
                    ),
                    IconButton(
                      icon: const ContainerCircle(
                        child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                      ),
                      onPressed: () => StoreChatDialog.show(context, storeName: storeName, storeCity: storeCity),
                    ),
                    IconButton(
                      icon: const ContainerCircle(
                        child: Icon(Icons.share_outlined, color: Colors.white, size: 20),
                      ),
                      onPressed: () {},
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.darkNavy, Color(0xFF1E293B)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Icon(Icons.storefront_rounded, size: 200, color: Colors.white.withOpacity(0.04)),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                                  ],
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            storeName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (widget.storeData['is_verified'] == true || widget.storeData['verified'] == true)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentGreen,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text('معتمد 🛡️', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: AppTheme.primaryGold, size: 14),
                                        const SizedBox(width: 4),
                                        Text(storeCity, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.star_rounded, color: AppTheme.primaryGold, size: 14),
                                        const SizedBox(width: 2),
                                        Text(storeRating, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Store Body Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store-Restricted Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: TextField(
                            controller: _storeSearchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'ابحث داخل $storeName فقط...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold, size: 24),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                                      onPressed: () {
                                        _storeSearchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Store-Specific Auto-sliding Banner Carousel
                        StoreBannerCarouselWidget(storeName: storeName),

                        const SizedBox(height: 24),

                        // Circular Category Icons
                        const Text(
                          'أقسام ومكونات المتجر',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingProducts)
                          const SizedBox(
                            height: 95,
                            child: Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryGold),
                            ),
                          )
                        else if (_storeCategories.length <= 1)
                          const SizedBox(
                            height: 95,
                            child: Center(
                              child: Text('لا توجد أقسام بعد', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                          )
                        else
                        SizedBox(
                          height: 95,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _storeCategories.length,
                            itemBuilder: (context, index) {
                              final cat = _storeCategories[index];
                              final isSelected = _selectedCategoryIndex == index;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategoryIndex = index),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppTheme.primaryGold : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(cat['title'] as String),
                                          color: isSelected ? Colors.white : AppTheme.darkNavy,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat['title'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? AppTheme.primaryGold : AppTheme.darkNavy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Store Chat Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.darkNavy, Color(0xFF1E293B)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => StoreChatDialog.show(context, storeName: storeName, storeCity: storeCity),
                            icon: const Icon(Icons.chat_rounded, color: AppTheme.primaryGold, size: 22),
                            label: const Text(
                              'دردشة واستشارة فنية مباشرة مع المتجر',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Store Products Grid Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'منتجات ومكونات المتجر المعروضة',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy),
                            ),
                            Text(
                              '${_filteredProducts.length} منتج',
                              style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Products Grid (IQD Only)
                        _filteredProducts.isEmpty
                            ? Container(
                                height: 180,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'لا توجد منتجات تطابق البحث في $storeName',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.70,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredProducts[index];
                                  return _buildStoreProductCard(item, storeName);
                                },
                              ),

                        const SizedBox(height: 120), // Spacing for floating cart bar
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating Cart Summary Bar (زر عرض عناصر السلة المضافة وحساب قيمتها الإجمالية)
            if (cartItemsCount > 0)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SolarCartScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: AppTheme.darkNavy.withOpacity(0.35), blurRadius: 15, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGold,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$cartItemsCount',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'المجموع: ${_formatIQD(cartSubtotal)}',
                                  style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Text(
                                  'عناصر مضافة في سلة المشتريات',
                                  style: TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: const [
                            Text(
                              'إتمام الطلب',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGold, size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreProductCard(Map<String, dynamic> item, String storeName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: {
                ...item,
                'store': storeName,
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ProductImageWidget(
                      imagePath: item['image'] as String?,
                      type: item['type'] as String?,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.darkNavy.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'متوفر: ${item['stock'] ?? 20}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy), maxLines: 1),
            const SizedBox(height: 2),
            Text(item['warranty'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item['priceIQD'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 11),
                ),
                Container(
                  decoration: const BoxDecoration(color: AppTheme.darkNavy, shape: BoxShape.circle),
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 15),
                    onPressed: () {
                      int priceValue = 175000;
                      if (item['priceIQD'] != null) {
                        String cleanStr = (item['priceIQD'] as String).replaceAll('د.ع', '').replaceAll(',', '').trim();
                        priceValue = int.tryParse(cleanStr) ?? 175000;
                      }

                      CartService.instance.addItem(
                        id: item['id'] as String,
                        title: item['name'] as String,
                        storeName: storeName,
                        storeId: widget.storeData['id']?.toString() ?? item['store_id']?.toString() ?? '',
                        branchId: item['branch_id']?.toString(),
                        priceIQD: priceValue,
                        qty: 1,
                      );

                      AppNotification.showSuccess(
                        context,
                        'تمت إضافة ${item['name']} لسلة المشتريات بنجاح 🛒',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContainerCircle extends StatelessWidget {
  final Widget child;
  const ContainerCircle({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}
