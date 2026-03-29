import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests that all trip-related snackbars:
/// 1. Don't use SnackBarAction (causes duration to be ignored)
/// 2. Use clearSnackBars before showing
/// 3. Have duration <= 4 seconds
/// 4. Use floating behavior
void main() {
  final files = [
    'lib/screens/stay/stay_result_screen.dart',
    'lib/screens/guide/guide_detail_screen.dart',
    'lib/screens/guide/native_guide_detail_screen.dart',
    'lib/screens/spot/spot_detail_screen.dart',
  ];

  group('Snackbar auto-dismiss compliance', () {
    test('No SnackBarAction in any trip snackbar (prevents auto-dismiss)', () {
      int violations = 0;
      for (final path in files) {
        final content = File(path).readAsStringSync();
        // Find all showSnackBar blocks
        final matches = RegExp(r'showSnackBar\(SnackBar\(').allMatches(content);
        for (final m in matches) {
          // Get ~500 chars after the showSnackBar call
          final end = (m.start + 600).clamp(0, content.length);
          final block = content.substring(m.start, end);
          if (block.contains('SnackBarAction(')) {
            violations++;
            print('VIOLATION: $path:${content.substring(0, m.start).split('\n').length} uses SnackBarAction');
          }
        }
      }
      expect(violations, 0, reason: 'SnackBarAction prevents reliable auto-dismiss. Use TextButton in Row instead.');
    });

    test('Every showSnackBar has clearSnackBars before it', () {
      for (final path in files) {
        final content = File(path).readAsStringSync();
        final showCount = 'showSnackBar'.allMatches(content).length;
        final clearCount = 'clearSnackBars'.allMatches(content).length;
        expect(clearCount, greaterThanOrEqualTo(showCount),
            reason: '$path: $showCount showSnackBar but only $clearCount clearSnackBars');
      }
    });

    test('All snackbar durations are <= 4 seconds', () {
      for (final path in files) {
        final content = File(path).readAsStringSync();
        final durations = RegExp(r'Duration\(seconds:\s*(\d+)\)').allMatches(content);
        for (final m in durations) {
          final seconds = int.parse(m.group(1)!);
          expect(seconds, lessThanOrEqualTo(4),
              reason: '$path: snackbar duration ${seconds}s too long');
        }
      }
    });

    test('All snackbars use floating behavior', () {
      for (final path in files) {
        final content = File(path).readAsStringSync();
        final snackbars = 'showSnackBar'.allMatches(content).length;
        final floating = 'SnackBarBehavior.floating'.allMatches(content).length;
        // At least one floating per file that has snackbars
        if (snackbars > 0) {
          expect(floating, greaterThan(0),
              reason: '$path: has snackbars but no SnackBarBehavior.floating');
        }
      }
    });
  });
}
