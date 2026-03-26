import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Determines booking provider based on locale and region.
/// Matches web app logic:
///   - Japan region + ja locale → Jalan (via /api/out server redirect)
///   - Korea region OR ko locale → Agoda
///   - Fallback → Booking.com
class BookingProvider {
  /// Agoda area/poi IDs loaded from bundled data
  static Map<String, dynamic>? _agodaAreaIds;
  /// Jalan station codes loaded from bundled data
  static Map<String, dynamic>? _jalanCodes;

  static Future<void>? _loadFuture;

  static Future<void> preloadAgodaIds() {
    _loadFuture ??= _doLoad();
    return _loadFuture!;
  }

  static Future<void> _doLoad() async {
    if (_agodaAreaIds != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/agoda-area-ids.json');
      _agodaAreaIds = jsonDecode(raw) as Map<String, dynamic>;
      debugPrint('Agoda area IDs loaded: ${_agodaAreaIds!.length} entries');
    } catch (e) {
      debugPrint('Failed to load Agoda area IDs: $e');
      _agodaAreaIds = {};
    }
    try {
      final raw = await rootBundle.loadString('assets/data/station-jalan-codes.json');
      _jalanCodes = jsonDecode(raw) as Map<String, dynamic>;
      debugPrint('Jalan codes loaded: ${_jalanCodes!.length} entries');
    } catch (e) {
      debugPrint('Failed to load Jalan codes: $e');
      _jalanCodes = {};
    }
  }

  /// Ensure data is loaded (call before buildSearchUrl if needed)
  static Future<void> ensureLoaded() async {
    if (_agodaAreaIds == null) await preloadAgodaIds();
  }

  static const _jalanBaseUrl = 'https://www.jalan.net';
  static const _agodaBaseUrl = 'https://www.agoda.com';
  static const _bookingBaseUrl = 'https://www.booking.com';
  static const _apiOutUrl = 'https://norigo.app/api/out';

  static const _koreaRegions = ['seoul', 'busan'];
  static const _japanRegions = ['kanto', 'kansai'];

  /// Get the primary provider name for display
  static String providerName(String locale, String region) {
    if (_japanRegions.contains(region) && locale == 'ja') return 'jalan.net';
    if (_koreaRegions.contains(region) || locale == 'ko') return 'Agoda';
    return 'Expedia';
  }

  /// EN/FR/ZH: returns 3 provider buttons (Expedia + Hotels.com + Booking.com)
  static List<({String name, String url, Color color, Color textColor})> buildMultiProviderUrls({
    required String locale,
    required String region,
    required String stationName,
    double? lat,
    double? lng,
    String? checkIn,
    String? checkOut,
    String? maxBudget,
  }) {
    if (locale == 'ja' || locale == 'ko') return [];

    final expediaUrl = _buildExpediaUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng, maxBudget: maxBudget);
    final hotelsComUrl = _buildHotelsComUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng, maxBudget: maxBudget);
    final bookingUrl = _buildBookingUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng, maxBudget: maxBudget);

    return [
      (
        name: 'Expedia',
        url: _wrapWithApiOut(expediaUrl, 'expedia'),
        color: const Color(0xFFFEC84C),
        textColor: const Color(0xFF202843),
      ),
      (
        name: 'Hotels.com',
        url: _wrapWithApiOut(hotelsComUrl, 'hotels_com'),
        color: const Color(0xFFD32F2F),
        textColor: Colors.white,
      ),
      (
        name: 'Booking.com',
        url: _wrapWithApiOut(bookingUrl, 'booking'),
        color: const Color(0xFF003B95),
        textColor: Colors.white,
      ),
    ];
  }

  /// Get the provider label for attribution
  static String providerAttribution(String locale, String region) {
    final name = providerName(locale, region);
    return 'Powered by $name';
  }

  /// Wrap URL via /api/out for server-side affiliate redirect (matching web)
  /// Uses Uri class to avoid double-encoding the url parameter
  static String _wrapWithApiOut(String url, String provider, {String? stationId}) {
    final params = <String, String>{
      'shopId': 'app',
      'url': url,
      'provider': provider,
    };
    if (stationId != null) params['stationId'] = stationId;
    return Uri.parse(_apiOutUrl).replace(queryParameters: params).toString();
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
    String? stationId,
    String? maxBudget,
  }) {
    if (_japanRegions.contains(region) && locale == 'ja') {
      return _buildJalanUrl(stationName, checkIn, checkOut, stationId: stationId, maxBudget: maxBudget);
    }
    if (_koreaRegions.contains(region) || locale == 'ko') {
      return _buildAgodaUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng, stationId: stationId, region: region);
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
    String? stationId,
  }) {
    if (_japanRegions.contains(region) && locale == 'ja') {
      if (hotelId != null) {
        final jalanUrl = '$_jalanBaseUrl/yad/stay/$hotelId.html';
        return _wrapWithApiOut(jalanUrl, 'jalan', stationId: stationId);
      }
      return _buildJalanUrl(stationName, checkIn, checkOut, stationId: stationId);
    }
    if (_koreaRegions.contains(region) || locale == 'ko') {
      if (hotelId != null) {
        return '$_agodaBaseUrl/hotel/$hotelId.html?cid=1922458';
      }
      return _buildAgodaUrl(stationName, locale, checkIn, checkOut, lat: lat, lng: lng, region: region);
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
    return _wrapWithApiOut(tabelogUrl, 'tabelog');
  }

  /// Build Jalan URL — uses station-specific page if code available (matching web)
  static String _buildJalanUrl(String query, String? checkIn, String? checkOut, {String? stationId, String? maxBudget}) {
    // Try station-specific URL (matching web's buildJalanSearchUrl)
    if (stationId != null && _jalanCodes != null) {
      final code = _jalanCodes![stationId];
      if (code != null) {
        final sta = code['sta'] as String;
        final pref = code['pref'] as String;
        var jalanUrl = '$_jalanBaseUrl/$pref/STA_$sta/';

        final params = <String>[];
        // Budget filter (matching web: minPrice/maxPrice)
        if (maxBudget != null && maxBudget != 'any') {
          final range = parseBudgetRange(maxBudget);
          if (range.min > 0) params.add('minPrice=${range.min}');
          if (range.max < 999999999) params.add('maxPrice=${range.max}');
        }
        if (checkIn != null) {
          final parts = checkIn.split('-');
          if (parts.length == 3) {
            params.add('stayYear=${parts[0]}&stayMonth=${parts[1]}&stayDay=${parts[2]}');
          }
        }
        if (checkIn != null && checkOut != null) {
          final ci = DateTime.tryParse(checkIn);
          final co = DateTime.tryParse(checkOut);
          if (ci != null && co != null) {
            final nights = co.difference(ci).inDays.clamp(1, 30);
            params.add('stayCount=$nights');
          }
        }
        if (params.isNotEmpty) jalanUrl = '$jalanUrl?${params.join('&')}';

        return _wrapWithApiOut(jalanUrl, 'jalan', stationId: stationId);
      }
    }

    // Fallback: keyword search
    final params = <String, String>{
      'screenId': 'UWW3001',
      'keyword': query,
    };
    if (checkIn != null) params['dateUndecided'] = '0';
    final jalanUrl = '$_jalanBaseUrl/yad/list.html?${_encodeParams(params)}';
    return _wrapWithApiOut(jalanUrl, 'jalan', stationId: stationId);
  }

  static String _buildAgodaUrl(String query, String locale, String? checkIn, String? checkOut, {double? lat, double? lng, String? stationId, String? region}) {
    final langCode = switch (locale) {
      'ko' => 'ko-kr',
      'zh' => 'zh-cn',
      'ja' => 'ja-jp',
      _ => 'en-us',
    };
    const cid = '1922458';

    if (checkIn != null && checkOut != null) {
      var base = '$_agodaBaseUrl/$langCode/search?cid=$cid&checkIn=$checkIn&checkOut=$checkOut&rooms=1&adults=2';

      if (stationId != null && stationId.isNotEmpty && _agodaAreaIds != null) {
        final entry = _agodaAreaIds![stationId];
        if (entry != null) {
          final idType = entry['type'] as String;
          final id = entry['id'];
          if (idType == 'area') return '$base&area=$id';
          if (idType == 'poi') return '$base&poi=$id';
        }
      }

      if (lat != null && lng != null) return '$base&latitude=$lat&longitude=$lng';
      return '$base&textToSearch=${Uri.encodeComponent(query)}';
    }

    return '$_agodaBaseUrl/$langCode/search?cid=$cid&textToSearch=${Uri.encodeComponent(query)}';
  }

  static String _buildBookingUrl(String query, String locale, String? checkIn, String? checkOut, {double? lat, double? lng, String? maxBudget}) {
    final langCode = switch (locale) {
      'ko' => 'ko',
      'zh' => 'zh-cn',
      'ja' => 'ja',
      _ => 'en-us',
    };
    // Append 駅 (Station) to query for better search results (matching web)
    final ss = '$query駅';
    final params = <String, String>{
      'ss': ss,
      'lang': langCode,
      'aid': '2432111',
    };
    if (lat != null) params['latitude'] = lat.toString();
    if (lng != null) params['longitude'] = lng.toString();
    if (checkIn != null) params['checkin'] = checkIn;
    if (checkOut != null) params['checkout'] = checkOut;
    // Price filter matching web: per-person → per-room (×2)
    if (maxBudget != null && maxBudget != 'any') {
      final range = parseBudgetRange(maxBudget);
      final priceMin = range.min * 2;
      final priceMax = range.max >= 999999999 ? 999999 : range.max * 2;
      params['nflt'] = 'price=JPY-$priceMin-$priceMax-1';
    }
    return '$_bookingBaseUrl/searchresults.$langCode.html?${_encodeParams(params)}';
  }

  /// Build destination string for Expedia/Hotels.com
  /// CJK characters → fallback to city name
  static String _expediaDestination(String query, double? lng) {
    final hasCjk = RegExp(r'[\u3000-\u9FFF\uF900-\uFAFF\uAC00-\uD7AF]').hasMatch(query);
    final isKorea = lng != null && lng < 130;
    final name = hasCjk ? (isKorea ? 'Seoul' : 'Tokyo') : query;
    return '$name Station, ${isKorea ? "South Korea" : "Japan"}';
  }

  static const _jpyToUsd = 150;

  /// Calculate number of nights from checkIn/checkOut dates
  static int _calcNights(String? checkIn, String? checkOut) {
    if (checkIn == null || checkOut == null) return 1;
    final ci = DateTime.tryParse(checkIn);
    final co = DateTime.tryParse(checkOut);
    if (ci == null || co == null) return 1;
    return co.difference(ci).inDays.clamp(1, 30);
  }

  static String _buildExpediaUrl(String query, String locale, String? checkIn, String? checkOut, {double? lat, double? lng, String? maxBudget}) {
    final domain = switch (locale) {
      'ko' => 'expedia.co.kr',
      'ja' => 'expedia.co.jp',
      'fr' => 'expedia.fr',
      _ => 'expedia.com',
    };
    const affcid = 'US.DIRECT.PHG.1011l426920.1100l68075';
    final destination = _expediaDestination(query, lng);
    var url = 'https://www.$domain/Hotel-Search?destination=${Uri.encodeComponent(destination)}';
    if (checkIn != null) url += '&startDate=$checkIn';
    if (checkOut != null) url += '&endDate=$checkOut';
    // Expedia price filter = total stay price (per-night × nights), JPY → USD
    if (maxBudget != null && maxBudget != 'any') {
      final range = parseBudgetRange(maxBudget);
      final nights = _calcNights(checkIn, checkOut);
      final minUsd = (range.min * nights / _jpyToUsd).round();
      final maxUsd = range.max >= 999999999 ? 10000 : (range.max * nights / _jpyToUsd).round();
      if (minUsd > 0) url += '&price=$minUsd';
      url += '&price=$maxUsd';
    }
    url += '&affcid=$affcid';
    return url;
  }

  static String _buildHotelsComUrl(String query, String locale, String? checkIn, String? checkOut, {double? lat, double? lng, String? maxBudget}) {
    // Use locale subdomain + siteid + locale + currency=USD to force USD pricing
    // (matching web app's working URL pattern)
    // Always use www.hotels.com (matching web app)
    final domainLocale = switch (locale) {
      'ko' => (domain: 'www.hotels.com', siteId: '300000034', loc: 'ko_KR'),
      'ja' => (domain: 'www.hotels.com', siteId: '300000034', loc: 'ja_JP'),
      'fr' => (domain: 'www.hotels.com', siteId: '300000034', loc: 'fr_FR'),
      'zh' => (domain: 'www.hotels.com', siteId: '300000034', loc: 'zh_CN'),
      _ => (domain: 'www.hotels.com', siteId: '300000034', loc: 'en_US'),
    };
    const affcid = 'US.DIRECT.PHG.1011l426920.1100l68075';
    final destination = _expediaDestination(query, lng);
    var url = 'https://${domainLocale.domain}/Hotel-Search?siteid=${domainLocale.siteId}&locale=${domainLocale.loc}&currency=USD&destination=${Uri.encodeComponent(destination)}';
    if (checkIn != null) url += '&startDate=$checkIn';
    if (checkOut != null) url += '&endDate=$checkOut';
    // Hotels.com price filter = per-night price, JPY → USD (nights=1)
    if (maxBudget != null && maxBudget != 'any') {
      final range = parseBudgetRange(maxBudget);
      final minUsd = (range.min / _jpyToUsd).round();
      final maxUsd = range.max >= 999999999 ? 10000 : (range.max / _jpyToUsd).round();
      if (minUsd > 0) url += '&price=$minUsd';
      url += '&price=$maxUsd';
    }
    url += '&sort=RECOMMENDED&affcid=$affcid';
    return url;
  }

  /// Parse budget key into {min, max} in JPY (matching web's parseBudgetRange)
  static ({int min, int max}) parseBudgetRange(String? key) {
    if (key == null || key == 'any') return (min: 0, max: 999999999);
    final underMatch = RegExp(r'^under(\d+)$').firstMatch(key);
    if (underMatch != null) return (min: 0, max: int.parse(underMatch.group(1)!));
    final overMatch = RegExp(r'^over(\d+)$').firstMatch(key);
    if (overMatch != null) return (min: int.parse(overMatch.group(1)!), max: 999999999);
    final rangeMatch = RegExp(r'^(\d+)-(\d+)$').firstMatch(key);
    if (rangeMatch != null) return (min: int.parse(rangeMatch.group(1)!), max: int.parse(rangeMatch.group(2)!));
    return (min: 0, max: 999999999);
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
