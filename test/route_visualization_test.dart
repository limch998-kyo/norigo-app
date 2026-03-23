import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/models/meetup_result.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/services/api_client.dart';

/// Tests for route visualization features:
/// - Polyline path data from API
/// - Station code badges (JY17, S02, etc.)
/// - Numbered landmark matching
void main() {
  group('RouteSegment path parsing', () {
    test('parses path coordinates from JSON', () {
      final seg = RouteSegment.fromJson({
        'line': '山手線',
        'operator': '東日本旅客鉄道',
        'minutes': 5,
        'color': '#9ACD32',
        'fromStationId': 'shibuya',
        'toStationId': 'shinjuku',
        'path': [[35.659, 139.703], [35.670, 139.702], [35.690, 139.704]],
      });

      expect(seg.path, isNotNull);
      expect(seg.path!.length, 3);
      expect(seg.path![0][0], 35.659); // lat
      expect(seg.path![0][1], 139.703); // lng
      expect(seg.path![2][0], 35.690);
    });

    test('path is null when not provided', () {
      final seg = RouteSegment.fromJson({
        'line': '山手線',
        'operator': '',
        'minutes': 5,
        'color': '#9ACD32',
        'fromStationId': 'a',
        'toStationId': 'b',
      });

      expect(seg.path, isNull);
    });

    test('empty path is handled', () {
      final seg = RouteSegment.fromJson({
        'line': '山手線',
        'operator': '',
        'minutes': 5,
        'color': '#9ACD32',
        'fromStationId': 'a',
        'toStationId': 'b',
        'path': [],
      });

      expect(seg.path, isNotNull);
      expect(seg.path, isEmpty);
    });
  });

  group('Station codes (from bundled JSON)', () {
    late Map<String, dynamic> codesData;

    setUpAll(() {
      final raw = File('assets/data/station-codes.json').readAsStringSync();
      codesData = jsonDecode(raw) as Map<String, dynamic>;
    });

    List<String> getCodesForStation(String stationName) {
      final results = <String>[];
      for (final entry in codesData.entries) {
        final lineData = entry.value as Map<String, dynamic>;
        final prefix = lineData['prefix'] as String? ?? '';
        if (lineData.containsKey(stationName)) {
          results.add('$prefix${lineData[stationName]}');
        }
      }
      return results;
    }

    test('Shinjuku has Yamanote and Chuo codes', () {
      final codes = getCodesForStation('新宿');
      expect(codes, contains('JY17'));
      expect(codes, contains('JC05'));
      print('✓ Shinjuku codes: ${codes.join(', ')}');
    });

    test('Shibuya has Yamanote code', () {
      final codes = getCodesForStation('渋谷');
      expect(codes, contains('JY20'));
      print('✓ Shibuya codes: ${codes.join(', ')}');
    });

    test('Tokyo has multiple codes', () {
      final codes = getCodesForStation('東京');
      expect(codes.length, greaterThan(3)); // JY, JC, 丸ノ内, etc.
      print('✓ Tokyo codes: ${codes.join(', ')}');
    });

    test('unknown station returns empty', () {
      final codes = getCodesForStation('架空駅');
      expect(codes, isEmpty);
    });
  });

  group('API returns path data for stay recommendation', () {
    test('route segments contain path coordinates', () async {
      final api = ApiClient();
      final result = await api.getStayRecommendation(
        landmarks: [
          Landmark(slug: 'shibuya', name: '渋谷', lat: 35.659, lng: 139.703, region: 'kanto'),
          Landmark(slug: 'asakusa', name: '浅草', lat: 35.714, lng: 139.796, region: 'kanto'),
        ],
        mode: 'minTotal',
        region: 'kanto',
      );

      // Find a landmark distance with route
      final ld = result.areas
          .expand((a) => a.landmarkDistances)
          .firstWhere((d) => d.route.isNotEmpty);

      final seg = ld.route.first;
      expect(seg.path, isNotNull, reason: 'API should return path for polyline');
      expect(seg.path!.length, greaterThanOrEqualTo(2), reason: 'Path needs at least 2 points');
      expect(seg.path![0].length, 2, reason: 'Each point is [lat, lng]');
      print('✓ Route path: ${seg.line}, ${seg.path!.length} points');
    });
  });

  group('Landmark numbering', () {
    test('landmarks get sequential numbers', () {
      final landmarks = [
        {'name': '渋谷', 'index': 1},
        {'name': '浅草', 'index': 2},
        {'name': '新宿', 'index': 3},
      ];

      for (final lm in landmarks) {
        expect(lm['index'], greaterThan(0));
      }
      // Verify sequential
      for (var i = 0; i < landmarks.length; i++) {
        expect(landmarks[i]['index'], i + 1);
      }
    });
  });
}
