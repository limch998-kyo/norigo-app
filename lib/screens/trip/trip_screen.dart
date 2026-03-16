import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../models/trip.dart';

class TripScreen extends ConsumerWidget {
  const TripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final state = ref.watch(tripProvider);
    final notifier = ref.read(tripProvider.notifier);

    final trips = state.filteredTrips;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripTitle),
        actions: [
          // Country toggle
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'japan',
                label: Text(
                  locale == 'ja' ? '日本' : locale == 'ko' ? '일본' : 'Japan',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              ButtonSegment(
                value: 'korea',
                label: Text(
                  locale == 'ja' ? '韓国' : locale == 'ko' ? '한국' : 'Korea',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            selected: {state.country},
            onSelectionChanged: (s) => notifier.setCountry(s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: trips.isEmpty
          ? _EmptyState(locale: locale)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                final items = state.items.where((i) => i.tripId == trip.id).toList();
                final isActive = state.activeTripId == trip.id;

                return _TripCard(
                  trip: trip,
                  itemCount: items.length,
                  isActive: isActive,
                  locale: locale,
                  onTap: () => notifier.setActiveTrip(trip.id),
                  onRename: () => _showRenameDialog(context, notifier, trip, locale),
                  onDelete: () => _showDeleteDialog(context, notifier, trip, locale),
                  onFindHotels: items.length >= 2
                      ? () {
                          // Navigate to stay search with trip items
                          // Navigate to stay search with trip items
                          notifier.getItemsAsLandmarks(trip.id);
                        }
                      : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, notifier, locale),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, TripNotifier notifier, String locale) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          locale == 'ja'
              ? '新しい旅行'
              : locale == 'ko'
                  ? '새 여행'
                  : 'New Trip',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: locale == 'ja'
                ? '旅行名を入力'
                : locale == 'ko'
                    ? '여행 이름 입력'
                    : 'Enter trip name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale == 'ja' ? 'キャンセル' : locale == 'ko' ? '취소' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                notifier.createTrip(name);
                Navigator.pop(ctx);
              }
            },
            child: Text(locale == 'ja' ? '作成' : locale == 'ko' ? '생성' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, TripNotifier notifier, Trip trip, String locale) {
    final controller = TextEditingController(text: trip.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          locale == 'ja' ? '名前を変更' : locale == 'ko' ? '이름 변경' : 'Rename',
        ),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale == 'ja' ? 'キャンセル' : locale == 'ko' ? '취소' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                notifier.renameTrip(trip.id, name);
                Navigator.pop(ctx);
              }
            },
            child: Text(locale == 'ja' ? '保存' : locale == 'ko' ? '저장' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, TripNotifier notifier, Trip trip, String locale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          locale == 'ja' ? '削除確認' : locale == 'ko' ? '삭제 확인' : 'Delete Trip',
        ),
        content: Text(
          locale == 'ja'
              ? '「${trip.name}」を削除しますか？'
              : locale == 'ko'
                  ? '"${trip.name}"을 삭제하시겠습니까?'
                  : 'Delete "${trip.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale == 'ja' ? 'キャンセル' : locale == 'ko' ? '취소' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              notifier.deleteTrip(trip.id);
              Navigator.pop(ctx);
            },
            child: Text(locale == 'ja' ? '削除' : locale == 'ko' ? '삭제' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final int itemCount;
  final bool isActive;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onFindHotels;

  const _TripCard({
    required this.trip,
    required this.itemCount,
    required this.isActive,
    required this.locale,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    this.onFindHotels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        locale == 'ja' ? 'アクティブ' : locale == 'ko' ? '활성' : 'Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      trip.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Text(locale == 'ja' ? '名前変更' : locale == 'ko' ? '이름변경' : 'Rename'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          locale == 'ja' ? '削除' : locale == 'ko' ? '삭제' : 'Delete',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    locale == 'ja'
                        ? '$itemCount件のスポット'
                        : locale == 'ko'
                            ? '$itemCount개 관광지'
                            : '$itemCount spots',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  if (onFindHotels != null)
                    TextButton.icon(
                      onPressed: onFindHotels,
                      icon: const Icon(Icons.hotel, size: 16),
                      label: Text(
                        locale == 'ja'
                            ? 'ホテルを探す'
                            : locale == 'ko'
                                ? '호텔 찾기'
                                : 'Find Hotels',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String locale;

  const _EmptyState({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            locale == 'ja'
                ? 'まだ旅行がありません'
                : locale == 'ko'
                    ? '아직 여행이 없습니다'
                    : 'No trips yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            locale == 'ja'
                ? '＋ボタンから新しい旅行を作成'
                : locale == 'ko'
                    ? '+ 버튼으로 새 여행 생성'
                    : 'Tap + to create a new trip',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
