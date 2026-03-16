import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect device locale
  final deviceLocale = ui.PlatformDispatcher.instance.locale.languageCode;
  final supportedLocales = ['ja', 'ko', 'en', 'zh'];
  final initialLocale = supportedLocales.contains(deviceLocale) ? deviceLocale : 'en';

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => initialLocale),
      ],
      child: const NorigoApp(),
    ),
  );
}
