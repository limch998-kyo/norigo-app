import 'package:flutter/material.dart';

class ModeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final String locale;
  final List<String>? modes;

  const ModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.locale = 'en',
    this.modes,
  });

  static const stayModes = ['centroid', 'minTotal'];
  static const meetupModes = ['centroid', 'minTotal', 'balanced'];

  static Map<String, Map<String, String>> get modeLabels => {
        'centroid': {
          'ja': '均等な距離',
          'en': 'Equal Distance',
          'ko': '균등 거리',
          'zh': '均等距离',
          'fr': 'Distance égale',
        },
        'minTotal': {
          'ja': '最短移動',
          'en': 'Min Travel',
          'ko': '최소 이동',
          'zh': '最短移动',
          'fr': 'Trajet min.',
        },
        'balanced': {
          'ja': '公平',
          'en': 'Fairest',
          'ko': '가장 공평하게',
          'zh': '最公平',
          'fr': 'Le plus équitable',
        },
      };

  static Map<String, Map<String, String>> get modeDescriptions => {
        'centroid': {
          'ja': 'どの観光地にも同じくらいの時間で到着',
          'en': 'Similar travel time to all spots',
          'ko': '모든 관광지에 비슷한 시간으로 도착',
          'zh': '到所有景点的时间相近',
          'fr': 'Temps de trajet similaire pour tous les sites',
        },
        'minTotal': {
          'ja': '観光地への合計移動時間が最も少ない',
          'en': 'Least total travel time to all spots',
          'ko': '모든 관광지까지 이동시간 합계가 가장 적음',
          'zh': '到所有景点的总移动时间最短',
          'fr': 'Temps de trajet total le plus court',
        },
        'balanced': {
          'ja': '一番遠い人も遠すぎない',
          'en': 'No one travels too far',
          'ko': '가장 먼 사람도 너무 멀지 않게',
          'zh': '最远的人也不会太远',
          'fr': 'Personne ne voyage trop loin',
        },
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeModes = modes ?? stayModes;

    return Row(
      children: activeModes.map((mode) {
        final isSelected = selected == mode;
        final label = modeLabels[mode]?[locale] ?? modeLabels[mode]?['en'] ?? mode;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mode != activeModes.last ? 8 : 0,
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
