import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/landmark_localizer.dart';
import '../../utils/tr.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final trip = ref.read(tripProvider).trips.where((t) => t.id == widget.tripId).firstOrNull;
    _notesController = TextEditingController(text: trip?.notes ?? '');
  }

  @override
  void dispose() {
    // Save notes on dispose
    final notes = _notesController.text.trim();
    ref.read(tripProvider.notifier).setNotes(widget.tripId, notes.isEmpty ? null : notes);
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final state = ref.watch(tripProvider);
    final notifier = ref.read(tripProvider.notifier);
    final theme = Theme.of(context);

    final trip = state.trips.where((t) => t.id == widget.tripId).firstOrNull;
    if (trip == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Trip not found')));
    }

    final items = state.items.where((i) => i.tripId == widget.tripId).toList();
    final hasCoords = items.any((i) => i.lat != 0 && i.lng != 0);

    // Budget label
    final budgetLabel = trip.maxBudget != null && trip.maxBudget != 'any'
        ? (AppConstants.stayBudgetLabels[trip.maxBudget]?[locale] ?? trip.maxBudget!)
        : tr(locale, ja: '未設定', ko: '미설정', en: 'Not set', zh: '未设置', fr: 'Non défini');

    // Date label
    final dateLabel = trip.checkIn != null && trip.checkOut != null
        ? '${trip.checkIn} → ${trip.checkOut}'
        : tr(locale, ja: '未設定', ko: '미설정', en: 'Not set', zh: '未设置', fr: 'Non défini');

    return Scaffold(
      appBar: AppBar(title: Text(trip.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Map
          if (hasCoords) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      items.map((i) => i.lat).reduce((a, b) => a + b) / items.length,
                      items.map((i) => i.lng).reduce((a, b) => a + b) / items.length,
                    ),
                    initialZoom: 12,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(markers: items.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      return Marker(
                        point: LatLng(item.lat, item.lng),
                        width: 28, height: 28,
                        child: Container(
                          decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Summary cards
          Row(children: [
            Expanded(child: _InfoCard(
              icon: Icons.calendar_today,
              label: tr(locale, ja: '日程', ko: '일정', en: 'Dates', zh: '日期', fr: 'Dates'),
              value: dateLabel,
            )),
            const SizedBox(width: 10),
            Expanded(child: _InfoCard(
              icon: Icons.payments,
              label: tr(locale, ja: '予算', ko: '예산', en: 'Budget', zh: '预算', fr: 'Budget'),
              value: budgetLabel,
            )),
          ]),
          const SizedBox(height: 16),

          // Spots list
          Text(
            tr(locale, ja: 'スポット (${items.length})', ko: '관광지 (${items.length})', en: 'Spots (${items.length})', zh: '景点 (${items.length})', fr: 'Sites (${items.length})'),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                tr(locale, ja: 'スポットを追加しましょう', ko: '관광지를 추가해보세요', en: 'Add some spots', zh: '添加一些景点吧', fr: 'Ajoutez des sites'),
                style: TextStyle(color: Colors.grey),
              ),
            )),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final name = LandmarkLocalizer.getLocalizedName(locale: locale, slug: item.slug, name: item.name, lat: item.lat, lng: item.lng) ?? item.name;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(children: [
                CircleAvatar(radius: 14, backgroundColor: AppTheme.primaryBg,
                  child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => notifier.removeItem(item.slug, widget.tripId),
                ),
              ]),
            );
          }),

          // Notes
          const SizedBox(height: 16),
          Text(
            tr(locale, ja: 'メモ', ko: '메모', en: 'Notes', zh: '备注', fr: 'Notes'),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: tr(locale, ja: 'メモを入力...', ko: '메모를 입력...', en: 'Add notes...', zh: '输入备注...', fr: 'Ajouter des notes...'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (value) {
              // Auto-save on change (debounced by dispose)
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: items.length >= 2
          ? SafeArea(child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Save notes before navigating
                  final notes = _notesController.text.trim();
                  notifier.setNotes(widget.tripId, notes.isEmpty ? null : notes);
                  Navigator.pop(context, 'find_hotels');
                },
                icon: const Icon(Icons.hotel),
                label: Text(tr(locale, ja: 'ホテルを探す', ko: '호텔 찾기', en: 'Find Hotels', zh: '查找酒店', fr: 'Trouver des hôtels')),
              ),
            ))
          : null,
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
