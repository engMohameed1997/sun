import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/network/api_client.dart';
import 'notifications_screen.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/banner_carousel.dart';
import '../../../merchant/presentation/screens/store_detail_screen.dart';
import '../../../products/presentation/screens/product_detail_screen.dart';
import '../../../products/presentation/screens/promotions_catalog_screen.dart';
import '../../../../core/data/mock_products_repository.dart';
import '../../../../core/widgets/product_image_widget.dart';

class SuperQiHomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const SuperQiHomeScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  State<SuperQiHomeScreen> createState() => _SuperQiHomeScreenState();
}

class _SuperQiHomeScreenState extends State<SuperQiHomeScreen> {
  final ScrollController _storesScrollController = ScrollController();
  List<Map<String, dynamic>> _storesList = [];
  List<Map<String, dynamic>> _productsList = [];
  List<Map<String, dynamic>> _installersList = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveData();
  }

  Future<void> _fetchLiveData() async {
    final productsRes = await ApiClient.getProducts();
    final storesRes = await ApiClient.getStores();
    final installersRes = await ApiClient.getInstallers(perPage: 10);

    if (mounted) {
      setState(() {
        if (productsRes['data'] != null && productsRes['data'] is List) {
          final list = productsRes['data'] as List;
          _productsList = list.map((item) {
            final m = item as Map<String, dynamic>;
            final priceUsd = (m['price_usd'] ?? 0.0).toDouble();
            final priceRaw = (priceUsd * 1500).toInt();
            return {
              'id': m['id']?.toString() ?? '',
              'name': m['name'] ?? '',
              'brand': m['brand'] ?? 'ماركة معتمدة',
              'store': 'متجر معتمد',
              'category': m['category_id'] ?? 'منظومات شمسية',
              'price': '${priceRaw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},')} د.ع',
              'priceIQD': '${priceRaw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},')} د.ع',
              'price_iqd': priceRaw,
              'price_usd': priceUsd,
              'image': 'assets/images/solar_panel_longi.jpg',
              'rating': '4.9 ⭐',
              'warranty': '25 سنة كفالة',
              'stock': m['stock_quantity'] ?? 50,
              'type': m['type'] ?? 'panel',
              'specs': m['specifications'] ?? {},
              'isFeatured': true,
            };
          }).toList();
        }

        if (storesRes['data'] != null && storesRes['data'] is List) {
          final stores = storesRes['data'] as List;
          _storesList = stores.map((s) {
            final sm = s as Map<String, dynamic>;
            return {
              'id': sm['id']?.toString() ?? '',
              'name': sm['full_name'] ?? 'متجر طاقة متكامل',
              'fullName': sm['full_name'] ?? 'متجر طاقة شمسية معتمد في العراق',
              'rating': '4.9 ⭐',
              'city': '${sm['governorate'] ?? 'بغداد'} - ${sm['city'] ?? 'المركز'}',
              'verified': sm['is_verified'] ?? true,
              'phone': sm['phone'] ?? '07700000000',
              'icon': Icons.wb_sunny_rounded,
              'color': const Color(0xFFF59E0B),
            };
          }).toList();
        }

        if (installersRes['data'] != null && installersRes['data'] is List) {
          final installers = installersRes['data'] as List;
          _installersList = installers.map((i) {
            final im = i as Map<String, dynamic>;
            final gov = im['governorate'] ?? '';
            final city = im['city'] ?? '';
            final location = city.isNotEmpty ? '$gov - $city' : gov;
            final role = im['role'] ?? 'installer';
            final roleLabel = role == 'engineer' ? 'مهندس طاقة شمسية' : 'فني تركيب منظومات';
            return {
              'id': im['id']?.toString() ?? '',
              'name': im['full_name'] ?? 'فني معتمد',
              'location': location.isNotEmpty ? location : 'العراق',
              'installs': roleLabel,
              'phone': im['phone'] ?? '',
              'is_verified': im['is_verified'] ?? false,
              'raw': im,
            };
          }).toList();
        }

        _isLoadingData = false;
      });
    }
  }

  void _scrollStoresLeft() {
    if (_storesScrollController.hasClients) {
      _storesScrollController.animateTo(
        _storesScrollController.offset - 280,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollStoresRight() {
    if (_storesScrollController.hasClients) {
      _storesScrollController.animateTo(
        _storesScrollController.offset + 280,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Header with Notifications Bell & Search Bar
              _buildSuperQiHeader(),

              const SizedBox(height: 12),

              // 2. Interactive Auto-sliding Banner Carousel (بنرات الشاشة الرئيسية)
              BannerCarouselWidget(
                onBannerAction: (targetIndex) {
                  widget.onNavigateTab?.call(targetIndex);
                },
              ),

              const SizedBox(height: 24),

              // 4. Featured Solar Stores Section (عرض اللوجو + اسم المتجر اسفله لاربع متاجر واسهم للتنقل لـ 10 متاجر وزر عرض كل المتاجر)
              _buildStoresSection(),

              const SizedBox(height: 24),

              // 5. Verified Technicians & Installers (فنيين ومهندسين)
              _buildSectionTitle(
                '👨‍🔧 فنيين ومهندسين   ',
                onSeeAll: () => widget.onNavigateTab?.call(4),
              ),
              const SizedBox(height: 12),
              _buildVerifiedInstallersList(),

              const SizedBox(height: 24),

              // 6. Solar Load Calculator Interactive Banner ("احسب الآن")
              _buildCalculatorBannerCard(),

              const SizedBox(height: 24),

              // 7. Featured Solar Components & Products (الألواح والانفيرترات بالدينار)
              _buildSectionTitle(
                'أحدث الألواح والانفيرترات والبطاريات',
                onSeeAll: () => widget.onNavigateTab?.call(3),
              ),
              const SizedBox(height: 12),
              _buildProductsGrid(),

              const SizedBox(height: 100), // Spacing for floating navbar
            ],
          ),
        ),
      ),
    );
  }

  // --- Super Qi Header ---
  Widget _buildSuperQiHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'أهلاً بك 👋',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.darkNavy, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              SearchFilterSheet.show(context, onApply: (filters) {
                AppNotification.showSuccess(
                  context,
                  'تم تطبيق الفلترة لـ ${filters['scope']} في ${filters['governorate']}',
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.primaryGold, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ابحث في جميع المتاجر، الألواح، والمحافظات...',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // --- Calculator Banner Card ---
  Widget _buildCalculatorBannerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryGold.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'أداة حاسبة المنظومة ☀️',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'احسب حاجتك من الألواح والبطاريات والتكلفة بالدينار بضغطة واحدة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                widget.onNavigateTab?.call(2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 4,
              ),
              child: const Text('احسب الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Featured Stores Section (Logo + Store Name, Arrow Navigation for 10 Stores, Header & End-of-List View All) ---
  Widget _buildStoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Section Title + View All Link + Scroll Arrows for 10 Stores
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
           
                  SizedBox(height: 2),
       
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(3),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض الكل',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGold),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppTheme.primaryGold),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Stores Carousel: Store Logo Avatar + Store Name Underneath + View All at End
        SizedBox(
          height: 135,
          child: ListView.builder(
            controller: _storesScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: _storesList.length + 1, // 10 Stores + 1 End View All Card
            itemBuilder: (context, index) {
              if (index == _storesList.length) {
                // 11th Card at End of List: "عرض كل المتاجر"
                return GestureDetector(
                  onTap: () {
                    widget.onNavigateTab?.call(3);
                  },
                  child: Container(
                    width: 86,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.darkNavy,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppTheme.darkNavy.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGold, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'عرض كل المتاجر ➔',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppTheme.darkNavy,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final store = _storesList[index];
              final color = (store['color'] as Color? ?? AppTheme.primaryGold);
              final icon = (store['icon'] as IconData? ?? Icons.storefront_rounded);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreDetailScreen(storeData: store),
                    ),
                  );
                },
                child: Container(
                  width: 86,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      // Store Logo Icon Box
                      Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 2),
                              boxShadow: [
                                BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Center(
                              child: Icon(icon, color: color, size: 34),
                            ),
                          ),
                          if (store['verified'] == true)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_rounded, color: AppTheme.primaryGold, size: 18),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Store Name Underneath
                      Text(
                        store['name'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppTheme.darkNavy,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Featured Products Grid (IQD Prices Only) ---
  Widget _buildProductsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.74,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _productsList.map((p) {
          return _buildProductTile(p);
        }).toList(),
      ),
    );
  }

  Widget _buildProductTile(Map<String, dynamic> product) {
    final imagePath = product['image'] as String?;
    final discountTag = product['discountTag'] as String?;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
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
                      imagePath: imagePath,
                      type: product['type'] as String?,
                    ),
                  ),
                  if (discountTag != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          discountTag,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product['store'] as String,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product['price'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppTheme.darkNavy, shape: BoxShape.circle),
                  child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Verified Installers ---
  Widget _buildVerifiedInstallersList() {
    if (_installersList.isEmpty) {
      return SizedBox(
        height: 95,
        child: Center(
          child: Text(
            'لا يوجد فنيين معتمدين حالياً',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ),
      );
    }

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _installersList.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final inst = _installersList[index];
          return GestureDetector(
            onTap: () {
              AppNotification.showInfo(
                context,
                'الاتصال بالفني المعتمد ${inst['name']}: ${inst['phone']}',
              );
            },
            child: Container(
              width: 225,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.darkNavy,
                    child: Icon(Icons.engineering_rounded, color: AppTheme.primaryGold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(inst['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy), maxLines: 1),
                        Text(inst['location'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), maxLines: 1),
                        Text(inst['installs'] as String, style: const TextStyle(fontSize: 10, color: AppTheme.primaryGold, fontWeight: FontWeight.bold), maxLines: 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text('عرض الكل', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
