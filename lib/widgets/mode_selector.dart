import 'package:flutter/material.dart';

class ModeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final String locale;

  const ModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.locale = 'en',
  });

  static const _modes = ['centroid', 'minTotal', 'balanced'];

  static Map<String, Map<String, String>> get modeLabels => {
        'centroid': {
          'ja': '中間地点',
          'en': 'Middle Point',
          'ko': '중간 지점',
          'zh': '中间点',
        },
        'minTotal': {
          'ja': '最速',
          'en': 'Fastest',
          'ko': '가장 빠르게',
          'zh': '最快',
        },
        'balanced': {
          'ja': '公平',
          'en': 'Fairest',
          'ko': '가장 공평하게',
          'zh': '最公平',
        },
      };

  static Map<String, Map<String, String>> get modeDescriptions => {
        'centroid': {
          'ja': 'みんなの距離が近い駅',
          'en': 'Similar distance for everyone',
          'ko': '모두와 비슷한 거리의 역',
          'zh': '所有人距离相近的站',
        },
        'minTotal': {
          'ja': '全体の移動時間が最も短い',
          'en': 'Least total travel time',
          'ko': '전체 이동시간이 가장 적은 역',
          'zh': '总通勤时间最短',
        },
        'balanced': {
          'ja': '一番遠い人も遠すぎない',
          'en': 'No one travels too far',
          'ko': '가장 먼 사람도 너무 멀지 않게',
          'zh': '最远的人也不会太远',
        },
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: _modes.map((mode) {
        final isSelected = selected == mode;
        final label = modeLabels[mode]?[locale] ?? modeLabels[mode]?['en'] ?? mode;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode != _modes.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
