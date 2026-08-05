import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
import '../shared/workforce_constants.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _technician;
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> _zones = [];

  // Availability & Hours
  String _availabilityStatus = 'offline';
  TimeOfDay _availableFrom = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _availableUntil = const TimeOfDay(hour: 17, minute: 0);
  final Set<String> _workingDays = {'sat', 'sun', 'mon', 'tue', 'wed', 'thu'};

  final List<Map<String, dynamic>> _allGovernorates = [
    {'id': 1, 'name': 'بغداد'},
    {'id': 2, 'name': 'البصرة'},
    {'id': 3, 'name': 'أربيل'},
    {'id': 4, 'name': 'النجف الأشرف'},
    {'id': 5, 'name': 'نينوى (الموصل)'},
    {'id': 6, 'name': 'كربلاء المقدسة'},
    {'id': 7, 'name': 'بابل (الحلة)'},
    {'id': 8, 'name': 'ذي قار (الناصرية)'},
    {'id': 9, 'name': 'كركوك'},
    {'id': 10, 'name': 'ديالى'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final res = await ApiClient.getTechnicianProfile();
    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      final data = Map<String, dynamic>.from(res['data']);
      final tech = Map<String, dynamic>.from(data['technician'] ?? {});
      final port = List<Map<String, dynamic>>.from(data['portfolio'] ?? []);
      final zns = List<Map<String, dynamic>>.from(data['zones'] ?? []);

      setState(() {
        _profile = data;
        _technician = tech;
        _portfolio = port;
        _zones = zns;
        _availabilityStatus = tech['availability_status']?.toString() ?? 'offline';

        if (tech['available_from'] != null) {
          _availableFrom = _parseTime(tech['available_from'].toString()) ?? _availableFrom;
        }
        if (tech['available_until'] != null) {
          _availableUntil = _parseTime(tech['available_until'].toString()) ?? _availableUntil;
        }
        if (tech['working_days'] is List) {
          _workingDays.clear();
          for (var day in tech['working_days']) {
            _workingDays.add(day.toString());
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    } catch (_) {}
    return null;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveWorkingHours() async {
    final res = await ApiClient.updateAvailability(
      status: _availabilityStatus,
      availableFrom: _formatTime(_availableFrom),
      availableUntil: _formatTime(_availableUntil),
      workingDays: _workingDays.toList(),
    );
    if (!mounted) return;
    if (res['success'] == true) {
      AppNotification.showSuccess(context, 'تم تحديث ساعات وأيام العمل بنجاح ⏰');
      _loadProfileData();
    } else {
      AppNotification.showError(context, res['message']?.toString() ?? 'فشل التحديث');
    }
  }

  Future<void> _showZonesDialog() async {
    final selectedIds = _zones.map<int>((z) => (z['governorate_id'] as num).toInt()).toSet();
    int? primaryGovId = _zones.firstWhere(
      (z) => z['is_primary'] == true,
      orElse: () => _zones.isNotEmpty ? _zones.first : {'governorate_id': 1},
    )['governorate_id'] as int?;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('إدارة مناطق التغطية الجغرافية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allGovernorates.length,
                    itemBuilder: (context, index) {
                      final gov = _allGovernorates[index];
                      final id = gov['id'] as int;
                      final name = gov['name'] as String;
                      final isChecked = selectedIds.contains(id);
                      final isPrimary = primaryGovId == id;

                      return CheckboxListTile(
                        title: Row(
                          children: [
                            Text(name, style: const TextStyle(fontSize: 14)),
                            if (isPrimary) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('الرئيسية', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        value: isChecked,
                        activeColor: AppTheme.primaryGold,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedIds.add(id);
                              primaryGovId ??= id;
                            } else {
                              selectedIds.remove(id);
                              if (primaryGovId == id) {
                                primaryGovId = selectedIds.isNotEmpty ? selectedIds.first : null;
                              }
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy),
                    onPressed: () async {
                      Navigator.pop(context);
                      final res = await ApiClient.updateTechnicianZones(
                        governorateIds: selectedIds.toList(),
                        primaryGovernorate: primaryGovId,
                      );
                      if (!mounted) return;
                      if (res['success'] == true) {
                        AppNotification.showSuccess(context, 'تم تحديث مناطق التغطية بنجاح 🗺️');
                        _loadProfileData();
                      } else {
                        AppNotification.showError(context, res['message']?.toString() ?? 'فشل التحديث');
                      }
                    },
                    child: const Text('حفظ المناطق', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }

    final name = _technician?['full_name'] ?? 'الفني';
    final role = _technician?['role'] == 'engineer' ? 'مهندس طاقة شمسية' : 'فني تركيبات';
    final isVerified = _technician?['is_verified'] == true;
    final rating = (_technician?['rating'] as num?)?.toDouble() ?? 0.0;
    final jobsCount = _technician?['completed_jobs_count'] ?? 0;
    final levelName = _technician?['level_name_ar'] ?? 'فني معتمد';
    final acceptanceRate = (_technician?['acceptance_rate'] as num?)?.toDouble() ?? 100.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('الملف الشخصي والمهني'),
          backgroundColor: AppTheme.darkNavy,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _loadProfileData,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.darkNavy,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.darkNavy.withValues(alpha: 0.25), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                          child: const Icon(Icons.engineering_rounded, color: AppTheme.primaryGold, size: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isVerified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: AppTheme.accentGreen, borderRadius: BorderRadius.circular(12)),
                                      child: const Text('موثق 🛡️', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(role, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('المستوى: $levelName', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('التقييم', '⭐ ${rating.toStringAsFixed(1)}'),
                        _buildStatItem('أعمال مكتملة', '$jobsCount مهمة'),
                        _buildStatItem('نسبة القبول', '${acceptanceRate.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Working Hours & Days Section
              const Text('ساعات وأيام العمل (التواجد)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _availableFrom);
                              if (picked != null) setState(() => _availableFrom = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('من الساعة', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(_formatTime(_availableFrom), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _availableUntil);
                              if (picked != null) setState(() => _availableUntil = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('إلى الساعة', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(_formatTime(_availableUntil), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Align(alignment: Alignment.centerRight, child: Text('أيام العمل في الأسبوع:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: WorkforceConstants.weekDays.entries.map((entry) {
                        final isSelected = _workingDays.contains(entry.key);
                        return FilterChip(
                          label: Text(entry.value, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppTheme.darkNavy)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGold,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _workingDays.add(entry.key);
                              } else {
                                _workingDays.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveWorkingHours,
                        icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                        label: const Text('حفظ ساعات العمل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Service Zones Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مناطق التغطية الجغرافية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                  TextButton.icon(
                    onPressed: _showZonesDialog,
                    icon: const Icon(Icons.edit_location_alt_rounded, size: 16, color: AppTheme.primaryGold),
                    label: const Text('تعديل المناطق', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _zones.isEmpty
                    ? const Text('لم تقم بتحديد مناطق تغطية بعد. انقر على تعديل المناطق.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _zones.map((zone) {
                          final name = zone['governorate_name'] ?? 'محافظة';
                          final isPrimary = zone['is_primary'] == true;
                          return Chip(
                            avatar: Icon(Icons.location_on_rounded, size: 14, color: isPrimary ? Colors.white : AppTheme.primaryGold),
                            label: Text(name, style: TextStyle(fontSize: 11, color: isPrimary ? Colors.white : AppTheme.darkNavy, fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal)),
                            backgroundColor: isPrimary ? AppTheme.darkNavy : Colors.grey.shade100,
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 20),

              // Portfolio Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('معرض المشاريع والأعمال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy)),
                  Text('${_portfolio.length} مشروع', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              _portfolio.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_outlined, size: 42, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('لا توجد مشاريع مرفوعة في معرض أعمالك حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _portfolio.length,
                      itemBuilder: (context, index) {
                        final item = _portfolio[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.solar_power_rounded, color: AppTheme.primaryGold),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['title'] ?? 'مشروع تركيب', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (item['description'] != null)
                                      Text(item['description'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('${item['system_capacity_kw'] ?? 0} kW ⋅ ${item['governorate'] ?? ''}', style: const TextStyle(fontSize: 10, color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
