import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

import 'sizing_calculator_screen.dart';
import 'roi_calculator_screen.dart';
import 'battery_runtime_screen.dart';
import 'appliance_calculator_screen.dart';
import 'panels_needed_screen.dart';
import 'roof_capacity_screen.dart';
import 'full_kit_cost_screen.dart';
import 'cable_sizing_screen.dart';
import 'mppt_string_screen.dart';
import 'breakers_fuses_screen.dart';
import 'battery_bank_screen.dart';
import 'solar_production_screen.dart';

class SolarCalculatorScreen extends StatefulWidget {
  final String userRole; // Optional fallback role

  const SolarCalculatorScreen({
    Key? key,
    this.userRole = 'customer',
  }) : super(key: key);

  @override
  State<SolarCalculatorScreen> createState() => _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends State<SolarCalculatorScreen> {
  bool _isLoading = true;
  String _userRole = 'customer';
  String _userName = '';
  List<Map<String, dynamic>> _calculators = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndCalculators();
  }

  Future<void> _loadUserAndCalculators() async {
    setState(() => _isLoading = true);

    // 1. Fetch active user role & name from AuthStorage
    final user = await AuthStorageService.getUser();
    if (user != null && user['role'] != null) {
      _userRole = user['role'].toString();
      _userName = user['full_name']?.toString() ?? '';
    } else {
      _userRole = widget.userRole;
    }

    // 2. Call GET /api/v1/calculators (Backend JWT role extraction)
    final fetched = await ApiClient.getCalculators();

    if (mounted) {
      setState(() {
        if (fetched.isNotEmpty) {
          _calculators = fetched;
        } else {
          // Offline Fallback
          _calculators = _getFallbackCalculators(_userRole);
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('حاسبات المنظومة الشمسية'),
          backgroundColor: AppTheme.darkNavy,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGold),
              tooltip: 'تحديث القائمة',
              onPressed: _loadUserAndCalculators,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadUserAndCalculators,
          color: AppTheme.primaryGold,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleHeaderBanner(),
                const SizedBox(height: 20),

                if (_isLoading)
                  _buildLoadingShimmer()
                else if (_calculators.isEmpty)
                  _buildEmptyState()
                else
                  _buildCalculatorsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
            child: Icon(_getRoleIcon(_userRole), color: AppTheme.primaryGold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _userName.isNotEmpty ? _userName : 'حساب ${_getRoleTitle(_userRole)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primaryGold, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        _getRoleTitle(_userRole),
                        style: const TextStyle(color: AppTheme.darkNavy, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'عرض الأدوات المصرحة لدورك الحسابي من السيرفر المباشر',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.98,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _calculators.length,
      itemBuilder: (context, index) {
        final calc = _calculators[index];
        return _buildCalcTile(calc);
      },
    );
  }

  Widget _buildCalcTile(Map<String, dynamic> calc) {
    final routeKey = calc['route_key']?.toString() ?? '';
    final title = calc['title']?.toString() ?? 'حاسبة شمسية';
    final subtitle = calc['subtitle']?.toString() ?? '';
    final iconKey = calc['icon_key']?.toString() ?? 'sun';
    final badge = calc['badge']?.toString() ?? '';
    final colorHex = calc['color_hex']?.toString() ?? '#F9A826';
    final isFeatured = calc['is_featured'] == true;
    final rawBgUrl = calc['background_image_url']?.toString();
    final hasBgImage = rawBgUrl != null && rawBgUrl.trim().isNotEmpty;
    final resolvedBgUrl = hasBgImage ? ApiClient.resolveImageUrl(rawBgUrl.trim()) : null;

    final cardColor = _parseColor(colorHex);
    final iconData = _getIconData(iconKey);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isFeatured ? cardColor.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.08),
            blurRadius: isFeatured ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFeatured ? cardColor : (hasBgImage ? cardColor.withValues(alpha: 0.4) : cardColor.withValues(alpha: 0.25)),
              width: isFeatured ? 2.0 : 1.2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image Layer with Cover Fit
              if (resolvedBgUrl != null && resolvedBgUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    resolvedBgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: cardColor.withValues(alpha: 0.08)),
                  ),
                ),

              // 2. High-Contrast Gradient Overlay Layer
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: hasBgImage
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.75),
                              AppTheme.darkNavy.withValues(alpha: 0.92),
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              cardColor.withValues(alpha: 0.06),
                            ],
                          ),
                  ),
                ),
              ),

              // 3. Card Content (Badges, Icon, Titles)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header Row: Circle Icon Avatar & Badge Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: hasBgImage
                              ? Colors.black.withValues(alpha: 0.4)
                              : cardColor.withValues(alpha: 0.15),
                          child: Icon(
                            iconData,
                            color: hasBgImage ? AppTheme.primaryGold : cardColor,
                            size: 20,
                          ),
                        ),
                        if (badge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasBgImage
                                  ? AppTheme.primaryGold
                                  : cardColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: hasBgImage
                                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]
                                  : null,
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                color: hasBgImage ? AppTheme.darkNavy : cardColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Title and Subtitle Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: hasBgImage ? Colors.white : AppTheme.darkNavy,
                            shadows: hasBgImage
                                ? [const Shadow(color: Colors.black, blurRadius: 6)]
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: hasBgImage ? Colors.white.withValues(alpha: 0.85) : Colors.grey.shade600,
                            height: 1.25,
                            shadows: hasBgImage
                                ? [const Shadow(color: Colors.black, blurRadius: 4)]
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 4. Material Touch Ripple Layer
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToCalculator(context, routeKey),
                    splashColor: (hasBgImage ? AppTheme.primaryGold : cardColor).withValues(alpha: 0.2),
                    highlightColor: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCalculator(BuildContext context, String routeKey) {
    switch (routeKey) {
      case 'system_sizing':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SizingCalculatorScreen()));
        break;
      case 'roi':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RoiCalculatorScreen()));
        break;
      case 'battery_runtime':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BatteryRuntimeScreen()));
        break;
      case 'appliance':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplianceCalculatorScreen()));
        break;
      case 'panels':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PanelsNeededScreen()));
        break;
      case 'roof':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RoofCapacityScreen()));
        break;
      case 'full_cost':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FullKitCostScreen()));
        break;
      case 'cable_sizing':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CableSizingScreen()));
        break;
      case 'mppt_string':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MpptStringScreen()));
        break;
      case 'breakers_fuses':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakersFusesScreen()));
        break;
      case 'battery_bank':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BatteryBankScreen()));
        break;
      case 'solar_production':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SolarProductionScreen()));
        break;
      default:
        AppNotification.showInfo(context, 'هذه الحاسبة متوفرة في تحديث التطبيق القادم');
    }
  }

  IconData _getIconData(String iconKey) {
    switch (iconKey) {
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'battery':
        return Icons.battery_charging_full_rounded;
      case 'power':
        return Icons.power_rounded;
      case 'grid':
        return Icons.grid_view_rounded;
      case 'roof':
        return Icons.roofing_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'cable':
        return Icons.cable_rounded;
      case 'tune':
        return Icons.tune_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'battery_saver':
        return Icons.battery_saver_rounded;
      case 'map':
        return Icons.map_rounded;
      default:
        return Icons.calculate_rounded;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'installer':
      case 'engineer':
        return Icons.engineering_rounded;
      case 'merchant':
        return Icons.storefront_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'installer':
        return 'فني تركيبات';
      case 'engineer':
        return 'مهندس طاقة';
      case 'merchant':
        return 'تاجر ومورد';
      case 'admin':
        return 'مدير النظام';
      default:
        return 'مستخدم منزلي';
    }
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return AppTheme.primaryGold;
  }

  Widget _buildLoadingShimmer() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGold),
          SizedBox(height: 16),
          Text('جاري جلب الحاسبات المصرحة لدورك...', style: TextStyle(color: AppTheme.darkNavy)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.calculate_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('لا توجد حاسبات مسموحة لهذا الدور حالياً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadUserAndCalculators,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy),
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFallbackCalculators(String role) {
    final isTech = role == 'installer' || role == 'engineer' || role == 'merchant' || role == 'admin';

    final homeList = [
      {'route_key': 'system_sizing', 'title': '1. حجم المنظومة', 'subtitle': 'الألواح، الانفرتر، والبطاريات', 'icon_key': 'sun', 'badge': 'ضرورية', 'color_hex': '#FF9800', 'is_featured': true},
      {'route_key': 'roi', 'title': '2. التوفير و ROI', 'subtitle': 'فترة استرجاع المال والتوفير', 'icon_key': 'savings', 'badge': 'استرداد', 'color_hex': '#4CAF50', 'is_featured': true},
      {'route_key': 'battery_runtime', 'title': '3. تشغيل البطاريات', 'subtitle': 'ساعات التغذية المستمرة', 'icon_key': 'battery', 'badge': 'ساعات', 'color_hex': '#2196F3', 'is_featured': false},
      {'route_key': 'appliance', 'title': '4. استهلاك الأجهزة', 'subtitle': 'استهلاك المكيف والثلاجة', 'icon_key': 'power', 'badge': 'أجهزة', 'color_hex': '#9C27B0', 'is_featured': false},
      {'route_key': 'panels', 'title': '5. الألواح بالاستهلاك', 'subtitle': 'إدخال استهلاك الشهري kWh', 'icon_key': 'grid', 'badge': 'عدد ألواح', 'color_hex': '#FF5722', 'is_featured': false},
      {'route_key': 'roof', 'title': '6. مساحة السطح', 'subtitle': 'أقصى عدد ألواح يستوعبه السطح', 'icon_key': 'roof', 'badge': 'مساحة السطح', 'color_hex': '#009688', 'is_featured': false},
      {'route_key': 'full_cost', 'title': '7. الكلفة ومتجر الشراء', 'subtitle': 'حساب التكلفة وعرض المتاجر', 'icon_key': 'shopping_bag', 'badge': 'ربط المتجر', 'color_hex': '#FF5252', 'is_featured': true},
    ];

    final techList = [
      {'route_key': 'cable_sizing', 'title': '1. Cable & VDrop', 'subtitle': 'سمك السلك وهبوط الجهد', 'icon_key': 'cable', 'badge': 'كابلات', 'color_hex': '#3F51B5', 'is_featured': true},
      {'route_key': 'mppt_string', 'title': '2. MPPT String', 'subtitle': 'سلاسل الألواح وتأثير الحرارة', 'icon_key': 'tune', 'badge': 'MPPT', 'color_hex': '#673AB7', 'is_featured': true},
      {'route_key': 'breakers_fuses', 'title': '3. Breaker & Fuse', 'subtitle': 'قواطع DC/AC والفيوزات', 'icon_key': 'shield', 'badge': 'حماية', 'color_hex': '#FF6F00', 'is_featured': false},
      {'route_key': 'battery_bank', 'title': '4. بنك البطاريات', 'subtitle': 'توصيل توالي/توازي Series/Parallel', 'icon_key': 'battery_saver', 'badge': 'توصيلات', 'color_hex': '#00838F', 'is_featured': false},
      {'route_key': 'solar_production', 'title': '5. إنتاجية المحافظات', 'subtitle': 'إنتاج العراق والزاوية المثالية', 'icon_key': 'map', 'badge': 'محافظات', 'color_hex': '#795548', 'is_featured': false},
    ];

    if (isTech) {
      return [...techList, ...homeList];
    }
    return homeList;
  }
}
