import 'dart:convert';
import 'package:flutter/services.dart';

/// Offline landmark name localization using bundled static data.
/// Maps coordinates → multilingual names instantly (no API calls).
class LandmarkLocalizer {
  static List<Map<String, dynamic>>? _allLandmarks;
  static final Map<String, String> _slugToRegion = {};

  static Future<void> _load() async {
    if (_allLandmarks != null) return;
    _allLandmarks = [];
    for (final region in ['kanto', 'kansai', 'kyushu', 'seoul', 'busan']) {
      try {
        final raw = await rootBundle.loadString('assets/data/landmarks-$region.json');
        final list = jsonDecode(raw) as List<dynamic>;
        // Tag each landmark with its region
        for (final item in list) {
          final map = Map<String, dynamic>.from(item as Map);
          map['_region'] = region;
          _allLandmarks!.add(map);
          // Also index by slug for fast region lookup
          final slug = map['slug'] as String?;
          if (slug != null) _slugToRegion[slug] = region;
        }
      } catch (_) {}
    }
  }

  /// Pre-load all landmark data (call at app startup)
  static Future<void> preload() => _load();

  /// Find a landmark by coordinates (within ~100m tolerance)
  static Map<String, dynamic>? _findByCoords(double lat, double lng) {
    if (_allLandmarks == null) return null;
    Map<String, dynamic>? best;
    double bestDist = double.infinity;
    for (final lm in _allLandmarks!) {
      final lmLat = (lm['lat'] as num).toDouble();
      final lmLng = (lm['lng'] as num).toDouble();
      final d = (lmLat - lat).abs() + (lmLng - lng).abs();
      if (d < bestDist) {
        bestDist = d;
        best = lm;
      }
    }
    // ~0.002 degrees ≈ ~200m tolerance
    return (best != null && bestDist < 0.002) ? best : null;
  }

  /// Find by slug
  static Map<String, dynamic>? _findBySlug(String slug) {
    if (_allLandmarks == null) return null;
    final lower = slug.toLowerCase();
    for (final lm in _allLandmarks!) {
      if ((lm['slug'] as String?)?.toLowerCase() == lower) return lm;
      if ((lm['romaji'] as String?)?.toLowerCase() == lower) return lm;
    }
    return null;
  }

  /// Get the localized name for a landmark.
  /// Tries slug match first, then coordinate match.
  /// Returns null if no match found.
  static String? getLocalizedName({
    required String locale,
    String? slug,
    String? name,
    double? lat,
    double? lng,
  }) {
    if (_allLandmarks == null) return null;

    // Try slug first
    Map<String, dynamic>? entry;
    if (slug != null) {
      entry = _findBySlug(slug);
    }
    // Try name match (slug might be a display name like '渋谷')
    if (entry == null && name != null) {
      entry = _findByName(name);
    }
    if (entry == null && slug != null && slug != name) {
      entry = _findByName(slug);
    }
    // Fallback: coordinate match
    if (entry == null && lat != null && lng != null) {
      entry = _findByCoords(lat, lng);
    }
    if (entry == null) return null;

    // Return locale-specific name
    switch (locale) {
      case 'ko':
        return entry['nameKo'] as String? ?? entry['nameEn'] as String? ?? entry['name'] as String?;
      case 'en':
      case 'fr': // French uses English names
        return entry['nameEn'] as String? ?? entry['name'] as String?;
      case 'zh':
        return entry['nameZh'] as String? ?? entry['nameEn'] as String? ?? entry['name'] as String?;
      case 'ja':
        return entry['name'] as String?;
      default:
        return entry['nameEn'] as String? ?? entry['name'] as String?;
    }
  }

  /// Find by any name field (name, nameKo, nameEn)
  static Map<String, dynamic>? _findByName(String name) {
    if (_allLandmarks == null) return null;
    for (final lm in _allLandmarks!) {
      if (lm['name'] == name || lm['nameKo'] == name || lm['nameEn'] == name) {
        return lm;
      }
    }
    return null;
  }

  /// Get all landmarks for a region (for popular spots)
  static List<Map<String, dynamic>>? getLandmarksForRegion(String region) {
    if (_allLandmarks == null) return null;
    return _allLandmarks!.where((lm) => lm['_region'] == region).toList();
  }

  /// Get coordinates for a landmark by slug or name
  static (double, double)? getCoordinates({String? slug, String? name}) {
    if (_allLandmarks == null) return null;

    // Try slug first
    if (slug != null && slug.isNotEmpty) {
      final entry = _findBySlug(slug);
      if (entry != null) {
        return ((entry['lat'] as num).toDouble(), (entry['lng'] as num).toDouble());
      }
    }

    // Try name match (any locale)
    if (name != null && name.isNotEmpty) {
      final lower = name.toLowerCase();
      for (final lm in _allLandmarks!) {
        if ((lm['name'] as String?)?.toLowerCase() == lower) return ((lm['lat'] as num).toDouble(), (lm['lng'] as num).toDouble());
        if ((lm['nameEn'] as String?)?.toLowerCase() == lower) return ((lm['lat'] as num).toDouble(), (lm['lng'] as num).toDouble());
        if ((lm['nameKo'] as String?)?.toLowerCase() == lower) return ((lm['lat'] as num).toDouble(), (lm['lng'] as num).toDouble());
        if ((lm['nameZh'] as String?)?.toLowerCase() == lower) return ((lm['lat'] as num).toDouble(), (lm['lng'] as num).toDouble());
      }
    }

    return null;
  }

  /// Get the region for a landmark by slug or name
  static String? getRegion({String? slug, String? name}) {
    if (_allLandmarks == null) return null;

    // Fast lookup by slug
    if (slug != null && slug.isNotEmpty && _slugToRegion.containsKey(slug)) {
      return _slugToRegion[slug];
    }

    Map<String, dynamic>? entry;
    if (slug != null && slug.isNotEmpty) entry = _findBySlug(slug);
    if (entry == null && name != null && name.isNotEmpty) {
      final lower = name.toLowerCase();
      for (final lm in _allLandmarks!) {
        if ((lm['name'] as String?)?.toLowerCase() == lower ||
            (lm['nameEn'] as String?)?.toLowerCase() == lower ||
            (lm['nameKo'] as String?)?.toLowerCase() == lower ||
            (lm['nameZh'] as String?)?.toLowerCase() == lower) {
          entry = lm;
          break;
        }
      }
    }

    return entry?['_region'] as String?;
  }

  /// Batch translate: given a list of (slug, lat, lng), return locale-specific names
  static Map<String, String> batchLocalize({
    required String locale,
    required List<({String slug, double lat, double lng})> items,
  }) {
    final result = <String, String>{};
    for (final item in items) {
      final name = getLocalizedName(
        locale: locale,
        slug: item.slug,
        lat: item.lat,
        lng: item.lng,
      );
      if (name != null) {
        result[item.slug] = name;
      }
    }
    return result;
  }
}
