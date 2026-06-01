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
      if (file.path.contains('.g.dart') || file.path.endsWith('tr.dart')) {
        continue;
      }

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Pattern 1: Map literal with 'ja': ... 'ko': ... 'en': ... but no 'fr':
        if (line.contains("'ja':") &&
            line.contains("'en':") &&
            !line.contains("'fr':")) {
          // Check next 3 lines too (multi-line maps)
          final block = lines
              .sublist(i, (i + 4).clamp(0, lines.length))
              .join(' ');
          if (!block.contains("'fr':")) {
            final path = file.path.replaceFirst('lib/', '');
            violations.add(
              '  $path:${i + 1}: ${line.trim().substring(0, line.trim().length.clamp(0, 80))}',
            );
          }
        }

        // Pattern 2: locale == 'ko' ? ... : something without ja check
        // (causes fr to fall through to Japanese default)
        if (line.contains("locale == 'ko'") &&
            !line.contains("locale == 'ja'")) {
          final block = lines
              .sublist(i, (i + 3).clamp(0, lines.length))
              .join(' ');
          if (!block.contains("locale == 'ja'") &&
              !block.contains("case 'ja'") &&
              (block.contains("['name']") || block.contains("l['name']"))) {
            final path = file.path.replaceFirst('lib/', '');
            violations.add(
              '  $path:${i + 1}: ko-only check → Japanese default for fr/zh',
            );
          }
        }
      }
    }

    // Ignore desc maps (they fall back to en via descMap?[locale] ?? descMap?['en']).
    final nonDescViolations = violations
        .where((v) => !v.contains("'desc':"))
        .toList();
    if (nonDescViolations.isNotEmpty) {
      fail(
        'Found ${nonDescViolations.length} locale map(s) without fr key.\n'
        'Add fr: key or ensure en fallback for French users.\n'
        '${nonDescViolations.join('\n')}',
      );
    }
  });

  test('All tr() calls across entire app have fr: parameter', () {
    final missing = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart')) continue;

      final content = file.readAsStringSync();
      if (!content.contains('tr(locale,') &&
          !content.contains('tr(widget.locale,')) {
        continue;
      }

      // Multi-line aware tr() check
      final pattern = RegExp(
        r'tr\(\s*(?:widget\.)?locale\s*,',
        multiLine: true,
      );
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
      fail(
        'Found ${missing.length} tr() call(s) missing fr:\n${missing.join('\n')}',
      );
    }
  });

  test('All switch(locale) blocks include fr case', () {
    final violations = <String>[];
    final switchRe = RegExp(r'switch\s*\(\s*locale\s*\)');

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart') || file.path.contains('l10n/')) {
        continue;
      }
      // Non-UI switches localize via en/nameEn fallback, not an fr branch.
      if (file.path.contains('tr.dart') ||
          file.path.contains('models/') ||
          file.path.contains('services/')) {
        continue;
      }

      final content = file.readAsStringSync();
      for (final m in switchRe.allMatches(content)) {
        // Brace-match the full switch body so multi-line (dart format'd) cases
        // are checked as one block instead of a fixed-size line window.
        final braceStart = content.indexOf('{', m.end);
        if (braceStart < 0) continue;
        var depth = 0;
        var end = braceStart;
        for (var i = braceStart; i < content.length; i++) {
          final c = content[i];
          if (c == '{') {
            depth++;
          } else if (c == '}') {
            depth--;
            if (depth == 0) {
              end = i;
              break;
            }
          }
        }
        final block = content.substring(braceStart, end + 1);

        if (block.contains("case 'ja':") &&
            block.contains("case 'ko':") &&
            !block.contains("case 'fr':") &&
            // _getName with nameEn default is OK (fr falls to English).
            !block.contains('nameEn')) {
          final line =
              '\n'.allMatches(content.substring(0, m.start)).length + 1;
          final path = file.path.replaceFirst('lib/', '');
          violations.add('  $path:$line: switch has ja/ko but no fr case');
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found ${violations.length} switch block(s) without fr case:\n${violations.join('\n')}',
      );
    }
  });

  test('Suggestion chips and popular spots use en fallback for fr locale', () {
    final violations = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart')) continue;

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Pattern: locale == 'en' ? nameEn : spot['name'] (missing ja check)
        // This causes fr to fall through to Japanese 'name'
        if (line.contains("locale == 'en'") &&
            !line.contains("locale == 'ja'")) {
          final block = lines
              .sublist(i, (i + 3).clamp(0, lines.length))
              .join(' ');
          if (block.contains("spot['name']") &&
              !block.contains("locale == 'ja'") &&
              !block.contains("nameEn")) {
            final path = file.path.replaceFirst('lib/', '');
            violations.add(
              '  $path:${i + 1}: en-only check → Japanese default for fr',
            );
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found locale patterns where fr falls to Japanese:\n${violations.join('\n')}',
      );
    }
  });
}
