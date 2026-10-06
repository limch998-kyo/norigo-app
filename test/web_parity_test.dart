import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/config/constants.dart';
import 'package:norigo_app/utils/tr.dart';

/// The meetup search sends category and budget keys straight to the web's
/// /api/recommend. The web ignores a key it does not know (no error, no
/// filter), which is how the app's budget choice did nothing until 2.0.1.
/// These keep the two sides equal and the old keys readable.
void main() {
  group('meetup keys match the web', () {
    test('categories are the web HotPepper genre keys', () {
      expect(
        AppConstants.categories.keys.toSet(),
        {'izakaya', 'japanese', 'italian', 'chinese', 'korean', 'yakiniku', 'cafe', 'bar'},
      );
    });

    test('budgets are the web BUDGET_MAX_YEN keys', () {
      expect(
        AppConstants.budgets.keys.toList(),
        ['under2000', 'under3000', 'under4000', 'under5000', 'over5000'],
      );
    });

    test('every choice has a label in every language', () {
      for (final map in [...AppConstants.categories.values, ...AppConstants.budgets.values]) {
        for (final locale in ['ja', 'ko', 'en', 'zh', 'fr']) {
          expect(map[locale], isNotEmpty, reason: '$map lacks $locale');
        }
        expect(pickLoc(map, 'zh-TW'), isNotEmpty);
      }
    });

    test('budget labels for Traditional Chinese say 日圓', () {
      for (final map in AppConstants.budgets.values) {
        expect(pickLoc(map, 'zh-TW'), contains('日圓'));
      }
    });
  });

  group('old keys keep their meaning', () {
    test('pre-2.0.1 budgets map onto the web keys', () {
      expect(AppConstants.normalizeBudget('2000'), 'under2000');
      expect(AppConstants.normalizeBudget('3000'), 'under3000');
      expect(AppConstants.normalizeBudget('4000'), 'under4000');
      expect(AppConstants.normalizeBudget('5000'), 'under5000');
      expect(AppConstants.normalizeBudget('8000'), 'over5000');
      expect(AppConstants.normalizeBudget('10000'), 'over5000');
    });

    test('web keys pass through, anything else means no budget', () {
      expect(AppConstants.normalizeBudget('under3000'), 'under3000');
      expect(AppConstants.normalizeBudget('any'), isNull);
      expect(AppConstants.normalizeBudget(''), isNull);
      expect(AppConstants.normalizeBudget(null), isNull);
      expect(AppConstants.normalizeBudget('under99999'), isNull);
    });

    test('ramen (never a web genre) becomes no category; web keys pass through', () {
      expect(AppConstants.normalizeCategory('ramen'), isNull);
      expect(AppConstants.normalizeCategory('bar'), 'bar');
      expect(AppConstants.normalizeCategory('any'), isNull);
      expect(AppConstants.normalizeCategory(null), isNull);
    });
  });

  group('bundled data follows the web', () {
    test('every landmark carries a Traditional Chinese name', () {
      for (final region in ['kanto', 'kansai', 'kyushu', 'seoul', 'busan']) {
        final list = jsonDecode(File('assets/data/landmarks-$region.json').readAsStringSync()) as List;
        for (final lm in list.cast<Map<String, dynamic>>()) {
          expect(lm['nameZhTw'], isA<String>(), reason: '${lm['slug']} ($region)');
          expect((lm['nameZhTw'] as String).trim(), isNotEmpty, reason: '${lm['slug']} ($region)');
        }
      }
    });

    test('line translations cover the Seoul and Busan lines added on the web', () {
      final map = jsonDecode(File('assets/data/line-translations.json').readAsStringSync()) as Map<String, dynamic>;
      expect(map.length, greaterThanOrEqualTo(308));
      expect(map, contains('공항철도직통'));
      expect(map, contains('부산교통공사|1호선'));
    });
  });
}
