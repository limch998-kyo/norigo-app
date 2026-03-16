import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/services/api_client.dart';
import 'package:norigo_app/models/station.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/models/meetup_result.dart';
import 'package:norigo_app/models/stay_area.dart';

/// Integration tests for all norigo.app API endpoints
/// Run with: flutter test test/api_integration_test.dart
void main() {
  late ApiClient api;

  setUp(() {
    api = ApiClient();
  });

  group('Station Search API', () {
    test('search Japanese station name returns results', () async {
      final results = await api.searchStations('渋谷');
      expect(results, isNotEmpty, reason: '渋谷 should return stations');
      expect(results.first.id, isNotEmpty);
      expect(results.first.name, contains('渋谷'));
      print('✓ Station search "渋谷": ${results.length} results, first=${results.first.name} (${results.first.id})');
    });

    test('search English station name returns results', () async {
      final results = await api.searchStations('shibuya');
      expect(results, isNotEmpty, reason: 'shibuya should return stations');
      print('✓ Station search "shibuya": ${results.length} results');
    });

    test('station has lines info', () async {
      final results = await api.searchStations('新宿');
      expect(results, isNotEmpty);
      final shinjuku = results.first;
      expect(shinjuku.lines, isNotEmpty, reason: 'Shinjuku should have lines');
      print('✓ Station lines: ${shinjuku.name} -> ${shinjuku.lines.take(3).join(", ")}');
    });

    test('search with region filter', () async {
      final results = await api.searchStations('梅田', region: 'kansai');
      expect(results, isNotEmpty, reason: '梅田 in kansai should return results');
      print('✓ Kansai station search "梅田": ${results.length} results');
    });

    test('empty query returns empty', () async {
      final results = await api.searchStations('xyznonexistent');
      expect(results, isEmpty);
      print('✓ Non-existent station returns empty');
    });
  });

  group('Landmark Search API', () {
    test('search landmark returns results', () async {
      final results = await api.searchLandmarks('渋谷', locale: 'ja');
      expect(results, isNotEmpty, reason: '渋谷 landmark should return results');
      expect(results.first.name, isNotEmpty);
      expect(results.first.lat, isNot(0));
      expect(results.first.lng, isNot(0));
      print('✓ Landmark search "渋谷": ${results.length} results, first=${results.first.name} (${results.first.lat}, ${results.first.lng})');
    });

    test('search English landmark', () async {
      final results = await api.searchLandmarks('Tokyo Tower', locale: 'en');
      expect(results, isNotEmpty, reason: 'Tokyo Tower should return results');
      print('✓ Landmark search "Tokyo Tower": ${results.length} results');
    });

    test('search Korean landmark', () async {
      final results = await api.searchLandmarks('명동', locale: 'ko', region: 'seoul');
      // May or may not return results depending on API
      print('✓ Landmark search "명동": ${results.length} results');
    });
  });

  group('Meetup Recommend API', () {
    late String shibuyaId;
    late String shinjukuId;

    setUp(() async {
      // Get valid station IDs
      final shibuya = await api.searchStations('渋谷');
      final shinjuku = await api.searchStations('新宿');
      shibuyaId = shibuya.first.id;
      shinjukuId = shinjuku.first.id;
    });

    test('recommend with 2 stations returns results', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId],
        mode: 'centroid',
        region: 'kanto',
      );
      expect(result.stations, isNotEmpty, reason: 'Should return recommended stations');
      expect(result.stations.length, greaterThanOrEqualTo(1));

      final first = result.stations.first;
      expect(first.station.name, isNotEmpty);
      expect(first.avgEstimatedMinutes, greaterThan(0));
      expect(first.finalScore, greaterThan(0));
      expect(first.distances, isNotEmpty);
      print('✓ Meetup recommend: ${result.stations.length} results, best=${first.station.name} (${first.avgEstimatedMinutes}min, score=${first.finalScore.toStringAsFixed(1)})');
    });

    test('recommend with minTotal mode', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId],
        mode: 'minTotal',
        region: 'kanto',
      );
      expect(result.stations, isNotEmpty);
      print('✓ Meetup minTotal: ${result.stations.length} results, best=${result.stations.first.station.name}');
    });

    test('recommend with balanced mode', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId],
        mode: 'balanced',
        region: 'kanto',
      );
      expect(result.stations, isNotEmpty);
      print('✓ Meetup balanced: ${result.stations.length} results');
    });

    test('recommend with category filter', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId],
        mode: 'centroid',
        region: 'kanto',
        category: 'izakaya',
      );
      expect(result.stations, isNotEmpty);
      print('✓ Meetup with izakaya filter: ${result.stations.length} results');
    });

    test('distances match participant count', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId],
        mode: 'centroid',
        region: 'kanto',
      );
      for (final station in result.stations) {
        expect(station.distances.length, equals(2),
            reason: '${station.station.name} should have 2 distances for 2 participants');
      }
      print('✓ Distance count matches participant count');
    });
  });

  group('Stay Recommend API', () {
    test('recommend with 2 landmarks returns areas', () async {
      final result = await api.getStayRecommendation(
        landmarks: [
          const Landmark(slug: 'shibuya', name: '渋谷', lat: 35.6595, lng: 139.7004, region: 'kanto'),
          const Landmark(slug: 'asakusa', name: '浅草寺', lat: 35.7148, lng: 139.7967, region: 'kanto'),
        ],
        region: 'kanto',
        mode: 'centroid',
      );
      expect(result.areas, isNotEmpty, reason: 'Should return hotel areas');

      final first = result.areas.first;
      expect(first.station.name, isNotEmpty);
      expect(first.avgEstimatedMinutes, greaterThanOrEqualTo(0));
      expect(first.finalScore, greaterThan(0));
      print('✓ Stay recommend: ${result.areas.length} areas, best=${first.station.name} (${first.avgEstimatedMinutes}min, score=${first.finalScore.toStringAsFixed(1)})');
    });

    test('recommend with 3 landmarks', () async {
      final result = await api.getStayRecommendation(
        landmarks: [
          const Landmark(slug: 'shibuya', name: '渋谷', lat: 35.6595, lng: 139.7004, region: 'kanto'),
          const Landmark(slug: 'asakusa', name: '浅草寺', lat: 35.7148, lng: 139.7967, region: 'kanto'),
          const Landmark(slug: 'tokyo-tower', name: '東京タワー', lat: 35.6586, lng: 139.7454, region: 'kanto'),
        ],
        region: 'kanto',
        mode: 'centroid',
      );
      expect(result.areas, isNotEmpty);
      print('✓ Stay 3 landmarks: ${result.areas.length} areas');
    });

    test('recommend Kansai region', () async {
      final result = await api.getStayRecommendation(
        landmarks: [
          const Landmark(slug: 'dotonbori', name: '道頓堀', lat: 34.6687, lng: 135.5013, region: 'kansai'),
          const Landmark(slug: 'kiyomizu', name: '清水寺', lat: 34.9949, lng: 135.7850, region: 'kansai'),
        ],
        region: 'kansai',
        mode: 'centroid',
      );
      expect(result.areas, isNotEmpty);
      print('✓ Stay Kansai: ${result.areas.length} areas, best=${result.areas.first.station.name}');
    });

    test('recommend Seoul region', () async {
      final result = await api.getStayRecommendation(
        landmarks: [
          const Landmark(slug: 'myeongdong', name: '明洞', lat: 37.5636, lng: 126.9869, region: 'seoul'),
          const Landmark(slug: 'gangnam', name: '江南', lat: 37.4979, lng: 127.0276, region: 'seoul'),
        ],
        region: 'seoul',
        mode: 'centroid',
      );
      expect(result.areas, isNotEmpty);
      print('✓ Stay Seoul: ${result.areas.length} areas, best=${result.areas.first.station.name}');
    });

    test('landmark distances present in results', () async {
      final result = await api.getStayRecommendation(
        landmarks: [
          const Landmark(slug: 'shibuya', name: '渋谷', lat: 35.6595, lng: 139.7004, region: 'kanto'),
          const Landmark(slug: 'asakusa', name: '浅草寺', lat: 35.7148, lng: 139.7967, region: 'kanto'),
        ],
        region: 'kanto',
        mode: 'centroid',
      );
      final first = result.areas.first;
      expect(first.landmarkDistances, isNotEmpty,
          reason: 'Should have landmark distances');
      print('✓ Landmark distances: ${first.landmarkDistances.map((d) => "${d.landmarkName}=${d.estimatedMinutes}min").join(", ")}');
    });
  });

  group('Event Log API', () {
    test('log event does not throw', () async {
      // Fire-and-forget, should not throw
      await api.logEvent(
        eventType: 'test',
        sessionId: 'test-session',
        userId: 'test-user',
        payload: {'platform': 'flutter_test'},
      );
      print('✓ Event log: no error');
    });
  });
}
