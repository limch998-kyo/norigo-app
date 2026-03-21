import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/app_providers.dart';
import 'services/line_localize.dart';
import 'services/landmark_localizer.dart';
import 'services/station_localizer.dart';
import 'services/tracking_service.dart';
import 'services/api_client.dart';
import 'config/booking_provider.dart';
import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Kakao SDK (native app key from Kakao Developers console)
  KakaoSdk.init(
    nativeAppKey: 'cbc1828029dae6bb3007fb428675af62',
    javaScriptAppKey: 'ef83068e8071507be6a45e8af10706ee',
  );

  // Detect device locale — try multiple sources
  final platformLocale = ui.PlatformDispatcher.instance.locale;
  final langCode = platformLocale.languageCode; // e.g. 'ko', 'ja', 'en'

  final supportedLocales = ['ja', 'ko', 'en', 'zh'];
  final initialLocale = supportedLocales.contains(langCode) ? langCode : 'en';

  // Preload all data before app starts
  await Future.wait([
    LineLocalizer.preload(),
    LandmarkLocalizer.preload(),
    StationLocalizer.preload(),
    BookingProvider.preloadAgodaIds(),
  ]);

  // Initialize tracking service
  final apiClient = ApiClient();
  final tracking = TrackingService(apiClient);
  await tracking.init();
  tracking.setLocale(initialLocale);

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => initialLocale),
        apiClientProvider.overrideWithValue(apiClient),
        trackingServiceProvider.overrideWithValue(tracking),
      ],
      child: const NorigoApp(),
    ),
  );
}
