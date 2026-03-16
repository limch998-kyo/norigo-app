import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:norigo_app/providers/trip_provider.dart';
import 'package:norigo_app/models/landmark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('addItem creates trip and adds item when no trips exist', () {
    final notifier = TripNotifier();
    expect(notifier.state.trips, isEmpty);

    notifier.addItem(Landmark(slug: 'sensoji', name: '센소지', lat: 35.7148, lng: 139.7967, region: 'kanto'), locale: 'ko');

    expect(notifier.state.trips.length, 1);
    expect(notifier.state.trips.first.name, '일본 여행');
    expect(notifier.state.trips.first.country, 'japan');
    expect(notifier.state.items.length, 1);
    expect(notifier.state.items.first.name, '센소지');
    expect(notifier.state.activeTripId, isNotNull);
    print('✓ Auto-create: ${notifier.state.trips.first.name}, item: ${notifier.state.items.first.name}');
  });

  test('addItem uses existing trip for same country', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'asakusa', name: '아사쿠사', lat: 35.7148, lng: 139.7967, region: 'kanto'), locale: 'ko');

    expect(notifier.state.trips.length, 1);
    expect(notifier.state.items.length, 2);
    print('✓ Same trip: ${notifier.state.items.map((i) => i.name).join(", ")}');
  });

  test('addItem creates Korea trip for Seoul landmarks', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'myeongdong', name: '명동', lat: 37.5636, lng: 126.9869, region: 'seoul'), locale: 'ko');

    expect(notifier.state.trips.length, 2);
    final japanTrip = notifier.state.trips.firstWhere((t) => t.country == 'japan');
    final koreaTrip = notifier.state.trips.firstWhere((t) => t.country == 'korea');
    expect(japanTrip.name, '일본 여행');
    expect(koreaTrip.name, '한국 여행');

    final japanItems = notifier.state.items.where((i) => i.tripId == japanTrip.id).toList();
    final koreaItems = notifier.state.items.where((i) => i.tripId == koreaTrip.id).toList();
    expect(japanItems.first.name, '시부야');
    expect(koreaItems.first.name, '명동');
    print('✓ Country split: Japan=${japanItems.map((i) => i.name)}, Korea=${koreaItems.map((i) => i.name)}');
  });

  test('items show in Trip tab via activeItems', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'asakusa', name: '아사쿠사', lat: 35.7148, lng: 139.7967, region: 'kanto'), locale: 'ko');

    // activeItems should return items for active trip
    final activeItems = notifier.state.activeItems;
    expect(activeItems.length, 2);
    print('✓ activeItems: ${activeItems.map((i) => i.name).join(", ")}');

    // filteredTrips should include the trip
    final filtered = notifier.state.filteredTrips;
    expect(filtered.length, 1);
    print('✓ filteredTrips: ${filtered.first.name}');
  });

  test('no duplicate items', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');

    expect(notifier.state.items.length, 1);
    print('✓ No duplicate: ${notifier.state.items.length} item');
  });
}
