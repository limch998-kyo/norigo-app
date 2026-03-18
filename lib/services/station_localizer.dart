import 'dart:convert';
import 'package:flutter/services.dart';

/// Offline station name localization using bundled data.
class StationLocalizer {
  static Map<String, dynamic>? _names;

  static Future<void> preload() async {
    if (_names != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/station-names.json');
      _names = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _names = {};
    }
  }

  /// Get localized station name by ID
  static String? getLocalizedName(String stationId, String locale) {
    if (_names == null) return null;
    final entry = _names![stationId];
    if (entry == null) return null;
    return entry[locale] as String?;
  }

  /// Get coordinates for a station by ID
  static (double, double)? getCoordinates(String stationId) {
    if (_names == null) return null;
    final entry = _names![stationId];
    if (entry == null) return null;
    final lat = entry['lat'];
    final lng = entry['lng'];
    if (lat == null || lng == null) return null;
    return ((lat as num).toDouble(), (lng as num).toDouble());
  }
}
