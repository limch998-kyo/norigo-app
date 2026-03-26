import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:norigo_app/config/constants.dart';
import 'package:norigo_app/config/booking_provider.dart';
import 'package:norigo_app/providers/trip_provider.dart';
import 'package:norigo_app/models/landmark.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('Kyushu region configuration', () {
    test('kyushu is in japanRegions', () {
      expect(AppConstants.japanRegions, contains('kyushu'));
    });

    test('kyushu is in allRegions', () {
      expect(AppConstants.allRegions, contains('kyushu'));
    });

    test('kyushu is NOT in koreaRegions', () {
      expect(AppConstants.koreaRegions, isNot(contains('kyushu')));
    });

    test('getStayBudgets works for kyushu (uses JP tiers)', () {
      final budgets = AppConstants.getStayBudgets('kyushu');
      expect(budgets, equals(AppConstants.stayBudgetsJp));
    });
  });

  group('Kyushu booking provider', () {
    test('kyushu + ja → Jalan provider', () {
      expect(BookingProvider.providerName('ja', 'kyushu'), 'jalan.net');
    });

    test('kyushu + en → Expedia (3 provider buttons)', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kyushu', stationName: 'Hakata',
        lat: 33.59, lng: 130.42,
      );
      expect(providers.length, 3);
      expect(providers[0].name, 'Expedia');
    });

    test('kyushu + ko → empty (uses Agoda)', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'ko', region: 'kyushu', stationName: '하카타',
        lat: 33.59, lng: 130.42,
      );
      expect(providers, isEmpty);
    });
  });

  group('Kyushu trip creation', () {
    late ProviderContainer container;
    late TripNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      notifier = container.read(tripProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('createTrip with region=kyushu stores region', () {
      final id = notifier.createTrip('Fukuoka / Kyushu', country: 'japan', region: 'kyushu');
      final trip = container.read(tripProvider).trips.firstWhere((t) => t.id == id);
      expect(trip.region, 'kyushu');
      expect(trip.country, 'japan');
    });

    test('regionCountry for kyushu is japan', () {
      expect(TripNotifier.regionCountry('kyushu'), 'japan');
    });

    test('tripNameForRegion kyushu in all locales', () {
      expect(TripNotifier.tripNameForRegion('kyushu', 'ja'), '福岡・九州');
      expect(TripNotifier.tripNameForRegion('kyushu', 'ko'), '후쿠오카·큐슈');
      expect(TripNotifier.tripNameForRegion('kyushu', 'en'), 'Fukuoka / Kyushu');
      expect(TripNotifier.tripNameForRegion('kyushu', 'fr'), 'Fukuoka / Kyushu');
    });

    test('addItem to kyushu trip works', () {
      final id = notifier.createTrip('Kyushu', country: 'japan', region: 'kyushu');
      notifier.addItem(
        Landmark(slug: 'tenjin', name: 'Tenjin', lat: 33.59, lng: 130.40, region: 'kyushu'),
        tripId: id, locale: 'en',
      );
      final items = container.read(tripProvider).items.where((i) => i.tripId == id);
      expect(items.length, 1);
      expect(items.first.region, 'kyushu');
    });
  });

  group('Kyushu API', () {
    late Dio dio;
    setUp(() {
      dio = Dio(BaseOptions(
        baseUrl: 'https://norigo.app',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
    });

    test('stay/recommend works for kyushu', () async {
      final res = await dio.post('/api/stay/recommend', data: {
        'landmarks': [
          {'name': '天神', 'lat': 33.5903, 'lng': 130.399},
          {'name': '博多駅', 'lat': 33.5898, 'lng': 130.4207},
        ],
        'region': 'kyushu',
        'mode': 'centroid',
        'locale': 'ja',
      });
      expect(res.statusCode, 200);
      final results = res.data['results'] as List?;
      expect(results, isNotNull);
      expect(results, isNotEmpty);
      print('✓ Kyushu stay recommend: ${results!.length} areas, top=${results.first['station']['name']}');
    });

    test('landmark search works for kyushu', () async {
      final res = await dio.get('/api/search/landmark', queryParameters: {
        'q': 'tenjin', 'region': 'kyushu', 'locale': 'en',
      });
      expect(res.statusCode, 200);
      expect(res.data['landmarks'], isNotEmpty);
      print('✓ Kyushu landmark search: ${res.data['landmarks'].length} results');
    });
  });

  group('Kyushu data files', () {
    test('landmarks-kyushu.json exists and has entries', () {
      final file = File('assets/data/landmarks-kyushu.json');
      expect(file.existsSync(), true, reason: 'landmarks-kyushu.json should exist');
      final content = file.readAsStringSync();
      expect(content.length, greaterThan(100));
    });

    test('featured-guides.json has kyushu guides', () {
      final file = File('assets/data/featured-guides.json');
      final content = file.readAsStringSync();
      expect(content.contains('"kyushu"'), true, reason: 'Should have kyushu guides');
    });
  });

  group('Kyushu popular spots completeness', () {
    const kyushuSpots = [
      {'slug': 'tenjin', 'nameKo': '텐진'},
      {'slug': 'canal-city-hakata', 'nameKo': '캐널시티 하카타'},
      {'slug': 'dazaifu-tenmangu', 'nameKo': '다자이후 텐만구'},
      {'slug': 'nakasu', 'nameKo': '나카스'},
      {'slug': 'hakata-yatai', 'nameKo': '하카타 야타이'},
    ];

    test('All kyushu spots have Korean names', () {
      for (final s in kyushuSpots) {
        expect((s['nameKo'] as String).isNotEmpty, true, reason: '${s['slug']} missing Korean name');
        // Korean names should not be ASCII-only
        final isAllAscii = RegExp(r'^[\x00-\x7F]+$').hasMatch(s['nameKo']!);
        expect(isAllAscii, false, reason: '${s['slug']} Korean name "${s['nameKo']}" looks English');
      }
    });
  });

  group('Kyushu parity with other regions', () {
    test('All regions have region images', () {
      // These are hardcoded in trip_screen.dart and home_screen.dart
      const regionImages = {
        'kanto': 'shibuya-crossing',
        'kansai': 'dotonbori',
        'kyushu': 'canal-city-hakata',
        'seoul': 'myeongdong',
        'busan': 'haeundae',
      };
      for (final region in AppConstants.allRegions) {
        expect(regionImages.containsKey(region), true, reason: '$region missing region image');
      }
    });

    test('All regions have tripNameForRegion in all locales', () {
      for (final region in AppConstants.allRegions) {
        for (final locale in ['ja', 'ko', 'en', 'fr']) {
          final name = TripNotifier.tripNameForRegion(region, locale);
          expect(name, isNot(equals(region)), reason: '$region/$locale has no translated name');
        }
      }
    });
  });
}
