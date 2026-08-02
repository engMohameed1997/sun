import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/auth_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  static Future<Map<String, String>> headersAsync([String? token]) async {
    final activeToken = token ?? await AuthStorageService.getToken();
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (activeToken != null && activeToken.isNotEmpty) {
      map['Authorization'] = 'Bearer $activeToken';
    }
    return map;
  }

  static Map<String, String> headers([String? token]) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  // 1. Health Check
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8080/health'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'status': 'disconnected'};
    } catch (e) {
      return {'success': false, 'status': 'error', 'error': e.toString()};
    }
  }

  // 2. Auth: Register
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? governorate,
    String? city,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers(),
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
          'governorate': governorate ?? 'Baghdad',
          'city': city ?? 'Karrada',
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 3. Auth: Login
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 4. Orders: Create Order
  static Future<Map<String, dynamic>> createOrder(String token, Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers(token),
        body: jsonEncode(orderData),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل إنشاء الطلب: $e'};
    }
  }

  // 5. Orders: List User Orders
  static Future<Map<String, dynamic>> getUserOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: headers(token),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب الطلبات: $e'};
    }
  }

  // 6. Cart: Get Cart Items & Add
  static Future<Map<String, dynamic>> getCart(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart'), headers: headers(token));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب السلة'};
    }
  }

  // 7. Wallet: Get Balance
  static Future<Map<String, dynamic>> getWalletBalance(String token) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/wallet/balance'), headers: headers(token));
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب رصيد المحفظة'};
    }
  }

  // 8. Categories List
  static Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'), headers: headers());
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب التصنيفات'};
    }
  }

  // 9. Solar System Sizing Calculation
  static Future<Map<String, dynamic>> calculateSystem({
    required double dailykWh,
    required double peakSunHours,
    required int autonomyDays,
    required int panelWattage,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/estimate'),
        headers: headers(token),
        body: jsonEncode({
          'daily_consumption_kwh': dailykWh,
          'peak_sun_hours': peakSunHours,
          'autonomy_days': autonomyDays,
          'panel_wattage': panelWattage,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل في استلام نتائج الحساب'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.1 ROI & Savings Calculation
  static Future<Map<String, dynamic>> calculateROI({
    required double monthlyGeneratorFeeIQD,
    required double monthlyGridFeeIQD,
    required double systemCostIQD,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/roi'),
        headers: headers(),
        body: jsonEncode({
          'monthly_generator_fee_iqd': monthlyGeneratorFeeIQD,
          'monthly_national_grid_fee_iqd': monthlyGridFeeIQD,
          'system_cost_iqd': systemCostIQD,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.2 Battery Runtime Calculation
  static Future<Map<String, dynamic>> calculateBatteryRuntime({
    required double batteryCapacitykWh,
    required String batteryType,
    required double currentLoadkW,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/battery-runtime'),
        headers: headers(),
        body: jsonEncode({
          'battery_capacity_kwh': batteryCapacitykWh,
          'battery_type': batteryType,
          'current_load_kw': currentLoadkW,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.3 Appliance Consumption Calculation
  static Future<Map<String, dynamic>> calculateApplianceConsumption({
    required String applianceName,
    required double wattage,
    required int quantity,
    required double dailyHours,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/appliance-consumption'),
        headers: headers(),
        body: jsonEncode({
          'appliance_name': applianceName,
          'wattage': wattage,
          'quantity': quantity,
          'daily_hours': dailyHours,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.4 Roof Capacity Calculation
  static Future<Map<String, dynamic>> calculateRoofCapacity({
    required double length,
    required double width,
    int panelWattage = 550,
    double obstructionPercent = 10,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/roof-capacity'),
        headers: headers(),
        body: jsonEncode({
          'length_meters': length,
          'width_meters': width,
          'panel_wattage': panelWattage,
          'obstruction_percentage': obstructionPercent,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.5 Full Kit Cost Calculation
  static Future<Map<String, dynamic>> calculateFullKitCost({
    required double systemSizekW,
    required double batterykWh,
    bool includeInstallation = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/full-cost'),
        headers: headers(),
        body: jsonEncode({
          'system_size_kw': systemSizekW,
          'battery_kwh': batterykWh,
          'include_installation': includeInstallation,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.6 Technician: Cable Sizing
  static Future<Map<String, dynamic>> calculateCableSizing({
    required double amps,
    required double distance,
    required double voltage,
    String wireMaterial = 'copper',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/tech/cable-sizing'),
        headers: headers(),
        body: jsonEncode({
          'current_amps': amps,
          'distance_meters': distance,
          'system_voltage': voltage,
          'wire_material': wireMaterial,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.7 Technician: MPPT String
  static Future<Map<String, dynamic>> calculateMPPTString({
    required double panelVoc,
    required double panelVmp,
    required double inverterMaxVoc,
    required double inverterMinMPPT,
    required double inverterMaxMPPT,
    double minTempC = 0,
    double maxTempC = 50,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/tech/mppt-string'),
        headers: headers(),
        body: jsonEncode({
          'panel_voc': panelVoc,
          'panel_vmp': panelVmp,
          'min_temp_c': minTempC,
          'max_temp_c': maxTempC,
          'inverter_max_voc': inverterMaxVoc,
          'inverter_min_mppt_v': inverterMinMPPT,
          'inverter_max_mppt_v': inverterMaxMPPT,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.8 Technician: Breakers & Fuses
  static Future<Map<String, dynamic>> calculateBreakersFuses({
    required double arrayIsc,
    required double inverterOutputAmps,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/tech/breakers-fuses'),
        headers: headers(),
        body: jsonEncode({
          'array_isc': arrayIsc,
          'inverter_output_amps': inverterOutputAmps,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.9 Technician: Battery Bank
  static Future<Map<String, dynamic>> calculateBatteryBank({
    required double targetVoltage,
    required double targetCapacitykWh,
    required double singleBatteryVoltage,
    required double singleBatteryAh,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/tech/battery-bank'),
        headers: headers(),
        body: jsonEncode({
          'target_voltage': targetVoltage,
          'target_capacity_kwh': targetCapacitykWh,
          'single_battery_voltage': singleBatteryVoltage,
          'single_battery_ah': singleBatteryAh,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 9.10 Technician: Solar Production
  static Future<Map<String, dynamic>> calculateSolarProduction({
    required String province,
    required double systemSizekW,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calculator/tech/solar-production'),
        headers: headers(),
        body: jsonEncode({
          'province': province,
          'system_size_kw': systemSizekW,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 10. Products Catalog

  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل في جلب المنتجات'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 11. Profile
  static Future<Map<String, dynamic>> getUserProfile([String? token]) async {
    try {
      final h = await headersAsync(token);
      final response = await http.get(Uri.parse('$baseUrl/user/profile'), headers: h);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب ملف المستخدم'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // 12. Wallet Topup
  static Future<Map<String, dynamic>> topUpWallet(double amountUSD, [String? token]) async {
    try {
      final h = await headersAsync(token);
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/topup'),
        headers: h,
        body: jsonEncode({'amount_usd': amountUSD}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل شحن المحفظة: $e'};
    }
  }

  // 13. Admin Stats & Audit Logs
  static Future<Map<String, dynamic>> getAdminStats([String? token]) async {
    try {
      final h = await headersAsync(token);
      final response = await http.get(Uri.parse('$baseUrl/admin/stats'), headers: h);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب إحصائيات الإدارة'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAuditLogs([String? token]) async {
    try {
      final h = await headersAsync(token);
      final response = await http.get(Uri.parse('$baseUrl/admin/audit-logs'), headers: h);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب سجلات الأمان'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // 14. Live Stores List
  static Future<Map<String, dynamic>> getStores() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stores'), headers: headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب المتاجر المحلية'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 15. Live Banners List
  static Future<Map<String, dynamic>> getBanners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/banners'), headers: headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب إعلانات البنرات'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 16. Notifications
  static Future<Map<String, dynamic>> getNotifications({int page = 1, int perPage = 20}) async {
    try {
      final h = await headersAsync();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications?page=$page&per_page=$perPage'),
        headers: h,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب الإشعارات'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    try {
      final h = await headersAsync();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: h,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب عدد الإشعارات'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      final h = await headersAsync();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: h,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تحديث الإشعار: $e'};
    }
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final h = await headersAsync();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: h,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تحديث الإشعارات: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final h = await headersAsync();
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: h,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل حذف الإشعار: $e'};
    }
  }

  // 17. Installers/Engineers Directory
  static Future<Map<String, dynamic>> getInstallers({String? governorate, String? search, int page = 1, int perPage = 20}) async {
    try {
      String url = '$baseUrl/installers?page=$page&per_page=$perPage';
      if (governorate != null && governorate.isNotEmpty && governorate != 'الكل') {
        url += '&governorate=${Uri.encodeComponent(governorate)}';
      }
      if (search != null && search.isNotEmpty) {
        url += '&search=${Uri.encodeComponent(search)}';
      }
      final response = await http.get(Uri.parse(url), headers: headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب قائمة الفنيين'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  static Future<Map<String, dynamic>> getInstallerDetail(String installerId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/installers/$installerId'), headers: headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب تفاصيل الفني'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 18. Profile Update
  static Future<Map<String, dynamic>> updateProfile({required String fullName, required String phone, required String governorate, required String city}) async {
    try {
      final h = await headersAsync();
      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: h,
        body: jsonEncode({'full_name': fullName, 'phone': phone, 'governorate': governorate, 'city': city}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تحديث الملف الشخصي: $e'};
    }
  }

  // 19. Change Password
  static Future<Map<String, dynamic>> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      final h = await headersAsync();
      final response = await http.put(
        Uri.parse('$baseUrl/user/password'),
        headers: h,
        body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تغيير كلمة المرور: $e'};
    }
  }
}

