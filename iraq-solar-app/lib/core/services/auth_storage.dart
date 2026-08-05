import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const String _keyToken = 'auth_jwt_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserData = 'auth_user_data';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserData);
    if (data == null || data.isEmpty) return null;
    try {
      return jsonDecode(data);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final refreshToken = await getRefreshToken();
    final user = await getUser();
    final hasToken = (token != null && token.isNotEmpty) || (refreshToken != null && refreshToken.isNotEmpty);
    if (!hasToken || user == null || user.isEmpty) {
      return false;
    }
    return true;
  }

  static Future<void> clearBannerCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cached_banners_')) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
    await clearBannerCache();
  }
}
