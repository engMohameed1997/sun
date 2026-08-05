import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../services/auth_storage.dart';

class ApiClient {
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static String? resolveImageUrl(dynamic input) {
    if (input == null) return null;
    if (input is List && input.isNotEmpty) {
      return resolveImageUrl(input.first);
    }
    if (input is String && input.trim().isNotEmpty) {
      var str = input.trim();
      final currentUri = Uri.tryParse(baseUrl);
      final currentHost = currentUri?.host ?? (!kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost');

      if (currentHost != 'localhost' && currentHost != '127.0.0.1') {
        str = str.replaceAll('://localhost:', '://$currentHost:');
        str = str.replaceAll('://127.0.0.1:', '://$currentHost:');
        str = str.replaceAll('://localhost/', '://$currentHost/');
        str = str.replaceAll('://127.0.0.1/', '://$currentHost/');
      }

      if (str.startsWith('http://') || str.startsWith('https://')) {
        return str;
      }
      if (str.startsWith('assets/')) {
        return str;
      }
      final host = baseUrl.replaceAll('/api/v1', '');
      return str.startsWith('/') ? '$host$str' : '$host/$str';
    }
    return null;
  }

  // Helper for persistent device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('app_device_id');
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString('app_device_id', deviceId);
    }
    return deviceId;
  }

  static Future<Map<String, String>> headersAsync([String? token]) async {
    final activeToken = token ?? await AuthStorageService.getToken();
    final refreshToken = await AuthStorageService.getRefreshToken();
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (activeToken != null && activeToken.isNotEmpty) {
      map['Authorization'] = 'Bearer $activeToken';
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      map['X-Refresh-Token'] = refreshToken;
    }
    return map;
  }

  static Map<String, String> headers([String? token, String? refreshToken]) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      map['X-Refresh-Token'] = refreshToken;
    }
    return map;
  }

  static Future<bool> refreshTokenApi() async {
    final currentRefreshToken = await AuthStorageService.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Refresh-Token': currentRefreshToken,
        },
        body: jsonEncode({'refresh_token': currentRefreshToken}),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['success'] == true && res['data'] != null) {
          final data = res['data'];
          if (data['token'] != null) {
            await AuthStorageService.saveToken(data['token'].toString());
          }
          if (data['refresh_token'] != null) {
            await AuthStorageService.saveRefreshToken(data['refresh_token'].toString());
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<http.Response> sendAuthenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) requestFn, {
    String? explicitToken,
  }) async {
    var token = explicitToken ?? await AuthStorageService.getToken();
    var h = await headersAsync(token);
    var response = await requestFn(h);

    if (response.statusCode == 401) {
      final refreshed = await refreshTokenApi();
      if (refreshed) {
        final newToken = await AuthStorageService.getToken();
        h = await headersAsync(newToken);
        response = await requestFn(h);
      }
    }
    return response;
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
    required String phone,
    required String password,
    required String role,
    int? governorateId,
    int? districtId,
    String? governorate,
    String? city,
    String? landmark,
  }) async {
    try {
      final payload = <String, dynamic>{
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'role': role,
      };
      if (governorateId != null) payload['governorate_id'] = governorateId;
      if (districtId != null) payload['district_id'] = districtId;
      if (governorate != null && governorate.isNotEmpty) payload['governorate'] = governorate;
      if (city != null && city.isNotEmpty) payload['city'] = city;
      if (landmark != null && landmark.isNotEmpty) payload['landmark'] = landmark;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers(),
        body: jsonEncode(payload),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 3. Auth: Login
  static Future<Map<String, dynamic>> loginUser({
    String? phone,
    required String password,
  }) async {
    try {
      final payload = <String, dynamic>{
        'password': password,
      };
      if (phone != null && phone.isNotEmpty) {
        payload['phone'] = phone;
      }
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers(),
        body: jsonEncode(payload),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر: $e'};
    }
  }

  // 4. Orders: Create Order (correct payload for Go backend)
  static Future<Map<String, dynamic>> createOrder(String token, Map<String, dynamic> orderData) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.post(Uri.parse('$baseUrl/orders'), headers: h, body: jsonEncode(orderData)),
        explicitToken: token,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل إنشاء الطلب: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserOrders([String? token]) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/orders'), headers: h),
        explicitToken: token,
      );
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode == 401) {
          decoded['error_code'] = 'UNAUTHORIZED';
        }
        return decoded;
      }
      return {'success': false, 'message': 'استجابة غير صالحة'};
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب الطلبات: $e'};
    }
  }

  // 5b. Orders: Get Single Order by ID (with full relations)
  static Future<Map<String, dynamic>> getOrderById(String token, String orderId) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/orders/$orderId'), headers: h),
        explicitToken: token,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب تفاصيل الطلب: $e'};
    }
  }

  // 5c. Orders: Cancel an Order
  static Future<Map<String, dynamic>> cancelOrder(String token, String orderId) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.delete(Uri.parse('$baseUrl/orders/$orderId'), headers: h),
        explicitToken: token,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل إلغاء الطلب: $e'};
    }
  }

  // 5d. Support Tickets: List User Tickets
  static Future<Map<String, dynamic>> getSupportTickets() async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/support/tickets'), headers: h),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب تذاكر الدعم الفني: $e'};
    }
  }

  // 5e. Support Tickets: Create Ticket
  static Future<Map<String, dynamic>> createSupportTicket({required String message, String? subject}) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.post(
          Uri.parse('$baseUrl/support/tickets'),
          headers: h,
          body: jsonEncode({
            'subject': subject ?? 'بلاغ / استفسار عام',
            'message': message,
          }),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل إرسال تذكرة الدعم: $e'};
    }
  }

  // 5f. Saved Calculations: List User Calculations
  static Future<Map<String, dynamic>> getSavedCalculations() async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/user/calculations'), headers: h),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب الحسابات المحفوظة: $e'};
    }
  }

  // 6. Cart: Get Cart Items & Add
  static Future<Map<String, dynamic>> getCart([String? token]) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/cart'), headers: h),
        explicitToken: token,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب السلة'};
    }
  }

  // 7. Wallet: Get Balance
  static Future<Map<String, dynamic>> getWalletBalance([String? token]) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/wallet/balance'), headers: h),
        explicitToken: token,
      );
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
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/user/profile'), headers: h),
        explicitToken: token,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'فشل جلب ملف المستخدم'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // 11b. Fetch profile from API and save to local storage
  static Future<Map<String, dynamic>?> fetchAndSaveUserProfile() async {
    try {
      final res = await getUserProfile();
      if (res['success'] == true && res['data'] != null && res['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(res['data']);
        await AuthStorageService.saveUser(data);
        return data;
      }
    } catch (_) {}
    return null;
  }

  // 12. Wallet Topup
  static Future<Map<String, dynamic>> topUpWallet(double amountUSD, [String? token]) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.post(
          Uri.parse('$baseUrl/wallet/topup'),
          headers: h,
          body: jsonEncode({'amount_usd': amountUSD}),
        ),
        explicitToken: token,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل شحن المحفظة: $e'};
    }
  }

  // 13. Admin Stats & Audit Logs
  static Future<Map<String, dynamic>> getAdminStats([String? token]) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/admin/stats'), headers: h),
        explicitToken: token,
      );
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
      final response = await sendAuthenticatedRequest(
        (h) => http.get(Uri.parse('$baseUrl/admin/audit-logs'), headers: h),
        explicitToken: token,
      );
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

  // 15. Live Banners List (with query parameters & SharedPreferences per-user local offline cache)
  static Future<Map<String, dynamic>> getBanners({
    String placement = 'home',
    String? storeId,
    String? categoryId,
    String? productId,
  }) async {
    final user = await AuthStorageService.getUser();
    final userId = user?['id']?.toString();
    final userPrefix = (userId != null && userId.isNotEmpty) ? 'user_$userId' : 'guest';
    final cacheKey = 'cached_banners_${userPrefix}_${placement}_${storeId ?? ""}_${categoryId ?? ""}_${productId ?? ""}';

    try {
      final prefs = await SharedPreferences.getInstance();

      final queryParams = <String, String>{
        'placement': placement,
      };
      if (storeId != null && storeId.isNotEmpty) queryParams['store_id'] = storeId;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['category_id'] = categoryId;
      if (productId != null && productId.isNotEmpty) queryParams['product_id'] = productId;

      final uri = Uri.parse('$baseUrl/banners').replace(queryParameters: queryParams);
      final reqHeaders = await headersAsync();
      final response = await http.get(uri, headers: reqHeaders);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true) {
          final cacheData = {
            'cached_at': DateTime.now().millisecondsSinceEpoch,
            'response': decoded,
          };
          await prefs.setString(cacheKey, jsonEncode(cacheData));
        }
        return decoded;
      }
    } catch (_) {}

    // Fallback to local SharedPreferences cache if offline/error
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final cachedObj = jsonDecode(cachedStr);
        if (cachedObj is Map && cachedObj['response'] != null) {
          return Map<String, dynamic>.from(cachedObj['response'] as Map);
        }
        return jsonDecode(cachedStr);
      }
    } catch (_) {}

    return {'success': false, 'message': 'فشل جلب إعلانات البنرات'};
  }

  // 15b. Track Banner Event (impression or click)
  static Future<bool> trackBannerEvent(String bannerId, String eventType, {Map<String, dynamic>? metadata}) async {
    try {
      final deviceId = await getDeviceId();
      final body = <String, dynamic>{
        'event_type': eventType,
        'device_id': deviceId,
      };
      if (metadata != null) body['metadata'] = metadata;

      final reqHeaders = await headersAsync();
      final response = await http.post(
        Uri.parse('$baseUrl/banners/$bannerId/track'),
        headers: reqHeaders,
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 16. Notifications
  static Future<Map<String, dynamic>> getNotifications({int page = 1, int perPage = 20}) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.get(
          Uri.parse('$baseUrl/notifications?page=$page&per_page=$perPage'),
          headers: h,
        ),
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
      final response = await sendAuthenticatedRequest(
        (h) => http.get(
          Uri.parse('$baseUrl/notifications/unread-count'),
          headers: h,
        ),
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
      final response = await sendAuthenticatedRequest(
        (h) => http.put(
          Uri.parse('$baseUrl/notifications/$notificationId/read'),
          headers: h,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تحديث الإشعار: $e'};
    }
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.put(
          Uri.parse('$baseUrl/notifications/read-all'),
          headers: h,
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تحديث الإشعارات: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.delete(
          Uri.parse('$baseUrl/notifications/$notificationId'),
          headers: h,
        ),
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
      final response = await sendAuthenticatedRequest(
        (h) => http.put(
          Uri.parse('$baseUrl/user/profile'),
          headers: h,
          body: jsonEncode({'full_name': fullName, 'phone': phone, 'governorate': governorate, 'city': city}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تحديث الملف الشخصي: $e'};
    }
  }

  // 19. Change Password
  static Future<Map<String, dynamic>> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      final response = await sendAuthenticatedRequest(
        (h) => http.put(
          Uri.parse('$baseUrl/user/password'),
          headers: h,
          body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
        ),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل تغيير كلمة المرور: $e'};
    }
  }

  // 20. Governorates List (Public)
  static Future<Map<String, dynamic>> getGovernorates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/governorates'), headers: headers());
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب المحافظات: $e'};
    }
  }

  // 21. Store Delivery Fees (Public - per store)
  static Future<Map<String, dynamic>> getStoreDeliveryFees(String storeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stores/$storeId/delivery-fees'), headers: headers());
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب أسعار التوصيل: $e'};
    }
  }

  // 22. Districts List (Public)
  static Future<Map<String, dynamic>> getDistricts(int governorateId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/governorates/$governorateId/districts'), headers: headers());
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'فشل جلب الأقضية والنواحي: $e'};
    }
  }
}

