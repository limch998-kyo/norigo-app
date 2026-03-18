import '../services/station_localizer.dart';

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
    // Try model fields first, then bundled station names
    switch (locale) {
      case 'en':
        return nameEn ?? StationLocalizer.getLocalizedName(id, 'en') ?? name;
      case 'ko':
        return nameKo ?? StationLocalizer.getLocalizedName(id, 'ko') ?? name;
      case 'zh':
        return nameZh ?? StationLocalizer.getLocalizedName(id, 'zh') ?? name;
      default:
        return name;
    }
  }
}
