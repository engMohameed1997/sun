import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'home_screen.dart';
import '../../../calculator/presentation/screens/calculator_screen.dart';
import '../../../products/presentation/screens/catalog_screen.dart';
import '../../../installers/presentation/screens/installers_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelect(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      SuperQiHomeScreen(
        onNavigateTab: _onTabSelect,
      ),
      const SolarCalculatorScreen(),
      const SolarCatalogScreen(),
      const SolarInstallersScreen(),
      const SolarProfileScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),

            // Super Qi Style Persistent Floating Navigation Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: AppTheme.darkNavy,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.darkNavy.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
                    _buildNavItem(1, Icons.calculate_outlined, 'الحاسبة'),
                    _buildNavItem(2, Icons.storefront_outlined, 'المتاجر'),
                    _buildNavItem(3, Icons.engineering_outlined, 'الفنيين'),
                    _buildNavItem(4, Icons.person_outline_rounded, 'الحساب'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelect(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
