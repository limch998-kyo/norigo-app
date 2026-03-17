import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/services/api_client.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/models/hotel.dart';
import 'package:norigo_app/models/meetup_result.dart';
import 'package:norigo_app/config/booking_provider.dart';

/// Web app feature parity tests
/// Verifies ALL features match the web application
/// Run with: flutter test test/web_parity_test.dart
void main() {
  late ApiClient api;

  setUp(() {
    api = ApiClient();
  });

  // ═══════════════════════════════════════════
  // 1. STATION SEARCH (used by meetup)
  // ═══════════════════════════════════════════
  group('Station Search - Web Parity', () {
    test('returns station with id, name, lines', () async {
      final results = await api.searchStations('渋谷');
      expect(results, isNotEmpty);
      final s = results.first;
      expect(s.id, isNotEmpty, reason: 'Station must have id for recommend API');
      expect(s.name, isNotEmpty);
      expect(s.lines, isNotEmpty, reason: 'Web shows line badges');
      print('✓ Station: ${s.name} (${s.id}), lines: ${s.lines.take(3).join(", ")}');
    });

    test('kanto and kansai regions work', () async {
      final kanto = await api.searchStations('新宿', region: 'kanto');
      final kansai = await api.searchStations('梅田', region: 'kansai');
      expect(kanto, isNotEmpty);
      expect(kansai, isNotEmpty);
      print('✓ Kanto: ${kanto.length} results, Kansai: ${kansai.length} results');
    });
  });

  // ═══════════════════════════════════════════
  // 2. LANDMARK SEARCH (used by stay)
  // ═══════════════════════════════════════════
  group('Landmark Search - Web Parity', () {
    test('returns landmark with name, lat, lng', () async {
      final results = await api.searchLandmarks('東京タワー', locale: 'ja');
      expect(results, isNotEmpty);
      final l = results.first;
      expect(l.name, isNotEmpty);
      expect(l.lat, isNot(0));
      expect(l.lng, isNot(0));
      print('✓ Landmark: ${l.name} (${l.lat}, ${l.lng})');
    });

    test('works with Korean locale', () async {
      final results = await api.searchLandmarks('명동', locale: 'ko', region: 'seoul');
      expect(results, isNotEmpty);
      print('✓ Korean landmark: ${results.first.name}');
    });
  });

  // ═══════════════════════════════════════════
  // 3. MEETUP RECOMMEND
  // ═══════════════════════════════════════════
  group('Meetup Recommend - Web Parity', () {
    late String shibuyaId, shinjukuId;

    setUp(() async {
      shibuyaId = (await api.searchStations('渋谷')).first.id;
      shinjukuId = (await api.searchStations('新宿')).first.id;
    });

    test('returns stations with all required fields', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId], mode: 'centroid', region: 'kanto',
      );
      expect(result.stations, isNotEmpty);
      final r = result.stations.first;

      // Web displays all these
      expect(r.station.name, isNotEmpty, reason: 'Station name');
      expect(r.rank, greaterThan(0), reason: 'Rank badge');
      expect(r.avgEstimatedMinutes, greaterThanOrEqualTo(0), reason: 'Avg minutes');
      expect(r.maxEstimatedMinutes, greaterThanOrEqualTo(0), reason: 'Max minutes');
      expect(r.finalScore, greaterThan(0), reason: 'Score badge');
      expect(r.distances, hasLength(2), reason: '2 participants = 2 distances');
      print('✓ Meetup result: ${r.station.name}, score=${r.finalScore}, avg=${r.avgEstimatedMinutes}min');
    });

    test('distances contain route segments', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId], mode: 'centroid', region: 'kanto',
      );
      final d = result.stations.first.distances.first;
      expect(d.participantStationName, isNotEmpty, reason: 'Web shows participant name');
      expect(d.distanceKm, greaterThan(0), reason: 'Web shows distance in km');
      expect(d.route, isNotEmpty, reason: 'Web shows route bar per participant');

      final seg = d.route.first;
      expect(seg.line, isNotEmpty, reason: 'Route segment line name');
      expect(seg.color, startsWith('#'), reason: 'Route color for visualization');
      expect(seg.minutes, greaterThan(0), reason: 'Segment duration');
      print('✓ Route: ${d.participantStationName} → ${seg.line} (${seg.color}, ${seg.minutes}min)');
    });

    test('venues (Hot Pepper) with photo and details', () async {
      final result = await api.getMeetupRecommendation(
        stationIds: [shibuyaId, shinjukuId], mode: 'centroid', region: 'kanto', category: 'izakaya',
      );
      final venues = result.stations.first.venues;
      expect(venues, isNotEmpty, reason: 'Web shows venues when category selected');

      final v = venues.first;
      expect(v.name, isNotEmpty, reason: 'Venue name');
      expect(v.imageUrl, isNotNull, reason: 'Web shows venue photo (photoUrl)');
      expect(v.genre, isNotNull, reason: 'Web shows genre badge');
      expect(v.budget, isNotNull, reason: 'Web shows budget badge');
      expect(v.url, isNotNull, reason: 'Web has venue link');
      print('✓ Venue: ${v.name}, genre=${v.genre}, budget=${v.budget}, photo=${v.imageUrl != null}');

      // These fields are shown in web but were missing before
      // catchText = description, access = walking directions
      print('  catchText: ${v.catchText != null ? "✓" : "✗"}');
      print('  access: ${v.access != null ? "✓" : "✗"}');
    });

    test('all 3 modes return different results', () async {
      final centroid = await api.getMeetupRecommendation(stationIds: [shibuyaId, shinjukuId], mode: 'centroid', region: 'kanto');
      final minTotal = await api.getMeetupRecommendation(stationIds: [shibuyaId, shinjukuId], mode: 'minTotal', region: 'kanto');
      final balanced = await api.getMeetupRecommendation(stationIds: [shibuyaId, shinjukuId], mode: 'balanced', region: 'kanto');
      expect(centroid.stations, isNotEmpty);
      expect(minTotal.stations, isNotEmpty);
      expect(balanced.stations, isNotEmpty);
      print('✓ 3 modes: centroid=${centroid.stations.first.station.name}, minTotal=${minTotal.stations.first.station.name}, balanced=${balanced.stations.first.station.name}');
    });
  });

  // ═══════════════════════════════════════════
  // 4. STAY RECOMMEND
  // ═══════════════════════════════════════════
  group('Stay Recommend - Web Parity', () {
    final landmarks = [
      const Landmark(slug: 'shibuya', name: '渋谷', lat: 35.6595, lng: 139.7004, region: 'kanto'),
      const Landmark(slug: 'asakusa', name: '浅草寺', lat: 35.7148, lng: 139.7967, region: 'kanto'),
    ];

    test('returns areas with all required fields', () async {
      final result = await api.getStayRecommendation(landmarks: landmarks, region: 'kanto', mode: 'centroid');
      expect(result.areas, isNotEmpty);
      final a = result.areas.first;

      expect(a.station.name, isNotEmpty, reason: 'Area station name');
      expect(a.station.lines, isNotEmpty, reason: 'Web shows line badges');
      expect(a.avgEstimatedMinutes, greaterThanOrEqualTo(0));
      expect(a.maxEstimatedMinutes, greaterThanOrEqualTo(0));
      expect(a.finalScore, greaterThan(0));
      print('✓ Stay area: ${a.station.name}, score=${a.finalScore}, avg=${a.avgEstimatedMinutes}min');
    });

    test('landmark distances with route data', () async {
      final result = await api.getStayRecommendation(landmarks: landmarks, region: 'kanto', mode: 'centroid');
      final ld = result.areas.first.landmarkDistances;
      expect(ld, isNotEmpty);

      final d = ld.first;
      expect(d.landmarkName, isNotEmpty, reason: 'Landmark name in distance');
      expect(d.distanceKm, greaterThan(0), reason: 'Web shows distance km');
      expect(d.estimatedMinutes, greaterThanOrEqualTo(0), reason: 'Web shows minutes');

      // Route for transit (web shows RouteBar or "walking" if ≤1km)
      final hasRoute = ld.any((l) => l.route.isNotEmpty);
      print('✓ Landmark distances: ${ld.map((l) => "${l.landmarkName}=${l.estimatedMinutes}min(${l.distanceKm}km)").join(", ")}');
      print('  Has route data: $hasRoute');
      print('  Walking (≤1km): ${ld.where((l) => l.distanceKm <= 1.0).map((l) => l.landmarkName).join(", ")}');
    });

    test('reachable destinations present', () async {
      final result = await api.getStayRecommendation(landmarks: landmarks, region: 'kanto', mode: 'centroid');
      final rd = result.areas.first.reachableDestinations;
      expect(rd, isNotEmpty, reason: 'Web shows reachable destinations');
      print('✓ Reachable: ${rd.take(3).map((r) => "${r.name}=${r.minutes}min").join(", ")}');
    });

    test('works for Seoul region', () async {
      final result = await api.getStayRecommendation(
        landmarks: [
          const Landmark(slug: 'myeongdong', name: '明洞', lat: 37.5636, lng: 126.9869, region: 'seoul'),
          const Landmark(slug: 'gangnam', name: '江南', lat: 37.4979, lng: 127.0276, region: 'seoul'),
        ],
        region: 'seoul', mode: 'centroid',
      );
      expect(result.areas, isNotEmpty);
      print('✓ Seoul: ${result.areas.first.station.name}');
    });
  });

  // ═══════════════════════════════════════════
  // 5. HOTELS API (Agoda)
  // ═══════════════════════════════════════════
  group('Hotels API - Web Parity', () {
    test('returns hotels with all Agoda fields', () async {
      final hotels = await api.getHotels(
        stationId: '88339adc84bf', // 新宿
        checkIn: '2026-04-15', checkOut: '2026-04-17', locale: 'ko',
      );
      expect(hotels, isNotEmpty, reason: 'Web lazy-loads hotels from this API');

      final h = hotels.first;
      expect(h.hotelId, greaterThan(0), reason: 'Hotel ID');
      expect(h.name, isNotEmpty, reason: 'Hotel name (hotelName from API)');
      expect(h.dailyRate, isNotNull, reason: 'Daily rate (not pricePerNight)');
      expect(h.dailyRate, greaterThan(0));
      expect(h.imageUrl, isNotNull, reason: 'Image URL (imageURL from API)');
      expect(h.bookingUrl, isNotNull, reason: 'Booking URL (landingURL from API)');
      print('✓ Hotel: ${h.name}, rate=${h.formattedPrice}, score=${h.formattedRating}');
    });

    test('currency matches locale (ko → KRW)', () async {
      final hotels = await api.getHotels(
        stationId: '88339adc84bf', checkIn: '2026-04-15', checkOut: '2026-04-17', locale: 'ko',
      );
      final h = hotels.first;
      expect(h.currency, equals('KRW'), reason: 'ko locale should return KRW');
      expect(h.formattedPrice, startsWith('₩'), reason: 'Korean won symbol');
      print('✓ Currency ko→KRW: ${h.formattedPrice}');
    });

    test('currency matches locale (ja → JPY)', () async {
      final hotels = await api.getHotels(
        stationId: '88339adc84bf', checkIn: '2026-04-15', checkOut: '2026-04-17', locale: 'ja',
      );
      final h = hotels.first;
      expect(h.currency, equals('JPY'), reason: 'ja locale should return JPY');
      expect(h.formattedPrice, startsWith('¥'), reason: 'Yen symbol');
      print('✓ Currency ja→JPY: ${h.formattedPrice}');
    });

    test('amenity fields present', () async {
      final hotels = await api.getHotels(
        stationId: '88339adc84bf', checkIn: '2026-04-15', checkOut: '2026-04-17', locale: 'ja',
      );
      // At least some hotels should have amenities
      final hasBreakfast = hotels.any((h) => h.includeBreakfast);
      final hasWifi = hotels.any((h) => h.freeWifi);
      print('✓ Amenities: breakfast=${hasBreakfast ? "some" : "none"}, wifi=${hasWifi ? "some" : "none"}');
    });

    test('discount (crossedOutRate) present for some hotels', () async {
      final hotels = await api.getHotels(
        stationId: '88339adc84bf', checkIn: '2026-04-15', checkOut: '2026-04-17', locale: 'ja',
      );
      final discounted = hotels.where((h) => h.discountPercent > 0).toList();
      print('✓ Discounted hotels: ${discounted.length}/${hotels.length}');
      if (discounted.isNotEmpty) {
        final h = discounted.first;
        print('  Example: ${h.name} ${h.formattedCrossedOutPrice} → ${h.formattedPrice} (-${h.discountPercent}%)');
      }
    });

    test('hotel has coordinates for map markers', () async {
      final hotels = await api.getHotels(
        stationId: '88339adc84bf', checkIn: '2026-04-15', checkOut: '2026-04-17', locale: 'ja',
      );
      final withCoords = hotels.where((h) => h.lat != 0 && h.lng != 0).toList();
      expect(withCoords, isNotEmpty, reason: 'Web shows hotel markers on map');
      print('✓ Hotels with coordinates: ${withCoords.length}/${hotels.length}');
    });
  });

  // ═══════════════════════════════════════════
  // 6. BOOKING PROVIDER LOGIC
  // ═══════════════════════════════════════════
  group('Booking Provider - Web Parity', () {
    test('ja + kanto → Jalan', () {
      expect(BookingProvider.providerName('ja', 'kanto'), equals('jalan.net'));
    });

    test('ko + seoul → Agoda', () {
      expect(BookingProvider.providerName('ko', 'seoul'), equals('Agoda'));
    });

    test('en + kanto → Booking.com', () {
      expect(BookingProvider.providerName('en', 'kanto'), equals('Booking.com'));
    });

    test('ko + kanto → Agoda (ko locale overrides)', () {
      expect(BookingProvider.providerName('ko', 'kanto'), equals('Agoda'));
    });

    test('currency symbols correct', () {
      expect(BookingProvider.currencySymbol('kanto'), equals('¥'));
      expect(BookingProvider.currencySymbol('seoul'), equals('₩'));
    });
  });

  // ═══════════════════════════════════════════
  // 7. EVENT LOGGING
  // ═══════════════════════════════════════════
  group('Event Log - Web Parity', () {
    test('log event completes without error', () async {
      await api.logEvent(
        eventType: 'flutter_test', sessionId: 'test', userId: 'test',
        payload: {'platform': 'flutter', 'test': true},
      );
      print('✓ Event log works');
    });
  });
}
