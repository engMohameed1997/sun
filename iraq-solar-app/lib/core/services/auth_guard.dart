import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'auth_storage.dart';

class AuthGuard {
  /// Checks if the user is authenticated. If yes, runs [onSuccess] or returns true.
  /// If not authenticated, opens full-screen [SolarLoginScreen] directly (no bottomsheet modal).
  static Future<bool> requireAuth(
    BuildContext context, {
    required String reasonMessage,
    VoidCallback? onSuccess,
  }) async {
    final loggedIn = await AuthStorageService.isLoggedIn();
    if (loggedIn) {
      if (onSuccess != null) {
        onSuccess();
      }
      return true;
    }

    if (!context.mounted) return false;

    // Open Full Screen SolarLoginScreen directly
    final loginSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SolarLoginScreen()),
    );

    if (loginSuccess == true) {
      if (onSuccess != null) {
        onSuccess();
      }
      return true;
    }

    return false;
  }
}
