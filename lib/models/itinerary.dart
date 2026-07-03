import 'stay_area.dart';

/// Result of POST /api/trip/optimize — a multi-day itinerary with a hotel base
/// per cluster. Mirrors the web `ItineraryResponse` type.

class ItineraryLandmark {
  final String name;
  final double lat;
  final double lng;
  final String? slug;

  const ItineraryLandmark({
    required this.name,
    required this.lat,
    required this.lng,
    this.slug,
  });

  factory ItineraryLandmark.fromJson(Map<String, dynamic> j) =>
      ItineraryLandmark(
        name: j['name'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        slug: j['slug'] as String?,
      );
}

class ItineraryDay {
  final String date; // YYYY-MM-DD
  final int dayNumber; // 1-indexed
  final List<ItineraryLandmark> landmarks;

  const ItineraryDay({
    required this.date,
    required this.dayNumber,
    required this.landmarks,
  });

  factory ItineraryDay.fromJson(Map<String, dynamic> j) => ItineraryDay(
        date: j['date'] as String? ?? '',
        dayNumber: (j['dayNumber'] as num?)?.toInt() ?? 0,
        landmarks: (j['landmarks'] as List<dynamic>?)
                ?.map((e) => ItineraryLandmark.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class HotelCluster {
  final List<ItineraryLandmark> landmarks;
  final List<ItineraryDay> days;
  final List<StayArea> hotelRecommendations;
  final int nights;

  const HotelCluster({
    required this.landmarks,
    required this.days,
    required this.hotelRecommendations,
    required this.nights,
  });

  /// Top recommended stay area for this cluster (null if none returned).
  StayArea? get hotelBase =>
      hotelRecommendations.isNotEmpty ? hotelRecommendations.first : null;

  factory HotelCluster.fromJson(Map<String, dynamic> j) => HotelCluster(
        landmarks: (j['landmarks'] as List<dynamic>?)
                ?.map((e) => ItineraryLandmark.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        days: (j['days'] as List<dynamic>?)
                ?.map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        hotelRecommendations: (j['hotelRecommendations'] as List<dynamic>?)
                ?.map((e) => StayArea.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nights: (j['nights'] as num?)?.toInt() ?? 0,
      );
}

class ItineraryResult {
  final List<HotelCluster> clusters;
  final bool split; // landmarks split into 2 hotel zones
  final int totalDays;
  final String? checkIn;
  final String? checkOut;
  final Map<String, String> localNames;

  const ItineraryResult({
    required this.clusters,
    required this.split,
    required this.totalDays,
    this.checkIn,
    this.checkOut,
    this.localNames = const {},
  });

  factory ItineraryResult.fromJson(Map<String, dynamic> j) => ItineraryResult(
        clusters: (j['clusters'] as List<dynamic>?)
                ?.map((e) => HotelCluster.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        split: j['split'] as bool? ?? false,
        totalDays: (j['totalDays'] as num?)?.toInt() ?? 0,
        checkIn: j['checkIn'] as String?,
        checkOut: j['checkOut'] as String?,
        localNames: (j['localNames'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      );
}
