import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive test: finds ALL locale-specific map literals
/// that don't include 'fr' key, which causes French users to see
/// Japanese text as fallback.
void main() {
  test('All locale map literals include fr key (or use en fallback)', () {
    final violations = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart') || file.path.endsWith('tr.dart')) continue;

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Pattern 1: Map literal with 'ja': ... 'ko': ... 'en': ... but no 'fr':
        if (line.contains("'ja':") && line.contains("'en':") && !line.contains("'fr':")) {
          // Check next 3 lines too (multi-line maps)
          final block = lines.sublist(i, (i + 4).clamp(0, lines.length)).join(' ');
          if (!block.contains("'fr':")) {
            final path = file.path.replaceFirst('lib/', '');
            violations.add('  $path:${i + 1}: ${line.trim().substring(0, line.trim().length.clamp(0, 80))}');
          }
        }

        // Pattern 2: locale == 'ko' ? ... : something without ja check
        // (causes fr to fall through to Japanese default)
        if (line.contains("locale == 'ko'") && !line.contains("locale == 'ja'")) {
          final block = lines.sublist(i, (i + 3).clamp(0, lines.length)).join(' ');
          if (!block.contains("locale == 'ja'") && !block.contains("case 'ja'") &&
              (block.contains("['name']") || block.contains("l['name']"))) {
            final path = file.path.replaceFirst('lib/', '');
            violations.add('  $path:${i + 1}: ko-only check → Japanese default for fr/zh');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      // Print all but only fail with count
      for (final v in violations) {
        // ignore desc maps (they fallback to en correctly via descMap?[locale] ?? descMap?['en'])
        if (v.contains("'desc':")) continue;
        print(v);
      }
      final nonDescViolations = violations.where((v) => !v.contains("'desc':")).toList();
      if (nonDescViolations.isNotEmpty) {
        fail(
          'Found ${nonDescViolations.length} locale map(s) without fr key.\n'
          'Add fr: key or ensure en fallback for French users.',
        );
      }
    }
  });

  test('All tr() calls across entire app have fr: parameter', () {
    final missing = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart')) continue;

      final content = file.readAsStringSync();
      if (!content.contains('tr(locale,') && !content.contains('tr(widget.locale,')) continue;

      // Multi-line aware tr() check
      final pattern = RegExp(r'tr\(\s*(?:widget\.)?locale\s*,', multiLine: true);
      for (final match in pattern.allMatches(content)) {
        var depth = 1;
        var pos = match.end;
        while (pos < content.length && depth > 0) {
          if (content[pos] == '(') depth++;
          if (content[pos] == ')') depth--;
          pos++;
        }
        final block = content.substring(match.start, pos);
        if (!block.contains('fr:')) {
          final lineNum = content.substring(0, match.start).split('\n').length;
          final path = file.path.replaceFirst('lib/', '');
          missing.add('  $path:$lineNum');
        }
      }
    }

    if (missing.isNotEmpty) {
      fail('Found ${missing.length} tr() call(s) missing fr:\n${missing.join('\n')}');
    }
  });

  test('All switch(locale) blocks include fr case', () {
    final violations = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart') || file.path.contains('l10n/')) continue;

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        // Find switch blocks that have case 'ja' and case 'ko' but no case 'fr'
        if (lines[i].contains("case 'ja':") || lines[i].contains("case 'ko':")) {
          // Look at surrounding block (20 lines)
          final blockStart = (i - 3).clamp(0, lines.length);
          final blockEnd = (i + 20).clamp(0, lines.length);
          final block = lines.sublist(blockStart, blockEnd).join('\n');

          if (block.contains("case 'ja':") && block.contains("case 'ko':") &&
              !block.contains("case 'fr':") &&
              // Exclude known non-UI switches (l10n, tr helper, model localization)
              !file.path.contains('tr.dart') &&
              !file.path.contains('l10n/') &&
              !file.path.contains('models/') &&
              !file.path.contains('services/') &&
              // _getName with nameEn default is OK (fr falls to English)
              !block.contains("nameEn")) {
            final path = file.path.replaceFirst('lib/', '');
            if (!violations.any((v) => v.contains('$path:${i + 1}'))) {
              violations.add('  $path:${i + 1}: switch has ja/ko but no fr case');
            }
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      fail('Found ${violations.length} switch block(s) without fr case:\n${violations.join('\n')}');
    }
  });

  test('Suggestion chips and popular spots use en fallback for fr locale', () {
    // Check _popularByRegion and _SuggestionChips in stay_search_screen
    final content = File('lib/screens/stay/stay_search_screen.dart').readAsStringSync();

    // _getName should handle fr → nameEn fallback
    expect(content.contains("default: return spot['nameEn']"), true,
      reason: '_getName should fallback to nameEn for fr/zh/en');

    // Should NOT have: default: return spot['name'] (which is Japanese)
    final defaultJa = RegExp(r"default:\s*return\s+spot\['name'\]").hasMatch(content);
    expect(defaultJa, false,
      reason: '_getName should not default to Japanese name');
  });
}
