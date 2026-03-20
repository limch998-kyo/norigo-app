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

  static const _modes = ['centroid', 'minTotal'];

  static Map<String, Map<String, String>> get modeLabels => {
        'centroid': {
          'ja': '均等な距離',
          'en': 'Equal Distance',
          'ko': '균등 거리',
          'zh': '均等距离',
        },
        'minTotal': {
          'ja': '最短移動',
          'en': 'Min Travel',
          'ko': '최소 이동',
          'zh': '最短移动',
        },
      };

  static Map<String, Map<String, String>> get modeDescriptions => {
        'centroid': {
          'ja': 'どの観光地にも同じくらいの時間で到着',
          'en': 'Similar travel time to all spots',
          'ko': '모든 관광지에 비슷한 시간으로 도착',
          'zh': '到所有景点的时间相近',
        },
        'minTotal': {
          'ja': '観光地への合計移動時間が最も少ない',
          'en': 'Least total travel time to all spots',
          'ko': '모든 관광지까지 이동시간 합계가 가장 적음',
          'zh': '到所有景点的总移动时间最短',
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
