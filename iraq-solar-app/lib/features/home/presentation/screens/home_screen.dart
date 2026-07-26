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

class SuperQiHomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const SuperQiHomeScreen({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  State<SuperQiHomeScreen> createState() => _SuperQiHomeScreenState();
}

class _SuperQiHomeScreenState extends State<SuperQiHomeScreen> {
  final ScrollController _storesScrollController = ScrollController();

  final List<Map<String, dynamic>> _storesList = [
    {
      'id': 's1',
      'name': 'بغداد للطاقة',
      'fullName': 'متجر بغداد للطاقة الشمولية',
      'rating': '4.9 ⭐',
      'city': 'بغداد - الكرادة',
      'verified': true,
      'phone': '07701234567',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 's2',
      'name': 'دجلة الهجينة',
      'fullName': 'دجلة للحلول الشمسية الهجينة',
      'rating': '4.8 ⭐',
      'city': 'أربيل - العرصات',
      'verified': true,
      'phone': '07509876543',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 's3',
      'name': 'البصرة سولار',
      'fullName': 'البصرة سولار تك المعتمد',
      'rating': '4.9 ⭐',
      'city': 'البصرة - الجزائر',
      'verified': true,
      'phone': '07801122334',
      'icon': Icons.solar_power_rounded,
      'color': const Color(0xFF10B981),
    },
    {
      'id': 's4',
      'name': 'النجف تك',
      'fullName': 'النجف تكنولوجي للطاقة النظيفة',
      'rating': '4.7 ⭐',
      'city': 'النجف الأشرف - السنتر',
      'verified': true,
      'phone': '07715544332',
      'icon': Icons.electric_car_rounded,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 's5',
      'name': 'كربلاء جروب',
      'fullName': 'كربلاء سولار جروب المعتمد',
      'rating': '4.9 ⭐',
      'city': 'كربلاء المقدسة - الجمعية',
      'verified': true,
      'phone': '07812233445',
      'icon': Icons.energy_savings_leaf_rounded,
      'color': const Color(0xFFEC4899),
    },
    {
      'id': 's6',
      'name': 'النور النظيفة',
      'fullName': 'النور للطاقة الشمسية النظيفة',
      'rating': '4.8 ⭐',
      'city': 'نينوى (الموصل) - المجموعة',
      'verified': true,
      'phone': '07723344556',
      'icon': Icons.lightbulb_rounded,
      'color': const Color(0xFFF97316),
    },
    {
      'id': 's7',
      'name': 'الفرات هجين',
      'fullName': 'الفرات للحلول الشمسية الهجينة',
      'rating': '4.7 ⭐',
      'city': 'بابل (الحلة) - الشارع العام',
      'verified': true,
      'phone': '07823344556',
      'icon': Icons.power_rounded,
      'color': const Color(0xFF06B6D4),
    },
    {
      'id': 's8',
      'name': 'سومر سولار',
      'fullName': 'سومر لحلول الطاقة الشمسية',
      'rating': '4.8 ⭐',
      'city': 'ذي قار (الناصرية) - الحبوبي',
      'verified': true,
      'phone': '07834455667',
      'icon': Icons.offline_bolt_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'id': 's9',
      'name': 'بابا گرگر',
      'fullName': 'بابا گرگر للطاقة النظيفة',
      'rating': '4.9 ⭐',
      'city': 'كركوك - شارع المحافظة',
      'verified': true,
      'phone': '07734455667',
      'icon': Icons.shield_moon_rounded,
      'color': const Color(0xFF14B8A6),
    },
    {
      'id': 's10',
      'name': 'كوردستان انيرجي',
      'fullName': 'كوردستان للحلول الشمسية المتطورة',
      'rating': '4.9 ⭐',
      'city': 'السليمانية - سليم كندي',
      'verified': true,
      'phone': '07512233445',
      'icon': Icons.landscape_rounded,
      'color': const Color(0xFF84CC16),
    },
  ];

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

  final List<Map<String, dynamic>> _productsList = [
    {
      'id': 'p1',
      'name': 'LONGi 550W N-Type TOPCon',
      'store': 'متجر بغداد للطاقة',
      'price': '175,000 د.ع',
      'price_iqd': 175000,
      'brand': 'LONGi Solar',
      'type': 'panel',
    },
    {
      'id': 'p2',
      'name': 'انفيرتر Deye 8kW Hybrid',
      'store': 'دجلة للحلول الشمسية',
      'price': '1,875,000 د.ع',
      'price_iqd': 1875000,
      'brand': 'Deye',
      'type': 'inverter',
    },
    {
      'id': 'p3',
      'name': 'بطارية Felicity 10.2kWh LiFePO4',
      'store': 'البصرة سولار تك',
      'price': '2,175,000 د.ع',
      'price_iqd': 2175000,
      'brand': 'Felicity',
      'type': 'battery',
    },
    {
      'id': 'p4',
      'name': 'هيكل تثبيت ألمنيوم 4 ألواح',
      'store': 'متجر بغداد للطاقة',
      'price': '130,000 د.ع',
      'price_iqd': 130000,
      'brand': 'Solar Structure',
      'type': 'structure',
    },
  ];

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

              // 2. Interactive Auto-sliding Banner Carousel (بنرات الشاشة الرئيسية)
              BannerCarouselWidget(
                onBannerAction: (targetIndex) {
                  widget.onNavigateTab?.call(targetIndex);
                },
              ),

              const SizedBox(height: 20),

              // 3. Quick Actions Grid (حاسبة، متاجر، فنيين، عروض)
              _buildSuperQiQuickActionsGrid(),

              const SizedBox(height: 24),

              // 4. Featured Solar Stores Section (عرض اللوجو + اسم المتجر اسفله لاربع متاجر واسهم للتنقل لـ 10 متاجر وزر عرض كل المتاجر)
              _buildStoresSection(),

              const SizedBox(height: 24),

              // 5. Verified Technicians & Installers (فنيين ومهندسين)
              _buildSectionTitle(
                '👨‍🔧 فنيين ومهندسين معتمدين بالفحص والتركيب',
                onSeeAll: () => widget.onNavigateTab?.call(3),
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
                onSeeAll: () => widget.onNavigateTab?.call(2),
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
                      Text(
                        'منصة العراق للطاقة الشمسية',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

  // --- Quick Actions Grid ---
  Widget _buildSuperQiQuickActionsGrid() {
    final actions = [
      {
        'title': 'حاسبة الأحمال',
        'icon': Icons.calculate_rounded,
        'color': AppTheme.primaryGold,
        'action': () => widget.onNavigateTab?.call(1),
      },
      {
        'title': 'المتاجر',
        'icon': Icons.storefront_rounded,
        'color': AppTheme.darkNavy,
        'action': () => widget.onNavigateTab?.call(2),
      },
      {
        'title': 'دليل الفنيين',
        'icon': Icons.engineering_rounded,
        'color': AppTheme.accentGreen,
        'action': () => widget.onNavigateTab?.call(3),
      },
      {
        'title': 'العروض والخصومات',
        'icon': Icons.local_offer_rounded,
        'color': const Color(0xFFEC4899),
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PromotionsCatalogScreen()),
          );
        },
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: actions.map((act) {
            return GestureDetector(
              onTap: act['action'] as VoidCallback,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: (act['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    act['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.darkNavy),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
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
                widget.onNavigateTab?.call(1);
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
                  Text(
                    '🏪 أبرز المتاجر الرئيسية المعتمدة في العراق',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '4 متاجر بالشاشة (10 متاجر معتمدة بالكامل)',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(2),
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
                  const SizedBox(width: 6),
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppTheme.darkNavy),
                      onPressed: _scrollStoresRight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 15, color: AppTheme.darkNavy),
                      onPressed: _scrollStoresLeft,
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
                    widget.onNavigateTab?.call(2);
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.solar_power_rounded, color: AppTheme.primaryGold, size: 44),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(product['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy), maxLines: 1),
            Text(product['store'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), maxLines: 1),
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
    final installers = [
      {'name': 'م. كرار العبيدي', 'location': 'بغداد - الكرادة', 'installs': '120 منظومة فحص وحساب', 'phone': '07709988776'},
      {'name': 'فني صفا الناصري', 'location': 'البصرة - الجزائر', 'installs': '85 منظومة هجينة', 'phone': '07804455667'},
      {'name': 'م. أحمد الساعدي', 'location': 'أربيل - عينكاوة', 'installs': '150 منظومة صناعية', 'phone': '07503322114'},
    ];

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: installers.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final inst = installers[index];
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
                        Text(inst['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy), maxLines: 1),
                        Text(inst['location']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), maxLines: 1),
                        Text(inst['installs']!, style: const TextStyle(fontSize: 10, color: AppTheme.primaryGold, fontWeight: FontWeight.bold), maxLines: 1),
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
