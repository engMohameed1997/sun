import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/navigation/banner_action_handler.dart';
import '../../domain/models/banner_model.dart';

class BannerCarouselWidget extends StatefulWidget {
  final String placement;
  final String? storeId;
  final String? categoryId;
  final String? productId;
  final Function(int tabIndex)? onBannerAction;

  const BannerCarouselWidget({
    Key? key,
    this.placement = 'home',
    this.storeId,
    this.categoryId,
    this.productId,
    this.onBannerAction,
  }) : super(key: key);

  @override
  State<BannerCarouselWidget> createState() => _BannerCarouselWidgetState();
}

class _BannerCarouselWidgetState extends State<BannerCarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  final Set<String> _trackedImpressions = {};

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final res = await ApiClient.getBanners(
        placement: widget.placement,
        storeId: widget.storeId,
        categoryId: widget.categoryId,
        productId: widget.productId,
      );

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        List bannersList = [];
        if (data is List) {
          bannersList = data;
        } else if (data is Map && data['data'] != null) {
          bannersList = data['data'] as List;
        }

        if (mounted) {
          setState(() {
            _banners = bannersList
                .map((b) => BannerModel.fromJson(Map<String, dynamic>.from(b as Map)))
                .where((b) => b.imageUrl.isNotEmpty || (b.mobileImageUrl != null && b.mobileImageUrl!.isNotEmpty))
                .toList();
            _isLoading = false;
          });

          if (_banners.isNotEmpty) {
            _trackImpression(0);
            _startAutoSlide();
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _trackImpression(int index) {
    if (index >= 0 && index < _banners.length) {
      final banner = _banners[index];
      if (!_trackedImpressions.contains(banner.id)) {
        _trackedImpressions.add(banner.id);
        ApiClient.trackBannerEvent(banner.id, 'impression');
      }
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _banners.isNotEmpty) {
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
    if (_isLoading) {
      return const SizedBox(
        height: 175,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 175,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _trackImpression(index);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final rawUrl = (banner.mobileImageUrl != null && banner.mobileImageUrl!.isNotEmpty)
                  ? banner.mobileImageUrl!
                  : banner.imageUrl;
              final displayImageUrl = ApiClient.resolveImageUrl(rawUrl) ?? rawUrl;

              return GestureDetector(
                onTap: () => BannerActionHandler.handleAction(context, banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        displayImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppTheme.darkNavy,
                            child: const Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryGold),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppTheme.darkNavy,
                          child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
