import 'package:flutter/material.dart';
import '../../features/home/domain/models/banner_model.dart';
import '../network/api_client.dart';
import '../../features/merchant/presentation/screens/store_detail_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/products/presentation/screens/catalog_screen.dart';

typedef BannerActionFn = void Function(BuildContext context, Map<String, dynamic> payload);

class BannerActionHandler {
  static final Map<String, BannerActionFn> _handlers = {
    'open_store': (context, payload) {
      final storeId = payload['store_id']?.toString() ?? payload['storeId']?.toString();
      if (storeId != null && storeId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreDetailScreen(
              storeData: {'id': storeId, 'name': payload['store_name'] ?? 'المتجر'},
            ),
          ),
        );
      }
    },
    'open_product': (context, payload) {
      final productId = payload['product_id']?.toString() ?? payload['productId']?.toString();
      if (productId != null && productId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: {
                'id': productId,
                'name': payload['product_name'] ?? payload['title'] ?? 'منتج',
              },
            ),
          ),
        );
      }
    },
    'open_category': (context, payload) {
      final categoryId = payload['category_id']?.toString() ?? payload['categoryId']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SolarCatalogScreen(
              initialFilters: {'category_id': categoryId},
            ),
          ),
        );
      }
    },
    'open_search': (context, payload) {
      final query = payload['query']?.toString() ?? payload['search_term']?.toString() ?? '';
      if (query.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SolarCatalogScreen(
              initialSearchQuery: query,
            ),
          ),
        );
      }
    },
    'open_url': (context, payload) {
      final url = payload['url']?.toString() ?? '';
      if (url.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فتح الرابط: $url'),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    },
    'none': (context, payload) {},
  };

  static Future<void> handleAction(BuildContext context, BannerModel banner) async {
    // 1. Send click event asynchronously (fire-and-forget)
    ApiClient.trackBannerEvent(banner.id, 'click');

    final payload = banner.actionPayload;
    final handler = _handlers[banner.actionType] ?? _handlers['none'];
    handler?.call(context, payload);
  }
}
