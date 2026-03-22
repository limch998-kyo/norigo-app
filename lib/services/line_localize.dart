import 'dart:convert';
import 'package:flutter/services.dart';

/// Localizes Japanese train line names to ko/en/zh
/// Matches web app's getLocalizedLineName() + cleanKoreanDisplay() + cleanEnglishDisplay()
class LineLocalizer {
  static Map<String, Map<String, String>>? _translations;
  static final Map<String, String> _cache = {};

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

  /// Check if string contains Japanese characters (Kanji, Hiragana, Katakana)
  static bool _hasJapanese(String s) {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(s);
  }

  /// Check if string contains Korean characters (Hangul)
  static bool _hasKorean(String s) {
    return RegExp(r'[\uAC00-\uD7AF\u3131-\u318E]').hasMatch(s);
  }

  /// Clean Korean display — remove direction info in parentheses
  static String _cleanKorean(String s) {
    return s
        .replaceAll(RegExp(r'\s*\([^)]*(?:→|=>|⇒|하행|상행)[^)]*\)'), '')
        .replaceAll(RegExp(r'\s*[:：]\s*.+$'), '')
        .trim();
  }

  /// Clean English display — remove Train prefix, direction patterns, parenthetical content
  static String _cleanEnglish(String s) {
    var cleaned = s;
    // Remove "Train" prefix
    cleaned = cleaned.replaceAll(RegExp(r'^Train\s+'), '');
    // Remove direction patterns like ": StationA => StationB"
    cleaned = cleaned.replaceAll(RegExp(r'\s*[:：]\s*[A-Za-z].*(?:=>|→|⇒).*$'), '');
    // Remove parenthetical content (old, north section, to X, For X)
    cleaned = cleaned.replaceAll(RegExp(r'\s*\([^)]*(?:old|north|south|to |For )[^)]*\)', caseSensitive: false), '');
    // Remove trailing "Local" if it's a suffix, not part of the name
    cleaned = cleaned.replaceAll(RegExp(r'\s+Local$'), '');
    // Remove direction info after colon
    cleaned = cleaned.replaceAll(RegExp(r'\s*[:：]\s*.+$'), '');
    return cleaned.trim();
  }

  /// Format line name with JR prefix (matching web's formatLineName)
  static String _formatLineName(String lineName, String localizedName, String? operator) {
    if (operator != null && operator.contains('旅客鉄道') && !localizedName.startsWith('JR')) {
      return 'JR $localizedName';
    }
    return localizedName;
  }

  /// Get localized line name. Returns original if no translation.
  static Future<String> localize(String lineName, String locale) async {
    await _load();
    return localizeSync(lineName, locale);
  }

  /// Synchronous version using cached data (call after preload)
  static String localizeSync(String lineName, String locale, {String? operator}) {
    final cacheKey = '$lineName|$locale';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final entry = _translations?[lineName];
    String result;

    if (entry != null) {
      // Get locale-specific translation
      var localized = entry[locale] ?? entry['en'] ?? lineName;

      // For Japanese locale: if result has Korean chars, use English instead
      if (locale == 'ja' && _hasKorean(localized)) {
        localized = entry['en'] ?? lineName;
      }

      // Apply locale-specific cleanup
      if (locale == 'ko') {
        localized = _cleanKorean(localized);
      } else if (locale != 'ja') {
        localized = _cleanEnglish(localized);
      }

      result = _formatLineName(lineName, localized, operator);
    } else {
      // No translation found
      if (locale != 'ja' && _hasJapanese(lineName)) {
        // Non-Japanese locale but Japanese line name → try to clean it
        // Return as-is but remove direction info
        result = lineName
            .replaceAll(RegExp(r'\s*[:：]\s*.+$'), '')
            .replaceAll(RegExp(r'\s*\([^)]*(?:→|=>|⇒)[^)]*\)'), '')
            .trim();
      } else {
        result = lineName;
      }
    }

    _cache[cacheKey] = result;
    return result;
  }

  /// Pre-load translations (call in main or initState)
  static Future<void> preload() => _load();
}
