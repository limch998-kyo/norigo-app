import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/landmark.dart';
import '../models/station.dart';
import '../models/stay_area.dart';
import '../models/meetup_result.dart';
import '../models/hotel.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  // ── Unified Search (stations + landmarks) ──

  Future<UnifiedSearchResult> searchUnified(String query, {String? region}) async {
    final params = <String, dynamic>{'q': query};
    if (region != null) params['region'] = region;

    final response = await _dio.get(
      AppConstants.searchUnifiedEndpoint,
      queryParameters: params,
    );
    final data = response.data as Map<String, dynamic>;
    return UnifiedSearchResult.fromJson(data);
  }

  // ── Station Search ──

  Future<List<Station>> searchStations(String query, {String? region}) async {
    final params = <String, dynamic>{'q': query};
    if (region != null) params['region'] = region;

    final response = await _dio.get(
      AppConstants.stationSearchEndpoint,
      queryParameters: params,
    );
    final list = response.data as List;
    return list.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Landmark Search ──

  Future<List<Landmark>> searchLandmarks(String query, {String? region}) async {
    final params = <String, dynamic>{'q': query};
    if (region != null) params['region'] = region;

    final response = await _dio.get(
      AppConstants.searchLandmarkEndpoint,
      queryParameters: params,
    );
    final list = response.data as List;
    return list.map((e) => Landmark.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Stay Recommendation ──

  Future<StayRecommendResult> getStayRecommendation({
    required List<Landmark> landmarks,
    required String region,
    String mode = 'centroid',
    String? maxBudget,
    String? checkIn,
    String? checkOut,
  }) async {
    final response = await _dio.post(
      AppConstants.stayRecommendEndpoint,
      data: {
        'landmarks': landmarks.map((l) => l.toJson()).toList(),
        'region': region,
        'mode': mode,
        if (maxBudget != null) 'maxBudget': maxBudget,
        if (checkIn != null) 'checkIn': checkIn,
        if (checkOut != null) 'checkOut': checkOut,
      },
    );
    return StayRecommendResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Fetch Hotels for a Station ──

  Future<List<Hotel>> getHotels({
    required String stationId,
    String? checkIn,
    String? checkOut,
  }) async {
    final response = await _dio.post(
      AppConstants.stayHotelsEndpoint,
      data: {
        'stationId': stationId,
        if (checkIn != null) 'checkIn': checkIn,
        if (checkOut != null) 'checkOut': checkOut,
      },
    );
    final list = (response.data as Map<String, dynamic>)['hotels'] as List? ?? [];
    return list.map((e) => Hotel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Meetup Recommendation ──

  Future<MeetupResult> getMeetupRecommendation({
    required List<String> stationIds,
    required String mode,
    required String region,
    String? category,
    String? budget,
    List<String>? options,
  }) async {
    final response = await _dio.post(
      AppConstants.recommendEndpoint,
      data: {
        'participants': stationIds.map((id) => {'stationId': id}).toList(),
        'mode': mode,
        'region': region,
        if (category != null) 'category': category,
        if (budget != null) 'budget': budget,
        if (options != null && options.isNotEmpty) 'options': options,
      },
    );
    return MeetupResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Trip Optimization ──

  Future<Map<String, dynamic>> optimizeTrip({
    required List<Map<String, dynamic>> landmarks,
    required String region,
    String? checkIn,
    String? checkOut,
  }) async {
    final response = await _dio.post(
      AppConstants.tripOptimizeEndpoint,
      data: {
        'landmarks': landmarks,
        'region': region,
        if (checkIn != null) 'checkIn': checkIn,
        if (checkOut != null) 'checkOut': checkOut,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Event Logging ──

  Future<void> logEvent({
    required String eventType,
    required String sessionId,
    required String userId,
    Map<String, dynamic> payload = const {},
    String? path,
    String? locale,
  }) async {
    try {
      await _dio.post(
        AppConstants.eventLogEndpoint,
        data: {
          'eventType': eventType,
          'sessionId': sessionId,
          'userId': userId,
          'payload': {...payload, 'platform': 'flutter'},
          'path': path,
          'locale': locale,
          'referrer': '',
        },
      );
    } catch (_) {
      // Fire-and-forget, same as web
    }
  }
}

class UnifiedSearchResult {
  final List<Station> stations;
  final List<Landmark> landmarks;

  const UnifiedSearchResult({
    required this.stations,
    required this.landmarks,
  });

  factory UnifiedSearchResult.fromJson(Map<String, dynamic> json) {
    return UnifiedSearchResult(
      stations: (json['stations'] as List<dynamic>?)
              ?.map((e) => Station.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      landmarks: (json['landmarks'] as List<dynamic>?)
              ?.map((e) => Landmark.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
