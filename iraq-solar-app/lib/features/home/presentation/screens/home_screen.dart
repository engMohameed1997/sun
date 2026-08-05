import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/services/websocket_service.dart';
import 'notifications_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../widgets/search_filter_sheet.dart';
import '../widgets/banner_carousel.dart';
import '../../../merchant/presentation/screens/store_detail_screen.dart';
import '../../../products/presentation/screens/product_detail_screen.dart';
import '../../../products/presentation/screens/catalog_screen.dart';
import '../../../../core/widgets/product_image_widget.dart';

class SuperQiHomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const SuperQiHomeScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  State<SuperQiHomeScreen> createState() => _SuperQiHomeScreenState();
}

class _SuperQiHomeScreenState extends State<SuperQiHomeScreen> {
  final ScrollController _storesScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _storesList = [];
  List<Map<String, dynamic>> _productsList = [];
  List<Map<String, dynamic>> _installersList = [];
  bool _isLoadingData = true;
  String _userName = '';
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchLiveData();
  }

  @override
  void dispose() {
    _storesScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final isAuth = await AuthStorageService.isLoggedIn();
    final user = await AuthStorageService.getUser();
    if (mounted) {
      setState(() {
        _isLoggedIn = isAuth;
        if (isAuth && user != null && user['full_name'] != null && user['full_name'].toString().isNotEmpty) {
          _userName = user['full_name'].toString();
        } else {
          _userName = '';
        }
      });
    }

    if (isAuth) {
      // Connect WebSocket for real-time notifications
      WebSocketService.instance.connect();

      // Fetch initial unread count from REST API
      final unreadRes = await ApiClient.getUnreadNotificationCount();
      if (unreadRes['success'] == true && unreadRes['data'] != null) {
        final rawCount = unreadRes['data']['unread_count'] ?? unreadRes['data']['count'] ?? 0;
        final count = rawCount is int ? rawCount : (int.tryParse(rawCount.toString()) ?? 0);
        WebSocketService.instance.setUnread(count);
      }

      final profileRes = await ApiClient.getUserProfile();
      if (profileRes['success'] == true && profileRes['data'] != null && profileRes['data'] is Map) {
        final data = profileRes['data'] as Map<String, dynamic>;
        final name = data['full_name']?.toString() ?? '';
        if (name.isNotEmpty && mounted) {
          setState(() {
            _userName = name;
          });
        }
      }
    }
  }

  Future<void> _fetchLiveData() async {
    final productsRes = await ApiClient.getProducts();
    final storesRes = await ApiClient.getStores();
    final installersRes = await ApiClient.getInstallers(perPage: 10);

    if (mounted) {
      setState(() {
        // Build stores map first for product lookups
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
          _storesList = storesList.map((s) {
            final sm = s as Map<String, dynamic>;
            final logoUrl = ApiClient.resolveImageUrl(sm['logo_url'] ?? sm['logo']);
            final coverUrl = ApiClient.resolveImageUrl(sm['cover_url'] ?? sm['cover']);
            return {
              'id': sm['id']?.toString() ?? '',
              'name': sm['name'] ?? 'متجر طاقة متكامل',
              'description': sm['description'] ?? 'متجر طاقة شمسية معتمد في العراق',
              'fullName': sm['description'] ?? 'متجر طاقة شمسية معتمد في العراق',
              'logo_url': logoUrl,
              'cover_url': coverUrl,
              'logo': logoUrl,
              'cover': coverUrl,
              'rating': '${sm['rating'] ?? 0} ⭐',
              'city': sm['phone'] ?? '07700000000',
              'verified': sm['is_verified'] ?? true,
              'phone': sm['phone'] ?? '07700000000',
              'icon': Icons.wb_sunny_rounded,
              'color': const Color(0xFFF59E0B),
              'raw': sm,
            };
          }).toList();
        }

        if (productsRes['data'] != null && productsRes['data'] is List) {
          final list = productsRes['data'] as List;
          _productsList = list.map((item) {
            final m = item as Map<String, dynamic>;
            final priceRaw = (m['price_iqd'] ?? 0).toInt();
            final priceFormatted = '${priceRaw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]},')} د.ع';
            final rawSpecs = m['specifications'];
            final specsMap = rawSpecs != null && rawSpecs is Map
                ? Map<String, dynamic>.from(rawSpecs)
                : <String, dynamic>{};
            final warrantyVal = specsMap['الضمان']?.toString() ?? '';
            final storeId = m['store_id']?.toString() ?? '';
            final storeInfo = storeMap[storeId];
            final storeName = storeInfo?['name']?.toString() ?? 'متجر غير محدد';
            final storeRating = storeInfo?['rating'];
            final ratingStr = storeRating != null ? '$storeRating ⭐' : '—';
            final rawImg = ApiClient.resolveImageUrl(m['images']) ?? ApiClient.resolveImageUrl(m['image_url']) ?? ApiClient.resolveImageUrl(m['image']);
            return {
              'id': m['id']?.toString() ?? '',
              'name': m['name'] ?? '',
              'brand': m['brand_name'] ?? 'ماركة معتمدة',
              'model': m['model'] ?? '',
              'store': storeName,
              'store_description': storeInfo?['description'] ?? '',
              'is_verified': storeInfo?['is_verified'] ?? false,
              'category': m['category_id'] ?? 'منظومات شمسية',
              'price': priceFormatted,
              'priceIQD': priceFormatted,
              'price_iqd': priceRaw,
              'image': rawImg ?? 'assets/images/solar_panel_longi.jpg',
              'imageUrl': rawImg,
              'rating': ratingStr,
              'warranty': warrantyVal,
              'stock': m['stock_quantity'] ?? 50,
              'type': m['type'] ?? 'panel',
              'specs': specsMap,
              'isFeatured': m['is_available'] ?? false,
            };
          }).toList();
        }

        if (installersRes['data'] != null && installersRes['data'] is Map) {
          final installersData = installersRes['data'] as Map<String, dynamic>;
          final installers = installersData['installers'] as List? ?? [];
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

  void _executeSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SolarCatalogScreen(
            initialSearchQuery: cleanQuery,
          ),
        ),
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

              const SizedBox(height: 16),

              // 2. Interactive Auto-sliding Banner Carousel
              BannerCarouselWidget(
                onBannerAction: (targetIndex) {
                  widget.onNavigateTab?.call(targetIndex);
                },
              ),

              const SizedBox(height: 24),

              // 3. Featured Solar Stores Section
              _buildStoresSection(),

              const SizedBox(height: 24),

              // 4. Solar Load Calculator Interactive Banner Card
              _buildCalculatorBannerCard(),

              const SizedBox(height: 24),

              // 5. Verified Technicians & Installers
              _buildSectionTitle(
                'فنيين ومهندسين معتمدين 👨‍🔧',
                onSeeAll: () => widget.onNavigateTab?.call(3),
              ),
              const SizedBox(height: 12),
              _buildVerifiedInstallersList(),

              const SizedBox(height: 24),

              // 6. Featured Solar Components & Products (أحدث المنتجات والمنظومات)
              if (_productsList.isNotEmpty) ...[
                _buildSectionTitle(
                  'أحدث الألواح والانفيرترات والبطاريات ⚡',
                  onSeeAll: () => widget.onNavigateTab?.call(1),
                ),
                const SizedBox(height: 12),
                _buildProductsGrid(),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 80), // Spacing for floating navbar
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
              GestureDetector(
                onTap: () async {
                  if (!_isLoggedIn) {
                    final loginSuccess = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const SolarLoginScreen()),
                    );
                    if (loginSuccess == true) {
                      _loadUserData();
                    }
                  }
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoggedIn && _userName.isNotEmpty
                              ? 'مرحباً، $_userName 👋'
                              : 'أهلاً بك في منصة الطاقة الشمسية 👋',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoggedIn ? 'استكشف أحدث المتاجر والعروض والحلول' : 'سجل الدخول للاستفادة الكاملة من الخدمات 🔑',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                        _loadUserData();
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ValueListenableBuilder<int>(
                      valueListenable: WebSocketService.instance.unreadCountNotifier,
                      builder: (context, count, _) {
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: EdgeInsets.all(count > 9 ? 2 : 0),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.darkNavy, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _executeSearch(_searchController.text),
                  child: const Icon(Icons.search_rounded, color: AppTheme.primaryGold, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {});
                    },
                    onSubmitted: (query) {
                      _executeSearch(query);
                    },
                    style: const TextStyle(fontSize: 14, color: AppTheme.darkNavy),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج، متجر، أو منظومة...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      SearchFilterSheet.show(context, onApply: (filters) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SolarCatalogScreen(
                              initialFilters: filters,
                              initialTabIndex: filters['scope'] == 'المتاجر المعتمدة' ? 0 : 1,
                            ),
                          ),
                        );
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.darkNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Premium Calculator Banner Card ---
  Widget _buildCalculatorBannerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.primaryGold.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkNavy.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGold, width: 1.5),
              ),
              child: const Icon(Icons.calculate_rounded, color: AppTheme.primaryGold, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'أداة حاسبة الأحمال ☀️',
                          style: TextStyle(color: AppTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'احسب احتياجك من الألواح والبطاريات والتكلفة بالدينار',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                widget.onNavigateTab?.call(2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.darkNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 3,
              ),
              child: const Text('احسب الآن ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Featured Stores Section ---
  Widget _buildStoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'المتاجر والشركات المعتمدة 🏪',
          onSeeAll: () => widget.onNavigateTab?.call(1),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 120,
          child: ListView.builder(
            controller: _storesScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: _storesList.length + 1,
            itemBuilder: (context, index) {
              if (index == _storesList.length) {
                return GestureDetector(
                  onTap: () {
                    widget.onNavigateTab?.call(1);
                  },
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppTheme.darkNavy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: AppTheme.primaryGold, size: 22),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'كل المتاجر ➔',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppTheme.darkNavy,
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
                  width: 96,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 1.5),
                            ),
                            child: store['logo_url'] != null && (store['logo_url'] as String).isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      store['logo_url'] as String,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(child: Icon(icon, color: color, size: 26)),
                                    ),
                                  )
                                : Center(
                                    child: Icon(icon, color: color, size: 26),
                                  ),
                          ),
                          if (store['verified'] == true)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(1),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_rounded, color: AppTheme.primaryGold, size: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store['name'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: AppTheme.darkNavy,
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
        childAspectRatio: 0.76,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: _productsList.take(4).map((p) {
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 11),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: AppTheme.darkNavy, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
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
        physics: const BouncingScrollPhysics(),
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
              width: 220,
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
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.engineering_rounded, color: AppTheme.primaryGold, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(inst['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy), maxLines: 1),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 11, color: Colors.grey.shade500),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(inst['location'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
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

  // --- Uniform Section Title Widget ---
  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkNavy,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 11,
                    color: AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
