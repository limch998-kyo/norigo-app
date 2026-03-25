import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/config/booking_provider.dart';

/// End-to-end tests for Expedia + Hotels.com + Booking.com integration.
/// Validates every item in PROMPT_EXPEDIA_INTEGRATION.md checklist.
void main() {
  group('parseBudgetRange', () {
    test('any → (0, max)', () {
      final r = BookingProvider.parseBudgetRange('any');
      expect(r.min, 0);
      expect(r.max, 999999999);
    });

    test('under10000 → (0, 10000)', () {
      final r = BookingProvider.parseBudgetRange('under10000');
      expect(r.min, 0);
      expect(r.max, 10000);
    });

    test('10000-30000 → (10000, 30000)', () {
      final r = BookingProvider.parseBudgetRange('10000-30000');
      expect(r.min, 10000);
      expect(r.max, 30000);
    });

    test('over50000 → (50000, max)', () {
      final r = BookingProvider.parseBudgetRange('over50000');
      expect(r.min, 50000);
      expect(r.max, 999999999);
    });
  });

  group('Provider routing by locale', () {
    test('EN → 3 providers (Expedia, Hotels.com, Booking.com)', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers.length, 3);
      expect(providers[0].name, 'Expedia');
      expect(providers[1].name, 'Hotels.com');
      expect(providers[2].name, 'Booking.com');
    });

    test('FR → 3 providers (same as EN)', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'fr', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers.length, 3);
    });

    test('ZH → 3 providers (same as EN)', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'zh', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers.length, 3);
    });

    test('JA → empty (uses Jalan)', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'ja', region: 'kanto', stationName: '新宿',
        lat: 35.69, lng: 139.70, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers, isEmpty);
    });

    test('KO → empty (uses Agoda)', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'ko', region: 'seoul', stationName: '강남',
        lat: 37.50, lng: 127.03, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers, isEmpty);
    });
  });

  group('Brand colors', () {
    test('Expedia yellow, Hotels.com red, Booking.com blue', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
      );
      expect(providers[0].color.value, 0xFFFEC84C); // Expedia yellow
      expect(providers[0].textColor.value, 0xFF202843); // navy text
      expect(providers[1].color.value, 0xFFD32F2F); // Hotels.com red
      expect(providers[2].color.value, 0xFF003B95); // Booking.com blue
    });
  });

  group('Affiliate parameters', () {
    test('Expedia URL contains affcid', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
      );
      expect(providers[0].url, contains('affcid=US.DIRECT.PHG.1011l426920.1100l68075'));
    });

    test('Hotels.com URL contains affcid', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
      );
      expect(providers[1].url, contains('affcid=US.DIRECT.PHG.1011l426920.1100l68075'));
    });

    test('Booking.com URL contains aid', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
      );
      expect(providers[2].url, contains('aid=2432111'));
    });
  });

  group('CJK station name fallback', () {
    test('Japanese name → Tokyo Station, Japan', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: '新宿',
        lat: 35.69, lng: 139.70,
      );
      expect(providers[0].url, contains('Tokyo%20Station'));
      expect(providers[0].url, contains('Japan'));
    });

    test('Korean name → Seoul Station, South Korea', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: '강남',
        lat: 37.50, lng: 127.03,
      );
      expect(providers[0].url, contains('Seoul%20Station'));
      expect(providers[0].url, contains('South%20Korea'));
    });

    test('English name → used as-is', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
      );
      expect(providers[0].url, contains('Shinjuku%20Station'));
    });
  });

  group('Date parameters', () {
    test('Expedia: startDate/endDate', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers[0].url, contains('startDate=2026-04-01'));
      expect(providers[0].url, contains('endDate=2026-04-04'));
    });

    test('Hotels.com: startDate/endDate', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers[1].url, contains('startDate=2026-04-01'));
      expect(providers[1].url, contains('endDate=2026-04-04'));
    });

    test('Booking.com: checkin/checkout', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70, checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers[2].url, contains('checkin=2026-04-01'));
      expect(providers[2].url, contains('checkout=2026-04-04'));
    });
  });

  group('Hotels.com currency=USD', () {
    test('URL contains currency=USD', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
      );
      expect(providers[1].url, contains('currency=USD'));
    });
  });

  group('Budget: Expedia (total stay) vs Hotels.com (per night) — 3 nights', () {
    // checkIn=04/01, checkOut=04/04 = 3 nights

    test('under10000: Expedia price=200, Hotels price=67', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
        maxBudget: 'under10000',
      );
      final expediaUrl = providers[0].url;
      final hotelsUrl = providers[1].url;

      // Expedia: total = 10000 * 3 / 150 = 200
      expect(expediaUrl, contains('price=200'));
      // no min for under range
      expect(RegExp(r'price=0').hasMatch(expediaUrl), isFalse);

      // Hotels.com: per night = 10000 / 150 = 67
      expect(hotelsUrl, contains('price=67'));
    });

    test('10000-30000: Expedia price=200&price=600, Hotels price=67&price=200', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
        maxBudget: '10000-30000',
      );
      final expediaUrl = providers[0].url;
      final hotelsUrl = providers[1].url;

      // Expedia: min=10000*3/150=200, max=30000*3/150=600
      expect(expediaUrl, contains('price=200'));
      expect(expediaUrl, contains('price=600'));

      // Hotels.com: min=10000/150=67, max=30000/150=200
      expect(hotelsUrl, contains('price=67'));
      expect(hotelsUrl, contains('price=200'));

      print('✓ Expedia (total 3n): $expediaUrl');
      print('✓ Hotels.com (per night): $hotelsUrl');
    });

    test('30000-50000: Expedia price=600&price=1000, Hotels price=200&price=333', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
        maxBudget: '30000-50000',
      );
      final expediaUrl = providers[0].url;
      final hotelsUrl = providers[1].url;

      // Expedia: min=30000*3/150=600, max=50000*3/150=1000
      expect(expediaUrl, contains('price=600'));
      expect(expediaUrl, contains('price=1000'));

      // Hotels.com: min=30000/150=200, max=50000/150=333
      expect(hotelsUrl, contains('price=200'));
      expect(hotelsUrl, contains('price=333'));
    });

    test('over50000: Expedia price=1000&price=10000, Hotels price=333&price=10000', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
        maxBudget: 'over50000',
      );
      final expediaUrl = providers[0].url;
      final hotelsUrl = providers[1].url;

      // Expedia: min=50000*3/150=1000, max=Infinity→10000
      expect(expediaUrl, contains('price=1000'));
      expect(expediaUrl, contains('price=10000'));

      // Hotels.com: min=50000/150=333, max=Infinity→10000
      expect(hotelsUrl, contains('price=333'));
      expect(hotelsUrl, contains('price=10000'));

      print('✓ Expedia over50000: $expediaUrl');
      print('✓ Hotels.com over50000: $hotelsUrl');
    });

    test('any budget → no price params', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
        maxBudget: 'any',
      );
      expect(providers[0].url, isNot(contains('price=')));
      expect(providers[1].url, isNot(contains('price=')));
    });

    test('null budget → no price params', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
      );
      expect(providers[0].url, isNot(contains('price=')));
      expect(providers[1].url, isNot(contains('price=')));
    });
  });

  group('Budget: Booking.com (JPY nflt, per-room ×2)', () {
    test('10000-30000 → nflt=price=JPY-20000-60000-1', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
        maxBudget: '10000-30000',
      );
      // per-person×2: min=10000*2=20000, max=30000*2=60000
      expect(providers[2].url, contains('nflt=price%3DJPY-20000-60000-1'));
    });

    test('over50000 → nflt=price=JPY-100000-999999-1', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-04',
        maxBudget: 'over50000',
      );
      expect(providers[2].url, contains('nflt=price%3DJPY-100000-999999-1'));
    });
  });

  group('Expedia domain per locale', () {
    test('EN → expedia.com', () {
      final p = BookingProvider.buildMultiProviderUrls(locale: 'en', region: 'kanto', stationName: 'Shinjuku', lat: 35.69, lng: 139.70);
      expect(p[0].url, contains('www.expedia.com'));
    });

    test('FR → expedia.fr', () {
      final p = BookingProvider.buildMultiProviderUrls(locale: 'fr', region: 'kanto', stationName: 'Shinjuku', lat: 35.69, lng: 139.70);
      expect(p[0].url, contains('www.expedia.fr'));
    });
  });

  group('Budget: different night counts', () {
    test('1 night: 10000-30000 → Expedia price=67&price=200', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-02',
        maxBudget: '10000-30000',
      );
      // 1 night: min=10000*1/150=67, max=30000*1/150=200
      expect(providers[0].url, contains('price=67'));
      expect(providers[0].url, contains('price=200'));
    });

    test('5 nights: 10000-30000 → Expedia price=333&price=1000', () {
      final providers = BookingProvider.buildMultiProviderUrls(
        locale: 'en', region: 'kanto', stationName: 'Shinjuku',
        lat: 35.69, lng: 139.70,
        checkIn: '2026-04-01', checkOut: '2026-04-06',
        maxBudget: '10000-30000',
      );
      // 5 nights: min=10000*5/150=333, max=30000*5/150=1000
      expect(providers[0].url, contains('price=333'));
      expect(providers[0].url, contains('price=1000'));
      // Hotels.com stays per-night regardless of nights
      expect(providers[1].url, contains('price=67'));
      expect(providers[1].url, contains('price=200'));
    });
  });
}
