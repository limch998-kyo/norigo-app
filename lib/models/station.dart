class Station {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameKo;
  final String? nameZh;
  final double lat;
  final double lng;
  final String region;
  final List<String> lines;

  const Station({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameKo,
    this.nameZh,
    required this.lat,
    required this.lng,
    required this.region,
    this.lines = const [],
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String?,
      nameKo: json['nameKo'] as String?,
      nameZh: json['nameZh'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      region: json['region'] as String? ?? 'kanto',
      lines: (json['lines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'region': region,
      };

  String localizedName(String locale) {
    switch (locale) {
      case 'en':
        return nameEn ?? name;
      case 'ko':
        return nameKo ?? name;
      case 'zh':
        return nameZh ?? name;
      default:
        return name;
    }
  }
}
