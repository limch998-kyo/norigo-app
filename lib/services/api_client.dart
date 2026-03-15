import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/landmark.dart';

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

  /// Search landmarks by query (autocomplete)
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

  /// Get stay recommendations for given landmarks
  Future<Map<String, dynamic>> getStayRecommendation({
    required List<Landmark> landmarks,
    required String region,
    String? maxBudget,
  }) async {
    final response = await _dio.post(
      AppConstants.stayRecommendEndpoint,
      data: {
        'landmarks': landmarks.map((l) => l.toJson()).toList(),
        'region': region,
        if (maxBudget case final b?) 'maxBudget': b,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Log an analytics event (same pipeline as web)
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
