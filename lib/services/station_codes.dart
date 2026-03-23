import 'dart:convert';
import 'package:flutter/services.dart';

/// Station code lookup (e.g., 新宿 on 山手線 → JY17)
/// Matches web app's station-codes.ts
class StationCodes {
  static Map<String, dynamic>? _data;
  static Map<String, String>? _lineColors;

  static Future<void> preload() async {
    if (_data != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/station-codes.json');
      _data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _data = {};
    }
    try {
      final raw = await rootBundle.loadString('assets/data/line-colors.json');
      _lineColors = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      _lineColors = {};
    }
  }

  /// Get all station codes for a station name on its lines.
  /// Returns list of {line, code, color} maps.
  static List<Map<String, String>> getCodes(String stationName, List<String> lines) {
    if (_data == null) return [];
    final results = <Map<String, String>>[];

    for (final entry in _data!.entries) {
      final lineName = entry.key;
      final lineData = entry.value as Map<String, dynamic>;
      final prefix = lineData['prefix'] as String? ?? '';

      if (lineData.containsKey(stationName)) {
        final number = lineData[stationName] as String;
        final code = '$prefix$number';
        // Get line color
        final color = getLineColor(lineName);
        results.add({'line': lineName, 'code': code, 'color': color});
      }
    }

    return results;
  }

  /// Line color lookup — uses 358 colors from web's line-colors.ts
  static String getLineColor(String lineName) {
    return _lineColors?[lineName] ?? '#888888';
  }
}
