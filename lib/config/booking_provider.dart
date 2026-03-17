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
    double? lat,
    double? lng,
    String? checkIn,
    String? checkOut,
  }) {
    if (_japanRegions.contains(region) && locale == 'ja') {
      return _buildJalanUrl(stationName, checkIn, checkOut);
    }
    if (_koreaRegions.contains(region) || locale == 'ko') {
      return _buildAgodaUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng);
    }
    return _buildBookingUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng);
  }

  /// Build a hotel-specific URL for the booking provider
  static String buildHotelUrl({
    required String locale,
    required String region,
    required String stationName,
    double? lat,
    double? lng,
    String? checkIn,
    String? checkOut,
    int? hotelId,
  }) {
    if (_japanRegions.contains(region) && locale == 'ja') {
      if (hotelId != null) {
        final jalanUrl = '$_jalanBaseUrl/yad/stay/$hotelId.html';
        return 'https://ck.jp.ap.valuecommerce.com/servlet/referral?sid=3693387&pid=889792382&vc_url=${Uri.encodeComponent(jalanUrl)}';
      }
      return _buildJalanUrl(stationName, checkIn, checkOut);
    }
    if (_koreaRegions.contains(region) || locale == 'ko') {
      if (hotelId != null) {
        return '$_agodaBaseUrl/hotel/$hotelId.html?cid=1922458';
      }
      return _buildAgodaUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng);
    }
    if (hotelId != null) {
      return '$_bookingBaseUrl/hotel/$hotelId.html?aid=2432111';
    }
    return _buildBookingUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng);
  }

  /// Build a Tabelog URL for restaurant search
  static String buildTabelogUrl(String stationName, String locale) {
    final domain = locale == 'ko' ? 'kr.tabelog.com' : locale == 'ja' ? 'tabelog.com' : 'en.tabelog.com';
    final encoded = Uri.encodeComponent(stationName);
    final tabelogUrl = 'https://$domain/rstLst/?vs=1&sk=$encoded';
    // Wrap with ValueCommerce for non-ja
    if (locale != 'ja') {
      return 'https://ck.jp.ap.valuecommerce.com/servlet/referral?sid=3693387&pid=889792383&vc_url=${Uri.encodeComponent(tabelogUrl)}';
    }
    return tabelogUrl;
  }

  static String _buildJalanUrl(String query, String? checkIn, String? checkOut) {
    final params = <String, String>{
      'screenId': 'UWW3001',
      'keyword': query,
    };
    if (checkIn != null) params['dateUndecided'] = '0';
    final jalanUrl = '$_jalanBaseUrl/yad/list.html?${_encodeParams(params)}';
    // Wrap with ValueCommerce affiliate redirect
    return 'https://ck.jp.ap.valuecommerce.com/servlet/referral?sid=3693387&pid=889792382&vc_url=${Uri.encodeComponent(jalanUrl)}';
  }

  static String _buildAgodaUrl(String query, String locale, String? checkIn, String? checkOut, {double? lat, double? lng}) {
    final langCode = switch (locale) {
      'ko' => 'ko-kr',
      'zh' => 'zh-cn',
      'ja' => 'ja-jp',
      _ => 'en-us',
    };
    // Match web app: /{lang}/search?cid=...&checkIn=...&checkOut=...&rooms=1&adults=2
    final params = <String, String>{
      'cid': '1922458',
      'rooms': '1',
      'adults': '2',
    };
    if (checkIn != null) params['checkIn'] = checkIn;
    if (checkOut != null) params['checkOut'] = checkOut;
    // Use lat/lng for precise location (matching web fallback)
    if (lat != null && lng != null) {
      params['latitude'] = lat.toString();
      params['longitude'] = lng.toString();
    } else {
      params['textToSearch'] = query;
    }
    return '$_agodaBaseUrl/$langCode/search?${_encodeParams(params)}';
  }

  static String _buildBookingUrl(String query, String locale, String? checkIn, String? checkOut, {double? lat, double? lng}) {
    final langCode = switch (locale) {
      'ko' => 'ko',
      'zh' => 'zh-cn',
      'ja' => 'ja',
      _ => 'en-us',
    };
    final params = <String, String>{
      'ss': query,
      'lang': langCode,
      'aid': '2432111',
    };
    if (lat != null) params['latitude'] = lat.toString();
    if (lng != null) params['longitude'] = lng.toString();
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
