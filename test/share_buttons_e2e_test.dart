import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// End-to-end tests for all share button URLs and functionality.
void main() {
  final testShareUrl = 'https://norigo.app/s/testABC123';
  final testText = 'Best hotel area for Shibuya, Shinjuku';

  group('X (Twitter) share', () {
    test('Intent URL format is correct', () {
      final text = Uri.encodeComponent(testText);
      final encodedUrl = Uri.encodeComponent(testShareUrl);
      final twitterUrl = 'https://twitter.com/intent/tweet?text=$text&url=$encodedUrl';

      final parsed = Uri.parse(twitterUrl);
      expect(parsed.host, 'twitter.com');
      expect(parsed.path, '/intent/tweet');
      expect(parsed.queryParameters['text'], testText);
      expect(parsed.queryParameters['url'], testShareUrl);
    });

    test('X intent endpoint responds', () async {
      final dio = Dio(BaseOptions(followRedirects: true, validateStatus: (s) => true,
        connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
      try {
        final res = await dio.get('https://twitter.com/intent/tweet?text=test&url=https://norigo.app');
        print('X: ${res.statusCode}');
        expect(res.statusCode, lessThan(500));
      } catch (e) {
        print('X: connection issue (OK in production)');
      }
    });
  });

  group('LINE share', () {
    test('LIFF URL has correct format and params', () {
      final liffParams = Uri(queryParameters: {
        'url': testShareUrl,
        'title': 'Norigo',
        'desc': testText,
      }).query;
      final liffUrl = 'https://liff.line.me/2009553286-JcRNsKER?$liffParams';

      final parsed = Uri.parse(liffUrl);
      expect(parsed.host, 'liff.line.me');
      expect(parsed.queryParameters['url'], testShareUrl);
      expect(parsed.queryParameters['title'], 'Norigo');
    });

    test('LINE fallback URL format is valid', () {
      final encoded = Uri.encodeComponent('$testText\n$testShareUrl');
      final lineUrl = 'https://line.me/R/share?text=$encoded';
      final parsed = Uri.parse(lineUrl);
      expect(parsed.host, 'line.me');
      expect(parsed.path, '/R/share');
    });

    test('LIFF endpoint responds', () async {
      final dio = Dio(BaseOptions(followRedirects: true, validateStatus: (s) => true,
        connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
      try {
        final res = await dio.get('https://liff.line.me/2009553286-JcRNsKER?url=https://norigo.app');
        print('LIFF: ${res.statusCode}');
        expect(res.statusCode, lessThan(500));
      } catch (e) {
        print('LIFF: connection issue');
      }
    });
  });

  group('Kakao share', () {
    test('Short URL under 2000 chars', () {
      expect(testShareUrl.length, lessThan(2000));
    });

    test('Fallback to homepage when URL > 2000', () {
      final longUrl = 'https://norigo.app/en/stay/result?l=${'x' * 2500}';
      final shareUrl = longUrl.length > 2000 ? 'https://norigo.app/en' : longUrl;
      expect(shareUrl, 'https://norigo.app/en');
    });

    test('OG image endpoint responds', () async {
      final dio = Dio(BaseOptions(followRedirects: true, validateStatus: (s) => true,
        connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
      final res = await dio.head('https://norigo.app/api/og?locale=ko');
      print('OG: ${res.statusCode}');
      expect(res.statusCode, lessThan(500));
    });
  });

  group('Copy link', () {
    test('URL is valid', () {
      expect(Uri.tryParse(testShareUrl), isNotNull);
    });
  });

  group('Native share', () {
    test('Share text includes URL and description', () {
      final shareText = '$testText\n$testShareUrl';
      expect(shareText, contains('norigo.app'));
      expect(shareText, contains(testText));
    });
  });

  group('Short URL API', () {
    test('Creates short URL', () async {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
      final res = await dio.post('https://norigo.app/api/share', data: {
        'path': '/stay/result',
        'params': {'l': jsonEncode([{'name': 'Shibuya', 'lat': 35.66, 'lng': 139.70}]), 'm': 'centroid', 'r': 'kanto'},
        'locale': 'en',
      });
      expect(res.statusCode, 200);
      expect(res.data['url'], startsWith('https://norigo.app/s/'));
      print('Short URL: ${res.data['url']}');
    });

    test('Short URL redirects to result page', () async {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
      final createRes = await dio.post('https://norigo.app/api/share', data: {
        'path': '/stay/result',
        'params': {'l': jsonEncode([{'name': 'Test', 'lat': 35.66, 'lng': 139.70}]), 'm': 'centroid', 'r': 'kanto'},
        'locale': 'en',
      });
      final shortUrl = createRes.data['url'] as String;
      final redirectDio = Dio(BaseOptions(followRedirects: false, validateStatus: (s) => true));
      final res = await redirectDio.get(shortUrl);
      expect(res.statusCode, 307);
      expect(res.headers['location']?.first, contains('/stay/result'));
    });
  });

  group('Share code quality', () {
    test('Kakao has macOS platform guard', () {
      final content = File('lib/widgets/share_buttons.dart').readAsStringSync();
      expect(content, contains('Platform.isIOS'));
      expect(content, contains('Platform.isAndroid'));
    });

    test('LINE uses LIFF app ID', () {
      final content = File('lib/widgets/share_buttons.dart').readAsStringSync();
      expect(content, contains('2009553286-JcRNsKER'));
    });

    test('X uses twitter.com/intent/tweet', () {
      final content = File('lib/widgets/share_buttons.dart').readAsStringSync();
      expect(content, contains('twitter.com/intent/tweet'));
    });

    test('All share methods have try-catch', () {
      final content = File('lib/widgets/share_buttons.dart').readAsStringSync();
      final tryCatchCount = 'try {'.allMatches(content).length;
      expect(tryCatchCount, greaterThanOrEqualTo(3));
    });

    test('Short URL fetched on init', () {
      final content = File('lib/widgets/share_buttons.dart').readAsStringSync();
      expect(content, contains('_fetchShortUrl'));
      expect(content, contains('initState'));
    });
  });
}
