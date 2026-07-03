import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/utils/tr.dart';
import 'package:norigo_app/config/constants.dart';
import 'package:norigo_app/models/station.dart';

/// zh-TW (Traditional Chinese) support: the app renders in Simplified Chinese
/// (zh) for zh-TW users unless a Traditional override is provided, and constant
/// labels fall back to zh rather than English.
void main() {
  group('tr() zh-TW fallback', () {
    test('falls back to zh when no zhTw override', () {
      expect(tr('zh-TW', en: 'Hotel', zh: '酒店'), '酒店');
    });

    test('uses zhTw override when provided', () {
      expect(tr('zh-TW', en: 'Yen', zh: '日元', zhTw: '日圓'), '日圓');
    });

    test('falls back to en when neither zh nor zhTw given', () {
      expect(tr('zh-TW', en: 'Only English'), 'Only English');
    });

    test('does not affect zh (Simplified)', () {
      expect(tr('zh', en: 'Yen', zh: '日元', zhTw: '日圓'), '日元');
    });
  });

  group('trMap / pickLoc zh-TW fallback', () {
    test('trMap zh-TW → zh', () {
      expect(trMap('zh-TW', {'en': 'A', 'zh': 'B'}), 'B');
    });

    test('trMap zh-TW → en when no zh', () {
      expect(trMap('zh-TW', {'en': 'A', 'ja': 'C'}), 'A');
    });

    test('pickLoc zh-TW → zh', () {
      expect(pickLoc({'en': 'A', 'zh': 'B'}, 'zh-TW'), 'B');
    });

    test('pickLoc uses fallback when map is empty', () {
      expect(pickLoc({}, 'zh-TW', fallback: 'x'), 'x');
    });
  });

  group('AppConstants.stayBudgetLabel zh-TW', () {
    test('zh-TW falls back to the Simplified (zh) label, not English', () {
      final zh = AppConstants.stayBudgetLabel('10000-30000', 'zh');
      final zhTw = AppConstants.stayBudgetLabel('10000-30000', 'zh-TW');
      final en = AppConstants.stayBudgetLabel('10000-30000', 'en');
      expect(zhTw, zh);
      expect(zhTw, isNot(en));
    });

    test('unknown key returns the key itself', () {
      expect(AppConstants.stayBudgetLabel('nonexistent', 'zh-TW'), 'nonexistent');
    });
  });

  group('Station.localizedName zh-TW', () {
    const s = Station(
      id: 's1',
      name: '新宿',
      nameEn: 'Shinjuku',
      nameZh: '新宿站',
      lat: 35.69,
      lng: 139.70,
      region: 'kanto',
    );

    test('zh-TW uses the Simplified (nameZh) name, not English', () {
      expect(s.localizedName('zh-TW'), s.localizedName('zh'));
      expect(s.localizedName('zh-TW'), '新宿站');
      expect(s.localizedName('zh-TW'), isNot(s.localizedName('en')));
    });

    test('other locales unaffected', () {
      expect(s.localizedName('en'), 'Shinjuku');
      expect(s.localizedName('ja'), '新宿');
    });
  });
}
