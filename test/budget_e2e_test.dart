import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norigo_app/providers/stay_provider.dart';
import 'package:norigo_app/config/constants.dart';
import 'package:norigo_app/config/booking_provider.dart';
import 'package:norigo_app/models/landmark.dart';

String _innerUrl(String wrappedUrl) {
  final uri = Uri.parse(wrappedUrl);
  return uri.queryParameters['url'] ?? wrappedUrl;
}

/// End-to-end budget flow tests:
/// QuickCard → setBudget → state.maxBudget → ExternalHotelLinks → URL params
void main() {
  group('Budget state flow', () {
    late ProviderContainer container;
    late StaySearchNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(staySearchProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('Initial state: maxBudget is null', () {
      final state = container.read(staySearchProvider);
      expect(state.maxBudget, isNull);
    });

    test('setBudget updates state', () {
      notifier.setBudget('10000-30000');
      expect(container.read(staySearchProvider).maxBudget, '10000-30000');
    });

    test('setBudget(null) clears budget', () {
      notifier.setBudget('10000-30000');
      notifier.setBudget(null);
      expect(container.read(staySearchProvider).maxBudget, isNull);
    });

    test('Quick card flow: setRegion → addLandmark → setBudget', () {
      // Simulates _QuickSearchPlans.onSelect callback
      notifier.setRegion('kanto');
      notifier.addLandmark(Landmark(slug: 'shinjuku', name: 'Shinjuku', lat: 35.69, lng: 139.70, region: 'kanto'));
      notifier.addLandmark(Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.66, lng: 139.70, region: 'kanto'));

      // This is what the quick card does:
      final isKorea = ['seoul', 'busan'].contains('kanto');
      final budget = isKorea ? '25000-35000' : '10000-30000';
      notifier.setBudget(budget);

      final state = container.read(staySearchProvider);
      expect(state.maxBudget, '10000-30000');
      expect(state.landmarks.length, 2);
      expect(state.region, 'kanto');

      print('✓ Quick card budget: ${state.maxBudget}');
    });

    test('Quick card Korea flow: budget = 25000-35000', () {
      notifier.setRegion('seoul');
      notifier.addLandmark(Landmark(slug: 'gangnam', name: '강남', lat: 37.50, lng: 127.03, region: 'seoul'));
      notifier.addLandmark(Landmark(slug: 'myeongdong', name: '명동', lat: 37.56, lng: 126.99, region: 'seoul'));

      final isKorea = ['seoul', 'busan'].contains('seoul');
      final budget = isKorea ? '25000-35000' : '10000-30000';
      notifier.setBudget(budget);

      expect(container.read(staySearchProvider).maxBudget, '25000-35000');
    });

    test('Budget persists after setting dates', () {
      notifier.setBudget('10000-30000');
      notifier.setDates('2026-04-01', '2026-04-04');
      expect(container.read(staySearchProvider).maxBudget, '10000-30000');
    });

    test('Budget persists after setting mode', () {
      notifier.setBudget('10000-30000');
      notifier.setMode('centroid');
      expect(container.read(staySearchProvider).maxBudget, '10000-30000');
    });

    test('clearResult preserves budget', () {
      notifier.setBudget('30000-50000');
      notifier.clearResult();
      expect(container.read(staySearchProvider).maxBudget, '30000-50000');
    });

    test('reset clears budget', () {
      notifier.setBudget('30000-50000');
      notifier.reset();
      expect(container.read(staySearchProvider).maxBudget, isNull);
    });
  });

  group('Budget tier keys match between search and result', () {
    test('JP budget tiers are valid parseBudgetRange keys', () {
      for (final key in AppConstants.stayBudgetsJp) {
        final range = BookingProvider.parseBudgetRange(key);
        expect(range.min, isNonNegative, reason: '$key min >= 0');
        expect(range.max, greaterThan(0), reason: '$key max > 0');
        // Verify label exists for every tier
        if (key != 'any') {
          expect(AppConstants.stayBudgetLabels.containsKey(key), isTrue, reason: '$key has label');
        }
      }
      print('✓ JP tiers: ${AppConstants.stayBudgetsJp}');
    });

    test('KR budget tiers are valid parseBudgetRange keys', () {
      for (final key in AppConstants.stayBudgetsKr) {
        final range = BookingProvider.parseBudgetRange(key);
        expect(range.min, isNonNegative, reason: '$key min >= 0');
        expect(range.max, greaterThan(0), reason: '$key max > 0');
        if (key != 'any') {
          expect(AppConstants.stayBudgetLabels.containsKey(key), isTrue, reason: '$key has label');
        }
      }
      print('✓ KR tiers: ${AppConstants.stayBudgetsKr}');
    });

    test('All budget labels have all 5 locales', () {
      final requiredLocales = ['ja', 'en', 'ko', 'zh', 'fr'];
      for (final entry in AppConstants.stayBudgetLabels.entries) {
        for (final locale in requiredLocales) {
          expect(entry.value.containsKey(locale), isTrue,
              reason: '${entry.key} missing $locale label');
        }
      }
    });

    test('Default JP budget is in JP tiers list', () {
      expect(AppConstants.stayBudgetsJp.contains(AppConstants.defaultStayBudgetJp), isTrue);
    });

    test('Quick card default budgets are in tier lists', () {
      // JP quick cards use '10000-30000'
      expect(AppConstants.stayBudgetsJp.contains('10000-30000'), isTrue);
      // KR quick cards use '25000-35000'
      expect(AppConstants.stayBudgetsKr.contains('25000-35000'), isTrue);
    });
  });

  group('Budget → URL end-to-end (full flow simulation)', () {
    late ProviderContainer container;
    late StaySearchNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(staySearchProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('Quick card → search → result screen → Expedia URL has correct price', () {
      // 1. Quick card sets landmarks + budget
      notifier.setRegion('kanto');
      notifier.addLandmark(Landmark(slug: 'shinjuku', name: 'Shinjuku', lat: 35.69, lng: 139.70, region: 'kanto'));
      notifier.addLandmark(Landmark(slug: 'shibuya', name: 'Shibuya', lat: 35.66, lng: 139.70, region: 'kanto'));
      notifier.setBudget('10000-30000');
      notifier.setDates('2026-04-01', '2026-04-04'); // 3 nights

      // 2. Read state (simulates what result screen does)
      final state = container.read(staySearchProvider);
      expect(state.maxBudget, '10000-30000');

      // 3. Result screen passes to _ExternalHotelLinks → buildMultiProviderUrls
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en',
        region: state.region,
        stationName: 'Shinjuku',
        lat: 35.69,
        lng: 139.70,
        checkIn: state.checkIn,
        checkOut: state.checkOut,
        maxBudget: state.maxBudget, // THIS is the key connection
      );

      expect(providers.length, 4);

      // 4. Verify Expedia URL has total price (3 nights)
      final expediaUrl = _innerUrl(providers[0].url);
      expect(expediaUrl, contains('price=200')); // min: 10000*3/150=200
      expect(expediaUrl, contains('price=600')); // max: 30000*3/150=600

      // 5. Verify Hotels.com URL has per-night price
      final hotelsUrl = _innerUrl(providers[1].url);
      expect(hotelsUrl, contains('price=67'));  // min: 10000/150=67
      expect(hotelsUrl, contains('price=200')); // max: 30000/150=200
      expect(hotelsUrl, contains('currency=USD'));

      // 6. Verify Booking.com URL has JPY price ×2
      final bookingUrl = _innerUrl(providers[3].url);
      expect(bookingUrl, contains('nflt=price%3DJPY-20000-60000-1'));

      print('✓ Full flow: maxBudget=${state.maxBudget}');
      print('  Expedia: $expediaUrl');
      print('  Hotels.com: $hotelsUrl');
      print('  Booking.com: $bookingUrl');
    });

    test('No budget set → URLs have no price params', () {
      notifier.setRegion('kanto');
      notifier.addLandmark(Landmark(slug: 'shinjuku', name: 'Shinjuku', lat: 35.69, lng: 139.70, region: 'kanto'));
      notifier.setDates('2026-04-01', '2026-04-04');

      final state = container.read(staySearchProvider);
      expect(state.maxBudget, isNull);

      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: state.region, stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: state.checkIn, checkOut: state.checkOut,
        maxBudget: state.maxBudget,
      );

      for (final p in providers) {
        expect(p.url, isNot(contains('price=')), reason: '${p.name} should have no price');
      }
    });

    test('Budget filter chip change updates URLs', () {
      notifier.setRegion('kanto');
      notifier.setBudget('10000-30000');
      notifier.setDates('2026-04-01', '2026-04-04');

      // User changes budget to over50000 via top chip
      notifier.setBudget('over50000');
      final state = container.read(staySearchProvider);
      expect(state.maxBudget, 'over50000');

      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: state.region, stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: state.checkIn, checkOut: state.checkOut,
        maxBudget: state.maxBudget,
      );

      // Expedia: 50000*3/150=1000, max=10000
      expect(_innerUrl(providers[0].url), contains('price=1000'));
      expect(_innerUrl(providers[0].url), contains('price=10000'));
    });

    test('initState default budget is in tier list', () {
      // The initState sets '10000-30000' as default
      // This MUST be in the JP tier list, otherwise chips won't highlight
      notifier.setBudget('10000-30000');
      final budget = container.read(staySearchProvider).maxBudget;
      expect(AppConstants.stayBudgetsJp.contains(budget), isTrue,
          reason: 'Default budget "$budget" must be in JP tiers: ${AppConstants.stayBudgetsJp}');
    });

    test('OLD default "under30000" is NOT in new tier list (regression guard)', () {
      // This was the bug: old default was not in new tier list
      expect(AppConstants.stayBudgetsJp.contains('under30000'), isFalse,
          reason: 'Legacy key "under30000" should NOT be in new JP tiers');
    });
  });
}
