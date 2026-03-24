import 'package:dio/dio.dart';
import '../models/hotel.dart';

/// Direct Rakuten Travel API client for Flutter.
/// Rakuten's public key requires Referer header validation.
class RakutenClient {
  static const _appId = '7d0d6830-fb85-4338-a124-06172b57bd76';
  static const _accessKey = 'pk_sjfeMPgbykXuLEVd8Hkbm0guRmpCJ5srVSbMCACHBYH';
  static const _affiliateId = '51cb5ad1.fd064f1a.51cb5ad2.a471b7b5';
  static const _apiUrl = 'https://openapi.rakuten.co.jp/engine/api/Travel/SimpleHotelSearch/20170426';

  static final _dio = Dio(BaseOptions(
    headers: {
      'Referer': 'https://norigo.app/',
      'Origin': 'https://norigo.app',
    },
  ));

  /// Fetch hotels near coordinates from Rakuten Travel.
  /// Returns Hotel objects compatible with existing UI.
  static Future<List<Hotel>> fetchHotels({
    required double lat,
    required double lng,
    double radiusKm = 2,
    int maxPages = 4,
  }) async {
    final allHotels = <List<dynamic>>[];

    // Fetch page 1
    final page1 = await _fetchPage(lat, lng, radiusKm, 1);
    if (page1 == null) return [];

    final hotels1 = page1['hotels'] as List<dynamic>?;
    if (hotels1 == null || hotels1.isEmpty) return [];
    allHotels.addAll(hotels1.map((e) => e as List<dynamic>));

    final pageCount = (page1['pagingInfo'] as Map?)?['pageCount'] as int? ?? 1;

    // Fetch additional pages in parallel
    if (pageCount > 1) {
      final pages = pageCount < maxPages ? pageCount : maxPages;
      final futures = <Future<Map<String, dynamic>?>>[];
      for (var p = 2; p <= pages; p++) {
        futures.add(_fetchPage(lat, lng, radiusKm, p));
      }
      final results = await Future.wait(futures);
      for (final pg in results) {
        if (pg != null) {
          final h = pg['hotels'] as List<dynamic>?;
          if (h != null) allHotels.addAll(h.map((e) => e as List<dynamic>));
        }
      }
    }

    // Map to Hotel objects, filter to only those with reviews
    return allHotels
        .map((entry) => _mapToHotel(entry))
        .where((h) => h != null && (h.reviewScore ?? 0) > 0)
        .cast<Hotel>()
        .toList();
  }

  static Future<Map<String, dynamic>?> _fetchPage(double lat, double lng, double radiusKm, int page) async {
    try {
      final response = await _dio.get(_apiUrl, queryParameters: {
        'applicationId': _appId,
        'accessKey': _accessKey,
        'affiliateId': _affiliateId,
        'latitude': lat,
        'longitude': lng,
        'searchRadius': radiusKm,
        'datumType': 1,
        'hits': 30,
        'formatVersion': 2,
        'sort': 'standard',
        'page': page,
      });
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('errors') || data.containsKey('error')) return null;
      if (data['hotels'] == null) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  static Hotel? _mapToHotel(List<dynamic> entry) {
    try {
      final items = entry;
      Map<String, dynamic>? basicInfo;
      Map<String, dynamic>? ratingInfo;

      for (final item in items) {
        if (item is Map<String, dynamic>) {
          if (item.containsKey('hotelBasicInfo')) basicInfo = item['hotelBasicInfo'] as Map<String, dynamic>;
          if (item.containsKey('hotelRatingInfo')) ratingInfo = item['hotelRatingInfo'] as Map<String, dynamic>;
        }
      }

      if (basicInfo == null) return null;

      final reviewAvg = (basicInfo['reviewAverage'] as num?)?.toDouble() ?? 0;
      final minCharge = (basicInfo['hotelMinCharge'] as num?)?.toDouble() ?? 0;

      return Hotel(
        hotelId: basicInfo['hotelNo'] as int? ?? 0,
        name: basicInfo['hotelName'] as String? ?? '',
        lat: (basicInfo['latitude'] as num?)?.toDouble() ?? 0,
        lng: (basicInfo['longitude'] as num?)?.toDouble() ?? 0,
        reviewScore: reviewAvg > 0 ? reviewAvg * 2 : null, // Convert 5-scale to 10-scale
        reviewCount: basicInfo['reviewCount'] as int?,
        dailyRate: minCharge > 0 ? minCharge * 2 : null, // Per-person → 2 adults
        currency: 'JPY',
        imageUrl: basicInfo['hotelImageUrl'] as String?,
        bookingUrl: basicInfo['planListUrl'] as String? ?? basicInfo['hotelInformationUrl'] as String?,
        freeWifi: true,
      );
    } catch (_) {
      return null;
    }
  }
}
