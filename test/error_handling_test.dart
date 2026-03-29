import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/models/station.dart';
import 'package:norigo_app/models/stay_area.dart';
import 'package:norigo_app/models/meetup_result.dart';
import 'package:norigo_app/providers/stay_provider.dart';

/// Tests for edge cases and error handling in model parsing.
void main() {
  group('Landmark.fromJson edge cases', () {
    test('handles missing optional fields', () {
      final json = {'slug': 'test', 'name': 'Test', 'lat': 35.0, 'lng': 139.0, 'region': 'kanto'};
      final lm = Landmark.fromJson(json);
      expect(lm.slug, 'test');
      expect(lm.nameEn, isNull);
    });

    test('handles all fields populated', () {
      final json = {'slug': 'test', 'name': 'Test', 'nameEn': 'TestEN', 'lat': 35.0, 'lng': 139.0, 'region': 'kanto', 'description': 'desc', 'imageUrl': 'url'};
      final lm = Landmark.fromJson(json);
      expect(lm.nameEn, 'TestEN');
      expect(lm.description, 'desc');
    });

    test('handles zero coordinates', () {
      final json = {'slug': 'test', 'name': 'Test', 'lat': 0.0, 'lng': 0.0, 'region': 'kanto'};
      final lm = Landmark.fromJson(json);
      expect(lm.lat, 0.0);
      expect(lm.lng, 0.0);
    });
  });

  group('Station.fromJson edge cases', () {
    test('handles missing optional fields', () {
      final json = {'id': 'test', 'name': 'Test', 'lat': 35.0, 'lng': 139.0, 'region': 'kanto'};
      final st = Station.fromJson(json);
      expect(st.nameEn, isNull);
      expect(st.lines, isEmpty);
    });

    test('handles lines as list', () {
      final json = {'id': 'test', 'name': 'Test', 'lat': 35.0, 'lng': 139.0, 'region': 'kanto', 'lines': ['JR', 'Metro']};
      final st = Station.fromJson(json);
      expect(st.lines, ['JR', 'Metro']);
    });
  });

  group('StayRecommendResult.fromJson edge cases', () {
    test('handles empty areas list', () {
      final json = {'areas': [], 'split': false};
      final result = StayRecommendResult.fromJson(json);
      expect(result.areas, isEmpty);
    });

    test('handles missing split field', () {
      final json = {'areas': []};
      final result = StayRecommendResult.fromJson(json);
      expect(result.split, false);
    });
  });

  group('MeetupResult.fromJson edge cases', () {
    test('handles empty stations', () {
      final json = {'stations': []};
      final result = MeetupResult.fromJson(json);
      expect(result.stations, isEmpty);
    });
  });

  group('StaySearchState', () {
    test('landmarks getter filters null slots', () {
      final state = StaySearchState(slots: [
        Landmark(slug: 'a', name: 'A', lat: 35.0, lng: 139.0, region: 'kanto'),
        null,
        Landmark(slug: 'b', name: 'B', lat: 35.1, lng: 139.1, region: 'kanto'),
      ]);
      expect(state.landmarks.length, 2);
      expect(state.landmarks[0].slug, 'a');
      expect(state.landmarks[1].slug, 'b');
    });

    test('copyWith clearResult sets result to null', () {
      final state = StaySearchState(error: 'some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('copyWith clearBudget sets budget to null', () {
      final state = StaySearchState(maxBudget: '10000');
      final cleared = state.copyWith(clearBudget: true);
      expect(cleared.maxBudget, isNull);
    });
  });
}
