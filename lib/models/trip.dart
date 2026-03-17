class Trip {
  final String id;
  final String name;
  final String? country;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.name,
    this.country,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Trip copyWith({String? name, String? country}) {
    return Trip(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class TripItem {
  final String slug;
  final String name;
  final double lat;
  final double lng;
  final String region;
  final String tripId;
  final DateTime addedAt;

  const TripItem({
    required this.slug,
    required this.name,
    required this.lat,
    required this.lng,
    required this.region,
    required this.tripId,
    required this.addedAt,
  });

  factory TripItem.fromJson(Map<String, dynamic> json) {
    return TripItem(
      slug: json['slug'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      region: json['region'] as String,
      tripId: json['tripId'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'lat': lat,
        'lng': lng,
        'region': region,
        'tripId': tripId,
        'addedAt': addedAt.toIso8601String(),
      };
}
