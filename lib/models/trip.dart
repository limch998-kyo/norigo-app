class Trip {
  final String id;
  final String name;
  final String? country;
  final String? checkIn;
  final String? checkOut;
  final String? searchMode;
  final String? maxBudget;
  final String? region;
  final bool isPinned;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.name,
    this.country,
    this.checkIn,
    this.checkOut,
    this.searchMode,
    this.maxBudget,
    this.region,
    this.isPinned = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String?,
      checkIn: json['checkIn'] as String?,
      checkOut: json['checkOut'] as String?,
      searchMode: json['searchMode'] as String?,
      maxBudget: json['maxBudget'] as String?,
      region: json['region'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'searchMode': searchMode,
        'maxBudget': maxBudget,
        'region': region,
        'isPinned': isPinned,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Trip copyWith({
    String? name,
    String? country,
    String? checkIn,
    String? checkOut,
    String? searchMode,
    String? maxBudget,
    String? region,
    bool? isPinned,
    String? notes,
    bool clearNotes = false,
    bool clearSearchMode = false,
    bool clearMaxBudget = false,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      searchMode: clearSearchMode ? null : (searchMode ?? this.searchMode),
      maxBudget: clearMaxBudget ? null : (maxBudget ?? this.maxBudget),
      region: region ?? this.region,
      isPinned: isPinned ?? this.isPinned,
      notes: clearNotes ? null : (notes ?? this.notes),
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
