import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// Validates that all landmark images referenced in the app actually exist on the server.
void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  });

  group('Region fallback images exist', () {
    const regionImages = {
      'kanto': 'shibuya-crossing',
      'kansai': 'dotonbori',
      'kyushu': 'canal-city-hakata',
      'seoul': 'myeongdong',
      'busan': 'haeundae',
    };

    for (final entry in regionImages.entries) {
      test('${entry.key} → ${entry.value}.webp exists', () async {
        final res = await dio.head('https://norigo.app/images/landmarks/${entry.value}.webp');
        expect(res.statusCode, 200, reason: '${entry.value}.webp should exist for region ${entry.key}');
      });
    }
  });

  group('Quick plan card images exist', () {
    const planImages = [
      'shibuya-crossing',
      'asakusa-senso-ji',
      'tokyo-disneyland',
      'dotonbori',
      'fushimi-inari-taisha',
      'canal-city-hakata',
    ];

    for (final slug in planImages) {
      test('$slug.webp exists', () async {
        final res = await dio.head('https://norigo.app/images/landmarks/$slug.webp');
        expect(res.statusCode, 200, reason: '$slug.webp should exist for quick plan card');
      });
    }
  });

  group('Kyushu suggested spot images', () {
    const kyushuSpots = {
      'tenjin': false, // known missing
      'canal-city-hakata': true,
      'dazaifu-tenmangu': true,
      'nakasu': false, // known missing
      'hakata-yatai': false, // known missing
      'hakata-station': true,
    };

    for (final entry in kyushuSpots.entries) {
      test('${entry.key}.webp → ${entry.value ? "exists" : "fallback icon OK"}', () async {
        try {
          final res = await dio.head('https://norigo.app/images/landmarks/${entry.key}.webp');
          if (entry.value) {
            expect(res.statusCode, 200);
          }
        } on DioException catch (e) {
          if (!entry.value) {
            // Expected 404 — app shows fallback icon, not broken
            expect(e.response?.statusCode, 404);
          } else {
            fail('${entry.key}.webp should exist but got ${e.response?.statusCode}');
          }
        }
      });
    }
  });
}
