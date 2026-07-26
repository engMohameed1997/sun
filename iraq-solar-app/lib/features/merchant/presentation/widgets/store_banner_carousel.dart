import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StoreBannerCarouselWidget extends StatefulWidget {
  final String storeName;

  const StoreBannerCarouselWidget({Key? key, required this.storeName}) : super(key: key);

  @override
  State<StoreBannerCarouselWidget> createState() => _StoreBannerCarouselWidgetState();
}

class _StoreBannerCarouselWidgetState extends State<StoreBannerCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  late List<Map<String, dynamic>> _storeBanners;

  @override
  void initState() {
    super.initState();
    _storeBanners = [
      {
        'tag': 'عرض المتجر الحصري ⚡',
        'title': 'خصم 10% عند شراء منظومة هجينة متكاملة من ${widget.storeName}',
        'subtitle': 'يشمل الألواح والانفيرتر والبطاريات مع الشحن المباشر والمجاني.',
        'icon': Icons.local_offer_rounded,
        'color': const Color(0xFFFEF3C7),
        'textColor': AppTheme.darkNavy,
      },
      {
        'tag': 'توصيل وتركيب فوري 🚚',
        'title': 'خدمة المعاينة الميدانية والتجهيز في بغداد والمحافظات',
        'subtitle': 'فريق الفحص الفني الخاص بالمتجر جاهز للتثبيت خلال 24 ساعة.',
        'icon': Icons.local_shipping_rounded,
        'color': const Color(0xFFE0F2FE),
        'textColor': const Color(0xFF0369A1),
      },
      {
        'tag': 'ضمان واستبدال 📜',
        'title': 'كفالة رسمية ممتدة 5 سنوات استبدال مباشر',
        'subtitle': 'جميع الألواح والانفيرترات والبطاريات مفحوصة ومضمونة.',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFFDCFCE7),
        'textColor': const Color(0xFF15803D),
      },
    ];

    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _storeBanners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _storeBanners.length,
            itemBuilder: (context, index) {
              final b = _storeBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: b['color'] as Color,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: (b['textColor'] as Color).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.darkNavy,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              b['tag'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: b['textColor'] as Color,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b['subtitle'] as String,
                            style: TextStyle(fontSize: 10, color: (b['textColor'] as Color).withOpacity(0.8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(b['icon'] as IconData, size: 48, color: (b['textColor'] as Color).withOpacity(0.6)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_storeBanners.length, (index) {
            final isSelected = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 16 : 6,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGold : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
