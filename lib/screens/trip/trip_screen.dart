import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../providers/stay_provider.dart';
// saved_searches_provider removed — searches are now part of trips
import '../../models/trip.dart';
import '../../models/landmark.dart';
import '../../utils/tr.dart';
import '../../services/landmark_localizer.dart';

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
                // Read latest trip state (dates/settings may have been updated)
                final latestTrip = ref.read(tripProvider).trips.firstWhere((t) => t.id == trip.id, orElse: () => trip);
                final landmarks = notifier.getItemsAsLandmarks(trip.id);
                final stayNotifier = ref.read(staySearchProvider.notifier);
                stayNotifier.reset();
                stayNotifier.setSavedSearchId(trip.id);
                if (landmarks.isNotEmpty) stayNotifier.setRegion(landmarks.first.region);
                for (final l in landmarks) { stayNotifier.addLandmark(l); }
                // Restore saved search settings from trip, or use defaults
                if (latestTrip.searchMode != null) {
                  stayNotifier.setMode(latestTrip.searchMode!);
                }
                if (latestTrip.maxBudget != null) {
                  stayNotifier.setBudget(latestTrip.maxBudget!);
                } else {
                  final isKorea = ['seoul', 'busan'].contains(landmarks.firstOrNull?.region);
                  final budget = isKorea ? '25000-35000' : '10000-30000';
                  stayNotifier.setBudget(budget);
                }
                if (latestTrip.checkIn != null && latestTrip.checkOut != null) {
                  stayNotifier.setDates(latestTrip.checkIn!, latestTrip.checkOut!);
                } else {
                  final checkIn = DateTime.now().add(const Duration(days: 30));
                  stayNotifier.setDates(checkIn.toIso8601String().substring(0, 10),
                    checkIn.add(const Duration(days: 3)).toIso8601String().substring(0, 10));
                }
                stayNotifier.search();
                onSwitchTab?.call(1);
              } : null,
            );
          }),
        ],
      );
    }

    final japanLabel = tr(locale, ja: '日本', ko: '일본', en: 'Japan', zh: '日本', fr: 'Japon');
    final koreaLabel = tr(locale, ja: '韓国', ko: '한국', en: 'Korea', zh: '韩国', fr: 'Corée');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            title: Text(tr(locale, ja: 'スポットを追加', ko: '스팟 추가', en: 'Add Spot', zh: '添加景点', fr: 'Ajouter un site')),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: tr(locale, ja: '観光地・レストランを検索', ko: '관광지 또는 음식점 검색', en: 'Search landmarks or restaurants', zh: '搜索景点或餐厅', fr: 'Rechercher des sites ou restaurants'),
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
                    tr(locale, ja: '結果がありません', ko: '결과가 없습니다', en: 'No results', zh: '没有结果', fr: 'Aucun résultat'),
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
                child: Text(tr(locale, ja: 'キャンセル', ko: '취소', en: 'Cancel', zh: '取消', fr: 'Annuler'))),
            ],
          );
        });
      },
    );
  }

  void _showCreateDialog(
      BuildContext context, TripNotifier notifier, String locale) {
    final regions = [
      {'id': 'kanto', 'country': 'japan', 'label': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto', 'fr': 'Tokyo / Kanto'}},
      {'id': 'kansai', 'country': 'japan', 'label': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai', 'fr': 'Osaka / Kansai'}},
      {'id': 'seoul', 'country': 'korea', 'label': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul', 'fr': 'Séoul'}},
      {'id': 'busan', 'country': 'korea', 'label': {'ja': '釜山', 'ko': '부산', 'en': 'Busan', 'fr': 'Busan'}},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(locale, ja: '新しい旅行プラン', ko: '새 여행 플랜', en: 'New Trip Plan', zh: '新旅行计划', fr: 'Nouveau voyage')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr(locale, ja: '地域を選択してください', ko: '지역을 선택해주세요', en: 'Select region', zh: '选择地区', fr: 'Sélectionnez une région'),
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
            child: Text(tr(locale, ja: 'キャンセル', ko: '취소', en: 'Cancel', zh: '取消', fr: 'Annuler')),
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
          tr(locale, ja: '名前を変更', ko: '이름 변경', en: 'Rename', zh: '重命名', fr: 'Renommer'),
        ),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(locale, ja: 'キャンセル', ko: '취소', en: 'Cancel', zh: '取消', fr: 'Annuler')),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                notifier.renameTrip(trip.id, name);
                Navigator.pop(ctx);
              }
            },
            child: Text(tr(locale, ja: '保存', ko: '저장', en: 'Save', zh: '保存', fr: 'Enregistrer')),
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
          tr(locale, ja: '削除確認', ko: '삭제 확인', en: 'Delete Trip', zh: '确认删除', fr: 'Supprimer le voyage'),
        ),
        content: Text(
          tr(locale,
            ja: '「${localizedTripName(trip.name, locale)}」を削除しますか？',
            ko: '"${localizedTripName(trip.name, locale)}"을 삭제하시겠습니까?',
            en: 'Delete "${localizedTripName(trip.name, locale)}"?',
            zh: '确定删除"${localizedTripName(trip.name, locale)}"吗？',
            fr: 'Supprimer "${localizedTripName(trip.name, locale)}" ?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(locale, ja: 'キャンセル', ko: '취소', en: 'Cancel', zh: '取消', fr: 'Annuler')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              notifier.deleteTrip(trip.id);
              Navigator.pop(ctx);
            },
            child: Text(tr(locale, ja: '削除', ko: '삭제', en: 'Delete', zh: '删除', fr: 'Supprimer')),
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
      helpText: tr(locale, ja: 'チェックイン〜チェックアウト', ko: '체크인 ~ 체크아웃', en: 'Check-in ~ Check-out', zh: '入住 ~ 退房', fr: 'Arrivée ~ Départ'),
      saveText: tr(locale, ja: '設定', ko: '설정', en: 'Set', zh: '设置', fr: 'Définir'),
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
                        tr(locale, ja: 'アクティブ', ko: '활성', en: 'Active', zh: '活跃', fr: 'Actif'),
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
                        child: Text(tr(locale, ja: '名前変更', ko: '이름변경', en: 'Rename', zh: '重命名', fr: 'Renommer')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          tr(locale, ja: '削除', ko: '삭제', en: 'Delete', zh: '删除', fr: 'Supprimer'),
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
                      Expanded(child: Text(
                        LandmarkLocalizer.getLocalizedName(locale: locale, slug: item.slug, name: item.name, lat: item.lat, lng: item.lng) ?? item.name,
                        style: const TextStyle(fontSize: 13))),
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
                    tr(locale, ja: '${items.length}件のスポット', ko: '${items.length}개 관광지', en: '${items.length} spots', zh: '${items.length}个景点', fr: '${items.length} sites'),
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
                    _CompactButton(icon: Icons.add_location_alt, label: tr(locale, ja: 'スポット追加', ko: '스팟 추가', en: 'Add Spot', zh: '添加景点', fr: 'Ajouter'), onTap: onAddSpot!),
                  _CompactButton(icon: Icons.calendar_month, label: trip.checkIn != null ? tr(locale, ja: '日程変更', ko: '날짜 변경', en: 'Dates', zh: '修改日期', fr: 'Dates') : tr(locale, ja: '日程設定', ko: '날짜 설정', en: 'Set dates', zh: '设置日期', fr: 'Dates'), onTap: () => _showDateDialog(context, ref, trip, locale)),
                  if (onFindHotels != null)
                    _CompactButton(icon: Icons.hotel, label: tr(locale, ja: 'ホテル検索', ko: '호텔 찾기', en: 'Hotels', zh: '搜索酒店', fr: 'Hôtels'), onTap: onFindHotels!),
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
            tr(locale, ja: 'マイスポット', ko: '내 관광지', en: 'My Spots', zh: '我的景点', fr: 'Mes sites'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text('${items.length}${tr(locale, ja: '件', ko: '개', en: '', zh: '个', fr: '')}',
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
                Text(LandmarkLocalizer.getLocalizedName(locale: locale, slug: item.slug, name: item.name, lat: item.lat, lng: item.lng) ?? item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                  final isKorea = landmarks.isNotEmpty && ['seoul', 'busan'].contains(landmarks.first.region);
                  stayNotifier.setBudget(isKorea ? '25000-35000' : '10000-30000');
                  final checkIn = DateTime.now().add(const Duration(days: 30));
                  stayNotifier.setDates(checkIn.toIso8601String().substring(0, 10),
                    checkIn.add(const Duration(days: 3)).toIso8601String().substring(0, 10));
                  onSwitchTab?.call(1);
                },
                icon: const Icon(Icons.hotel, size: 16),
                label: Text(
                  tr(locale, ja: 'この${items.length}スポットでホテル検索', ko: '이 ${items.length}개로 호텔 검색', en: 'Search hotels for ${items.length} spots', zh: '为${items.length}个景点搜索酒店', fr: 'Chercher des hôtels pour ${items.length} sites'),
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
      'kanto': {'ja': '東京・関東', 'ko': '도쿄/간토', 'en': 'Tokyo', 'fr': 'Tokyo'},
      'kansai': {'ja': '大阪・関西', 'ko': '오사카/간사이', 'en': 'Osaka', 'fr': 'Osaka'},
      'seoul': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul', 'fr': 'Séoul'},
      'busan': {'ja': '釜山', 'ko': '부산', 'en': 'Busan', 'fr': 'Busan'},
    };
    return labels[region]?[locale] ?? region;
  }
}

/// Translates known region-based trip names to the current locale.
/// If the stored name doesn't match a known entry, returns it as-is.
String localizedTripName(String storedName, String locale) {
  const tripNameMap = {
    // Korean stored names
    '도쿄·간토': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto', 'fr': 'Tokyo / Kanto'},
    '오사카·간사이': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai', 'fr': 'Osaka / Kansai'},
    '서울': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul', 'fr': 'Séoul'},
    '부산': {'ja': '釜山', 'ko': '부산', 'en': 'Busan', 'fr': 'Busan'},
    // Japanese stored names
    '東京・関東': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto', 'fr': 'Tokyo / Kanto'},
    '大阪・関西': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai', 'fr': 'Osaka / Kansai'},
    'ソウル': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul', 'fr': 'Séoul'},
    '釜山': {'ja': '釜山', 'ko': '부산', 'en': 'Busan', 'fr': 'Busan'},
    // English stored names
    'Tokyo / Kanto': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto', 'fr': 'Tokyo / Kanto'},
    'Osaka / Kansai': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai', 'fr': 'Osaka / Kansai'},
    'Seoul': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul', 'fr': 'Séoul'},
    'Busan': {'ja': '釜山', 'ko': '부산', 'en': 'Busan', 'fr': 'Busan'},
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
            tr(locale, ja: 'まだ旅行がありません', ko: '아직 여행이 없습니다', en: 'No trips yet', zh: '还没有旅行', fr: 'Aucun voyage pour l\'instant'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(locale, ja: '＋ボタンから新しい旅行を作成', ko: '+ 버튼으로 새 여행 생성', en: 'Tap + to create a new trip', zh: '点击+创建新旅行', fr: 'Appuyez sur + pour créer un voyage'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
