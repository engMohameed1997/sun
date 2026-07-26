import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../merchant/presentation/screens/store_detail_screen.dart';

class SolarCatalogScreen extends StatefulWidget {
  const SolarCatalogScreen({Key? key}) : super(key: key);

  @override
  State<SolarCatalogScreen> createState() => _SolarCatalogScreenState();
}

class _SolarCatalogScreenState extends State<SolarCatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _universalSearchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  final Set<String> _favoriteStoreIds = {'s1', 's2'};

  final List<String> _categories = [
    'الكل',
    'ألواح شمسية',
    'انفيرترات هجينة',
    'بطاريات ليثيوم',
    'هياكل تثبيت',
    'كوابل وملحقات',
  ];

  final List<Map<String, dynamic>> _stores = [
    {
      'id': 's1',
      'name': 'متجر بغداد للطاقة الشمولية',
      'rating': '4.9 ⭐',
      'city': 'بغداد - الكرادة شارع الصناعة',
      'phone': '07701234567',
      'verified': true,
      'productsCount': 48,
    },
    {
      'id': 's2',
      'name': 'دجلة للحلول الشمسية الهجينة',
      'rating': '4.8 ⭐',
      'city': 'أربيل - شارع العرصات',
      'phone': '07509876543',
      'verified': true,
      'productsCount': 35,
    },
    {
      'id': 's3',
      'name': 'البصرة سولار تك المعتمد',
      'rating': '4.9 ⭐',
      'city': 'البصرة - حي الجزائر',
      'phone': '07801122334',
      'verified': true,
      'productsCount': 52,
    },
    {
      'id': 's4',
      'name': 'النجف تكنولوجي للطاقة النظيفة',
      'rating': '4.7 ⭐',
      'city': 'النجف الأشرف - شارع السنتر',
      'phone': '07715544332',
      'verified': true,
      'productsCount': 28,
    },
  ];

  final List<Map<String, dynamic>> _crossStoreProducts = [
    {
      'id': 'p1',
      'name': 'لوح طاقة شمسية LONGi 550W N-Type TOPCon',
      'category': 'ألواح شمسية',
      'priceIQD': '175,000 د.ع',
      'storeName': 'متجر بغداد للطاقة الشمولية',
      'storeData': {
        'id': 's1',
        'name': 'متجر بغداد للطاقة الشمولية',
        'rating': '4.9 ⭐',
        'city': 'بغداد - الكرادة شارع الصناعة',
      },
      'city': 'بغداد - الكرادة',
      'icon': Icons.solar_power_rounded,
    },
    {
      'id': 'p2',
      'name': 'انفيرتر هجين Deye 8kW Three Phase 48V',
      'category': 'انفيرترات هجينة',
      'priceIQD': '1,875,000 د.ع',
      'storeName': 'دجلة للحلول الشمسية الهجينة',
      'storeData': {
        'id': 's2',
        'name': 'دجلة للحلول الشمسية الهجينة',
        'rating': '4.8 ⭐',
        'city': 'أربيل - شارع العرصات',
      },
      'city': 'أربيل - العرصات',
      'icon': Icons.bolt_rounded,
    },
    {
      'id': 'p3',
      'name': 'بطارية ليثيوم Felicity 10.2kWh LiFePO4',
      'category': 'بطاريات ليثيوم',
      'priceIQD': '2,175,000 د.ع',
      'storeName': 'البصرة سولار تك المعتمد',
      'storeData': {
        'id': 's3',
        'name': 'البصرة سولار تك المعتمد',
        'rating': '4.9 ⭐',
        'city': 'البصرة - حي الجزائر',
      },
      'city': 'البصرة - الجزائر',
      'icon': Icons.battery_charging_full_rounded,
    },
    {
      'id': 'p4',
      'name': 'هيكل تثبيت ألمنيوم مقاوم للرياح 4 ألواح',
      'category': 'هياكل تثبيت',
      'priceIQD': '130,000 د.ع',
      'storeName': 'متجر بغداد للطاقة الشمولية',
      'storeData': {
        'id': 's1',
        'name': 'متجر بغداد للطاقة الشمولية',
        'rating': '4.9 ⭐',
        'city': 'بغداد - الكرادة شارع الصناعة',
      },
      'city': 'بغداد - الكرادة',
      'icon': Icons.grid_on_rounded,
    },
    {
      'id': 'p5',
      'name': 'كابل طاقة شمسية نحاسي 6mm² - 100 متر',
      'category': 'كوابل وملحقات',
      'priceIQD': '145,000 د.ع',
      'storeName': 'النجف تكنولوجي للطاقة النظيفة',
      'storeData': {
        'id': 's4',
        'name': 'النجف تكنولوجي للطاقة النظيفة',
        'rating': '4.7 ⭐',
        'city': 'النجف الأشرف - شارع السنتر',
      },
      'city': 'النجف الأشرف',
      'icon': Icons.cable_rounded,
    },
    {
      'id': 'p6',
      'name': 'منظومة طاقة شمسية كاملة 10kW مع البطاريات',
      'category': 'باكات كاملة',
      'priceIQD': '6,300,000 د.ع',
      'storeName': 'متجر بغداد للطاقة الشمولية',
      'storeData': {
        'id': 's1',
        'name': 'متجر بغداد للطاقة الشمولية',
        'rating': '4.9 ⭐',
        'city': 'بغداد - الكرادة شارع الصناعة',
      },
      'city': 'بغداد - الكرادة',
      'icon': Icons.home_max_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _crossStoreProducts.where((p) {
      final matchesCat = _selectedCategory == 'الكل' || p['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p['storeName'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredStores {
    return _stores.where((s) {
      return _searchQuery.isEmpty ||
          (s['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s['city'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
          title: const Text(
            'دليل المتاجر والبحث الشامل عن المنتجات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryGold,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryGold,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'المتاجر المعتمدة 🏬'),
              Tab(text: 'البحث عن المنتجات عبر المتاجر 🔍'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Universal Search Header
            Container(
              color: AppTheme.darkNavy,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _universalSearchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج أو متجر معين عبر كافة المتاجر...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                            onPressed: () {
                              _universalSearchController.clear();
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
            ),

            // Tab Views Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Stores Directory (المتاجر المعتمدة)
                  _buildStoresDirectoryTab(),

                  // Tab 2: Universal Cross-Store Products Search
                  _buildCrossStoreProductsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Stores Directory ---
  Widget _buildStoresDirectoryTab() {
    if (_filteredStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('لا توجد متاجر تطابق البحث', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStores.length,
      itemBuilder: (context, index) {
        final store = _filteredStores[index];
        return GestureDetector(
          onTap: () => _navigateToStore(store),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.darkNavy, width: 2),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              store['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('معتمد 🛡️', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(right: 6),
                                icon: Icon(
                                  _favoriteStoreIds.contains(store['id']) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: _favoriteStoreIds.contains(store['id']) ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  final storeId = store['id'] as String;
                                  final isFav = _favoriteStoreIds.contains(storeId);
                                  setState(() {
                                    if (isFav) {
                                      _favoriteStoreIds.remove(storeId);
                                    } else {
                                      _favoriteStoreIds.add(storeId);
                                    }
                                  });
                                  AppNotification.showSuccess(
                                    context,
                                    !isFav ? 'تمت إضافة ${store['name']} للمفضلة ❤️' : 'تمت إزالة ${store['name']} من المفضلة',
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.primaryGold, size: 14),
                          const SizedBox(width: 4),
                          Text(store['city'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(width: 10),
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(store['rating'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${store['productsCount']} منتج معروض بالمتجر', style: const TextStyle(fontSize: 11, color: AppTheme.darkNavy, fontWeight: FontWeight.bold)),
                          const Text('التسوق من المتجر ←', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Tab 2: Universal Cross-Store Products Search ---
  Widget _buildCrossStoreProductsTab() {
    return Column(
      children: [
        // Filter Categories Horizontal Scroll Bar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGold : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300),
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

        // Products Results List with Store Names & IQD Prices
        Expanded(
          child: _filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('لا توجد منتجات تطابق البحث في المتاجر', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final item = _filteredProducts[index];
                    final storeData = item['storeData'] as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () => _navigateToStore(storeData),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(item['icon'] as IconData, color: AppTheme.primaryGold, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Store Badge
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront_rounded, color: AppTheme.primaryGold, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'متوفر في: ${item['storeName']}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.darkNavy, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(item['city'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item['priceIQD'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkNavy,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('المتجر ←', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    );
  }
}
