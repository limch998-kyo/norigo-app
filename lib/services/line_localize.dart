import 'dart:convert';
import 'package:flutter/services.dart';

/// Localizes Japanese train line names to ko/en/zh
/// Matches web app's getLocalizedLineName()
class LineLocalizer {
  static Map<String, Map<String, String>>? _translations;

  static Future<void> _load() async {
    if (_translations != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/line-translations.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _translations = data.map((k, v) => MapEntry(k, Map<String, String>.from(v as Map)));
    } catch (_) {
      _translations = {};
    }
  }

  /// Get localized line name. Returns original if no translation.
  static Future<String> localize(String lineName, String locale) async {
    // Japanese locale: return as-is (already in Japanese)
    if (locale == 'ja') return lineName;

    await _load();
    final entry = _translations?[lineName];
    if (entry == null) return lineName;

    final localized = entry[locale] ?? entry['en'] ?? lineName;
    // Clean direction info
    return localized
        .replaceAll(RegExp(r'\s*[:：]\s*.+$'), '')
        .replaceAll(RegExp(r'\s*\([^)]*(?:→|=>|⇒|하행|상행)[^)]*\)'), '')
        .trim();
  }

  /// Synchronous version using cached data (call after _load)
  static String localizeSync(String lineName, String locale) {
    if (locale == 'ja') return lineName;
    final entry = _translations?[lineName];
    if (entry == null) return lineName;
    final localized = entry[locale] ?? entry['en'] ?? lineName;
    return localized.replaceAll(RegExp(r'\s*[:：]\s*.+$'), '').trim();
  }

  /// Pre-load translations (call in main or initState)
  static Future<void> preload() => _load();
}
