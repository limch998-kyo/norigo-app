import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:norigo_app/providers/stay_provider.dart';
import 'package:norigo_app/providers/meetup_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('JSON injection prevention', () {
    test('Landmark name with quotes does not break JSON', () {
      // Simulate names that could break string interpolation
      final names = [
        'Shinjuku',
        'McDonald\'s Shibuya',
        'Café "Latte"',
        '渋谷・原宿',
        'Station (East)',
        'O\'Hare',
      ];

      for (final name in names) {
        final landmarks = [{'name': name, 'lat': 35.66, 'lng': 139.70}];
        final encoded = jsonEncode(landmarks);
        // Must be valid JSON
        final decoded = jsonDecode(encoded) as List;
        expect(decoded.first['name'], name, reason: 'Name "$name" should survive JSON roundtrip');
      }
    });

    test('jsonEncode produces valid JSON for share params', () {
      final landmarks = [
        {'name': 'Tokyo Tower', 'lat': 35.6586, 'lng': 139.7454},
        {'name': 'Shinjuku "Station"', 'lat': 35.6852, 'lng': 139.71},
      ];
      final json = jsonEncode(landmarks);
      expect(() => jsonDecode(json), returnsNormally);
      final parsed = jsonDecode(json) as List;
      expect(parsed.length, 2);
      expect(parsed[1]['name'], 'Shinjuku "Station"');
    });

    test('Share URL with special characters is valid', () {
      final landmarks = [
        {'name': 'Café L\'amour', 'lat': 35.66, 'lng': 139.70},
      ];
      final json = jsonEncode(landmarks);
      final params = {'l': json, 'm': 'centroid', 'r': 'kanto'};
      final url = Uri.parse('https://norigo.app/en/stay/result').replace(queryParameters: params);
      // URL should be parseable
      expect(url.toString(), contains('norigo.app'));
      // Params should decode back correctly
      final decoded = jsonDecode(url.queryParameters['l']!) as List;
      expect(decoded.first['name'], 'Café L\'amour');
    });
  });

  group('CachedImage widget exists', () {
    test('cached_image.dart file exists with CachedImage class', () {
      final file = File('lib/widgets/cached_image.dart');
      expect(file.existsSync(), true);
      final content = file.readAsStringSync();
      expect(content, contains('class CachedImage'));
      expect(content, contains('CachedNetworkImage'));
      expect(content, contains('placeholder'));
      expect(content, contains('errorWidget'));
    });

    test('cached_network_image is in pubspec dependencies', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('cached_network_image'));
    });
  });

  group('Error messages are localized', () {
    test('Stay provider uses error keys, not toString()', () {
      final content = File('lib/providers/stay_provider.dart').readAsStringSync();
      // Should NOT have raw e.toString() for user-facing errors
      expect(content, isNot(contains("error: e.toString()")));
      // Should use error keys
      expect(content, contains("'network_error'"));
      expect(content, contains("'search_error'"));
    });

    test('Meetup provider uses error keys, not toString()', () {
      final content = File('lib/providers/meetup_provider.dart').readAsStringSync();
      expect(content, isNot(contains("error: e.toString()")));
      expect(content, contains("'network_error'"));
      expect(content, contains("'search_error'"));
    });

    test('Stay result screen translates error keys', () {
      final content = File('lib/screens/stay/stay_result_screen.dart').readAsStringSync();
      expect(content, contains("network_error"));
      expect(content, contains("ネットワークエラー"));
      expect(content, contains("네트워크 오류"));
      expect(content, contains("Network error"));
    });

    test('Meetup result screen translates error keys', () {
      final content = File('lib/screens/meetup/meetup_result_screen.dart').readAsStringSync();
      expect(content, contains("network_error"));
      expect(content, contains("ネットワークエラー"));
      expect(content, contains("네트워크 오류"));
    });
  });

  group('No hardcoded English strings in error states', () {
    final screens = [
      'lib/screens/guide/native_guide_detail_screen.dart',
      'lib/screens/vote/vote_screen.dart',
      'lib/screens/trip/trip_detail_screen.dart',
    ];

    for (final path in screens) {
      test('$path: no hardcoded "not found" strings', () {
        final content = File(path).readAsStringSync();
        // Should not have bare English strings for error states
        final bareNotFound = RegExp(r"Text\('[A-Z][a-z]+ not found'\)");
        expect(bareNotFound.hasMatch(content), false,
            reason: '$path has hardcoded English "not found" string');
      });
    }

    test('All "not found" messages use tr()', () {
      for (final path in screens) {
        final content = File(path).readAsStringSync();
        if (content.contains('not found')) {
          // If "not found" exists, it should be inside a tr() call
          expect(content, contains("tr(locale"),
              reason: '$path has "not found" but no tr() call nearby');
        }
      }
    });
  });

  group('Image caching applied to key screens', () {
    test('Stay result uses CachedImage for hotels', () {
      final content = File('lib/screens/stay/stay_result_screen.dart').readAsStringSync();
      expect(content, contains('CachedImage('));
      expect(content, contains("import '../../widgets/cached_image.dart'"));
    });

    test('Guide screen uses CachedImage for cards', () {
      final content = File('lib/screens/guide/guide_screen.dart').readAsStringSync();
      expect(content, contains('CachedImage('));
      expect(content, contains("import '../../widgets/cached_image.dart'"));
    });
  });

  group('Error detection logic', () {
    test('SocketException detected as network_error', () {
      final errorStr = 'DioException: SocketException: Connection refused';
      final isNetwork = errorStr.contains('SocketException') || errorStr.contains('ConnectionTimeout');
      expect(isNetwork, true);
    });

    test('ConnectionTimeout detected as network_error', () {
      final errorStr = 'DioException: ConnectionTimeout';
      final isNetwork = errorStr.contains('SocketException') || errorStr.contains('ConnectionTimeout');
      expect(isNetwork, true);
    });

    test('Other errors detected as search_error', () {
      final errorStr = 'DioException: 500 Internal Server Error';
      final isNetwork = errorStr.contains('SocketException') || errorStr.contains('ConnectionTimeout');
      expect(isNetwork, false);
    });
  });

  group('API integration — share URL', () {
    test('Share API accepts jsonEncode landmarks', () async {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final landmarks = [
        {'name': 'Shibuya', 'lat': 35.6595, 'lng': 139.7004},
        {'name': 'Shinjuku', 'lat': 35.6852, 'lng': 139.71},
      ];
      final res = await dio.post('https://norigo.app/api/share', data: {
        'path': '/stay/result',
        'params': {
          'l': jsonEncode(landmarks),
          'm': 'centroid',
          'r': 'kanto',
        },
        'locale': 'en',
      });
      expect(res.statusCode, 200);
      expect(res.data['url'], startsWith('https://norigo.app/s/'));
      print('✓ Share URL: ${res.data['url']}');
    });

    test('Share URL with special chars in name works', () async {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final landmarks = [
        {'name': 'McDonald\'s Shibuya', 'lat': 35.66, 'lng': 139.70},
        {'name': 'Café "Tokyo"', 'lat': 35.68, 'lng': 139.71},
      ];
      final res = await dio.post('https://norigo.app/api/share', data: {
        'path': '/stay/result',
        'params': {
          'l': jsonEncode(landmarks),
          'm': 'centroid',
          'r': 'kanto',
        },
        'locale': 'en',
      });
      expect(res.statusCode, 200);
      print('✓ Special chars share URL: ${res.data['url']}');
    });
  });
}
