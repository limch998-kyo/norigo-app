/// Locale-aware string helper — ensures all 4 supported languages are covered.
/// Falls back: locale → en → first non-null value.
String tr(
  String locale, {
  required String en,
  String? ja,
  String? ko,
  String? zh,
}) {
  switch (locale) {
    case 'ja':
      return ja ?? en;
    case 'ko':
      return ko ?? en;
    case 'zh':
      return zh ?? en;
    default:
      return en;
  }
}
