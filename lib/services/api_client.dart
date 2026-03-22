import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/landmark.dart';
import '../models/station.dart';
import '../models/stay_area.dart';
import '../models/meetup_result.dart';
import '../models/hotel.dart';
import '../models/meetup_result.dart' show Venue;

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

  Future<List<Station>> searchStations(String query, {String? region, String? locale}) async {
    final params = <String, dynamic>{'q': query};
    if (region != null) params['region'] = region;
    if (locale != null) params['locale'] = locale;

    final response = await _dio.get(
      AppConstants.stationSearchEndpoint,
      queryParameters: params,
    );
    final data = response.data;
    // API returns {results: [...]} or flat array
    final List list;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      list = data['results'] as List;
    } else if (data is List) {
      list = data;
    } else {
      return [];
    }
    return list.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Landmark Search ──

  Future<List<Landmark>> searchLandmarks(String query, {String? region, String? locale}) async {
    final params = <String, dynamic>{'q': query};
    if (region != null) params['region'] = region;
    if (locale != null) params['locale'] = locale;

    final response = await _dio.get(
      AppConstants.searchLandmarkEndpoint,
      queryParameters: params,
    );
    final data = response.data;
    // API returns {landmarks: [...]} or flat array
    final List list;
    if (data is Map<String, dynamic> && data.containsKey('landmarks')) {
      list = data['landmarks'] as List;
    } else if (data is List) {
      list = data;
    } else {
      return [];
    }
    return list.map((e) {
      final json = e as Map<String, dynamic>;
      // API returns displayName/name, normalize to Landmark
      return Landmark(
        slug: json['slug'] as String? ?? json['name'] as String? ?? json['displayName'] as String? ?? '',
        name: json['displayName'] as String? ?? json['name'] as String? ?? '',
        nameEn: json['nameEn'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        region: json['region'] as String? ?? region ?? 'kanto',
      );
    }).toList();
  }

  // ── Stay Recommendation ──

  Future<StayRecommendResult> getStayRecommendation({
    required List<Landmark> landmarks,
    required String region,
    String mode = 'centroid',
    String stayStyle = 'auto',
    String? maxBudget,
    String? checkIn,
    String? checkOut,
    String? locale,
  }) async {
    final response = await _dio.post(
      AppConstants.stayRecommendEndpoint,
      data: {
        // API expects only name, lat, lng for each landmark
        'landmarks': landmarks.map((l) => {
          'name': l.name,
          'lat': l.lat,
          'lng': l.lng,
        }).toList(),
        'region': region,
        'mode': mode,
        'stayStyle': stayStyle,
        if (maxBudget != null) 'maxBudget': maxBudget,
        if (checkIn != null) 'checkIn': checkIn,
        if (checkOut != null) 'checkOut': checkOut,
        if (locale != null) 'locale': locale,
      },
    );
    return StayRecommendResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Fetch Hotels for a Station ──

  Future<List<Hotel>> getHotels({
    required String stationId,
    String? checkIn,
    String? checkOut,
    String? locale,
  }) async {
    final response = await _dio.post(
      AppConstants.stayHotelsEndpoint,
      data: {
        'stationId': stationId,
        if (checkIn != null) 'checkIn': checkIn,
        if (checkOut != null) 'checkOut': checkOut,
        if (locale != null) 'locale': locale,
      },
    );
    final data = response.data as Map<String, dynamic>;
    // API returns {results: [...]} not {hotels: [...]}
    final list = data['results'] as List? ?? data['hotels'] as List? ?? [];
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
    String? locale,
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
        if (locale != null) 'locale': locale,
      },
    );
    return MeetupResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Vote/Poll Creation ──

  Future<String?> createVotePoll({
    required String stationName,
    required String stationId,
    required List<Venue> venues,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.voteCreateEndpoint,
        data: {
          'stationName': stationName,
          'stationId': stationId,
          // Don't send type: 'station' — that hides venue photos on vote page
          'venues': venues.map((v) => {
            'id': v.url ?? v.name,
            'name': v.name,
            'url': v.url ?? '',
            'genre': v.genre ?? '',
            'budget': v.budget ?? '',
            'photoUrl': v.imageUrl ?? '',
          }).toList(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['pollId'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Vote ──

  Future<Map<String, dynamic>> getVotePoll(String pollId, {String? voterId}) async {
    final params = <String, String>{};
    if (voterId != null) params['voterId'] = voterId;
    final response = await _dio.get('/api/vote/$pollId', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<String> toggleVote({required String pollId, required String venueId, required String voterId}) async {
    final response = await _dio.post('/api/vote/$pollId', data: {
      'venueId': venueId,
      'voterId': voterId,
    });
    final data = response.data as Map<String, dynamic>;
    return data['action'] as String? ?? 'added';
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

  // ── Trip Resolve (get locale-specific names for landmarks) ──

  Future<List<Landmark>> resolveLandmarks(List<String> slugs, {String? locale}) async {
    try {
      final response = await _dio.post(
        AppConstants.tripResolveEndpoint,
        data: {
          'slugs': slugs,
          if (locale != null) 'locale': locale,
        },
      );
      final data = response.data;
      final List list = data is List ? data : (data is Map ? data['results'] as List? ?? [] : []);
      return list.map((e) {
        final json = e as Map<String, dynamic>;
        return Landmark(
          slug: json['slug'] as String? ?? '',
          name: json['name'] as String? ?? json['displayName'] as String? ?? '',
          nameEn: json['nameEn'] as String?,
          lat: (json['lat'] as num?)?.toDouble() ?? 0,
          lng: (json['lng'] as num?)?.toDouble() ?? 0,
          region: json['region'] as String? ?? 'kanto',
        );
      }).toList();
    } catch (_) {
      return [];
    }
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
