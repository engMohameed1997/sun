import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'installer_detail_screen.dart';

class SolarInstallersScreen extends StatefulWidget {
  const SolarInstallersScreen({Key? key}) : super(key: key);

  @override
  State<SolarInstallersScreen> createState() => _SolarInstallersScreenState();
}

class _SolarInstallersScreenState extends State<SolarInstallersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGov = 'الكل';

  final List<String> _governorates = [
    'الكل',
    'بغداد',
    'البصرة',
    'أربيل',
    'النجف الأشرف',
    'نينوى (الموصل)',
    'كركوك',
    'ذي قار',
  ];

  final List<Map<String, dynamic>> _allInstallers = [
    {
      'id': 'inst1',
      'name': 'م. كرار العبيدي',
      'role': 'مهندس استشاري ومعاين طاقة شمسية',
      'governorate': 'بغداد - الكرادة',
      'govKey': 'بغداد',
      'installs': '145 منظومة فحص وتثبيت',
      'rating': '4.9 ⭐',
      'reviews': '58 تقييم',
      'verified': true,
      'phone': '07701234567',
      'experience': '8 سنوات خبرة ميدانية',
      'projects': [
        {'title': 'تركيب منظومة 12kW هجينة', 'location': 'بغداد - الكرادة', 'specs': '16 لوح LONGi + بطارية 10kWh'},
        {'title': 'فحص محطة 25kW صناعية', 'location': 'بغداد - شارع فلسطين', 'specs': 'انفيرتر Deye ثلاثي الأطوار'},
        {'title': 'منظومة 8kW مضخة زراعية', 'location': 'بغداد - أبو غريب', 'specs': 'تشغيل مباشر عالي الكفاءة'},
      ],
    },
    {
      'id': 'inst2',
      'name': 'فني صفا الناصري',
      'role': 'فني فحص وتركيب بطاريات ليثيوم',
      'governorate': 'البصرة - حي الجزائر',
      'govKey': 'البصرة',
      'installs': '98 منظومة هجينة',
      'rating': '4.8 ⭐',
      'reviews': '42 تقييم',
      'verified': true,
      'phone': '07809876543',
      'experience': '6 سنوات خبرة',
      'projects': [
        {'title': 'تركيب بطاريات 20kWh', 'location': 'البصرة - الجزائر', 'specs': 'بطاريات Felicity LiFePO4'},
        {'title': 'منظومة 15kW صناعية', 'location': 'البصرة - الزبير', 'specs': 'تجهيز مع قواطع حماية صواعل'},
      ],
    },
    {
      'id': 'inst3',
      'name': 'م. أحمد الخفاجي',
      'role': 'استشاري محطات وأنظمة طاقة شمسية',
      'governorate': 'أربيل - شارع العرصات',
      'govKey': 'أربيل',
      'installs': '210 منظومة شمسية',
      'rating': '5.0 ⭐',
      'reviews': '84 تقييم',
      'verified': true,
      'phone': '07501122334',
      'experience': '10 سنوات خبرة',
      'projects': [
        {'title': 'محطة شمسية 50kW', 'location': 'أربيل - عينكاوة', 'specs': 'محطة تجارية كاملة'},
        {'title': 'منظومة 10kW كاملة', 'location': 'أربيل - العرصات', 'specs': 'أنظمة هجينة مستقلة'},
      ],
    },
    {
      'id': 'inst4',
      'name': 'م. حيدر الحسني',
      'role': 'مهندس كهربائي وفني أمان شمسي',
      'governorate': 'النجف الأشرف - حي الحنانة',
      'govKey': 'النجف الأشرف',
      'installs': '112 منظومة معتمدة',
      'rating': '4.9 ⭐',
      'reviews': '39 تقييم',
      'verified': true,
      'phone': '07714455667',
      'experience': '7 سنوات خبرة',
      'projects': [
        {'title': 'منظومة 10kW ثلاثية الأطوار', 'location': 'النجف - شارع السنتر', 'specs': 'حماية وتأريض كامل'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _filteredInstallers {
    return _allInstallers.where((inst) {
      final matchesGov = _selectedGov == 'الكل' || inst['govKey'] == _selectedGov;
      final matchesQuery = _searchQuery.isEmpty ||
          (inst['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (inst['governorate'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (inst['role'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesGov && matchesQuery;
    }).toList();
  }

  void _navigateToInstallerDetail(Map<String, dynamic> installer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstallerDetailScreen(installerData: installer),
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
          title: const Text('دليل المهندسين والفنيين المعتمدين في العراق'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: Column(
          children: [
            // Search Header Bar & Governorate Chips
            Container(
              color: AppTheme.darkNavy,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم المهندس، التخصص، أو المحافظة...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                                onPressed: () {
                                  _searchController.clear();
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

                  const SizedBox(height: 12),

                  // Governorate Filter Horizontal List
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _governorates.length,
                      itemBuilder: (context, index) {
                        final gov = _governorates[index];
                        final isSelected = _selectedGov == gov;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGov = gov),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryGold : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                gov,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Installers Directory List
            Expanded(
              child: _filteredInstallers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          Text(
                            'لا يوجد فنيين طاقة شمسية ينطبق عليهم البحث في $_selectedGov',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredInstallers.length,
                      itemBuilder: (context, index) {
                        final installer = _filteredInstallers[index];
                        return _buildInstallerCard(installer);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallerCard(Map<String, dynamic> installer) {
    return GestureDetector(
      onTap: () => _navigateToInstallerDetail(installer),
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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.darkNavy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGold, width: 2),
              ),
              child: const Icon(Icons.engineering_rounded, color: AppTheme.primaryGold, size: 30),
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
                          installer['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('معتمد 🛡️', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(installer['role'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.grey, size: 14),
                      const SizedBox(width: 2),
                      Text(installer['governorate'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(width: 10),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(installer['rating'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(installer['installs'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.darkNavy, fontWeight: FontWeight.bold)),
                      const Text('معاينة البروفايل والأعمال ←', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
