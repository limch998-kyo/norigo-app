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
          'ja': '均等',
          'en': 'Balanced Time',
          'ko': '균등',
          'zh': '均衡',
        },
        'minTotal': {
          'ja': '最短合計',
          'en': 'Min Total',
          'ko': '최단합계',
          'zh': '最短总计',
        },
        'balanced': {
          'ja': '公平',
          'en': 'Fair',
          'ko': '공평',
          'zh': '公平',
        },
      };

  static Map<String, Map<String, String>> get modeDescriptions => {
        'centroid': {
          'ja': '全員の移動時間を均等に',
          'en': 'Minimize variance in travel times',
          'ko': '모두의 이동시간을 균등하게',
          'zh': '使所有人的通勤时间均衡',
        },
        'minTotal': {
          'ja': '合計移動時間を最短に',
          'en': 'Minimize total travel time',
          'ko': '총 이동시간을 최소화',
          'zh': '最小化总通勤时间',
        },
        'balanced': {
          'ja': '最大移動時間を最小に',
          'en': 'Minimize max travel time',
          'ko': '최대 이동시간을 최소화',
          'zh': '最小化最长通勤时间',
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
