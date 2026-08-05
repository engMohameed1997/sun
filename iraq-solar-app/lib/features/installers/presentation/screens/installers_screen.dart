import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workforce/customer/create_service_order_screen.dart';
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

  List<Map<String, dynamic>> _installers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  final List<String> _governorates = [
    'الكل', 'بغداد', 'البصرة', 'أربيل', 'النجف الأشرف',
    'نينوى (الموصل)', 'كركوك', 'ذي قار',
  ];

  @override
  void initState() {
    super.initState();
    _loadInstallers();
  }

  Future<void> _loadInstallers() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final res = await ApiClient.getInstallers(
        governorate: _selectedGov == 'الكل' ? null : _selectedGov,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final list = data['installers'];
        if (list is List) {
          setState(() {
            _installers = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _installers = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'فشل الاتصال بالسيرفر';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    _loadInstallers();
  }

  void _onGovChanged(String gov) {
    setState(() => _selectedGov = gov);
    _loadInstallers();
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
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateServiceOrderScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.darkNavy,
            icon: const Icon(Icons.build_circle_rounded, color: AppTheme.primaryGold),
            label: const Text('اطلب خدمة شمسية (توزيع تلقائي)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        body: Column(
          children: [
            // Search Header Bar & Governorate Chips
            Container(
              color: AppTheme.darkNavy,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم المهندس، التخصص، أو المحافظة...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
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
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _governorates.length,
                      itemBuilder: (context, index) {
                        final gov = _governorates[index];
                        final isSelected = _selectedGov == gov;
                        return GestureDetector(
                          onTap: () => _onGovChanged(gov),
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

            // Content Area
            Expanded(
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : _hasError
                      ? _buildErrorState()
                      : _installers.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadInstallers,
                              color: AppTheme.primaryGold,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _installers.length,
                                itemBuilder: (context, index) {
                                  return _buildInstallerCard(_installers[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 140, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 200, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 160, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(_errorMessage, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadInstallers,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            'لا يوجد فنيين طاقة شمسية في $_selectedGov حالياً',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallerCard(Map<String, dynamic> installer) {
    final name = installer['full_name'] ?? 'فني';
    final role = installer['role'] == 'engineer' ? 'مهندس طاقة شمسية معتمد' : 'فني تركيب منظومات شمسية';
    final gov = installer['governorate'] ?? '';
    final city = installer['city'] ?? '';
    final location = city.isNotEmpty ? '$gov - $city' : gov;
    final isVerified = installer['is_verified'] == true;

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
              width: 58, height: 58,
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
                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: const Text('معتمد 🛡️', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(role, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.grey, size: 14),
                      const SizedBox(width: 2),
                      Expanded(child: Text(location, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('معاينة البروفايل والأعمال ←', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 11)),
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
