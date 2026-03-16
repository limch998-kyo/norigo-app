import 'station.dart';
import 'hotel.dart';

class LandmarkDistance {
  final String landmarkName;
  final int estimatedMinutes;
  final double distanceKm;

  const LandmarkDistance({
    required this.landmarkName,
    required this.estimatedMinutes,
    required this.distanceKm,
  });

  factory LandmarkDistance.fromJson(Map<String, dynamic> json) {
    return LandmarkDistance(
      landmarkName: json['landmarkName'] as String? ?? json['name'] as String? ?? '',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StayArea {
  final Station station;
  final List<LandmarkDistance> landmarkDistances;
  final int avgEstimatedMinutes;
  final int maxEstimatedMinutes;
  final double travelScore;
  final double hotelScore;
  final double finalScore;
  final List<Hotel> hotels;
  final String? areaDescription;

  const StayArea({
    required this.station,
    required this.landmarkDistances,
    required this.avgEstimatedMinutes,
    required this.maxEstimatedMinutes,
    required this.travelScore,
    required this.hotelScore,
    required this.finalScore,
    required this.hotels,
    this.areaDescription,
  });

  factory StayArea.fromJson(Map<String, dynamic> json) {
    return StayArea(
      station: Station.fromJson(json['station'] as Map<String, dynamic>),
      landmarkDistances: (json['landmarkDistances'] as List<dynamic>?)
              ?.map((e) => LandmarkDistance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      avgEstimatedMinutes: json['avgEstimatedMinutes'] as int? ?? 0,
      maxEstimatedMinutes: json['maxEstimatedMinutes'] as int? ?? 0,
      travelScore: (json['travelScore'] as num?)?.toDouble() ?? 0,
      hotelScore: (json['hotelScore'] as num?)?.toDouble() ?? 0,
      finalScore: (json['finalScore'] as num?)?.toDouble() ?? 0,
      hotels: (json['hotels'] as List<dynamic>?)
              ?.map((e) => Hotel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      areaDescription: json['areaDescription'] as String? ??
          (json['areaProfile'] as Map<String, dynamic>?)?['description'] as String?,
    );
  }
}

class StayRecommendResult {
  final List<StayArea> areas;
  final bool split;
  final List<StayArea>? splitAreas;

  const StayRecommendResult({
    required this.areas,
    required this.split,
    this.splitAreas,
  });

  factory StayRecommendResult.fromJson(Map<String, dynamic> json) {
    // API returns 'results' not 'areas'
    final areaList = json['results'] as List<dynamic>? ?? json['areas'] as List<dynamic>? ?? [];
    return StayRecommendResult(
      areas: areaList
              .map((e) => StayArea.fromJson(e as Map<String, dynamic>))
              .toList(),
      split: json['split'] as bool? ?? false,
      splitAreas: (json['splitAreas'] as List<dynamic>?)
          ?.map((e) => StayArea.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
