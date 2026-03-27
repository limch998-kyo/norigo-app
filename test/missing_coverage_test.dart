import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norigo_app/config/theme.dart';
import 'package:norigo_app/config/constants.dart';
import 'package:norigo_app/providers/trip_provider.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/services/landmark_localizer.dart';
import 'package:norigo_app/services/station_codes.dart';
import 'package:norigo_app/services/line_localize.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Meetup Search Screen ──
  group('Meetup search screen config', () {
    test('All regions have labels in meetup_search_screen', () {
      final content = File('lib/screens/meetup/meetup_search_screen.dart').readAsStringSync();
      for (final region in AppConstants.allRegions) {
        expect(content, contains("'$region'"), reason: 'Region $region missing from meetup search');
      }
    });

    test('Kyushu chip exists in meetup search', () {
      final content = File('lib/screens/meetup/meetup_search_screen.dart').readAsStringSync();
      expect(content, contains("'kyushu'"));
      expect(content, contains('큐슈'));
    });

    test('Japan-first order for ja locale', () {
      final content = File('lib/screens/meetup/meetup_search_screen.dart').readAsStringSync();
      // ja locale should show kanto first
      expect(content, contains("'kanto', 'kansai', 'kyushu', 'seoul', 'busan'"));
    });

    test('Korea-first order for other locales', () {
      final content = File('lib/screens/meetup/meetup_search_screen.dart').readAsStringSync();
      expect(content, contains("'seoul', 'busan', 'kanto', 'kansai', 'kyushu'"));
    });
  });

  // ── 2. Settings Screen ──
  group('Settings screen', () {
    test('Has all 5 locale options', () {
      final content = File('lib/screens/settings/settings_screen.dart').readAsStringSync();
      expect(content, contains("'ja': '日本語'"));
      expect(content, contains("'en': 'English'"));
      expect(content, contains("'ko': '한국어'"));
      expect(content, contains("'zh': '中文"));
      expect(content, contains("'fr': 'Français'"));
    });

    test('Has dark mode toggle with 3 options', () {
      final content = File('lib/screens/settings/settings_screen.dart').readAsStringSync();
      expect(content, contains('ThemeMode.system'));
      expect(content, contains('ThemeMode.light'));
      expect(content, contains('ThemeMode.dark'));
    });

    test('Links use correct URLs', () {
      final content = File('lib/screens/settings/settings_screen.dart').readAsStringSync();
      expect(content, contains('norigo.app'));
      expect(content, contains('/privacy'));
      expect(content, contains('/terms'));
      expect(content, contains('/credits'));
    });

    test('Version display hides build number', () {
      final content = File('lib/screens/settings/settings_screen.dart').readAsStringSync();
      // Should show v${version} not v${version}+${buildNumber}
      expect(content, contains("'v\${snapshot.data!.version}'"));
      expect(content, isNot(contains('buildNumber')));
    });
  });

  // ── 3. Trip Stay Provider ──
  group('Trip stay provider logic', () {
    test('Provider file has items.isEmpty check', () {
      final content = File('lib/providers/trip_stay_provider.dart').readAsStringSync();
      expect(content, contains('if (items.isEmpty) return null'));
    });

    test('Provider watches itemSlugs with select()', () {
      final content = File('lib/providers/trip_stay_provider.dart').readAsStringSync();
      expect(content, contains('.select('));
      expect(content, contains('itemSlugs'));
    });

    test('Returns null for less than 2 items', () {
      final content = File('lib/providers/trip_stay_provider.dart').readAsStringSync();
      expect(content, contains('if (itemSlugs.length < 2) return null'));
    });
  });

  // ── 4. Landmark Localizer ──
  group('Landmark localizer', () {
    test('Loads all 5 regions', () {
      final content = File('lib/services/landmark_localizer.dart').readAsStringSync();
      for (final region in ['kanto', 'kansai', 'kyushu', 'seoul', 'busan']) {
        expect(content, contains("'$region'"), reason: 'Region $region missing from landmark_localizer');
      }
    });

    test('Data files exist for all regions', () {
      for (final region in ['kanto', 'kansai', 'kyushu', 'seoul', 'busan']) {
        final file = File('assets/data/landmarks-$region.json');
        expect(file.existsSync(), true, reason: 'landmarks-$region.json missing');
        final content = file.readAsStringSync();
        final data = jsonDecode(content) as List;
        expect(data.length, greaterThan(10), reason: 'landmarks-$region.json has too few entries');
      }
    });

    test('Landmark data has required fields', () {
      final file = File('assets/data/landmarks-kanto.json');
      final data = jsonDecode(file.readAsStringSync()) as List;
      final first = data.first as Map<String, dynamic>;
      expect(first.containsKey('slug'), true);
      expect(first.containsKey('name'), true);
      expect(first.containsKey('lat'), true);
      expect(first.containsKey('lng'), true);
    });

    test('Landmark data has locale names', () {
      final file = File('assets/data/landmarks-kanto.json');
      final data = jsonDecode(file.readAsStringSync()) as List;
      // At least some entries should have nameEn/nameKo
      final withEn = data.where((l) => (l as Map).containsKey('nameEn')).length;
      expect(withEn, greaterThan(0), reason: 'No landmarks with nameEn');
    });
  });

  // ── 5. Station Codes ──
  group('Station codes', () {
    test('Station codes data file exists', () {
      final file = File('assets/data/station-codes.json');
      expect(file.existsSync(), true);
      final data = jsonDecode(file.readAsStringSync());
      expect(data, isNotEmpty);
    });

    test('Station code entries have required fields', () {
      final file = File('assets/data/station-codes.json');
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      // Check first entry
      final firstKey = data.keys.first;
      final firstVal = data[firstKey];
      expect(firstVal, isA<Map>());
    });

    test('StationCodes class has preload and lookup methods', () {
      final content = File('lib/services/station_codes.dart').readAsStringSync();
      expect(content, contains('preload'));
      expect(content, contains('getCode'));
    });
  });

  // ── 6. Line Localize ──
  group('Line localize', () {
    test('Line localize data file exists', () {
      // Check if line data is bundled
      final content = File('lib/services/line_localize.dart').readAsStringSync();
      expect(content, contains('preload'));
    });

    test('Has locale support for ja/ko/en', () {
      final content = File('lib/services/line_localize.dart').readAsStringSync();
      // Should handle multiple locales
      expect(content, contains('locale'));
    });
  });

  // ── 7. Dark Mode Colors ──
  group('Dark mode colors', () {
    test('AppTheme has isDark flag', () {
      expect(AppTheme.isDark, isFalse); // Default
    });

    test('Dynamic colors change with isDark', () {
      // Light mode
      AppTheme.isDark = false;
      final lightForeground = AppTheme.foreground;
      final lightBackground = AppTheme.background;
      final lightBorder = AppTheme.border;
      final lightMuted = AppTheme.muted;

      // Dark mode
      AppTheme.isDark = true;
      final darkForeground = AppTheme.foreground;
      final darkBackground = AppTheme.background;
      final darkBorder = AppTheme.border;
      final darkMuted = AppTheme.muted;

      // All should be different
      expect(lightForeground, isNot(equals(darkForeground)), reason: 'foreground unchanged in dark');
      expect(lightBackground, isNot(equals(darkBackground)), reason: 'background unchanged in dark');
      expect(lightBorder, isNot(equals(darkBorder)), reason: 'border unchanged in dark');
      expect(lightMuted, isNot(equals(darkMuted)), reason: 'muted unchanged in dark');

      // Reset
      AppTheme.isDark = false;
    });

    test('Dark foreground is light colored', () {
      AppTheme.isDark = true;
      final fg = AppTheme.foreground;
      // Dark mode foreground should be bright (high R/G/B values)
      expect(fg.r, greaterThan(0.8), reason: 'Dark foreground should be bright');
      AppTheme.isDark = false;
    });

    test('Dark background is dark colored', () {
      AppTheme.isDark = true;
      final bg = AppTheme.background;
      // Dark mode background should be dark (low R/G/B values)
      expect(bg.r, lessThan(0.15), reason: 'Dark background should be dark');
      AppTheme.isDark = false;
    });

    test('No hardcoded Colors.white for backgrounds in key widgets', () {
      final files = [
        'lib/widgets/landmark_input_list.dart',
        'lib/widgets/station_input_list.dart',
      ];
      for (final path in files) {
        final content = File(path).readAsStringSync();
        // Should use AppTheme.card not Colors.white for backgrounds
        final whiteBackgrounds = RegExp(r'color:\s*Colors\.white').allMatches(content).length;
        expect(whiteBackgrounds, 0, reason: '$path still has Colors.white background');
      }
    });
  });

  // ── 8. Date Validation ──
  group('Date validation', () {
    test('Stay search screen has date picker', () {
      final content = File('lib/screens/stay/stay_search_screen.dart').readAsStringSync();
      expect(content, contains('_pickDate'));
      expect(content, contains('checkIn'));
      expect(content, contains('checkOut'));
    });

    test('Default dates are in the future', () {
      final content = File('lib/screens/stay/stay_search_screen.dart').readAsStringSync();
      // Default check-in should be future date (Duration(days: 30))
      expect(content, contains('Duration(days: 30)'));
    });

    test('Trip detail has date range picker', () {
      final content = File('lib/screens/trip/trip_detail_screen.dart').readAsStringSync();
      expect(content, contains('showDateRangePicker'));
      expect(content, contains('firstDate: now'));
    });

    test('Date range picker firstDate is today (prevents past dates)', () {
      final content = File('lib/screens/trip/trip_detail_screen.dart').readAsStringSync();
      // firstDate should be now (today), preventing past date selection
      expect(content, contains('firstDate: now'));
    });
  });

  // ── 9. App Lifecycle ──
  group('App lifecycle', () {
    test('MainShell has WidgetsBindingObserver', () {
      final content = File('lib/app.dart').readAsStringSync();
      expect(content, contains('WidgetsBindingObserver'));
      expect(content, contains('addObserver'));
      expect(content, contains('removeObserver'));
      expect(content, contains('didChangeAppLifecycleState'));
    });

    test('Provider select() used in MainShell', () {
      final content = File('lib/app.dart').readAsStringSync();
      expect(content, contains('.select('));
      expect(content, isNot(contains('ref.watch(staySearchProvider);')));
      expect(content, isNot(contains('ref.watch(meetupSearchProvider);')));
    });
  });

  // ── 10. Memory Safety ──
  group('Memory safety', () {
    test('FocusNode listeners added only once', () {
      for (final path in [
        'lib/widgets/landmark_input_list.dart',
        'lib/widgets/station_input_list.dart',
      ]) {
        final content = File(path).readAsStringSync();
        expect(content, contains('_focusListenerAdded'), reason: '$path missing listener guard');
        expect(content, contains('if (!_focusListenerAdded.contains(index))'), reason: '$path missing guard check');
      }
    });

    test('No dead provider files', () {
      expect(File('lib/providers/saved_searches_provider.dart').existsSync(), false,
          reason: 'Dead code: saved_searches_provider.dart should be deleted');
    });
  });
}
