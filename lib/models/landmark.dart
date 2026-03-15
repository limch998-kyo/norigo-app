class Landmark {
  final String slug;
  final String name;
  final String? nameEn;
  final double lat;
  final double lng;
  final String region;
  final String? description;
  final String? imageUrl;

  const Landmark({
    required this.slug,
    required this.name,
    this.nameEn,
    required this.lat,
    required this.lng,
    required this.region,
    this.description,
    this.imageUrl,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      slug: json['slug'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      region: json['region'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'nameEn': nameEn,
    'lat': lat,
    'lng': lng,
    'region': region,
  };
}
