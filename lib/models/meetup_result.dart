import 'station.dart';

class StationDistance {
  final String participantStationId;
  final String participantStationName;
  final double distanceKm;
  final int estimatedMinutes;
  final List<RouteSegment> route;

  const StationDistance({
    required this.participantStationId,
    required this.participantStationName,
    required this.distanceKm,
    required this.estimatedMinutes,
    this.route = const [],
  });

  factory StationDistance.fromJson(Map<String, dynamic> json) {
    return StationDistance(
      // API uses stationId/stationName, not participantStationId
      participantStationId: json['stationId'] as String? ?? json['participantStationId'] as String? ?? '',
      participantStationName: json['stationName'] as String? ?? json['participantStationName'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      // Route is inside each distance, not at top level
      route: (json['route'] as List<dynamic>?)
              ?.map((e) => RouteSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RouteSegment {
  final String line;
  final String operator;
  final int minutes;
  final String color;
  final String fromStationId;
  final String toStationId;
  final String? fromStationName;
  final String? toStationName;
  final int? transferMinutes;

  const RouteSegment({
    required this.line,
    required this.operator,
    required this.minutes,
    required this.color,
    required this.fromStationId,
    required this.toStationId,
    this.fromStationName,
    this.toStationName,
    this.transferMinutes,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      line: json['line'] as String? ?? '',
      operator: json['operator'] as String? ?? '',
      minutes: json['minutes'] as int? ?? 0,
      color: json['color'] as String? ?? '#888888',
      fromStationId: json['fromStationId'] as String? ?? '',
      toStationId: json['toStationId'] as String? ?? '',
      fromStationName: json['fromStationName'] as String?,
      toStationName: json['toStationName'] as String?,
      transferMinutes: json['transferMinutes'] as int?,
    );
  }
}

class Venue {
  final String name;
  final String? genre;
  final String? budget;
  final String? address;
  final String? imageUrl;
  final String? url;
  final double? lat;
  final double? lng;
  final String? access;
  final String? catchText;

  const Venue({
    required this.name,
    this.genre,
    this.budget,
    this.address,
    this.imageUrl,
    this.url,
    this.lat,
    this.lng,
    this.access,
    this.catchText,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      name: json['name'] as String? ?? '',
      genre: json['genre'] as String?,
      budget: json['budget'] as String?,
      address: json['address'] as String?,
      // API uses 'photoUrl', not 'imageUrl'
      imageUrl: json['photoUrl'] as String? ?? json['imageUrl'] as String? ?? json['photo'] as String?,
      url: json['url'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      access: json['access'] as String?,
      catchText: json['catch'] as String? ?? json['genreCatch'] as String?,
    );
  }
}

class RecommendedStation {
  final Station station;
  final int rank;
  final List<StationDistance> distances;
  final double avgDistanceKm;
  final double maxDistanceKm;
  final int avgEstimatedMinutes;
  final int maxEstimatedMinutes;
  final double travelScore;
  final double funScore;
  final double finalScore;
  final List<Venue> venues;

  const RecommendedStation({
    required this.station,
    required this.rank,
    required this.distances,
    required this.avgDistanceKm,
    required this.maxDistanceKm,
    required this.avgEstimatedMinutes,
    required this.maxEstimatedMinutes,
    required this.travelScore,
    required this.funScore,
    required this.finalScore,
    required this.venues,
  });

  /// Get all route segments from all distances
  List<RouteSegment> get allRoutes {
    return distances.expand((d) => d.route).toList();
  }

  factory RecommendedStation.fromJson(Map<String, dynamic> json) {
    return RecommendedStation(
      station: Station.fromJson(json['station'] as Map<String, dynamic>),
      rank: json['rank'] as int? ?? 0,
      distances: (json['distances'] as List<dynamic>?)
              ?.map((e) => StationDistance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      avgDistanceKm: (json['avgDistanceKm'] as num?)?.toDouble() ?? 0,
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble() ?? 0,
      avgEstimatedMinutes: json['avgEstimatedMinutes'] as int? ?? 0,
      maxEstimatedMinutes: json['maxEstimatedMinutes'] as int? ?? 0,
      travelScore: (json['travelScore'] as num?)?.toDouble() ?? 0,
      funScore: (json['funScore'] as num?)?.toDouble() ?? 0,
      finalScore: (json['finalScore'] as num?)?.toDouble() ?? 0,
      venues: (json['venues'] as List<dynamic>?)
              ?.map((e) => Venue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MeetupResult {
  final List<RecommendedStation> stations;

  const MeetupResult({required this.stations});

  factory MeetupResult.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? json['stations'] as List<dynamic>? ?? [];
    return MeetupResult(
      stations: list
              .map((e) => RecommendedStation.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
