import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final String? type;
  final double width;
  final double height;
  final BoxFit fit;

  const ProductImageWidget({
    Key? key,
    this.imagePath,
    this.imageUrl,
    this.type,
    this.width = double.infinity,
    this.height = double.infinity,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
      );
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold),
              ),
            ),
          );
        },
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    IconData iconData;
    switch (type) {
      case 'inverter':
        iconData = Icons.bolt_rounded;
        break;
      case 'battery':
        iconData = Icons.battery_charging_full_rounded;
        break;
      case 'heater':
        iconData = Icons.water_drop_rounded;
        break;
      case 'accessory':
        iconData = Icons.sensors_rounded;
        break;
      case 'kit':
        iconData = Icons.inventory_2_rounded;
        break;
      default:
        iconData = Icons.solar_power_rounded;
    }

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          color: AppTheme.primaryGold,
          size: height > 100 ? 56 : 32,
        ),
      ),
    );
  }
}
