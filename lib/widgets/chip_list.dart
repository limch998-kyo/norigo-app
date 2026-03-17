import 'package:flutter/material.dart';

class ChipList extends StatelessWidget {
  final List<String> items;
  final void Function(int index) onRemove;

  const ChipList({
    super.key,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        return Chip(
          label: Text(
            entry.value,
            style: const TextStyle(fontSize: 13),
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => onRemove(entry.key),
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
