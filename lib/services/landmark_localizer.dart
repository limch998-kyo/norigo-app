import 'dart:convert';
import 'package:flutter/services.dart';

/// Offline landmark name localization using bundled static data.
/// Maps coordinates → multilingual names instantly (no API calls).
class LandmarkLocalizer {
  static List<Map<String, dynamic>>? _allLandmarks;

  static Future<void> _load() async {
    if (_allLandmarks != null) return;
    _allLandmarks = [];
    for (final region in ['kanto', 'kansai', 'seoul', 'busan']) {
      try {
        final raw = await rootBundle.loadString('assets/data/landmarks-$region.json');
        final list = jsonDecode(raw) as List<dynamic>;
        _allLandmarks!.addAll(list.cast<Map<String, dynamic>>());
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
    double? lat,
    double? lng,
  }) {
    if (_allLandmarks == null) return null;

    // Try slug first
    Map<String, dynamic>? entry;
    if (slug != null) {
      entry = _findBySlug(slug);
    }
    // Fallback: coordinate match
    if (entry == null && lat != null && lng != null) {
      entry = _findByCoords(lat, lng);
    }
    if (entry == null) return null;

    // Return locale-specific name
    switch (locale) {
      case 'ko':
        return entry['nameKo'] as String? ?? entry['name'] as String?;
      case 'en':
        return entry['nameEn'] as String? ?? entry['name'] as String?;
      case 'zh':
        return entry['nameZh'] as String? ?? entry['name'] as String?;
      case 'ja':
      default:
        return entry['name'] as String?; // 'name' is Japanese by default
    }
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
