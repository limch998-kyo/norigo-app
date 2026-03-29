import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norigo_app/providers/meetup_provider.dart';
import 'package:norigo_app/models/station.dart';

/// Unit tests for MeetupSearchNotifier — core business logic, no network calls.
void main() {
  late ProviderContainer container;
  late MeetupSearchNotifier notifier;

  final shibuya = Station(id: 'shibuya', name: '渋谷', lat: 35.6580, lng: 139.7016, region: 'kanto');
  final shinjuku = Station(id: 'shinjuku', name: '新宿', lat: 35.6896, lng: 139.7006, region: 'kanto');
  final ikebukuro = Station(id: 'ikebukuro', name: '池袋', lat: 35.7295, lng: 139.7109, region: 'kanto');

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(meetupSearchProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('Initial state', () {
    test('starts with 2 empty slots, kanto region', () {
      final state = container.read(meetupSearchProvider);
      expect(state.slots, [null, null]);
      expect(state.region, 'kanto');
      expect(state.mode, 'centroid');
      expect(state.filledStations, isEmpty);
    });
  });

  group('setStation', () {
    test('sets station at index', () {
      notifier.setStation(0, shibuya);
      expect(container.read(meetupSearchProvider).slots[0], shibuya);
    });

    test('sets both stations', () {
      notifier.setStation(0, shibuya);
      notifier.setStation(1, shinjuku);
      expect(container.read(meetupSearchProvider).filledStations.length, 2);
    });
  });

  group('removeSlot', () {
    test('does nothing when only 2 slots (minimum)', () {
      notifier.setStation(0, shibuya);
      notifier.setStation(1, shinjuku);
      notifier.removeSlot(0);
      final state = container.read(meetupSearchProvider);
      expect(state.slots.length, 2);
      // Meetup removeSlot returns early when <= 2 slots
      expect(state.slots[0], shibuya);
      expect(state.slots[1], shinjuku);
    });

    test('removes slot when more than 2', () {
      notifier.setStation(0, shibuya);
      notifier.setStation(1, shinjuku);
      notifier.addSlot();
      notifier.setStation(2, ikebukuro);
      notifier.removeSlot(1);
      final state = container.read(meetupSearchProvider);
      expect(state.slots.length, 2);
      expect(state.filledStations, [shibuya, ikebukuro]);
    });
  });

  group('addSlot', () {
    test('adds empty slot', () {
      notifier.addSlot();
      expect(container.read(meetupSearchProvider).slots.length, 3);
    });

    test('max 10 slots', () {
      for (var i = 0; i < 15; i++) notifier.addSlot();
      expect(container.read(meetupSearchProvider).slots.length, 10);
    });
  });

  group('setRegion', () {
    test('switches region and preserves slots', () {
      notifier.setStation(0, shibuya);
      notifier.setRegion('kansai');
      expect(container.read(meetupSearchProvider).slots, [null, null]);

      notifier.setRegion('kanto');
      expect(container.read(meetupSearchProvider).slots[0], shibuya);
    });
  });

  group('setMode / setCategory / setBudget / toggleOption', () {
    test('setMode', () {
      notifier.setMode('balanced');
      expect(container.read(meetupSearchProvider).mode, 'balanced');
    });

    test('setCategory', () {
      notifier.setCategory('izakaya');
      expect(container.read(meetupSearchProvider).category, 'izakaya');
      notifier.setCategory(null);
      expect(container.read(meetupSearchProvider).category, isNull);
    });

    test('toggleOption adds and removes', () {
      notifier.toggleOption('wifi');
      expect(container.read(meetupSearchProvider).options, ['wifi']);
      notifier.toggleOption('wifi');
      expect(container.read(meetupSearchProvider).options, isEmpty);
    });
  });

  group('clearResult / reset', () {
    test('clearResult preserves inputs', () {
      notifier.setStation(0, shibuya);
      notifier.setMode('balanced');
      notifier.clearResult();
      final state = container.read(meetupSearchProvider);
      expect(state.result, isNull);
      expect(state.slots[0], shibuya);
      expect(state.mode, 'balanced');
    });

    test('reset clears everything', () {
      notifier.setStation(0, shibuya);
      notifier.reset();
      final state = container.read(meetupSearchProvider);
      expect(state.slots, [null, null]);
    });
  });

  group('search validation', () {
    test('search with < 2 stations does nothing', () async {
      notifier.setStation(0, shibuya);
      await notifier.search();
      expect(container.read(meetupSearchProvider).isLoading, false);
    });
  });
}
