import 'package:flutter_test/flutter_test.dart';
import 'package:iraq_solar_app/features/home/domain/models/banner_model.dart';

void main() {
  group('BannerModel Tests', () {
    test('fromJson parses full JSON correctly', () {
      final jsonMap = {
        'id': 'banner-123',
        'image_url': 'https://example.com/banner.png',
        'mobile_image_url': 'https://example.com/mobile.png',
        'action_type': 'open_store',
        'action_payload': {'store_id': 'store-456'},
        'priority': 80,
        'display_order': 1,
      };

      final banner = BannerModel.fromJson(jsonMap);

      expect(banner.id, equals('banner-123'));
      expect(banner.imageUrl, equals('https://example.com/banner.png'));
      expect(banner.mobileImageUrl, equals('https://example.com/mobile.png'));
      expect(banner.actionType, equals('open_store'));
      expect(banner.actionPayload['store_id'], equals('store-456'));
      expect(banner.priority, equals(80));
      expect(banner.displayOrder, equals(1));
    });

    test('toJson serializes correctly', () {
      final banner = BannerModel(
        id: 'banner-789',
        imageUrl: 'https://example.com/b.jpg',
        actionType: 'open_url',
        actionPayload: {'url': 'https://solar.iq'},
        priority: 10,
      );

      final jsonMap = banner.toJson();

      expect(jsonMap['id'], equals('banner-789'));
      expect(jsonMap['action_type'], equals('open_url'));
      expect(jsonMap['action_payload']['url'], equals('https://solar.iq'));
    });
  });
}
