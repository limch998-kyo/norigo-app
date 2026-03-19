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
import '../../models/landmark.dart';

class TripScreen extends ConsumerWidget {
  final void Function(int)? onSwitchTab;
  const TripScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final state = ref.watch(tripProvider);
    final notifier = ref.read(tripProvider.notifier);

    // Split trips by country, sorted by most recently updated
    final japanTrips = state.trips
        .where((t) => t.country == 'japan' || t.country == null)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final koreaTrips = state.trips
        .where((t) => t.country == 'korea')
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Determine which section goes first (most recently updated trip)
    final japanLatest = japanTrips.isNotEmpty ? japanTrips.first.updatedAt : DateTime(2000);
    final koreaLatest = koreaTrips.isNotEmpty ? koreaTrips.first.updatedAt : DateTime(2000);
    final japanFirst = japanLatest.isAfter(koreaLatest);

    Widget buildTripSection(String label, String flag, List<Trip> trips) {
      if (trips.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          ...trips.map((trip) {
            final items = state.items.where((i) => i.tripId == trip.id).toList();
            final isActive = state.activeTripId == trip.id;
            return _TripCard(
              trip: trip,
              items: items,
              isActive: isActive,
              locale: locale,
              onTap: () => notifier.setActiveTrip(trip.id),
              onRename: () => _showRenameDialog(context, notifier, trip, locale),
              onDelete: () => _showDeleteDialog(context, notifier, trip, locale),
              onRemoveItem: (slug, tripId) => notifier.removeItem(slug, tripId),
              onAddSpot: () => _showAddSpotDialog(context, ref, trip, locale),
              onFindHotels: items.length >= 2 ? () {
                final landmarks = notifier.getItemsAsLandmarks(trip.id);
                final stayNotifier = ref.read(staySearchProvider.notifier);
                stayNotifier.reset();
                if (landmarks.isNotEmpty) stayNotifier.setRegion(landmarks.first.region);
                for (final l in landmarks) { stayNotifier.addLandmark(l); }
                final isKorea = ['seoul', 'busan'].contains(landmarks.firstOrNull?.region);
                final budget = isKorea ? 'under35000' : (locale == 'ja' ? 'under20000' : 'under30000');
                stayNotifier.setBudget(budget);
                if (trip.checkIn != null && trip.checkOut != null) {
                  stayNotifier.setDates(trip.checkIn!, trip.checkOut!);
                } else {
                  final checkIn = DateTime.now().add(const Duration(days: 30));
                  stayNotifier.setDates(checkIn.toIso8601String().substring(0, 10),
                    checkIn.add(const Duration(days: 3)).toIso8601String().substring(0, 10));
                }
                onSwitchTab?.call(1);
              } : null,
            );
          }),
        ],
      );
    }

    final japanLabel = locale == 'ja' ? '日本' : locale == 'ko' ? '일본' : 'Japan';
    final koreaLabel = locale == 'ja' ? '韓国' : locale == 'ko' ? '한국' : 'Korea';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Saved Searches ──
          _SavedSearchesSection(locale: locale, ref: ref, onSwitchTab: onSwitchTab),

          // ── Trips (both countries, most recent first) ──
          if (japanFirst) ...[
            buildTripSection(japanLabel, '🇯🇵', japanTrips),
            buildTripSection(koreaLabel, '🇰🇷', koreaTrips),
          ] else ...[
            buildTripSection(koreaLabel, '🇰🇷', koreaTrips),
            buildTripSection(japanLabel, '🇯🇵', japanTrips),
          ],

          if (japanTrips.isEmpty && koreaTrips.isEmpty && state.items.isEmpty)
            _EmptyState(locale: locale),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, notifier, locale),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSpotDialog(BuildContext context, WidgetRef ref, Trip trip, String locale) {
    final controller = TextEditingController();
    final api = ref.read(apiClientProvider);
    final notifier = ref.read(tripProvider.notifier);
    // Determine search region from trip's country
    final tripItems = ref.read(tripProvider).items.where((i) => i.tripId == trip.id);
    final tripRegion = tripItems.isNotEmpty ? tripItems.first.region : (trip.country == 'korea' ? 'seoul' : 'kanto');

    showDialog(
      context: context,
      builder: (ctx) {
        List<Landmark> results = [];
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(locale == 'ja' ? 'スポットを追加' : locale == 'ko' ? '스팟 추가' : 'Add Spot'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: locale == 'ja' ? '観光地・レストランを検索' : locale == 'ko' ? '관광지 또는 음식점 검색' : 'Search landmarks or restaurants',
                  prefixIcon: const Icon(Icons.search, size: 18),
                ),
                onChanged: (q) async {
                  if (q.length < 2) { setDialogState(() => results = []); return; }
                  final r = await api.searchLandmarks(q, region: tripRegion, locale: locale);
                  setDialogState(() => results = r);
                },
              ),
              const SizedBox(height: 8),
              if (results.isEmpty && controller.text.length >= 2)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    locale == 'ja' ? '結果がありません' : locale == 'ko' ? '결과가 없습니다' : 'No results',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ...results.take(5).map((l) => ListTile(
                dense: true,
                leading: const Icon(Icons.place, size: 18),
                title: Text(l.name, style: const TextStyle(fontSize: 13)),
                subtitle: l.nameEn != null ? Text(l.nameEn!, style: TextStyle(fontSize: 10, color: Colors.grey)) : null,
                onTap: () {
                  notifier.addItem(l, tripId: trip.id, locale: locale);
                  Navigator.pop(ctx);
                },
              )),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text(locale == 'ja' ? 'キャンセル' : locale == 'ko' ? '취소' : 'Cancel')),
            ],
          );
        });
      },
    );
  }

  void _showCreateDialog(
      BuildContext context, TripNotifier notifier, String locale) {
    final regions = [
      {'id': 'kanto', 'country': 'japan', 'label': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto'}},
      {'id': 'kansai', 'country': 'japan', 'label': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai'}},
      {'id': 'seoul', 'country': 'korea', 'label': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul'}},
      {'id': 'busan', 'country': 'korea', 'label': {'ja': '釜山', 'ko': '부산', 'en': 'Busan'}},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale == 'ja' ? '新しい旅行プラン' : locale == 'ko' ? '새 여행 플랜' : 'New Trip Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locale == 'ja' ? '地域を選択してください' : locale == 'ko' ? '지역을 선택해주세요' : 'Select region',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 12),
            ...regions.map((r) {
              final label = (r['label'] as Map<String, String>)[locale] ?? (r['label'] as Map<String, String>)['en']!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      notifier.createTrip(label, country: r['country'] as String);
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    child: Text(label),
                  ),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale == 'ja' ? 'キャンセル' : locale == 'ko' ? '취소' : 'Cancel'),
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
              ? '「${localizedTripName(trip.name, locale)}」を削除しますか？'
              : locale == 'ko'
                  ? '"${localizedTripName(trip.name, locale)}"을 삭제하시겠습니까?'
                  : 'Delete "${localizedTripName(trip.name, locale)}"?',
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

class _TripCard extends ConsumerWidget {
  final Trip trip;
  final List<TripItem> items;
  final bool isActive;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onFindHotels;
  final VoidCallback? onAddSpot;
  final void Function(String slug, String tripId)? onRemoveItem;

  const _TripCard({
    required this.trip,
    required this.items,
    required this.isActive,
    required this.locale,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    this.onFindHotels,
    this.onAddSpot,
    this.onRemoveItem,
  });

  void _showDateDialog(BuildContext context, WidgetRef ref, Trip trip, String locale) async {
    final now = DateTime.now();
    final initialRange = (trip.checkIn != null && trip.checkOut != null)
        ? DateTimeRange(start: DateTime.parse(trip.checkIn!), end: DateTime.parse(trip.checkOut!))
        : DateTimeRange(start: now.add(const Duration(days: 30)), end: now.add(const Duration(days: 33)));

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: locale == 'ja' ? 'チェックイン〜チェックアウト' : locale == 'ko' ? '체크인 ~ 체크아웃' : 'Check-in ~ Check-out',
      saveText: locale == 'ja' ? '設定' : locale == 'ko' ? '설정' : 'Set',
    );
    if (picked == null) return;

    ref.read(tripProvider.notifier).setTripDates(
      trip.id,
      picked.start.toIso8601String().substring(0, 10),
      picked.end.toIso8601String().substring(0, 10),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      localizedTripName(trip.name, locale),
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
              if (trip.checkIn != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today, size: 14, color: AppTheme.mutedForeground),
                  const SizedBox(width: 6),
                  Text(
                    '${trip.checkIn} → ${trip.checkOut ?? "?"}',
                    style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                  ),
                ]),
              ],
              const SizedBox(height: 8),
              // Show items inline
              if (items.isNotEmpty) ...[
                ...items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      CircleAvatar(radius: 12, backgroundColor: AppTheme.primaryBg,
                        child: Text('${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                      if (isActive)
                        GestureDetector(
                          onTap: () => onRemoveItem?.call(item.slug, item.tripId),
                          child: Icon(Icons.close, size: 14, color: AppTheme.mutedForeground),
                        ),
                    ]),
                  );
                }),
                const SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(Icons.place, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    locale == 'ja'
                        ? '${items.length}件のスポット'
                        : locale == 'ko'
                            ? '${items.length}개 관광지'
                            : '${items.length} spots',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (onAddSpot != null)
                    _CompactButton(icon: Icons.add_location_alt, label: locale == 'ja' ? 'スポット追加' : locale == 'ko' ? '스팟 추가' : 'Add Spot', onTap: onAddSpot!),
                  _CompactButton(icon: Icons.calendar_month, label: trip.checkIn != null ? (locale == 'ja' ? '日程変更' : locale == 'ko' ? '날짜 변경' : 'Dates') : (locale == 'ja' ? '日程設定' : locale == 'ko' ? '날짜 설정' : 'Set dates'), onTap: () => _showDateDialog(context, ref, trip, locale)),
                  if (onFindHotels != null)
                    _CompactButton(icon: Icons.hotel, label: locale == 'ja' ? 'ホテル検索' : locale == 'ko' ? '호텔 찾기' : 'Hotels', onTap: onFindHotels!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MySpotsSection extends StatelessWidget {
  final String locale;
  final TripState state;
  final TripNotifier notifier;
  final void Function(int)? onSwitchTab;
  final WidgetRef ref;

  const _MySpotsSection({required this.locale, required this.state, required this.notifier, this.onSwitchTab, required this.ref});

  @override
  Widget build(BuildContext context) {
    final items = state.activeItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.luggage, size: 18, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            locale == 'ja' ? 'マイスポット' : locale == 'ko' ? '내 관광지' : 'My Spots',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('${items.length}${locale == 'ja' ? '件' : locale == 'ko' ? '개' : ''}',
            style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
        ]),
        const SizedBox(height: 8),

        // Spot list
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryBg,
                child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(
                  _regionLabel(item.region),
                  style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
                ),
              ])),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: AppTheme.mutedForeground),
                visualDensity: VisualDensity.compact,
                onPressed: () => notifier.removeItem(item.slug, item.tripId),
              ),
            ]),
          );
        }),

        // Action buttons
        if (items.length >= 2)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final landmarks = notifier.getItemsAsLandmarks(state.activeTripId!);
                  final stayNotifier = ref.read(staySearchProvider.notifier);
                  stayNotifier.reset();
                  if (landmarks.isNotEmpty) stayNotifier.setRegion(landmarks.first.region);
                  for (final l in landmarks) { stayNotifier.addLandmark(l); }
                  final budget = locale == 'ja' ? 'under20000' : locale == 'ko' ? 'under30000' : 'under50000';
                  stayNotifier.setBudget(budget);
                  final checkIn = DateTime.now().add(const Duration(days: 30));
                  stayNotifier.setDates(checkIn.toIso8601String().substring(0, 10),
                    checkIn.add(const Duration(days: 3)).toIso8601String().substring(0, 10));
                  onSwitchTab?.call(1);
                },
                icon: const Icon(Icons.hotel, size: 16),
                label: Text(
                  locale == 'ja' ? 'この${items.length}スポットでホテル検索'
                      : locale == 'ko' ? '이 ${items.length}개로 호텔 검색'
                      : 'Search hotels for ${items.length} spots',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _regionLabel(String region) {
    const labels = {
      'kanto': {'ja': '東京・関東', 'ko': '도쿄/간토', 'en': 'Tokyo'},
      'kansai': {'ja': '大阪・関西', 'ko': '오사카/간사이', 'en': 'Osaka'},
      'seoul': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul'},
      'busan': {'ja': '釜山', 'ko': '부산', 'en': 'Busan'},
    };
    return labels[region]?[locale] ?? region;
  }
}

class _SavedSearchesSection extends StatelessWidget {
  final String locale;
  final WidgetRef ref;
  final void Function(int)? onSwitchTab;

  const _SavedSearchesSection({required this.locale, required this.ref, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    // Show all saved searches (no country filter)
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

          return Dismissible(
            key: ValueKey(search.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.delete, color: Colors.red.shade400),
            ),
            confirmDismiss: (direction) async {
              return true;
            },
            onDismissed: (direction) {
              ref.read(savedSearchesProvider.notifier).remove(search.id);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Restore search and switch to hotel tab
                  final notifier = ref.read(staySearchProvider.notifier);
                  notifier.reset();
                  notifier.setRegion(search.region);
                  for (final l in search.landmarks) {
                    notifier.addLandmark(l);
                  }
                  notifier.setMode(search.mode);
                  if (search.maxBudget != null) notifier.setBudget(search.maxBudget!);
                  if (search.checkIn != null && search.checkOut != null) {
                    notifier.setDates(search.checkIn, search.checkOut);
                  }
                  notifier.setSavedSearchId(search.id);
                  notifier.search();
                  onSwitchTab?.call(1);
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
                          notifier.setRegion(search.region);
                          for (final l in search.landmarks) {
                            notifier.addLandmark(l);
                          }
                          notifier.setMode(search.mode);
                          if (search.maxBudget != null) notifier.setBudget(search.maxBudget!);
                          if (search.checkIn != null) notifier.setDates(search.checkIn, search.checkOut);
                          notifier.setSavedSearchId(search.id);
                          notifier.search();
                          onSwitchTab?.call(1);
                        },
                        icon: const Icon(Icons.search, size: 14),
                        label: Text(locale == 'ja' ? '再検索' : locale == 'ko' ? '재검색' : 'Search', style: const TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Rename + Delete
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        GestureDetector(
                          onTap: () => _showRenameSearchDialog(context, ref, search, locale),
                          child: Text(locale == 'ja' ? '名前変更' : locale == 'ko' ? '이름변경' : 'Rename',
                            style: TextStyle(fontSize: 10, color: AppTheme.primary)),
                        ),
                        Text(' · ', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
                        GestureDetector(
                          onTap: () => ref.read(savedSearchesProvider.notifier).remove(search.id),
                          child: Text(locale == 'ja' ? '削除' : locale == 'ko' ? '삭제' : 'Delete',
                            style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
                        ),
                      ]),
                    ]),
                  ]),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showRenameSearchDialog(BuildContext context, WidgetRef ref, SavedSearch search, String locale) {
    final controller = TextEditingController(text: search.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale == 'ja' ? '名前を変更' : locale == 'ko' ? '이름 변경' : 'Rename'),
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
                ref.read(savedSearchesProvider.notifier).rename(search.id, name);
                Navigator.pop(ctx);
              }
            },
            child: Text(locale == 'ja' ? '保存' : locale == 'ko' ? '저장' : 'Save'),
          ),
        ],
      ),
    );
  }
}

/// Translates known region-based trip names to the current locale.
/// If the stored name doesn't match a known entry, returns it as-is.
String localizedTripName(String storedName, String locale) {
  const tripNameMap = {
    // Korean stored names
    '도쿄·간토': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto'},
    '오사카·간사이': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai'},
    '서울': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul'},
    '부산': {'ja': '釜山', 'ko': '부산', 'en': 'Busan'},
    // Japanese stored names
    '東京・関東': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto'},
    '大阪・関西': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai'},
    'ソウル': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul'},
    '釜山': {'ja': '釜山', 'ko': '부산', 'en': 'Busan'},
    // English stored names
    'Tokyo / Kanto': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto'},
    'Osaka / Kansai': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai'},
    'Seoul': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul'},
    'Busan': {'ja': '釜山', 'ko': '부산', 'en': 'Busan'},
  };

  final mapped = tripNameMap[storedName];
  if (mapped != null) return mapped[locale] ?? mapped['en'] ?? storedName;
  return storedName;
}

class _CompactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CompactButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500)),
        ]),
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
