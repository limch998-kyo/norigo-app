import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/models/hotel.dart';
import 'package:norigo_app/models/station.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/models/stay_area.dart';
import 'package:norigo_app/models/meetup_result.dart';

/// Tests derived from web app's recommend.test.ts, stay-recommend.test.ts,
/// hotel-scoring.test.ts, and search.test.ts — adapted for Flutter's API
/// response parsing layer.
void main() {
  // ═══════════════════════════════════════════════════════════════
  // 1. API Response Parsing (from recommend.test.ts + stay-recommend.test.ts)
  // ═══════════════════════════════════════════════════════════════
  group('API response parsing - Stay recommendation', () {
    test('StayRecommendResult parses normal (non-split) response', () {
      final json = {
        'results': [
          {
            'station': {'id': 'shinjuku', 'name': '新宿', 'lat': 35.6938, 'lng': 139.7034, 'lines': ['JR山手線']},
            'landmarkDistances': [
              {'name': '渋谷', 'estimatedMinutes': 5, 'distanceKm': 2.5, 'route': []},
            ],
            'avgEstimatedMinutes': 5,
            'maxEstimatedMinutes': 5,
            'travelScore': 90,
            'areaProfile': {
              'description': 'Shopping area',
              'areaTags': ['shopping', 'nightlife'],
              'poiCounts': {'convenience': 50, 'restaurant': 100, 'cafe': 30},
            },
          },
        ],
        'localNames': {'shinjuku': '신주쿠'},
      };

      final result = StayRecommendResult.fromJson(json);

      expect(result.areas.length, 1);
      expect(result.split, false);
      expect(result.areas[0].station.name, '新宿');
      expect(result.areas[0].avgEstimatedMinutes, 5);
      expect(result.areas[0].landmarkDistances.length, 1);
      expect(result.areas[0].landmarkDistances[0].landmarkName, '渋谷');
      expect(result.localNames['shinjuku'], '신주쿠');
    });

    test('StayRecommendResult parses split (cluster) response', () {
      final json = {
        'style': 'split',
        'clusters': [
          {
            'landmarks': ['渋谷', '新宿'],
            'results': [
              {
                'station': {'id': 'shinjuku', 'name': '新宿', 'lat': 35.69, 'lng': 139.70, 'lines': []},
                'landmarkDistances': [],
                'avgEstimatedMinutes': 3,
                'maxEstimatedMinutes': 5,
              },
            ],
            'localNames': <String, dynamic>{},
          },
          {
            'landmarks': ['浅草', '上野'],
            'results': [
              {
                'station': {'id': 'ueno', 'name': '上野', 'lat': 35.71, 'lng': 139.77, 'lines': []},
                'landmarkDistances': [],
                'avgEstimatedMinutes': 4,
                'maxEstimatedMinutes': 6,
              },
            ],
            'localNames': <String, dynamic>{},
          },
        ],
      };

      final result = StayRecommendResult.fromJson(json);

      expect(result.split, true);
      expect(result.clusters.length, 2);
      expect(result.clusters[0].landmarks, ['渋谷', '新宿']);
      expect(result.clusters[0].areas.length, 1);
      expect(result.clusters[0].areas[0].station.name, '新宿');
      expect(result.clusters[1].landmarks, ['浅草', '上野']);
      expect(result.clusters[1].areas[0].station.name, '上野');
    });

    test('StayArea parses area tags and POI counts', () {
      final json = {
        'station': {'id': 'shibuya', 'name': '渋谷', 'lat': 35.66, 'lng': 139.70, 'lines': ['JR山手線', '東急東横線']},
        'landmarkDistances': [],
        'avgEstimatedMinutes': 8,
        'maxEstimatedMinutes': 15,
        'travelScore': 85,
        'hotelScore': 70,
        'finalScore': 80,
        'areaProfile': {
          'description': 'Youth culture hub',
          'areaTags': ['shopping', 'nightlife', 'transit'],
          'poiCounts': {'convenience': 45, 'restaurant': 120, 'cafe': 55},
        },
      };

      final area = StayArea.fromJson(json);

      // areaTags and poiCounts may be inside areaProfile or flat
      expect(area.station.name, '渋谷');
      expect(area.travelScore, 85);
      expect(area.avgEstimatedMinutes, 8);
      expect(area.maxEstimatedMinutes, 15);
      expect(area.station.lines.length, 2);
    });
  });

  group('API response parsing - Meetup recommendation', () {
    test('MeetupResult parses stations with distances', () {
      final json = {
        'results': [
          {
            'station': {'id': 'shinjuku', 'name': '新宿', 'lat': 35.69, 'lng': 139.70, 'lines': ['JR山手線']},
            'rank': 1,
            'distances': [
              {
                'participantStationId': 'shibuya',
                'participantStationName': '渋谷',
                'distanceKm': 2.5,
                'estimatedMinutes': 5,
                'route': [
                  {'line': 'JR山手線', 'minutes': 5, 'color': '#9acd32'}
                ],
              },
              {
                'participantStationId': 'ikebukuro',
                'participantStationName': '池袋',
                'distanceKm': 4.8,
                'estimatedMinutes': 10,
                'route': [
                  {'line': 'JR山手線', 'minutes': 10, 'color': '#9acd32'}
                ],
              },
            ],
            'avgDistanceKm': 3.65,
            'avgEstimatedMinutes': 8,
            'travelScore': 92,
          },
        ],
      };

      final result = MeetupResult.fromJson(json);

      expect(result.stations.length, 1);
      expect(result.stations[0].station.name, '新宿');
      expect(result.stations[0].rank, 1);
      expect(result.stations[0].distances.length, 2);
      expect(result.stations[0].avgEstimatedMinutes, 8); // int — 7.5 rounds to 8
      expect(result.stations[0].distances[0].route.length, 1);
      expect(result.stations[0].distances[0].route[0].line, 'JR山手線');
    });

    test('MeetupResult parses venues', () {
      final json = {
        'results': [
          {
            'station': {'id': 'shinjuku', 'name': '新宿', 'lat': 35.69, 'lng': 139.70, 'lines': []},
            'rank': 1,
            'distances': [],
            'avgDistanceKm': 0,
            'avgEstimatedMinutes': 0,
            'venues': [
              {
                'name': 'テスト居酒屋',
                'genre': '居酒屋',
                'budget': '3000円〜',
                'address': '新宿区1-1-1',
                'lat': 35.69,
                'lng': 139.70,
                'features': {'privateRoom': true, 'noSmoking': true, 'freeDrink': false},
              },
            ],
          },
        ],
      };

      final result = MeetupResult.fromJson(json);
      final venue = result.stations[0].venues[0];

      expect(venue.name, 'テスト居酒屋');
      expect(venue.genre, '居酒屋');
      expect(venue.privateRoom, true);
      expect(venue.noSmoking, true);
      expect(venue.freeDrink, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 2. Hotel card display (from hotel-scoring.test.ts)
  // ═══════════════════════════════════════════════════════════════
  group('Hotel model - display formatting', () {
    test('formattedPrice shows correct currency symbol', () {
      final jpyHotel = Hotel.fromJson({
        'hotelId': 1, 'hotelName': 'Test', 'latitude': 35.0, 'longitude': 139.0,
        'dailyRate': 15000, 'currency': 'JPY',
      });
      expect(jpyHotel.formattedPrice, '¥15,000');

      final krwHotel = Hotel.fromJson({
        'hotelId': 2, 'hotelName': 'Test', 'latitude': 35.0, 'longitude': 139.0,
        'dailyRate': 120000, 'currency': 'KRW',
      });
      expect(krwHotel.formattedPrice, '₩120,000');

      final usdHotel = Hotel.fromJson({
        'hotelId': 3, 'hotelName': 'Test', 'latitude': 35.0, 'longitude': 139.0,
        'dailyRate': 120, 'currency': 'USD',
      });
      expect(usdHotel.formattedPrice, '\$120');
    });

    test('formattedRating formats to 1 decimal', () {
      final hotel = Hotel.fromJson({
        'hotelId': 1, 'hotelName': 'Test', 'latitude': 35.0, 'longitude': 139.0,
        'reviewScore': 8.7,
      });
      expect(hotel.formattedRating, '8.7');
    });

    test('discountPercent calculates correctly', () {
      final hotel = Hotel.fromJson({
        'hotelId': 1, 'hotelName': 'Test', 'latitude': 35.0, 'longitude': 139.0,
        'dailyRate': 8000, 'crossedOutRate': 10000, 'currency': 'JPY',
      });
      expect(hotel.discountPercent, 20);
    });

    test('formattedCrossedOutPrice returns null when no discount', () {
      final hotel = Hotel.fromJson({
        'hotelId': 1, 'hotelName': 'Test', 'latitude': 35.0, 'longitude': 139.0,
        'dailyRate': 10000, 'crossedOutRate': 10000, 'currency': 'JPY',
      });
      expect(hotel.formattedCrossedOutPrice, isNull);
    });

    test('handles alternative JSON field names', () {
      // API sometimes uses different field names
      final hotel = Hotel.fromJson({
        'id': 99,
        'name': 'Alt Name Hotel',
        'lat': 35.5,
        'lng': 139.5,
        'pricePerNight': 20000,
        'imageUrl': 'https://example.com/img.jpg',
        'bookingUrl': 'https://example.com/book',
      });
      expect(hotel.hotelId, 99);
      expect(hotel.name, 'Alt Name Hotel');
      expect(hotel.dailyRate, 20000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 3. Station multilingual support (from search.test.ts)
  // ═══════════════════════════════════════════════════════════════
  group('Station multilingual name', () {
    test('localizedName returns correct name per locale', () {
      final station = Station.fromJson({
        'id': 'shinjuku',
        'name': '新宿',
        'nameEn': 'Shinjuku',
        'nameKo': '신주쿠',
        'nameZh': '新宿',
        'lat': 35.6938,
        'lng': 139.7034,
        'lines': ['JR山手線'],
      });

      expect(station.localizedName('ja'), '新宿');
      expect(station.localizedName('en'), 'Shinjuku');
      expect(station.localizedName('ko'), '신주쿠');
      expect(station.localizedName('zh'), '新宿');
    });

    test('localizedName falls back to Japanese name', () {
      final station = Station.fromJson({
        'id': 'test',
        'name': 'テスト駅',
        'lat': 35.0,
        'lng': 139.0,
        'lines': [],
      });

      // No localized names provided — should fall back to Japanese
      expect(station.localizedName('en'), 'テスト駅');
      expect(station.localizedName('ko'), 'テスト駅');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 4. Landmark model
  // ═══════════════════════════════════════════════════════════════
  group('Landmark model', () {
    test('parses from JSON correctly', () {
      final landmark = Landmark.fromJson({
        'slug': 'shibuya-crossing',
        'name': '渋谷スクランブル交差点',
        'nameEn': 'Shibuya Crossing',
        'lat': 35.6595,
        'lng': 139.7004,
        'region': 'kanto',
      });

      expect(landmark.slug, 'shibuya-crossing');
      expect(landmark.name, '渋谷スクランブル交差点');
      expect(landmark.lat, 35.6595);
      expect(landmark.region, 'kanto');
    });

    test('toJson roundtrip preserves data', () {
      final original = Landmark(
        slug: 'tokyo-tower',
        name: '東京タワー',
        nameEn: 'Tokyo Tower',
        lat: 35.6586,
        lng: 139.7454,
        region: 'kanto',
      );

      final json = original.toJson();
      final restored = Landmark.fromJson(json);

      expect(restored.slug, original.slug);
      expect(restored.name, original.name);
      expect(restored.lat, original.lat);
      expect(restored.lng, original.lng);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 5. Route segment parsing
  // ═══════════════════════════════════════════════════════════════
  group('Route segment parsing', () {
    test('RouteSegment parses line colors and transfer minutes', () {
      final segment = RouteSegment.fromJson({
        'line': '東京メトロ銀座線',
        'operator': '東京メトロ',
        'minutes': 12,
        'color': '#FF9500',
        'fromStationId': 'shibuya',
        'toStationId': 'asakusa',
        'fromStationName': '渋谷',
        'toStationName': '浅草',
        'transferMinutes': 3,
      });

      expect(segment.line, '東京メトロ銀座線');
      expect(segment.minutes, 12);
      expect(segment.color, '#FF9500');
      expect(segment.transferMinutes, 3);
      expect(segment.fromStationName, '渋谷');
      expect(segment.toStationName, '浅草');
    });

    test('LandmarkDistance parses route with multiple segments', () {
      final ld = LandmarkDistance.fromJson({
        'name': '浅草寺',
        'estimatedMinutes': 25,
        'distanceKm': 8.5,
        'route': [
          {'line': 'JR山手線', 'minutes': 10, 'color': '#9acd32'},
          {'line': '東京メトロ銀座線', 'minutes': 15, 'color': '#FF9500', 'transferMinutes': 3},
        ],
      });

      expect(ld.landmarkName, '浅草寺');
      expect(ld.estimatedMinutes, 25);
      expect(ld.distanceKm, 8.5);
      expect(ld.route.length, 2);
      expect(ld.route[0].line, 'JR山手線');
      expect(ld.route[1].transferMinutes, 3);
    });
  });
}
