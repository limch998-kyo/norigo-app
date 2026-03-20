import 'package:flutter/material.dart';

class ModeTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final String locale;

  const ModeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    this.locale = 'en',
  });

  static const _modes = ['centroid', 'minTotal', 'balanced'];

  static const _labels = {
    'centroid': {'ja': '中間地点', 'en': 'Middle Point', 'ko': '중간 지점', 'zh': '中间点'},
    'minTotal': {'ja': '最速', 'en': 'Fastest', 'ko': '가장 빠르게', 'zh': '最快'},
    'balanced': {'ja': '公平', 'en': 'Fairest', 'ko': '가장 공평하게', 'zh': '最公平'},
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: _modes.map((mode) {
          final isSelected = selected == mode;
          final label = _labels[mode]?[locale] ?? _labels[mode]?['en'] ?? mode;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
