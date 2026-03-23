import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../utils/tr.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final state = ref.watch(tripProvider);
    final notifier = ref.read(tripProvider.notifier);
    final theme = Theme.of(context);

    final trip = state.trips.where((t) => t.id == tripId).firstOrNull;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Trip not found')),
      );
    }

    final items = state.items.where((i) => i.tripId == tripId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    tr(locale, ja: 'スポットを追加しましょう', ko: '관광지를 추가해보세요', en: 'Add some spots', zh: '添加一些景点吧', fr: 'Ajoutez des sites'),
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              onReorder: (oldIndex, newIndex) {
                // Reorder handled locally (future enhancement)
              },
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  key: ValueKey(item.slug),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      item.region.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => notifier.removeItem(item.slug, tripId),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: items.length >= 2
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to stay search with these items
                  },
                  icon: const Icon(Icons.hotel),
                  label: Text(
                    tr(locale, ja: 'ホテルを探す', ko: '호텔 찾기', en: 'Find Hotels', zh: '查找酒店', fr: 'Trouver des hôtels'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
