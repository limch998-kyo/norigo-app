import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../providers/stay_provider.dart';
import '../../providers/saved_searches_provider.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Saved Searches ──
          _SavedSearchesSection(locale: locale, ref: ref),

          // ── Trips ──
          if (trips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              locale == 'ja' ? '旅行プラン' : locale == 'ko' ? '여행 플랜' : 'Trip Plans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...trips.map((trip) {
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
                onFindHotels: items.length >= 2 ? () { notifier.getItemsAsLandmarks(trip.id); } : null,
              );
            }),
          ],

          if (trips.isEmpty)
            _EmptyState(locale: locale),
        ],
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

class _SavedSearchesSection extends StatelessWidget {
  final String locale;
  final WidgetRef ref;

  const _SavedSearchesSection({required this.locale, required this.ref});

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedSearchesProvider);
    if (saved.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.bookmark, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            locale == 'ja' ? '保存した検索' : locale == 'ko' ? '저장된 검색' : 'Saved Searches',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ]),
        const SizedBox(height: 8),
        ...saved.map((search) {
          final regionLabel = {
            'kanto': locale == 'ko' ? '도쿄/간토' : 'Tokyo',
            'kansai': locale == 'ko' ? '오사카/간사이' : 'Osaka',
            'seoul': locale == 'ko' ? '서울' : 'Seoul',
            'busan': locale == 'ko' ? '부산' : 'Busan',
          }[search.region] ?? search.region;

          final budgetLabel = search.maxBudget != null
              ? (AppConstants.stayBudgetLabels[search.maxBudget]?[locale] ?? search.maxBudget!)
              : '';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Restore search and switch to hotel tab
                final notifier = ref.read(staySearchProvider.notifier);
                notifier.reset();
                for (final l in search.landmarks) {
                  notifier.addLandmark(l);
                }
                notifier.setRegion(search.region);
                notifier.setMode(search.mode);
                if (search.maxBudget != null) notifier.setBudget(search.maxBudget!);
                if (search.checkIn != null && search.checkOut != null) {
                  notifier.setDates(search.checkIn, search.checkOut);
                }
                // Switch to stay tab and search
                notifier.search();
                // Find MainShell to switch tab
                final scaffold = Scaffold.maybeOf(context);
                if (scaffold != null) {
                  // Navigate via bottom nav
                  final nav = context.findAncestorWidgetOfExactType<BottomNavigationBar>();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  // Info
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(search.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(4)),
                        child: Text(regionLabel, style: TextStyle(fontSize: 10, color: AppTheme.primary)),
                      ),
                      if (budgetLabel.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(budgetLabel, style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${search.landmarks.length} ${locale == 'ja' ? 'スポット' : locale == 'ko' ? '관광지' : 'spots'}',
                      style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                    ),
                  ])),

                  // Actions
                  Column(children: [
                    // Re-search button
                    ElevatedButton.icon(
                      onPressed: () {
                        final notifier = ref.read(staySearchProvider.notifier);
                        notifier.reset();
                        for (final l in search.landmarks) {
                          notifier.addLandmark(l);
                        }
                        notifier.setRegion(search.region);
                        notifier.setMode(search.mode);
                        if (search.maxBudget != null) notifier.setBudget(search.maxBudget!);
                        if (search.checkIn != null) notifier.setDates(search.checkIn, search.checkOut);
                        notifier.search();
                      },
                      icon: const Icon(Icons.search, size: 14),
                      label: Text(locale == 'ja' ? '再検索' : locale == 'ko' ? '재검색' : 'Search', style: const TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Delete
                    GestureDetector(
                      onTap: () => ref.read(savedSearchesProvider.notifier).remove(search.id),
                      child: Text(locale == 'ja' ? '削除' : locale == 'ko' ? '삭제' : 'Delete',
                        style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
                    ),
                  ]),
                ]),
              ),
            ),
          );
        }),
      ],
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
