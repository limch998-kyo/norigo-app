import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/services/rakuten_client.dart';

/// Tests for Rakuten Travel direct API integration.
void main() {
  group('Rakuten Travel API', () {
    test('fetches hotels near Shinjuku with reviews', () async {
      final hotels = await RakutenClient.fetchHotels(
        lat: 35.6938,
        lng: 139.7034,
        radiusKm: 2,
        maxPages: 2,
      );

      expect(hotels, isNotEmpty);
      expect(hotels.first.name, isNotEmpty);
      expect(hotels.first.currency, 'JPY');
      // All returned hotels should have reviews (filtered in client)
      for (final h in hotels) {
        expect(h.reviewScore, isNotNull);
        expect(h.reviewScore!, greaterThan(0));
        expect(h.reviewScore!, lessThanOrEqualTo(10));
      }
      // Check prices
      final withPrice = hotels.where((h) => h.dailyRate != null && h.dailyRate! > 0).toList();
      expect(withPrice, isNotEmpty);
      // Check coordinates
      expect(hotels.first.lat, isNot(0));
      expect(hotels.first.lng, isNot(0));

      print('✓ Rakuten: ${hotels.length} hotels, first=${hotels.first.name}, score=${hotels.first.reviewScore}, price=¥${hotels.first.dailyRate?.round()}');
    });
  });
}
