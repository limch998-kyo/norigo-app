import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app.dart';
import 'providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect device locale
  final deviceLocale = ui.PlatformDispatcher.instance.locale.languageCode;
  final supportedLocales = ['ja', 'ko', 'en', 'zh'];
  final initialLocale = supportedLocales.contains(deviceLocale) ? deviceLocale : 'en';

  // Precache SVGs used on home screen (non-blocking)
  _precacheSvgs();

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => initialLocale),
      ],
      child: const NorigoApp(),
    ),
  );
}

/// Precache home screen SVGs in background so they render instantly
void _precacheSvgs() {
  const homeSvgs = [
    'assets/images/illustrations/service-stay.svg',
    'assets/images/illustrations/service-meetup.svg',
    'assets/images/illustrations/stay-step1.svg',
    'assets/images/illustrations/stay-step2.svg',
    'assets/images/illustrations/stay-step3.svg',
  ];
  for (final path in homeSvgs) {
    // Load SVG into cache in background (fire-and-forget)
    final loader = SvgAssetLoader(path);
    svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}
