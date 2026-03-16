import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:norigo_app/providers/trip_provider.dart';
import 'package:norigo_app/models/landmark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('addItem creates region-specific trip (ko locale)', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'sensoji', name: '센소지', lat: 35.7148, lng: 139.7967, region: 'kanto'), locale: 'ko');

    expect(notifier.state.trips.length, 1);
    expect(notifier.state.trips.first.name, '도쿄·간토');
    expect(notifier.state.items.length, 1);
    print('✓ Auto-create: ${notifier.state.trips.first.name}');
  });

  test('addItem uses existing trip for same region', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'asakusa', name: '아사쿠사', lat: 35.7148, lng: 139.7967, region: 'kanto'), locale: 'ko');

    expect(notifier.state.trips.length, 1);
    expect(notifier.state.items.length, 2);
    print('✓ Same trip: ${notifier.state.items.map((i) => i.name).join(", ")}');
  });

  test('addItem creates separate trips per region', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'dotonbori', name: '도톤보리', lat: 34.6687, lng: 135.5013, region: 'kansai'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'myeongdong', name: '명동', lat: 37.5636, lng: 126.9869, region: 'seoul'), locale: 'ko');

    expect(notifier.state.trips.length, 3);
    expect(notifier.state.trips.any((t) => t.name == '도쿄·간토'), isTrue);
    expect(notifier.state.trips.any((t) => t.name == '오사카·간사이'), isTrue);
    expect(notifier.state.trips.any((t) => t.name == '서울'), isTrue);
    print('✓ 3 region trips: ${notifier.state.trips.map((t) => t.name).join(", ")}');
  });

  test('no duplicate items', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    notifier.addItem(Landmark(slug: 'shibuya', name: '시부야', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ko');
    expect(notifier.state.items.length, 1);
    print('✓ No duplicate');
  });

  test('ja locale creates Japanese trip names', () {
    final notifier = TripNotifier();
    notifier.addItem(Landmark(slug: 'shibuya', name: '渋谷', lat: 35.6595, lng: 139.7004, region: 'kanto'), locale: 'ja');
    notifier.addItem(Landmark(slug: 'haeundae', name: '海雲台', lat: 35.1588, lng: 129.1604, region: 'busan'), locale: 'ja');

    expect(notifier.state.trips.any((t) => t.name == '東京・関東'), isTrue);
    expect(notifier.state.trips.any((t) => t.name == '釜山'), isTrue);
    print('✓ ja: ${notifier.state.trips.map((t) => t.name).join(", ")}');
  });
}
