import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/tracking_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final trackingServiceProvider = Provider<TrackingService>((ref) {
  final api = ref.watch(apiClientProvider);
  return TrackingService(api);
});

final localeProvider = StateProvider<String>((ref) => 'ja');

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
