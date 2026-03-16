/// Determines booking provider based on locale and region.
/// Matches web app logic:
///   - Japan region + ja locale → Jalan
///   - Korea region OR ko locale → Agoda
///   - Fallback → Booking.com
class BookingProvider {
  static const _jalanBaseUrl = 'https://www.jalan.net';
  static const _agodaBaseUrl = 'https://www.agoda.com';
  static const _bookingBaseUrl = 'https://www.booking.com';

  static const _koreaRegions = ['seoul', 'busan'];
  static const _japanRegions = ['kanto', 'kansai'];

  /// Get the provider name for display
  static String providerName(String locale, String region) {
    if (_japanRegions.contains(region) && locale == 'ja') return 'jalan.net';
    if (_koreaRegions.contains(region) || locale == 'ko') return 'Agoda';
    return 'Booking.com';
  }

  /// Get the provider label for attribution
  static String providerAttribution(String locale, String region) {
    final name = providerName(locale, region);
    return 'Powered by $name';
  }

  /// Build a search URL for the booking provider
  static String buildSearchUrl({
    required String locale,
    required String region,
    required String stationName,
    String? checkIn,
    String? checkOut,
  }) {
    if (_japanRegions.contains(region) && locale == 'ja') {
      return _buildJalanUrl(stationName, checkIn, checkOut);
    }
    if (_koreaRegions.contains(region) || locale == 'ko') {
      return _buildAgodaUrl(stationName, locale, checkIn, checkOut);
    }
    return _buildBookingUrl(stationName, locale, checkIn, checkOut);
  }

  static String _buildJalanUrl(String query, String? checkIn, String? checkOut) {
    final params = <String, String>{
      'screenId': 'UWW3001',
      'keyword': query,
    };
    if (checkIn != null) params['dateUndecided'] = '0';
    return '$_jalanBaseUrl/yad/list.html?${_encodeParams(params)}';
  }

  static String _buildAgodaUrl(String query, String locale, String? checkIn, String? checkOut) {
    final langCode = switch (locale) {
      'ko' => 'ko-kr',
      'zh' => 'zh-cn',
      'ja' => 'ja-jp',
      _ => 'en-us',
    };
    final params = <String, String>{
      'textToSearch': query,
      'locale': langCode,
    };
    if (checkIn != null) params['checkIn'] = checkIn;
    if (checkOut != null) params['checkOut'] = checkOut;
    return '$_agodaBaseUrl/search?${_encodeParams(params)}';
  }

  static String _buildBookingUrl(String query, String locale, String? checkIn, String? checkOut) {
    final langCode = switch (locale) {
      'ko' => 'ko',
      'zh' => 'zh-cn',
      'ja' => 'ja',
      _ => 'en-us',
    };
    final params = <String, String>{
      'ss': query,
      'lang': langCode,
    };
    if (checkIn != null) params['checkin'] = checkIn;
    if (checkOut != null) params['checkout'] = checkOut;
    return '$_bookingBaseUrl/searchresults.html?${_encodeParams(params)}';
  }

  static String _encodeParams(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Currency symbol for region
  static String currencySymbol(String region) {
    if (_koreaRegions.contains(region)) return '₩';
    if (_japanRegions.contains(region)) return '¥';
    return '\$';
  }
}
