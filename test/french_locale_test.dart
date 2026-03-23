import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests to ensure French locale doesn't show Japanese/Korean/Chinese text,
/// and that font sizes aren't too small across the app.
void main() {
  group('French locale - no foreign script leaks', () {
    test('No hardcoded Japanese fallback in _getName patterns', () {
      final violations = <String>[];

      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final lines = file.readAsStringSync().split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Pattern: locale == 'ko' ? ... : l['name'] (missing en/fr handling)
          // Should be: locale == 'ja' ? l['name'] : l['nameEn'] ?? l['name']
          if (line.contains("locale == 'ko'") && line.contains("l['name']") && !line.contains("locale == 'ja'")) {
            // Check if next lines handle ja separately
            final context = lines.sublist(i, (i + 3).clamp(0, lines.length)).join(' ');
            if (!context.contains("locale == 'ja'") && !context.contains("case 'ja'")) {
              final path = file.path.replaceFirst('lib/', '');
              violations.add('  $path:${i + 1}: Japanese fallback for non-ko locale');
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} place(s) where non-ko locales fall back to Japanese:\n'
          '${violations.join('\n')}\n'
          'Fix: use locale == "ja" ? name : (nameEn ?? name)',
        );
      }
    });

    test('tr() calls with fr: parameter exist for all files', () {
      final filesWithoutFr = <String>[];

      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();
        if (!content.contains('tr(locale,') && !content.contains('tr(widget.locale,')) continue;

        // Multi-line aware: find tr() blocks and check if fr: exists within them
        final pattern = RegExp(r'tr\(\s*(?:widget\.)?locale\s*,', multiLine: true);
        for (final match in pattern.allMatches(content)) {
          // Find the closing ) for this tr() call
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
            final preview = block.replaceAll(RegExp(r'\s+'), ' ');
            filesWithoutFr.add('  ${file.path}:$lineNum: ${preview.substring(0, preview.length.clamp(0, 60))}...');
          }
        }
      }

      if (filesWithoutFr.isNotEmpty) {
        fail(
          'Found ${filesWithoutFr.length} tr() call(s) missing fr: parameter:\n'
          '${filesWithoutFr.join('\n')}',
        );
      }
    });
  });

  group('Font size minimum', () {
    test('No text smaller than 9px in lib/', () {
      final violations = <String>[];

      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        if (file.path.contains('.g.dart')) continue;

        final lines = file.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Find fontSize: N where N < 9
          final match = RegExp(r'fontSize:\s*([0-9]+\.?[0-9]*)').firstMatch(line);
          if (match != null) {
            final size = double.parse(match.group(1)!);
            if (size < 9) {
              final path = file.path.replaceFirst('lib/', '');
              violations.add('  $path:${i + 1}: fontSize=$size (min 9) → ${line.trim()}');
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} text(s) with fontSize < 9:\n'
          '${violations.join('\n')}',
        );
      }
    });
  });
}
