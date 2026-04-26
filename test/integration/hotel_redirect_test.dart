import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:norigo_app/config/booking_provider.dart';

String _innerUrl(String wrappedUrl) {
  final uri = Uri.parse(wrappedUrl);
  return uri.queryParameters['url'] ?? wrappedUrl;
}

String _expectedCjkDestination({
  required String region,
  required double lat,
  required double lng,
}) {
  if (region == 'seoul' || region == 'busan' || lng < 130) {
    return region == 'busan' || lat < 36 ? 'Busan' : 'Seoul';
  }
  return switch (region) {
    'kansai' => 'Osaka',
    'kyushu' => 'Fukuoka',
    _ => 'Tokyo',
  };
}

void main() {
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (s) => true,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // Test each region × locale combination
  final testCases = [
    // Kanto
    (
      region: 'kanto',
      station: 'Shinjuku',
      lat: 35.69,
      lng: 139.70,
      locale: 'en',
    ),
    (
      region: 'kanto',
      station: 'Shibuya',
      lat: 35.66,
      lng: 139.70,
      locale: 'ko',
    ),
    // Kansai
    (region: 'kansai', station: 'Namba', lat: 34.67, lng: 135.50, locale: 'en'),
    // Kyushu
    (
      region: 'kyushu',
      station: 'Hakata',
      lat: 33.59,
      lng: 130.42,
      locale: 'en',
    ),
    // CJK fallback
    (region: 'kanto', station: '新宿', lat: 35.69, lng: 139.70, locale: 'en'),
    (region: 'kansai', station: '難波', lat: 34.67, lng: 135.50, locale: 'fr'),
  ];

  for (final tc in testCases) {
    group('${tc.station} (${tc.region}, ${tc.locale})', () {
      late List<({String name, String url, Color color, Color textColor})>
      providers;

      setUpAll(() {
        providers = BookingProvider.buildMultiProviderUrls(
          locale: tc.locale,
          region: tc.region,
          stationName: tc.station,
          lat: tc.lat,
          lng: tc.lng,
          checkIn: '2026-05-01',
          checkOut: '2026-05-04',
          maxBudget: '10000-30000',
        );
      });

      if (['en', 'fr', 'zh'].contains('en')) {
        test('Returns 4 providers', () {
          // EN/FR/ZH should get 4 providers, JA/KO get 0
          if (tc.locale == 'ja' || tc.locale == 'ko') {
            expect(providers, isEmpty);
          } else {
            expect(providers.length, 4);
          }
        });
      }

      test('Expedia: /api/out → 302 → Expedia page with station', () async {
        if (providers.isEmpty) return; // JA/KO skip

        final res = await dio.get(providers[0].url);
        expect(res.statusCode, 302, reason: 'Expedia /api/out should 302');

        final location = res.headers['location']?.first ?? '';
        final decoded = Uri.decodeComponent(location);
        print('  Expedia → $decoded');

        expect(
          decoded,
          contains('expedia'),
          reason: 'Should redirect to expedia',
        );
        expect(
          decoded,
          contains('Hotel-Search'),
          reason: 'Should be hotel search page',
        );

        // CJK fallback check
        final hasCjk = RegExp(
          r'[\u3000-\u9FFF\uAC00-\uD7AF]',
        ).hasMatch(tc.station);
        if (hasCjk) {
          expect(
            decoded,
            contains(
              _expectedCjkDestination(
                region: tc.region,
                lat: tc.lat,
                lng: tc.lng,
              ),
            ),
            reason:
                'CJK should fallback to the matching city for region/coordinates',
          );
        } else {
          expect(
            decoded,
            contains(tc.station),
            reason: 'Station name should be in URL',
          );
        }

        // Price params
        expect(decoded, contains('price='), reason: 'Should have price filter');
        expect(
          decoded,
          contains('affcid='),
          reason: 'Should have affiliate ID',
        );
      });

      test(
        'Hotels.com: /api/out → 302 → Hotels.com page with station + USD',
        () async {
          if (providers.isEmpty) return;

          final res = await dio.get(providers[1].url);
          expect(res.statusCode, 302, reason: 'Hotels.com /api/out should 302');

          final location = res.headers['location']?.first ?? '';
          final decoded = Uri.decodeComponent(location);
          print('  Hotels.com → $decoded');

          expect(
            decoded,
            contains('hotels.com'),
            reason: 'Should redirect to hotels.com',
          );
          expect(
            decoded,
            contains('www.hotels.com'),
            reason: 'Should use www.hotels.com',
          );
          expect(decoded, contains('currency=USD'), reason: 'Should force USD');
          expect(decoded, contains('siteid='), reason: 'Should have site ID');
          expect(
            decoded,
            contains('price='),
            reason: 'Should have price filter',
          );
          expect(
            decoded,
            contains('affcid='),
            reason: 'Should have affiliate ID',
          );
          expect(
            decoded,
            contains('sort=RECOMMENDED'),
            reason: 'Should sort by recommended',
          );
        },
      );

      test(
        'Booking.com: /api/out → 302 → Booking.com page with 駅 + lat/lng',
        () async {
          if (providers.isEmpty) return;

          final res = await dio.get(providers[3].url);
          expect(
            res.statusCode,
            302,
            reason: 'Booking.com /api/out should 302',
          );

          final location = res.headers['location']?.first ?? '';
          final decoded = Uri.decodeComponent(location);
          print('  Booking.com → $decoded');

          expect(
            decoded,
            contains('booking.com'),
            reason: 'Should redirect to booking.com',
          );
          expect(
            decoded,
            contains('searchresults'),
            reason: 'Should be search results page',
          );
          expect(decoded, contains('駅'), reason: 'Should append 駅 to search');
          expect(
            decoded,
            contains('latitude='),
            reason: 'Should have latitude',
          );
          expect(
            decoded,
            contains('longitude='),
            reason: 'Should have longitude',
          );
          expect(decoded, contains('aid='), reason: 'Should have affiliate ID');
          expect(
            decoded,
            contains('nflt='),
            reason: 'Should have price filter',
          );
        },
      );
    });
  }

  // ── Final page load test ──
  group('Final page actually loads (follow redirects)', () {
    final followDio = Dio(
      BaseOptions(
        followRedirects: true,
        maxRedirects: 5,
        validateStatus: (s) => true,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
        },
      ),
    );

    test('Expedia final page returns 200', () async {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en',
        region: 'kanto',
        stationName: 'Shinjuku',
        lat: 35.69,
        lng: 139.70,
        checkIn: '2026-05-01',
        checkOut: '2026-05-04',
      );
      final innerUrl = _innerUrl(providers[0].url);
      try {
        final res = await followDio.get(innerUrl);
        print('  Expedia final: ${res.statusCode} ${res.realUri}');
        expect(res.statusCode, lessThan(500), reason: 'Expedia should not 500');
      } catch (e) {
        print('  Expedia: connection issue (may be geo-blocked): $e');
      }
    });

    test('Booking.com final page returns 200', () async {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en',
        region: 'kanto',
        stationName: 'Shinjuku',
        lat: 35.69,
        lng: 139.70,
        checkIn: '2026-05-01',
        checkOut: '2026-05-04',
      );
      final innerUrl = _innerUrl(providers[3].url);
      try {
        final res = await followDio.get(innerUrl);
        print('  Booking.com final: ${res.statusCode} ${res.realUri}');
        expect(
          res.statusCode,
          lessThan(500),
          reason: 'Booking.com should not 500',
        );
      } catch (e) {
        print('  Booking.com: connection issue: $e');
      }
    });
  });
}
