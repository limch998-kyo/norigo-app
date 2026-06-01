import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/utils/color_utils.dart';

/// Unit tests for [hexToColor] — the shared hex parser extracted from the
/// four duplicate `_parseColor` copies (stay_result, meetup_result,
/// stay_inline_map). Route segment colors arrive from the API as '#RRGGBB'
/// strings (e.g. '#E44D2A'), so parsing + graceful fallback both matter.
void main() {
  group('hexToColor', () {
    test('parses #RRGGBB into an opaque color', () {
      // Real route line color seen in api_integration_test (湘南新宿ライン).
      expect(hexToColor('#E44D2A'), const Color(0xFFE44D2A));
    });

    test('requires a leading # — bare hex falls back to grey', () {
      // Callers always pass API route colors as '#RRGGBB', so the parser only
      // supports the '#'-prefixed form (replaceFirst('#', '0xFF')). A bare hex
      // string is not valid input and degrades to grey.
      expect(hexToColor('2563EB'), Colors.grey);
    });

    test('forces full opacity regardless of input', () {
      expect(hexToColor('#000000').a, 1.0);
      expect(hexToColor('#FFFFFF').a, 1.0);
    });

    test('parses lowercase hex', () {
      expect(hexToColor('#e44d2a'), const Color(0xFFE44D2A));
    });

    test('falls back to grey on malformed input', () {
      expect(hexToColor('not-a-color'), Colors.grey);
      expect(hexToColor('#ZZZZZZ'), Colors.grey);
      expect(hexToColor(''), Colors.grey);
    });
  });
}
