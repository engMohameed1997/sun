import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../merchant/presentation/screens/store_detail_screen.dart';

class PromotionsCatalogScreen extends StatefulWidget {
  const PromotionsCatalogScreen({Key? key}) : super(key: key);

  @override
  State<PromotionsCatalogScreen> createState() => _PromotionsCatalogScreenState();
}

class _PromotionsCatalogScreenState extends State<PromotionsCatalogScreen> {
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'الكل',
    'ألواح شمسية',
    'انفيرترات هجينة',
    'بطاريات ليثيوم',
    'منظومات كاملة',
  ];

  final List<Map<String, dynamic>> _discountedProducts = [
    {
      'id': 'off1',
      'name': 'بطارية ليثيوم Felicity 10.2kWh LiFePO4 48V',
      'category': 'بطاريات ليثيوم',
      'originalPriceIQD': '2,500,000 د.ع',
      'offerPriceIQD': '2,175,000 د.ع',
      'savedIQD': 'وفرت 325,000 د.ع',
      'discountPercent': 'خصم 15% 🔥',
      'offerDetails': 'خصم خاص من متجر البصرة مع شحن وتوصيل فوري مجاني داخل المحافظة.',
      'expiryDate': 'ينتهي العرض خلال 3 أيام',
      'icon': Icons.battery_charging_full_rounded,
      'storeData': {
        'id': 's3',
        'name': 'البصرة سولار تك المعتمد',
        'rating': '4.9 ⭐',
        'city': 'البصرة - حي الجزائر',
        'phone': '07801122334',
      },
    },
    {
      'id': 'off2',
      'name': 'انفيرتر هجين Deye 8kW Three Phase 48V',
      'category': 'انفيرترات هجينة',
      'originalPriceIQD': '2,100,000 د.ع',
      'offerPriceIQD': '1,875,000 د.ع',
      'savedIQD': 'وفرت 225,000 د.ع',
      'discountPercent': 'خصم 10% ⚡',
      'offerDetails': 'عرض صيف العراق شامل كفالة 5 سنوات استبدال ومعاينة مجانية.',
      'expiryDate': 'ينتهي العرض بنهاية الأسبوع',
      'icon': Icons.bolt_rounded,
      'storeData': {
        'id': 's2',
        'name': 'دجلة للحلول الشمسية الهجينة',
        'rating': '4.8 ⭐',
        'city': 'أربيل - شارع العرصات',
        'phone': '07509876543',
      },
    },
    {
      'id': 'off3',
      'name': 'باك 10 ألواح شمسية LONGi 550W N-Type',
      'category': 'ألواح شمسية',
      'originalPriceIQD': '1,950,000 د.ع',
      'offerPriceIQD': '1,750,000 د.ع',
      'savedIQD': 'وفرت 200,000 د.ع',
      'discountPercent': 'خصم الجملة 🏷️',
      'offerDetails': 'عرض تصفية الموسم على ألواح التوبكون عالية الكفاءة مع قاعدة ألمنيوم مجانية.',
      'expiryDate': 'تتوفر 15 وجبة فقط',
      'icon': Icons.solar_power_rounded,
      'storeData': {
        'id': 's1',
        'name': 'متجر بغداد للطاقة الشمولية',
        'rating': '4.9 ⭐',
        'city': 'بغداد - الكرادة شارع الصناعة',
        'phone': '07701234567',
      },
    },
    {
      'id': 'off4',
      'name': 'منظومة طاقة شمسية هجينة كاملة 10kW مع البطاريات',
      'category': 'منظومات كاملة',
      'originalPriceIQD': '7,200,000 د.ع',
      'offerPriceIQD': '6,300,000 د.ع',
      'savedIQD': 'وفرت 900,000 د.ع',
      'discountPercent': 'باج التوفير الكلي 🌟',
      'offerDetails': 'باقة المنظومة الجاهزة كاملة المكونات تشمل الألواح والانفيرتر والبطارية والتثبيت.',
      'expiryDate': 'عرض حصري لفترة محدودة',
      'icon': Icons.home_max_rounded,
      'storeData': {
        'id': 's1',
        'name': 'متجر بغداد للطاقة الشمولية',
        'rating': '4.9 ⭐',
        'city': 'بغداد - الكرادة شارع الصناعة',
        'phone': '07701234567',
      },
    },
  ];

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
              child: _filteredOffers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text('لا توجد عروض حالية في قسم ${_categories[_selectedCategoryIndex]}',
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
                                // Offer Top Badges Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        offer['discountPercent'] as String,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGold.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        offer['expiryDate'] as String,
                                        style: const TextStyle(color: AppTheme.secondaryGold, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Product Title & Icon
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundLight,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(offer['icon'] as IconData, color: AppTheme.primaryGold, size: 32),
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
                                            offer['offerDetails'] as String,
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

                                // Price Breakdown Row (Original vs Offer Price in IQD)
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
                                          const Text('السعر السابق:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          Text(
                                            offer['originalPriceIQD'] as String,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              decoration: TextDecoration.lineThrough,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(offer['savedIQD'] as String, style: const TextStyle(fontSize: 10, color: AppTheme.accentGreen, fontWeight: FontWeight.bold)),
                                          Text(
                                            offer['offerPriceIQD'] as String,
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
                                              storeData['city'] as String,
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
