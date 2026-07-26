import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class BannerCarouselWidget extends StatefulWidget {
  final Function(int tabIndex)? onBannerAction;

  const BannerCarouselWidget({Key? key, this.onBannerAction}) : super(key: key);

  @override
  State<BannerCarouselWidget> createState() => _BannerCarouselWidgetState();
}

class _BannerCarouselWidgetState extends State<BannerCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _banners = [
    {
      'tag': 'مبادرة حكومية رسمية 🏛️',
      'title': 'مبادرة البنك المركزي العراقي لدعم الطاقة الشمسية',
      'subtitle': 'احصل على تمويل منظومتك الشمسية بفائدة 0% وبأقساط ميسرة عن طريق المصارف الوطنية المعتمدة.',
      'buttonText': 'احسب التكلفة والتمويل ⚡',
      'gradient': const [Color(0xFF0F172A), Color(0xFF1E293B)],
      'badgeColor': AppTheme.primaryGold,
      'icon': Icons.account_balance_rounded,
      'tabTarget': 1, // Calculator tab
    },
    {
      'tag': 'عروض صيف العراق ☀️',
      'title': 'خصم 15% على باقات المنظومات الهجينة 10kW',
      'subtitle': 'تشمل ألواح LONGi TOPCon N-Type وانفيرتر Deye 8kW بطارية ليثيوم 10kWh مع التوصيل مجاناً.',
      'buttonText': 'تصفح العروض الآن 🛒',
      'gradient': const [Color(0xFFB45309), Color(0xFFF59E0B)],
      'badgeColor': AppTheme.darkNavy,
      'icon': Icons.solar_power_rounded,
      'tabTarget': 2, // Catalog tab
    },
    {
      'tag': 'خدمة مجانية 🛠️',
      'title': 'خدمة المعاينة الميدانية وفحص الأحمال الكهربائية',
      'subtitle': 'مهندس معتمد يزور منزلك في بغداد وكافة المحافظات لإجراء المسح الفني وتحديد زوايا الألواح.',
      'buttonText': 'طلب فحص هندسي 👷',
      'gradient': const [Color(0xFF065F46), Color(0xFF10B981)],
      'badgeColor': AppTheme.darkNavy,
      'icon': Icons.engineering_rounded,
      'tabTarget': 3, // Installers tab
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
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
          height: 175,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: banner['gradient'] as List<Color>,
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (banner['gradient'] as List<Color>).first.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: banner['badgeColor'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              banner['tag'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banner['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitle'] as String,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              final target = banner['tabTarget'] as int;
                              widget.onBannerAction?.call(target);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                banner['buttonText'] as String,
                                style: const TextStyle(
                                  color: AppTheme.darkNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(banner['icon'] as IconData, size: 64, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isSelected = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 20 : 6,
              height: 6,
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
