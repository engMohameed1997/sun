import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../widgets/installer_chat_dialog.dart';

class InstallerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> installerData;

  const InstallerDetailScreen({Key? key, required this.installerData}) : super(key: key);

  @override
  State<InstallerDetailScreen> createState() => _InstallerDetailScreenState();
}

class _InstallerDetailScreenState extends State<InstallerDetailScreen> {
  late PageController _projectsPageController;
  int _currentProjectPage = 0;
  Timer? _sliderTimer;
  bool _isFavoriteInstaller = false;

  late List<Map<String, String>> _projects;

  @override
  void initState() {
    super.initState();
    _projectsPageController = PageController();
    _projects = (widget.installerData['projects'] as List<dynamic>?)
            ?.map((p) => Map<String, String>.from(p as Map))
            .toList() ??
        [
          {'title': 'تركيب منظومة 12kW هجينة', 'location': 'بغداد - الكرادة', 'specs': '16 لوح LONGi + بطارية 10kWh'},
          {'title': 'فحص محطة 25kW صناعية', 'location': 'بغداد - شارع فلسطين', 'specs': 'انفيرتر Deye ثلاثي الأطوار'},
          {'title': 'منظومة 8kW مضخة زراعية', 'location': 'بغداد - أبو غريب', 'specs': 'تشغيل مباشر عالي الكفاءة'},
        ];

    _startProjectsSlider();
  }

  void _startProjectsSlider() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_projectsPageController.hasClients) {
        int nextPage = (_currentProjectPage + 1) % _projects.length;
        _projectsPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _projectsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.installerData['full_name'] ?? widget.installerData['name'] ?? 'فني';
    final roleKey = widget.installerData['role'] ?? 'installer';
    final role = roleKey == 'engineer' ? 'مهندس طاقة شمسية معتمد' : 'فني تركيب منظومات شمسية';
    final gov = widget.installerData['governorate'] ?? '';
    final city = widget.installerData['city'] ?? '';
    final governorate = city.isNotEmpty ? '$gov - $city' : gov;
    final phone = widget.installerData['phone'] ?? '';
    final createdAt = widget.installerData['created_at'] ?? '';
    final isVerified = widget.installerData['is_verified'] == true;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header Sliver App Bar
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppTheme.darkNavy,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                        child: Icon(
                          _isFavoriteInstaller ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavoriteInstaller ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        setState(() => _isFavoriteInstaller = !_isFavoriteInstaller);
                        AppNotification.showSuccess(
                          context,
                          _isFavoriteInstaller ? 'تمت إضافة المهندس/الفني $name للمفضلة ❤️' : 'تمت إزالته من المفضلة',
                        );
                      },
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                      ),
                      onPressed: () {
                        AppNotification.showInfo(context, 'تم نسخ رابط ملف المهندس $name للمشاركة');
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.darkNavy, Color(0xFF1E293B)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(Icons.engineering_rounded, size: 180, color: Colors.white.withOpacity(0.04)),
                        ),

                        // Engineer Profile Header Overlay
                        Positioned(
                          bottom: 20,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppTheme.darkNavy,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.primaryGold, width: 3),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                                  ],
                                ),
                                child: const Icon(Icons.engineering_rounded, color: AppTheme.primaryGold, size: 38),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (widget.installerData['is_verified'] == true)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentGreen,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text('معتمد 🛡️', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(role, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                                        const SizedBox(width: 4),
                                        Text(governorate, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Profile Details Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(Icons.verified_rounded, isVerified ? 'معتمد' : 'قيد المراجعة', 'حالة الاعتماد'),
                              Container(width: 1, height: 36, color: Colors.grey.shade300),
                              _buildStatItem(Icons.work_history_rounded, _calcExperience(createdAt), 'تاريخ الانضمام'),
                              Container(width: 1, height: 36, color: Colors.grey.shade300),
                              _buildStatItem(Icons.security_rounded, 'فحص رسمي', 'اعتمادية السلامة'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 3. Past Projects Slider (سلايدر كامل لأعماله وسجل المنظومات السابقة)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('سلايدر ومعرض الأعمال السابقة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                            Text('${_projects.length} مشاريع معروضة', style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildProjectsSlider(),

                        const SizedBox(height: 24),

                        // 4. Engineering Qualifications & Capabilities
                        const Text('التخصصات والقدرات الهندسية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              _buildSkillTile('إجراء المسح الفني وحساب استهلاك الاحمال بالـ kWh', Icons.calculate_rounded),
                              _buildSkillTile('تحديد وفحص أفضل زوايا ميلان الألواح لتفادي حرارة الصيف', Icons.wb_sunny_rounded),
                              _buildSkillTile('برمجة وتضبط انفيرترات Deye و Growatt ثلاثية الأطوار', Icons.bolt_rounded),
                              _buildSkillTile('ربط وتوازن بطاريات الليثيوم LiFePO4 وحمايتها من التفريغ العميق', Icons.battery_charging_full_rounded),
                              _buildSkillTile('فحص قواطع التأريض والأمان ومقاومة الصواعق', Icons.shield_rounded),
                            ],
                          ),
                        ),

                        const SizedBox(height: 110), // Spacing for sticky bottom buttons
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 5. Sticky Bottom Action Buttons (مراسلة وطلب فحص + اتصال)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          InstallerChatDialog.show(
                            context,
                            name: name,
                            role: role,
                            location: governorate,
                          );
                        },
                        icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                        label: const Text('مراسلة وطلب فحص ميداني', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkNavy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        AppNotification.showInfo(
                          context,
                          'الاتصال بالمهندس $name: $phone 📞',
                        );
                      },
                      icon: const Icon(Icons.call_rounded, color: AppTheme.primaryGold, size: 18),
                      label: const Text('اتصال', style: TextStyle(color: AppTheme.darkNavy, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Projects Auto Slider
  Widget _buildProjectsSlider() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _projectsPageController,
            onPageChanged: (index) => setState(() => _currentProjectPage = index),
            itemCount: _projects.length,
            itemBuilder: (context, index) {
              final proj = _projects[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryGold.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
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
                            decoration: BoxDecoration(color: AppTheme.darkNavy, borderRadius: BorderRadius.circular(12)),
                            child: Text(proj['location'] ?? 'بغداد', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            proj['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المواصفات: ${proj['specs']}',
                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(color: AppTheme.darkNavy, shape: BoxShape.circle),
                      child: const Icon(Icons.solar_power_rounded, color: AppTheme.primaryGold, size: 36),
                    ),
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
          children: List.generate(_projects.length, (index) {
            final isSelected = _currentProjectPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isSelected ? 18 : 6,
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

  Widget _buildStatItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 22),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkNavy)),
        Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildSkillTile(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
          ),
        ],
      ),
    );
  }

  String _calcExperience(String createdAt) {
    if (createdAt.isEmpty) return 'عضو جديد';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return 'منذ ${diff.inDays ~/ 365} سنة';
      if (diff.inDays > 30) return 'منذ ${diff.inDays ~/ 30} شهر';
      return 'عضو جديد';
    } catch (_) {
      return 'عضو جديد';
    }
  }
}
