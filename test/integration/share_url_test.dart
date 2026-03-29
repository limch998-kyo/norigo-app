import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// End-to-end tests for share URL shortening system.
void main() {
  group('Share URL API (/api/share)', () {
    late Dio dio;

    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'https://norigo.app',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
    });

    test('Stay result → short URL created', () async {
      final response = await dio.post('/api/share', data: {
        'path': '/stay/result',
        'params': {
          'l': '[{"slug":"shibuya","lat":35.6595,"lng":139.7004},{"slug":"shinjuku","lat":35.6852,"lng":139.71}]',
          'm': 'centroid',
          'r': 'kanto',
          'b': '10000-30000',
          'ci': '2026-04-25',
          'co': '2026-04-28',
        },
        'locale': 'ko',
      });

      expect(response.statusCode, 200);
      expect(response.data, isA<Map>());
      expect(response.data['url'], isNotNull);
      expect(response.data['url'], startsWith('https://norigo.app/s/'));

      final shortUrl = response.data['url'] as String;
      print('✓ Stay short URL: $shortUrl (${shortUrl.length} chars)');
      expect(shortUrl.length, lessThan(50)); // ~29 chars
    });

    test('Meetup result → short URL created', () async {
      final response = await dio.post('/api/share', data: {
        'path': '/result',
        'params': {
          'p': 'shinjuku,shibuya,ikebukuro',
          'm': 'centroid',
          'r': 'kanto',
        },
        'locale': 'en',
      });

      expect(response.statusCode, 200);
      expect(response.data['url'], startsWith('https://norigo.app/s/'));

      final shortUrl = response.data['url'] as String;
      print('✓ Meetup short URL: $shortUrl (${shortUrl.length} chars)');
    });

    test('Short URL is under Kakao 10KB limit', () async {
      // Even with max landmarks (10), short URL should be tiny
      final response = await dio.post('/api/share', data: {
        'path': '/stay/result',
        'params': {
          'l': '[{"slug":"a"},{"slug":"b"},{"slug":"c"},{"slug":"d"},{"slug":"e"},{"slug":"f"},{"slug":"g"},{"slug":"h"},{"slug":"i"},{"slug":"j"}]',
          'm': 'minTotal',
          'r': 'kansai',
          'b': 'over50000',
          'ci': '2026-05-01',
          'co': '2026-05-05',
        },
        'locale': 'ja',
      });

      expect(response.statusCode, 200);
      final shortUrl = response.data['url'] as String;
      expect(shortUrl.length, lessThan(100));
      print('✓ Max landmarks short URL: $shortUrl (${shortUrl.length} chars)');
    });

    test('Short URL redirect resolves (GET /s/{id})', () async {
      // First create a short URL
      final createRes = await dio.post('/api/share', data: {
        'path': '/stay/result',
        'params': {
          'l': '[{"slug":"shibuya"}]',
          'm': 'centroid',
          'r': 'kanto',
        },
        'locale': 'en',
      });
      final shortUrl = createRes.data['url'] as String;

      // Then verify it redirects (follow=false to check redirect)
      try {
        final getRes = await Dio(BaseOptions(
          followRedirects: false,
          validateStatus: (s) => s != null && s < 400,
        )).get(shortUrl);
        // Should be 307/302 redirect or 200 with page
        print('✓ Redirect status: ${getRes.statusCode}');
      } on DioException catch (e) {
        // 307 redirect throws DioException with redirect response
        if (e.response?.statusCode == 307 || e.response?.statusCode == 302) {
          final location = e.response?.headers['location']?.first;
          print('✓ Redirects to: $location');
          expect(location, contains('/stay/result'));
        } else {
          rethrow;
        }
      }
    });
  });
}
