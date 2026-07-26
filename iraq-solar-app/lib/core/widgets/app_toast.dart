import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NotificationType { success, error, info }

class AppNotification {
  static void showSuccess(BuildContext context, String message, {String title = 'تمت العملية بنجاح'}) {
    _show(context, title: title, message: message, type: NotificationType.success);
  }

  static void showError(BuildContext context, String message, {String title = 'تنبيه'}) {
    _show(context, title: title, message: message, type: NotificationType.error);
  }

  static void showInfo(BuildContext context, String message, {String title = 'إشعار'}) {
    _show(context, title: title, message: message, type: NotificationType.info);
  }

  static void _show(
    BuildContext context, {
    required String title,
    required String message,
    required NotificationType type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) {
        // Auto-dismiss dialog after 1.8 seconds
        Timer(const Duration(milliseconds: 1800), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });

        IconData iconData;
        Color primaryColor;
        List<Color> bgGradient;

        switch (type) {
          case NotificationType.success:
            iconData = Icons.check_circle_rounded;
            primaryColor = const Color(0xFF10B981); // Emerald Green
            bgGradient = [const Color(0xFFD1FAE5), Colors.white];
            break;
          case NotificationType.error:
            iconData = Icons.error_rounded;
            primaryColor = const Color(0xFFEF4444); // Red
            bgGradient = [const Color(0xFFFEE2E2), Colors.white];
            break;
          case NotificationType.info:
            iconData = Icons.info_rounded;
            primaryColor = AppTheme.primaryGold;
            bgGradient = [const Color(0xFFFEF3C7), Colors.white];
            break;
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 12,
            backgroundColor: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.7, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: bgGradient,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                      border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Glow Ring with Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 16,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Icon(iconData, color: primaryColor, size: 54),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkNavy,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Message Text
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Optional OK Button
                        InkWell(
                          onTap: () {
                            if (Navigator.of(ctx).canPop()) {
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'تم',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
