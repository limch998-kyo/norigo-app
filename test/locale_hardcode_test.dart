import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// This test ensures no hardcoded locale ternary patterns remain in display code.
/// Business logic patterns (budget defaults, domain URLs, tab ordering) are excluded.
void main() {
  test('No hardcoded locale display strings in lib/', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    // Allowed files/patterns — business logic, not display strings
    final allowedPatterns = [
      // Budget default selection (not display text)
      RegExp(r"locale == '(ja|ko)' \? 'under\d+"),
      // Domain URLs
      RegExp(r"locale == '(ja|ko)' \? '[\w.]+\.com"),
      RegExp(r"locale == 'ko' \? 'kr\.tabelog"),
      // Tab index switching (navigation logic)
      RegExp(r"locale == 'ja' \? \d+ :"),
      RegExp(r"locale == 'ja' \? l10n\."),
      RegExp(r"locale == 'ja' \? Icons\."),
      // Region ordering
      RegExp(r"locale == 'ja'.*\? \["),
      // isKorea budget logic
      RegExp(r"isKorea \?.*locale == 'ja'"),
    ];

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      // Skip generated files
      if (file.path.contains('.g.dart') || file.path.contains('.freezed.dart')) continue;
      // Skip the tr() helper itself
      if (file.path.endsWith('utils/tr.dart')) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Detect: locale == 'ja' ? 'JAPANESE_TEXT' (CJK or katakana/hiragana)
        final match = RegExp(
          r"""locale == '(ja|ko)' \? ['"]([^'"]*[\u3000-\u9FFF\uAC00-\uD7AF\u30A0-\u30FF\u3040-\u309F][^'"]*?)['"]"""
        ).firstMatch(line);

        if (match != null) {
          // Check if it's an allowed business logic pattern
          final isAllowed = allowedPatterns.any((p) => p.hasMatch(line));
          if (!isAllowed) {
            final relativePath = file.path.replaceFirst('lib/', '');
            violations.add('  $relativePath:${i + 1}: ${line.trim()}');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found ${violations.length} hardcoded locale display string(s).\n'
        'Use tr(locale, ja: ..., ko: ..., en: ..., zh: ...) instead:\n\n'
        '${violations.join('\n')}',
      );
    }
  });

  test('All ARB files have matching keys', () {
    final arbDir = Directory('lib/l10n');
    final arbFiles = arbDir.listSync().where((f) => f.path.endsWith('.arb')).toList();

    expect(arbFiles.length, greaterThanOrEqualTo(4), reason: 'Should have ja, ko, en, zh ARB files');

    // Read all keys from en (base) ARB
    final enArb = File('lib/l10n/app_en.arb');
    final enContent = enArb.readAsStringSync();
    final enKeys = RegExp(r'"(\w+)"(?=\s*:)').allMatches(enContent)
        .map((m) => m.group(1)!)
        .where((k) => !k.startsWith('@') && k != '@@locale')
        .toSet();

    for (final arbFile in arbFiles) {
      if (arbFile is! File) continue;
      final content = arbFile.readAsStringSync();
      final keys = RegExp(r'"(\w+)"(?=\s*:)').allMatches(content)
          .map((m) => m.group(1)!)
          .where((k) => !k.startsWith('@') && k != '@@locale')
          .toSet();

      final missing = enKeys.difference(keys);
      final fileName = arbFile.path.split('/').last;

      expect(missing, isEmpty, reason: '$fileName is missing keys: $missing');
    }
  });
}
