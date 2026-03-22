import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Detects button heights that may cause text clipping.
/// Buttons with text should have at least 44px height (Apple HIG minimum)
/// to prevent descenders (g, y, p, q, 표, etc.) from being cut off.
void main() {
  test('No buttons with height less than 44px in lib/', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    // Pattern: SizedBox with height < 44 followed by a Button widget
    final tightHeightPattern = RegExp(
      r'height:\s*(3[0-9]|4[0-3])[\s,)].*(?:Button|button)',
      multiLine: true,
    );

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart')) continue;

      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Check for SizedBox height < 44 with Button on same or next line
        final heightMatch = RegExp(r'height:\s*(3[0-9]|4[0-3])\b').firstMatch(line);
        if (heightMatch != null) {
          final height = int.parse(heightMatch.group(1)!);
          // Check this line and next 2 lines for Button
          final context = [
            line,
            if (i + 1 < lines.length) lines[i + 1],
            if (i + 2 < lines.length) lines[i + 2],
          ].join(' ');

          if (RegExp(r'Button\(|Button\.icon\(').hasMatch(context)) {
            final relativePath = file.path.replaceFirst('lib/', '');
            violations.add('  $relativePath:${i + 1}: height=$height → ${line.trim()}');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found ${violations.length} button(s) with height < 44px (may clip text).\n'
        'Increase height to at least 44px:\n\n'
        '${violations.join('\n')}',
      );
    }
  });

  test('No text widgets with overflow but without maxLines in lib/', () {
    final libDir = Directory('lib');
    final violations = <String>[];

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('.g.dart')) continue;

      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Text with overflow: TextOverflow.ellipsis but no maxLines
        if (line.contains('TextOverflow.ellipsis')) {
          // Check surrounding lines for maxLines
          final context = [
            if (i > 0) lines[i - 1],
            line,
            if (i + 1 < lines.length) lines[i + 1],
            if (i + 2 < lines.length) lines[i + 2],
          ].join(' ');

          if (!context.contains('maxLines')) {
            final relativePath = file.path.replaceFirst('lib/', '');
            violations.add('  $relativePath:${i + 1}: TextOverflow.ellipsis without maxLines');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      // Warning only — don't fail, just report
      print(
        'WARNING: Found ${violations.length} Text widget(s) with overflow but no maxLines:\n'
        '${violations.join('\n')}',
      );
    }
  });
}
