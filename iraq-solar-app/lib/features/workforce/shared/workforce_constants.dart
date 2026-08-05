import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Shared labels, colors and helpers for the workforce dispatch feature.
class WorkforceConstants {
  static const Map<String, String> orderTypeLabels = {
    'installation': 'تركيب',
    'maintenance': 'صيانة',
    'inspection': 'معاينة',
    'consultation': 'استشارة',
    'repair': 'إصلاح',
  };

  static const Map<String, IconData> orderTypeIcons = {
    'installation': Icons.solar_power_rounded,
    'maintenance': Icons.build_rounded,
    'inspection': Icons.search_rounded,
    'consultation': Icons.support_agent_rounded,
    'repair': Icons.handyman_rounded,
  };

  /// Customer-facing status labels — technician identity is never revealed here.
  static const Map<String, String> customerStatusLabels = {
    'new': 'تم استلام طلبك',
    'dispatching': 'جاري التعيين',
    'assigned': 'تم تعيين فني معتمد',
    'tech_accepted': 'تم تعيين فني معتمد',
    'on_the_way': 'الفني في الطريق',
    'arrived': 'وصل الفني',
    'working': 'جاري التنفيذ',
    'waiting_customer': 'بانتظار تجاوبك',
    'completed': 'تم الإنجاز',
    'cancelled': 'تم الإلغاء',
    'no_technician_available': 'لا يوجد فني متوفر حالياً',
  };

  static const Map<String, String> technicianStatusLabels = {
    'assigned': 'مُسندة إليك',
    'on_the_way': 'في الطريق',
    'arrived': 'وصلت',
    'working': 'جاري التنفيذ',
    'waiting_customer': 'الزبون غير متجاوب',
    'completed': 'مكتملة',
  };

  static const Map<String, String> availabilityLabels = {
    'available': 'متوفر',
    'busy': 'مشغول',
    'vacation': 'إجازة',
    'offline': 'غير متصل',
  };

  static const Map<String, String> leadStatusLabels = {
    'pending_review': 'بانتظار المراجعة',
    'approved': 'مقبول',
    'rejected': 'مرفوض',
    'converted': 'تم تحويله لطلب خدمة',
  };

  static const Map<String, String> weekDays = {
    'sat': 'السبت',
    'sun': 'الأحد',
    'mon': 'الإثنين',
    'tue': 'الثلاثاء',
    'wed': 'الأربعاء',
    'thu': 'الخميس',
    'fri': 'الجمعة',
  };

  static Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.accentGreen;
      case 'cancelled':
      case 'no_technician_available':
        return const Color(0xFFEF4444);
      case 'on_the_way':
      case 'arrived':
      case 'working':
        return const Color(0xFF3B82F6);
      case 'assigned':
      case 'tech_accepted':
        return AppTheme.primaryGold;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static Color availabilityColor(String status) {
    switch (status) {
      case 'available':
        return AppTheme.accentGreen;
      case 'busy':
        return AppTheme.primaryGold;
      case 'vacation':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static String formatIqd(num? value) {
    if (value == null) return '0 د.ع';
    final str = value.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '${buffer.toString()} د.ع';
  }

  /// Formats the remaining response time as mm:ss.
  static String formatCountdown(Duration remaining) {
    if (remaining.isNegative) return '00:00';
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
