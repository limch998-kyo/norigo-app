import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/models/trip.dart';
import 'package:norigo_app/providers/trip_provider.dart';
import 'package:norigo_app/providers/trip_stay_provider.dart';

/// Verifies the inputs that invalidate a trip's cached stay recommendation.
/// Guards against the regression where dates/budget/mode changes were ignored
/// (the old selector watched only spot slugs).
void main() {
  final now = DateTime(2026, 1, 1);

  Trip trip({
    String id = 't1',
    String name = 'Tokyo',
    String? checkIn,
    String? checkOut,
    String? maxBudget,
    String? searchMode,
  }) =>
      Trip(
        id: id,
        name: name,
        checkIn: checkIn,
        checkOut: checkOut,
        maxBudget: maxBudget,
        searchMode: searchMode,
        createdAt: now,
        updatedAt: now,
      );

  TripItem item(String slug, {String tripId = 't1'}) => TripItem(
        slug: slug,
        name: slug,
        lat: 1,
        lng: 2,
        region: 'kanto',
        tripId: tripId,
        addedAt: now,
      );

  TripState state({List<Trip>? trips, List<TripItem>? items}) => TripState(
        trips: trips ?? [trip()],
        items: items ?? [item('shibuya'), item('shinjuku')],
      );

  group('tripStaySignature — invalidating changes', () {
    test('changing check-in date changes the signature', () {
      final before = tripStaySignature(state(trips: [trip(checkIn: '2026-07-01')]), 't1');
      final after = tripStaySignature(state(trips: [trip(checkIn: '2026-07-08')]), 't1');
      expect(before, isNot(after));
    });

    test('changing check-out date changes the signature', () {
      final before = tripStaySignature(state(trips: [trip(checkOut: '2026-07-04')]), 't1');
      final after = tripStaySignature(state(trips: [trip(checkOut: '2026-07-05')]), 't1');
      expect(before, isNot(after));
    });

    test('changing budget changes the signature', () {
      final before = tripStaySignature(state(trips: [trip(maxBudget: '10000-30000')]), 't1');
      final after = tripStaySignature(state(trips: [trip(maxBudget: '30000-50000')]), 't1');
      expect(before, isNot(after));
    });

    test('changing search mode changes the signature', () {
      final before = tripStaySignature(state(trips: [trip(searchMode: 'centroid')]), 't1');
      final after = tripStaySignature(state(trips: [trip(searchMode: 'minTotal')]), 't1');
      expect(before, isNot(after));
    });

    test('adding a spot changes the signature', () {
      final before = tripStaySignature(state(), 't1');
      final after = tripStaySignature(
        state(items: [item('shibuya'), item('shinjuku'), item('ueno')]),
        't1',
      );
      expect(before, isNot(after));
    });
  });

  group('tripStaySignature — stable across irrelevant changes', () {
    test('renaming the trip does NOT change the signature', () {
      final before = tripStaySignature(state(trips: [trip(name: 'Tokyo')]), 't1');
      final after = tripStaySignature(state(trips: [trip(name: 'Renamed')]), 't1');
      expect(before, after);
    });

    test('spot order does not matter (slugs are sorted)', () {
      final a = tripStaySignature(state(items: [item('shibuya'), item('shinjuku')]), 't1');
      final b = tripStaySignature(state(items: [item('shinjuku'), item('shibuya')]), 't1');
      expect(a, b);
    });

    test('another trip changing does NOT affect this trip', () {
      final base = tripStaySignature(
        TripState(
          trips: [trip(id: 't1'), trip(id: 't2', checkIn: '2026-01-01')],
          items: [item('shibuya'), item('shinjuku')],
        ),
        't1',
      );
      final other = tripStaySignature(
        TripState(
          trips: [trip(id: 't1'), trip(id: 't2', checkIn: '2099-12-31')],
          items: [item('shibuya'), item('shinjuku')],
        ),
        't1',
      );
      expect(base, other);
    });

    test("only this trip's spots count, not other trips' items", () {
      final sig = tripStaySignature(
        TripState(
          trips: [trip(id: 't1')],
          items: [
            item('shibuya', tripId: 't1'),
            item('shinjuku', tripId: 't1'),
            item('osaka', tripId: 't2'),
          ],
        ),
        't1',
      );
      expect(sig.contains('osaka'), isFalse);
      expect(sig.contains('shibuya'), isTrue);
    });
  });
}
