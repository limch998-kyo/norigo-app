/// Locale-aware string helper — covers all supported UI languages.
///
/// Fallback order: locale → en → first non-null value. Traditional Chinese
/// (`zh-TW`, Taiwan/Hong Kong) falls back to Simplified Chinese (`zh`) unless a
/// `zhTw` override is given, matching the web's "zh-based + Traditional/currency
/// substitution" approach.
String tr(
  String locale, {
  required String en,
  String? ja,
  String? ko,
  String? zh,
  String? zhTw,
  String? fr,
}) {
  switch (locale) {
    case 'ja':
      return ja ?? en;
    case 'ko':
      return ko ?? en;
    case 'zh':
      return zh ?? en;
    case 'zh-TW':
      return zhTw ?? zh ?? en;
    case 'fr':
      return fr ?? en;
    default:
      return en;
  }
}

/// Lookup a value from a locale map like {'ja': '...', 'ko': '...', 'en': '...'}.
/// `zh-TW` falls back to `zh`; everything else falls back to 'en', never 'ja'.
String trMap(String locale, Map<String, String> map) {
  return map[locale] ??
      (locale == 'zh-TW' ? map['zh'] : null) ??
      map['en'] ??
      map.values.first;
}

/// Pick a locale value from a map whose values may be String or dynamic
/// (e.g. AppConstants label maps). `zh-TW` falls back to `zh`, then 'en', then
/// the first available value, then [fallback]. Use this instead of the raw
/// `map[locale] ?? map['en']` pattern so Traditional Chinese never leaks to
/// English.
String pickLoc(Map<String, dynamic> map, String locale, {String fallback = ''}) {
  final v = map[locale] ??
      (locale == 'zh-TW' ? map['zh'] : null) ??
      map['en'] ??
      (map.values.isNotEmpty ? map.values.first : null);
  return (v ?? fallback).toString();
}
