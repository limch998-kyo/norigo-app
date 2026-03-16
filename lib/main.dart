import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect device locale — try multiple sources
  final platformLocale = ui.PlatformDispatcher.instance.locale;
  final langCode = platformLocale.languageCode; // e.g. 'ko', 'ja', 'en'

  final supportedLocales = ['ja', 'ko', 'en', 'zh'];
  final initialLocale = supportedLocales.contains(langCode) ? langCode : 'en';

  debugPrint('Device locale: $platformLocale, languageCode: $langCode, using: $initialLocale');

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => initialLocale),
      ],
      child: const NorigoApp(),
    ),
  );
}
