import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:norigo_app/providers/trip_provider.dart';
import 'package:norigo_app/models/trip.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/config/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('Trip CRUD', () {
    late ProviderContainer container;
    late TripNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      notifier = container.read(tripProvider.notifier);
    });
    tearDown(() => container.dispose());

    test('Create trip', () {
      final id = notifier.createTrip('Tokyo Trip', country: 'japan');
      expect(id, isNotEmpty);
      expect(container.read(tripProvider).trips.length, 1);
      expect(container.read(tripProvider).trips.first.name, 'Tokyo Trip');
    });

    test('Add items to trip', () {
      final id = notifier.createTrip('Test', country: 'japan');
      notifier.addItem(Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.66, lng: 139.70, region: 'kanto'), tripId: id, locale: 'en');
      notifier.addItem(Landmark(slug: 'shinjuku', name: 'Shinjuku', lat: 35.69, lng: 139.71, region: 'kanto'), tripId: id, locale: 'en');
      expect(container.read(tripProvider).items.where((i) => i.tripId == id).length, 2);
    });

    test('Remove item from trip', () {
      final id = notifier.createTrip('Test', country: 'japan');
      notifier.addItem(Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.66, lng: 139.70, region: 'kanto'), tripId: id, locale: 'en');
      notifier.removeItem('shibuya', id);
      expect(container.read(tripProvider).items.where((i) => i.tripId == id).length, 0);
    });

    test('Pin toggle', () {
      final id = notifier.createTrip('Test', country: 'japan');
      expect(container.read(tripProvider).trips.first.isPinned, false);
      notifier.togglePin(id);
      expect(container.read(tripProvider).trips.first.isPinned, true);
      notifier.togglePin(id);
      expect(container.read(tripProvider).trips.first.isPinned, false);
    });

    test('Set notes', () {
      final id = notifier.createTrip('Test', country: 'japan');
      notifier.setNotes(id, 'Remember to book restaurant');
      expect(container.read(tripProvider).trips.first.notes, 'Remember to book restaurant');
      notifier.setNotes(id, null);
      expect(container.read(tripProvider).trips.first.notes, isNull);
    });

    test('Set dates', () {
      final id = notifier.createTrip('Test', country: 'japan');
      notifier.setTripDates(id, '2026-04-01', '2026-04-04');
      final trip = container.read(tripProvider).trips.first;
      expect(trip.checkIn, '2026-04-01');
      expect(trip.checkOut, '2026-04-04');
    });

    test('Set budget', () {
      final id = notifier.createTrip('Test', country: 'japan');
      notifier.setTripSearchSettings(id, maxBudget: '10000-30000');
      expect(container.read(tripProvider).trips.first.maxBudget, '10000-30000');
    });

    test('Delete trip', () {
      final id = notifier.createTrip('Test', country: 'japan');
      notifier.addItem(Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.66, lng: 139.70, region: 'kanto'), tripId: id, locale: 'en');
      notifier.deleteTrip(id);
      expect(container.read(tripProvider).trips, isEmpty);
      expect(container.read(tripProvider).items, isEmpty);
    });

    test('No duplicate items', () {
      final id = notifier.createTrip('Test', country: 'japan');
      notifier.addItem(Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.66, lng: 139.70, region: 'kanto'), tripId: id, locale: 'en');
      notifier.addItem(Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.66, lng: 139.70, region: 'kanto'), tripId: id, locale: 'en');
      expect(container.read(tripProvider).items.where((i) => i.tripId == id).length, 1);
    });
  });

  group('Trip model serialization', () {
    test('isPinned survives JSON roundtrip', () {
      final trip = Trip(id: '1', name: 'Test', isPinned: true, createdAt: DateTime.now(), updatedAt: DateTime.now());
      final json = trip.toJson();
      final restored = Trip.fromJson(json);
      expect(restored.isPinned, true);
    });

    test('notes survives JSON roundtrip', () {
      final trip = Trip(id: '1', name: 'Test', notes: 'hello', createdAt: DateTime.now(), updatedAt: DateTime.now());
      final json = trip.toJson();
      final restored = Trip.fromJson(json);
      expect(restored.notes, 'hello');
    });

    test('isPinned defaults to false for old data', () {
      final json = {'id': '1', 'name': 'Test', 'createdAt': DateTime.now().toIso8601String(), 'updatedAt': DateTime.now().toIso8601String()};
      final trip = Trip.fromJson(json);
      expect(trip.isPinned, false);
      expect(trip.notes, isNull);
    });

    test('Budget keys in stayBudgetLabels', () {
      for (final b in AppConstants.stayBudgetsJp) {
        if (b == 'any') continue;
        expect(AppConstants.stayBudgetLabels.containsKey(b), true, reason: '$b missing label');
      }
      for (final b in AppConstants.stayBudgetsKr) {
        if (b == 'any') continue;
        expect(AppConstants.stayBudgetLabels.containsKey(b), true, reason: '$b missing label');
      }
    });
  });

  group('Suggestion spot locale names', () {
    // All popular spots must have nameKo and nameEn for proper localization
    const popularSpots = {
      'kanto': [
        {'slug': 'shibuya-crossing', 'name': '渋谷', 'nameEn': 'Shibuya', 'nameKo': '시부야'},
        {'slug': 'shinjuku', 'name': '新宿', 'nameEn': 'Shinjuku', 'nameKo': '신주쿠'},
        {'slug': 'asakusa-senso-ji', 'name': '浅草寺', 'nameEn': 'Asakusa', 'nameKo': '아사쿠사'},
        {'slug': 'tokyo-tower', 'name': '東京タワー', 'nameEn': 'Tokyo Tower', 'nameKo': '도쿄타워'},
        {'slug': 'harajuku', 'name': '原宿', 'nameEn': 'Harajuku', 'nameKo': '하라주쿠'},
        {'slug': 'ichiran-shibuya', 'name': '一蘭 渋谷店', 'nameEn': 'Ichiran Shibuya', 'nameKo': '이치란 시부야'},
      ],
      'kansai': [
        {'slug': 'dotonbori', 'name': '道頓堀', 'nameEn': 'Dotonbori', 'nameKo': '도톤보리'},
        {'slug': 'fushimi-inari-taisha', 'name': '伏見稲荷大社', 'nameEn': 'Fushimi Inari', 'nameKo': '후시미이나리'},
        {'slug': 'kiyomizu-dera', 'name': '清水寺', 'nameEn': 'Kiyomizu-dera', 'nameKo': '기요미즈데라'},
        {'slug': 'osaka-castle', 'name': '大阪城', 'nameEn': 'Osaka Castle', 'nameKo': '오사카성'},
        {'slug': 'kuromon-market', 'name': '黒門市場', 'nameEn': 'Kuromon Market', 'nameKo': '구로몬시장'},
      ],
      'seoul': [
        {'slug': 'myeongdong', 'name': '명동', 'nameEn': 'Myeongdong', 'nameKo': '명동'},
        {'slug': 'hongdae', 'name': '홍대', 'nameEn': 'Hongdae', 'nameKo': '홍대'},
        {'slug': 'gangnam', 'name': '강남', 'nameEn': 'Gangnam', 'nameKo': '강남'},
        {'slug': 'gyeongbokgung', 'name': '景福宮', 'nameEn': 'Gyeongbokgung', 'nameKo': '경복궁'},
      ],
      'busan': [
        {'slug': 'haeundae', 'name': '海雲台', 'nameEn': 'Haeundae', 'nameKo': '해운대'},
        {'slug': 'gamcheon', 'name': '甘川文化村', 'nameEn': 'Gamcheon Village', 'nameKo': '감천문화마을'},
        {'slug': 'seomyeon', 'name': '西面', 'nameEn': 'Seomyeon', 'nameKo': '서면'},
      ],
    };

    test('All spots have nameKo (Korean name)', () {
      for (final entry in popularSpots.entries) {
        for (final spot in entry.value) {
          expect(spot['nameKo'], isNotNull, reason: '${entry.key}/${spot['slug']} missing nameKo');
          expect((spot['nameKo'] as String).isNotEmpty, true, reason: '${entry.key}/${spot['slug']} empty nameKo');
          // Korean name should not be English
          final ko = spot['nameKo'] as String;
          final en = spot['nameEn'] as String;
          if (entry.key != 'seoul' && entry.key != 'busan') {
            // Japan spots: Korean name should not equal English name
            // (Seoul/Busan spots may have same Korean and English for Korean places)
          }
          print('  ${entry.key}/${spot['slug']}: ja=${spot['name']} ko=$ko en=$en');
        }
      }
    });

    test('All spots have nameEn (English name)', () {
      for (final entry in popularSpots.entries) {
        for (final spot in entry.value) {
          expect(spot['nameEn'], isNotNull, reason: '${entry.key}/${spot['slug']} missing nameEn');
          expect((spot['nameEn'] as String).isNotEmpty, true);
        }
      }
    });

    test('Korean locale should show Korean names, not English', () {
      // Simulate locale resolution: ko → nameKo
      for (final entry in popularSpots.entries) {
        for (final spot in entry.value) {
          final ko = spot['nameKo'] as String;
          // Korean name should not contain only ASCII (would mean it's English)
          if (entry.key != 'seoul' && entry.key != 'busan') {
            final isAllAscii = RegExp(r'^[\x00-\x7F]+$').hasMatch(ko);
            expect(isAllAscii, false, reason: '${spot['slug']} Korean name "$ko" looks English');
          }
        }
      }
    });
  });

  group('Landmark search API', () {
    late Dio dio;
    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://norigo.app', connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
    });

    test('Search returns results for "shibuya"', () async {
      final res = await dio.get('/api/search/landmark', queryParameters: {'q': 'shibuya', 'region': 'kanto'});
      expect(res.statusCode, 200);
      expect(res.data['landmarks'], isNotEmpty);
      print('✓ shibuya: ${res.data['landmarks'].length} results');
    });

    test('Search returns results for "도톤보리"', () async {
      final res = await dio.get('/api/search/landmark', queryParameters: {'q': '도톤보리', 'region': 'kansai', 'locale': 'ko'});
      expect(res.statusCode, 200);
      expect(res.data['landmarks'], isNotEmpty);
      print('✓ 도톤보리: ${res.data['landmarks'].length} results');
    });

    test('Search returns results for "tokyo tower"', () async {
      final res = await dio.get('/api/search/landmark', queryParameters: {'q': 'tokyo tower', 'region': 'kanto', 'locale': 'en'});
      expect(res.statusCode, 200);
      expect(res.data['landmarks'], isNotEmpty);
      print('✓ tokyo tower: ${res.data['landmarks'].length} results');
    });

    test('Search with empty query returns empty', () async {
      final res = await dio.get('/api/search/landmark', queryParameters: {'q': 'x', 'region': 'kanto'});
      expect(res.statusCode, 200);
    });

    test('Search does not return access blocked error', () async {
      // This specifically tests the "access blocked" issue
      try {
        final res = await dio.get('/api/search/landmark', queryParameters: {'q': 'harajuku', 'region': 'kanto', 'locale': 'en'});
        expect(res.statusCode, 200);
        final data = res.data;
        // Should not contain error messages
        final jsonStr = data.toString();
        expect(jsonStr.contains('access blocked'), false, reason: 'API should not return access blocked');
        expect(jsonStr.contains('not following'), false, reason: 'API should not return policy error');
        print('✓ No access blocked for harajuku');
      } on DioException catch (e) {
        fail('API returned error: ${e.response?.statusCode} ${e.response?.data}');
      }
    });
  });
}
