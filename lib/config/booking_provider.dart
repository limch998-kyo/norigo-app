import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Determines booking provider based on locale and region.
/// Matches web app logic:
///   - Japan region + ja locale → Jalan
///   - Korea region OR ko locale → Agoda
///   - Fallback → Booking.com
class BookingProvider {
  /// Agoda area/poi IDs loaded from bundled data
  static Map<String, dynamic>? _agodaAreaIds;

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
  }

  /// Ensure data is loaded (call before buildSearchUrl if needed)
  static Future<void> ensureLoaded() async {
    if (_agodaAreaIds == null) await preloadAgodaIds();
  }
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
    String? stationId,
  }) {
    if (_japanRegions.contains(region) && locale == 'ja') {
      return _buildJalanUrl(stationName, checkIn, checkOut);
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

  static String _buildAgodaUrl(String query, String locale, String? checkIn, String? checkOut, {double? lat, double? lng, String? stationId, String? region}) {
    final langCode = switch (locale) {
      'ko' => 'ko-kr',
      'zh' => 'zh-cn',
      'ja' => 'ja-jp',
      _ => 'en-us',
    };
    const cid = '1922458';

    // With dates: match web buildAgodaSearchUrl exactly
    if (checkIn != null && checkOut != null) {
      var base = '$_agodaBaseUrl/$langCode/search?cid=$cid&checkIn=$checkIn&checkOut=$checkOut&rooms=1&adults=2';

      // 1) Try area ID (best: direct search results)
      if (stationId != null && stationId.isNotEmpty) {
        // Ensure data is loaded (may not be ready if called before preload completes)
        if (_agodaAreaIds == null) {
          // Synchronous fallback: try loading now
          try {
            // Data might not be ready yet, skip to lat/lng fallback
          } catch (_) {}
        }
        if (_agodaAreaIds != null) {
          final entry = _agodaAreaIds![stationId];
          if (entry != null) {
            final idType = entry['type'] as String;
            final id = entry['id'];
            if (idType == 'area') {
              debugPrint('Agoda: area match for $stationId → area=$id');
              return '$base&area=$id';
            } else if (idType == 'poi') {
              debugPrint('Agoda: poi match for $stationId → poi=$id');
              return '$base&poi=$id';
            }
          }
          debugPrint('Agoda: no entry for $stationId, falling back to lat/lng');
        } else {
          debugPrint('Agoda: area IDs not loaded yet');
        }
      }

      // 2) lat/lng fallback
      if (lat != null && lng != null) {
        final url = '$base&latitude=$lat&longitude=$lng';
        debugPrint('Agoda URL (lat/lng): $url');
        return url;
      }

      final url = '$base&textToSearch=${Uri.encodeComponent(query)}';
      debugPrint('Agoda URL (textToSearch): $url');
      return url;
    }

    // Without dates: simple search
    return '$_agodaBaseUrl/$langCode/search?cid=$cid&textToSearch=${Uri.encodeComponent(query)}';
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
