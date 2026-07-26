import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SearchFilterSheet extends StatefulWidget {
  final Function(Map<String, dynamic> filters)? onApplyFilters;

  const SearchFilterSheet({Key? key, this.onApplyFilters}) : super(key: key);

  static void show(BuildContext context, {Function(Map<String, dynamic>)? onApply}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterSheet(onApplyFilters: onApply),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  String _selectedCategoryType = 'الكل'; // الكل، المتاجر، الفنيين، القطع
  String _selectedGovernorate = 'جميع المحافظات';
  String _selectedComponentType = 'جميع القطع';
  RangeValues _priceRange = const RangeValues(50, 2500);
  double _minRating = 4.0;
  bool _verifiedOnly = true;
  bool _warrantyOnly = false;

  final List<String> _categoryTypes = ['الكل', 'المتاجر المعتمدة', 'الفنيين والمهندسين', 'القطع والمنتجات'];

  final List<String> _governorates = [
    'جميع المحافظات',
    'بغداد',
    'البصرة',
    'أربيل',
    'النجف الأشرف',
    'نينوى (الموصل)',
    'كركوك',
    'ذي قار (الناصرية)',
    'السليمانية',
    'بابل (الحلة)',
    'الأنبار (الرمادي)',
    'كربلاء المقدسة',
    'ديالى',
    'واسط (الكوت)',
    'ميسان (العمارة)',
    'القادسية (الديوانية)',
    'المثنى (السماوة)',
    'دهوك',
  ];

  final List<String> _componentTypes = [
    'جميع القطع',
    'ألواح طاقة شمسية (Panels)',
    'انفيرترات هجينة (Inverters)',
    'بطاريات ليثيوم (Batteries)',
    'هياكل تثبيت ألمنيوم (Structures)',
    'كابلات وقواطع حماية (Cables)',
    'منظومات كاملة جاهزة',
  ];

  void _resetFilters() {
    setState(() {
      _selectedCategoryType = 'الكل';
      _selectedGovernorate = 'جميع المحافظات';
      _selectedComponentType = 'جميع القطع';
      _priceRange = const RangeValues(50, 2500);
      _minRating = 4.0;
      _verifiedOnly = true;
      _warrantyOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Sheet Top Handle & Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppTheme.primaryGold, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'البحث المتقدم والفلترة الشاملة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkNavy),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('إعادة ضبط', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Filter Options Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 1. Search Scope / Entity Type
                  _buildSectionLabel('نوع البحث والكيان'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryTypes.map((type) {
                      final isSelected = _selectedCategoryType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedCategoryType = type),
                        selectedColor: AppTheme.primaryGold,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.darkNavy,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 2. Governorate Dropdown Selection
                  _buildSectionLabel('المحافظة العراقية'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGovernorate,
                        isExpanded: true,
                        icon: const Icon(Icons.location_on_rounded, color: AppTheme.primaryGold),
                        items: _governorates.map((gov) {
                          return DropdownMenuItem(
                            value: gov,
                            child: Text(gov, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedGovernorate = val!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Component / Part Selection
                  _buildSectionLabel('نوع القطعة أو المكون الشمسي'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedComponentType,
                        isExpanded: true,
                        icon: const Icon(Icons.category_rounded, color: AppTheme.primaryGold),
                        items: _componentTypes.map((comp) {
                          return DropdownMenuItem(
                            value: comp,
                            child: Text(comp, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedComponentType = val!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Price Range Slider (IQD Only)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('نطاق السعر (بالدينار العراقي)'),
                      Text(
                        '${(_priceRange.start.round() * 1500).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} - ${(_priceRange.end.round() * 1500).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} د.ع',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold, fontSize: 11),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 50,
                    max: 5000,
                    divisions: 99,
                    activeColor: AppTheme.primaryGold,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (values) => setState(() => _priceRange = values),
                  ),

                  const SizedBox(height: 20),

                  // 5. Rating Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionLabel('التقييم الأدنى'),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppTheme.primaryGold, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${_minRating.toStringAsFixed(1)}+ نجوم',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _minRating,
                    min: 3.0,
                    max: 5.0,
                    divisions: 4,
                    activeColor: AppTheme.primaryGold,
                    onChanged: (val) => setState(() => _minRating = val),
                  ),

                  const SizedBox(height: 20),

                  // 6. Fast Toggles
                  SwitchListTile(
                    title: const Text('المتاجر والفنيين المعتمدين فقط 🛡️', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    subtitle: const Text('إظهار الكيانات التي تمتلك شهادة فحص واختبار رسمية', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _verifiedOnly,
                    activeColor: AppTheme.primaryGold,
                    onChanged: (val) => setState(() => _verifiedOnly = val),
                  ),
                  SwitchListTile(
                    title: const Text('يشمل كفالة وضمان ممتد +25 سنة 📜', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    value: _warrantyOnly,
                    activeColor: AppTheme.primaryGold,
                    onChanged: (val) => setState(() => _warrantyOnly = val),
                  ),
                ],
              ),
            ),

            // Bottom Apply Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  final filterData = {
                    'scope': _selectedCategoryType,
                    'governorate': _selectedGovernorate,
                    'component': _selectedComponentType,
                    'minPrice': _priceRange.start,
                    'maxPrice': _priceRange.end,
                    'minRating': _minRating,
                    'verifiedOnly': _verifiedOnly,
                    'warrantyOnly': _warrantyOnly,
                  };
                  if (widget.onApplyFilters != null) {
                    widget.onApplyFilters!(filterData);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkNavy,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('تطبيق الفلترة وعرض النتائج', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy),
    );
  }
}
