import 'package:flutter/material.dart';
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
  final String userRole; // "customer", "installer", "engineer", "merchant", "admin"

  const SolarCalculatorScreen({
    Key? key,
    this.userRole = 'customer',
  }) : super(key: key);

  @override
  State<SolarCalculatorScreen> createState() => _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends State<SolarCalculatorScreen> {
  late String _activeRole;

  @override
  void initState() {
    super.initState();
    _activeRole = widget.userRole;
  }

  bool get _isTechUser =>
      _activeRole == 'installer' ||
      _activeRole == 'engineer' ||
      _activeRole == 'merchant' ||
      _activeRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('حاسبات المنظومة الشمسية المتكاملة'),
          backgroundColor: AppTheme.darkNavy,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.badge_outlined, color: AppTheme.primaryGold),
              tooltip: 'تبديل دور الحساب المعروض',
              onSelected: (role) {
                setState(() => _activeRole = role);
                AppNotification.showInfo(
                  context,
                  'تم تصفية العرض بحسب دور: ${_getRoleTitle(role)}',
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'customer', child: Text('👤 مستخدم منزلي (Customer)')),
                const PopupMenuItem(value: 'installer', child: Text('👨‍🔧 فني تركيبات (Installer)')),
                const PopupMenuItem(value: 'engineer', child: Text('📐 مهندس استشاري (Engineer)')),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoleHeaderBanner(),
              const SizedBox(height: 20),

              // SECTION 1: HOME USER CALCULATORS
              const Row(
                children: [
                  Icon(Icons.home_rounded, color: AppTheme.primaryGold, size: 24),
                  SizedBox(width: 8),
                  Text('حاسبات المستخدم المنزلي الشاملة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                ],
              ),
              const SizedBox(height: 12),
              _buildHomeUserGrid(),

              // SECTION 2: TECHNICIAN CALCULATORS
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _isTechUser ? Colors.blue.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: Text(_isTechUser ? 'حساب فني متقدم' : 'متاحة أيضاً للفنيين', style: TextStyle(color: _isTechUser ? Colors.blue.shade900 : Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.engineering_rounded, color: AppTheme.darkNavy, size: 24),
                  const SizedBox(width: 8),
                  const Text('حاسبات الفني والمهندس المختص', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTechGrid(),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleTitle(String role) {
    switch (role) {
      case 'installer':
        return 'فني تركيبات ميداني';
      case 'engineer':
        return 'مهندس طاقة شمسية';
      case 'merchant':
        return 'تاجر ومورد';
      default:
        return 'مستخدم منزلي';
    }
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
            child: Icon(_isTechUser ? Icons.engineering_rounded : Icons.person_rounded, color: AppTheme.primaryGold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('نوع الحساب: ${_getRoleTitle(_activeRole)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primaryGold, borderRadius: BorderRadius.circular(6)),
                      child: Text(_isTechUser ? 'كل الأدوات المتقدمة' : 'الأدوات المنزلية والتسوق', style: const TextStyle(color: AppTheme.darkNavy, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isTechUser ? 'اضغط على إحدى الحاسبات أدناه لفتح واجهتها المستقلة الكاملة.' : 'اختر أي حاسبة لفتح واجهتها التفاعلية الكاملة.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HOME USER GRID
  Widget _buildHomeUserGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.05,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildCalcTile(
          title: '1. حجم المنظومة',
          subtitle: 'الألواح، الانفرتر، والبطاريات',
          badge: '⭐⭐⭐⭐⭐ ضرورية',
          icon: Icons.wb_sunny_rounded,
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SizingCalculatorScreen())),
        ),
        _buildCalcTile(
          title: '2. التوفير و ROI',
          subtitle: 'فترة استرجاع المال والتوفير',
          badge: '⭐⭐⭐⭐⭐ استرداد',
          icon: Icons.savings_rounded,
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoiCalculatorScreen())),
        ),
        _buildCalcTile(
          title: '3. تشغيل البطاريات',
          subtitle: 'ساعات التغذية المستمرة',
          badge: '⭐⭐⭐⭐ ساعات',
          icon: Icons.battery_charging_full_rounded,
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatteryRuntimeScreen())),
        ),
        _buildCalcTile(
          title: '4. استهلاك الأجهزة',
          subtitle: 'استهلاك المكيف والثلاجة',
          badge: '⭐⭐⭐⭐ أجهزة',
          icon: Icons.power_rounded,
          color: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplianceCalculatorScreen())),
        ),
        _buildCalcTile(
          title: '5. الألواح بالاستهلاك',
          subtitle: 'إدخال استهلاك الشهري kWh',
          badge: '⭐⭐⭐⭐ عدد ألواح',
          icon: Icons.grid_view_rounded,
          color: Colors.deepOrange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PanelsNeededScreen())),
        ),
        _buildCalcTile(
          title: '6. مساحة السطح',
          subtitle: 'أقصى عدد ألواح يستوعبه السطح',
          badge: '⭐⭐⭐ مساحة السطح',
          icon: Icons.roofing_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoofCapacityScreen())),
        ),
        _buildCalcTile(
          title: '🔥 7. الكلفة ومتجر الشراء',
          subtitle: 'حساب التكلفة وعرض المتاجر',
          badge: '🛒 ربط المتجر',
          icon: Icons.shopping_bag_rounded,
          color: Colors.redAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FullKitCostScreen())),
        ),
      ],
    );
  }

  // TECHNICIAN GRID
  Widget _buildTechGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.05,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildCalcTile(
          title: '1. Cable & VDrop',
          subtitle: 'سمك السلك وهبوط الجهد',
          badge: '⭐⭐⭐⭐⭐ كابلات',
          icon: Icons.cable_rounded,
          color: Colors.indigo,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CableSizingScreen())),
        ),
        _buildCalcTile(
          title: '2. MPPT String',
          subtitle: 'سلاسل الألواح وتأثير الحرارة',
          badge: '⭐⭐⭐⭐⭐ MPPT',
          icon: Icons.tune_rounded,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MpptStringScreen())),
        ),
        _buildCalcTile(
          title: '3. Breaker & Fuse',
          subtitle: 'قواطع DC/AC والفيوزات',
          badge: '⭐⭐⭐⭐ حماية',
          icon: Icons.shield_rounded,
          color: Colors.amber.shade900,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreakersFusesScreen())),
        ),
        _buildCalcTile(
          title: '4. بنك البطاريات',
          subtitle: 'توصيل توالي/توازي Series/Parallel',
          badge: '⭐⭐⭐ توصيلات',
          icon: Icons.battery_saver_rounded,
          color: Colors.cyan.shade800,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BatteryBankScreen())),
        ),
        _buildCalcTile(
          title: '5. إنتاجية المحافظات',
          subtitle: 'إنتاج العراق والزاوية المثالية',
          badge: '⭐⭐⭐ محافظات',
          icon: Icons.map_rounded,
          color: Colors.brown,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SolarProductionScreen())),
        ),
      ],
    );
  }

  Widget _buildCalcTile({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(badge, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
