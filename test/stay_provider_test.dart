import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norigo_app/providers/stay_provider.dart';
import 'package:norigo_app/models/landmark.dart';

/// Unit tests for StaySearchNotifier — core business logic, no network calls.
void main() {
  late ProviderContainer container;
  late StaySearchNotifier notifier;

  final shibuya = Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.6595, lng: 139.7004, region: 'kanto');
  final harajuku = Landmark(slug: 'harajuku', name: 'Harajuku', lat: 35.6702, lng: 139.7026, region: 'kanto');
  final shinjuku = Landmark(slug: 'shinjuku', name: 'Shinjuku', lat: 35.6852, lng: 139.71, region: 'kanto');
  final namba = Landmark(slug: 'namba', name: 'Namba', lat: 34.6654, lng: 135.5013, region: 'kansai');

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(staySearchProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('Initial state', () {
    test('starts with 2 empty slots, kanto region', () {
      final state = container.read(staySearchProvider);
      expect(state.slots, [null, null]);
      expect(state.region, 'kanto');
      expect(state.mode, 'minTotal');
      expect(state.landmarks, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });

  group('addLandmark', () {
    test('fills first empty slot', () {
      notifier.addLandmark(shibuya);
      expect(container.read(staySearchProvider).slots, [shibuya, null]);
    });

    test('fills second empty slot', () {
      notifier.addLandmark(shibuya);
      notifier.addLandmark(harajuku);
      expect(container.read(staySearchProvider).landmarks, [shibuya, harajuku]);
    });

    test('prevents duplicate by slug', () {
      notifier.addLandmark(shibuya);
      notifier.addLandmark(shibuya);
      expect(container.read(staySearchProvider).landmarks.length, 1);
    });

    test('prevents duplicate by close coordinates', () {
      notifier.addLandmark(shibuya);
      final nearShibuya = Landmark(slug: 'shibuya2', name: 'Shibuya2', lat: 35.6596, lng: 139.7005, region: 'kanto');
      notifier.addLandmark(nearShibuya);
      expect(container.read(staySearchProvider).landmarks.length, 1);
    });

    test('adds new slot when all filled (up to 10)', () {
      notifier.addLandmark(shibuya);
      notifier.addLandmark(harajuku);
      notifier.addLandmark(shinjuku);
      expect(container.read(staySearchProvider).slots.length, 3);
    });
  });

  group('removeSlot', () {
    test('clears slot when only 2 slots (minimum)', () {
      notifier.addLandmark(shibuya);
      notifier.addLandmark(harajuku);
      notifier.removeSlot(0);
      final state = container.read(staySearchProvider);
      expect(state.slots.length, 2);
      expect(state.slots[0], isNull);
      expect(state.slots[1], harajuku);
    });

    test('removes slot when more than 2', () {
      notifier.addLandmark(shibuya);
      notifier.addLandmark(harajuku);
      notifier.addLandmark(shinjuku);
      notifier.removeSlot(1);
      final state = container.read(staySearchProvider);
      expect(state.slots.length, 2);
      expect(state.landmarks, [shibuya, shinjuku]);
    });
  });

  group('removeLandmark', () {
    test('clears by slug when 2 slots', () {
      notifier.addLandmark(shibuya);
      notifier.addLandmark(harajuku);
      notifier.removeLandmark('shibuya');
      expect(container.read(staySearchProvider).slots, [null, harajuku]);
    });
  });

  group('addSlot', () {
    test('adds empty slot', () {
      notifier.addSlot();
      expect(container.read(staySearchProvider).slots.length, 3);
    });

    test('max 10 slots', () {
      for (var i = 0; i < 15; i++) notifier.addSlot();
      expect(container.read(staySearchProvider).slots.length, 10);
    });
  });

  group('setRegion', () {
    test('switches region and preserves slots per region', () {
      notifier.addLandmark(shibuya);
      notifier.setRegion('kansai');
      // Kansai starts empty
      expect(container.read(staySearchProvider).slots, [null, null]);
      expect(container.read(staySearchProvider).region, 'kansai');

      // Switch back — kanto slots restored
      notifier.setRegion('kanto');
      expect(container.read(staySearchProvider).landmarks, [shibuya]);
    });

    test('no-op when same region', () {
      notifier.addLandmark(shibuya);
      notifier.setRegion('kanto');
      expect(container.read(staySearchProvider).landmarks, [shibuya]);
    });
  });

  group('setMode / setBudget / setDates', () {
    test('setMode updates mode', () {
      notifier.setMode('equalDistance');
      expect(container.read(staySearchProvider).mode, 'equalDistance');
    });

    test('setBudget sets and clears', () {
      notifier.setBudget('10000-30000');
      expect(container.read(staySearchProvider).maxBudget, '10000-30000');
      notifier.setBudget(null);
      expect(container.read(staySearchProvider).maxBudget, isNull);
    });

    test('setDates sets check-in/out', () {
      notifier.setDates('2026-04-01', '2026-04-03');
      final state = container.read(staySearchProvider);
      expect(state.checkIn, '2026-04-01');
      expect(state.checkOut, '2026-04-03');
    });
  });

  group('clearResult / reset', () {
    test('clearResult preserves inputs', () {
      notifier.addLandmark(shibuya);
      notifier.setMode('equalDistance');
      notifier.clearResult();
      final state = container.read(staySearchProvider);
      expect(state.result, isNull);
      expect(state.landmarks, [shibuya]);
      expect(state.mode, 'equalDistance');
    });

    test('reset clears everything', () {
      notifier.addLandmark(shibuya);
      notifier.setMode('equalDistance');
      notifier.reset();
      final state = container.read(staySearchProvider);
      expect(state.slots, [null, null]);
      expect(state.region, 'kanto');
    });
  });

  group('search validation', () {
    test('search with < 2 landmarks does nothing', () async {
      notifier.addLandmark(shibuya);
      await notifier.search();
      final state = container.read(staySearchProvider);
      // Should not set isLoading or error — just returns
      expect(state.isLoading, false);
    });
  });
}
