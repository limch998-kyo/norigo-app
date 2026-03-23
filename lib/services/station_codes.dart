import 'dart:convert';
import 'package:flutter/services.dart';
import 'line_localize.dart';

/// Station code lookup (e.g., 新宿 on 山手線 → JY17)
/// Matches web app's station-codes.ts
class StationCodes {
  static Map<String, dynamic>? _data;

  static Future<void> preload() async {
    if (_data != null) return;
    try {
      final raw = await rootBundle.loadString('assets/data/station-codes.json');
      _data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _data = {};
    }
  }

  /// Get all station codes for a station name on its lines.
  /// Returns list of {line, code, color} maps.
  static List<Map<String, String>> getCodes(String stationName, List<String> lines) {
    if (_data == null) return [];
    final results = <Map<String, String>>[];

    for (final entry in _data!.entries) {
      final lineName = entry.key;
      final lineData = entry.value as Map<String, dynamic>;
      final prefix = lineData['prefix'] as String? ?? '';

      if (lineData.containsKey(stationName)) {
        final number = lineData[stationName] as String;
        final code = '$prefix$number';
        // Get line color
        final color = _getLineColor(lineName);
        results.add({'line': lineName, 'code': code, 'color': color});
      }
    }

    return results;
  }

  /// Line color lookup — matches web's line-colors.ts
  static const _lineColors = {
    '山手線': '#9ACD32',
    '中央線': '#F15A22',
    '京浜東北線': '#00B2E5',
    '総武線': '#FFD400',
    '埼京線': '#00AC9B',
    '湘南新宿ライン': '#E44D2A',
    '上野東京ライン': '#E44D2A',
    '丸ノ内線': '#F62E36',
    '銀座線': '#FF9500',
    '日比谷線': '#B5B5AC',
    '東西線': '#009BBF',
    '千代田線': '#00BB85',
    '有楽町線': '#C1A470',
    '半蔵門線': '#8F76D6',
    '南北線': '#00AC9B',
    '副都心線': '#9C5E31',
    '浅草線': '#E85298',
    '三田線': '#0079C2',
    '新宿線': '#6CBB5A',
    '大江戸線': '#B6007A',
    '井の頭線': '#D3007F',
    '京王線': '#DD0077',
    '小田急小田原線': '#1E90FF',
    '東急東横線': '#DA0442',
    '東急田園都市線': '#00A040',
    '西武新宿線': '#009FE8',
    '西武池袋線': '#009FE8',
    '東武東上線': '#0068B7',
    '東武スカイツリーライン': '#0068B7',
    '京成本線': '#1A3B79',
    '京急本線': '#E5171F',
    'つくばエクスプレス': '#2F56A3',
    'りんかい線': '#00A4DB',
    'ゆりかもめ': '#00C1DE',
  };

  static String _getLineColor(String lineName) {
    return _lineColors[lineName] ?? '#888888';
  }
}
