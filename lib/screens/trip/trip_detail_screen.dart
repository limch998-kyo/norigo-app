import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/landmark_localizer.dart';
import '../../services/api_client.dart';
import '../../providers/app_providers.dart' show apiClientProvider;
import '../../models/landmark.dart';
import '../../models/trip.dart';
import '../../utils/tr.dart';
import '../../providers/trip_stay_provider.dart';
import '../../providers/stay_provider.dart';
import '../../app.dart';
import '../../widgets/stay_inline_map.dart';

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

  void _showAddSpotDialog(BuildContext context, WidgetRef ref, Trip trip, String locale) {
    final controller = TextEditingController();
    final api = ref.read(apiClientProvider);
    final notifier = ref.read(tripProvider.notifier);
    final tripItems = ref.read(tripProvider).items.where((i) => i.tripId == trip.id);
    final tripRegion = tripItems.isNotEmpty ? tripItems.first.region : (trip.region ?? (trip.country == 'korea' ? 'seoul' : 'kanto'));

    // Popular spots per region for recommendations
    const popularSpots = {
      'kanto': [
        {'slug': 'shibuya-crossing', 'name': '渋谷', 'nameEn': 'Shibuya', 'nameKo': '시부야', 'lat': 35.6595, 'lng': 139.7004, 'icon': 'place'},
        {'slug': 'shinjuku', 'name': '新宿', 'nameEn': 'Shinjuku', 'nameKo': '신주쿠', 'lat': 35.6852, 'lng': 139.71, 'icon': 'place'},
        {'slug': 'asakusa-senso-ji', 'name': '浅草寺', 'nameEn': 'Asakusa', 'nameKo': '아사쿠사', 'lat': 35.7148, 'lng': 139.7967, 'icon': 'place'},
        {'slug': 'tokyo-tower', 'name': '東京タワー', 'nameEn': 'Tokyo Tower', 'nameKo': '도쿄타워', 'lat': 35.6586, 'lng': 139.7454, 'icon': 'place'},
        {'slug': 'harajuku', 'name': '原宿', 'nameEn': 'Harajuku', 'nameKo': '하라주쿠', 'lat': 35.6702, 'lng': 139.7026, 'icon': 'place'},
        {'slug': 'ichiran-shibuya', 'name': '一蘭 渋谷店', 'nameEn': 'Ichiran Shibuya', 'nameKo': '이치란 시부야', 'lat': 35.6610, 'lng': 139.6988, 'icon': 'restaurant'},
      ],
      'kansai': [
        {'slug': 'dotonbori', 'name': '道頓堀', 'nameEn': 'Dotonbori', 'nameKo': '도톤보리', 'lat': 34.6687, 'lng': 135.5021, 'icon': 'place'},
        {'slug': 'fushimi-inari-taisha', 'name': '伏見稲荷大社', 'nameEn': 'Fushimi Inari', 'nameKo': '후시미이나리', 'lat': 34.9671, 'lng': 135.7727, 'icon': 'place'},
        {'slug': 'kiyomizu-dera', 'name': '清水寺', 'nameEn': 'Kiyomizu-dera', 'nameKo': '기요미즈데라', 'lat': 34.9949, 'lng': 135.785, 'icon': 'place'},
        {'slug': 'osaka-castle', 'name': '大阪城', 'nameEn': 'Osaka Castle', 'nameKo': '오사카성', 'lat': 34.6873, 'lng': 135.5262, 'icon': 'place'},
        {'slug': 'kuromon-market', 'name': '黒門市場', 'nameEn': 'Kuromon Market', 'nameKo': '구로몬시장', 'lat': 34.6681, 'lng': 135.5097, 'icon': 'restaurant'},
      ],
      'seoul': [
        {'slug': 'myeongdong', 'name': '명동', 'nameEn': 'Myeongdong', 'nameKo': '명동', 'lat': 37.5636, 'lng': 126.9869, 'icon': 'place'},
        {'slug': 'hongdae', 'name': '홍대', 'nameEn': 'Hongdae', 'nameKo': '홍대', 'lat': 37.5563, 'lng': 126.9237, 'icon': 'place'},
        {'slug': 'gangnam', 'name': '강남', 'nameEn': 'Gangnam', 'nameKo': '강남', 'lat': 37.4979, 'lng': 127.0276, 'icon': 'place'},
        {'slug': 'gyeongbokgung', 'name': '景福宮', 'nameEn': 'Gyeongbokgung', 'nameKo': '경복궁', 'lat': 37.5796, 'lng': 126.977, 'icon': 'place'},
      ],
      'kyushu': [
        {'slug': 'tenjin', 'name': '天神', 'nameEn': 'Tenjin', 'nameKo': '텐진', 'lat': 33.5903, 'lng': 130.3990, 'icon': 'place'},
        {'slug': 'canal-city-hakata', 'name': 'キャナルシティ博多', 'nameEn': 'Canal City Hakata', 'nameKo': '캐널시티 하카타', 'lat': 33.5895, 'lng': 130.4107, 'icon': 'place'},
        {'slug': 'dazaifu-tenmangu', 'name': '太宰府天満宮', 'nameEn': 'Dazaifu Tenmangu', 'nameKo': '다자이후 텐만구', 'lat': 33.5194, 'lng': 130.5350, 'icon': 'place'},
        {'slug': 'nakasu', 'name': '中洲', 'nameEn': 'Nakasu', 'nameKo': '나카스', 'lat': 33.5922, 'lng': 130.4042, 'icon': 'place'},
        {'slug': 'hakata-yatai', 'name': '博多屋台', 'nameEn': 'Hakata Yatai', 'nameKo': '하카타 야타이', 'lat': 33.5902, 'lng': 130.4017, 'icon': 'restaurant'},
      ],
      'busan': [
        {'slug': 'haeundae', 'name': '海雲台', 'nameEn': 'Haeundae', 'nameKo': '해운대', 'lat': 35.1587, 'lng': 129.1604, 'icon': 'place'},
        {'slug': 'gamcheon', 'name': '甘川文化村', 'nameEn': 'Gamcheon Village', 'nameKo': '감천문화마을', 'lat': 35.0975, 'lng': 129.0108, 'icon': 'place'},
        {'slug': 'seomyeon', 'name': '西面', 'nameEn': 'Seomyeon', 'nameKo': '서면', 'lat': 35.1578, 'lng': 129.0598, 'icon': 'place'},
      ],
    };

    final existingSlugs = tripItems.map((i) => i.slug).toSet();
    final suggestions = (popularSpots[tripRegion] ?? [])
        .where((s) => !existingSlugs.contains(s['slug']))
        .take(4)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        List<Landmark> results = [];
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(tr(locale, ja: 'スポットを追加', ko: '스팟 추가', en: 'Add Spot', zh: '添加景点', fr: 'Ajouter un site')),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: tr(locale, ja: '観光地・レストランを検索', ko: '관광지·음식점 검색', en: 'Search spots & restaurants', zh: '搜索景点和餐厅', fr: 'Rechercher lieux et restaurants'),
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                  onChanged: (q) async {
                    if (q.length < 2) { setDialogState(() => results = []); return; }
                    try {
                      final r = await api.searchLandmarks(q, region: tripRegion, locale: locale);
                      if (ctx.mounted) setDialogState(() => results = r);
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 8),
                if (results.isNotEmpty)
                  ...results.take(5).map((l) => ListTile(
                    dense: true,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(width: 28, height: 28, child: Image.network(
                        'https://norigo.app/images/landmarks/${l.slug}.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.place, size: 18),
                      )),
                    ),
                    title: Text(l.name, style: const TextStyle(fontSize: 13)),
                    onTap: () {
                      notifier.addItem(l, tripId: trip.id, locale: locale);
                      Navigator.pop(ctx);
                    },
                  )),
                if (results.isEmpty && controller.text.length < 2 && suggestions.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tr(locale, ja: 'おすすめ', ko: '추천', en: 'Suggested', zh: '推荐', fr: 'Suggéré'),
                      style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...suggestions.map((s) {
                    final localeKey = switch (locale) { 'ko' => 'nameKo', 'en' => 'nameEn', 'fr' => 'nameEn', _ => 'name' };
                    final displayName = LandmarkLocalizer.getLocalizedName(locale: locale, slug: s['slug'] as String, name: s['name'] as String)
                        ?? s[localeKey] as String? ?? s['name'] as String;
                    final isRestaurant = s['icon'] == 'restaurant';
                    return ListTile(
                      dense: true,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(width: 28, height: 28, child: Image.network(
                          'https://norigo.app/images/landmarks/${s['slug']}.webp',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(isRestaurant ? Icons.restaurant : Icons.place, size: 16, color: isRestaurant ? AppTheme.orange : AppTheme.primary),
                        )),
                      ),
                      title: Text(displayName, style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        notifier.addItem(
                          Landmark(slug: s['slug'] as String, name: displayName, lat: (s['lat'] as num).toDouble(), lng: (s['lng'] as num).toDouble(), region: tripRegion),
                          tripId: trip.id, locale: locale,
                        );
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text(tr(locale, ja: 'キャンセル', ko: '취소', en: 'Cancel', zh: '取消', fr: 'Annuler'))),
            ],
          );
        });
      },
    );
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref, Trip trip, String locale) async {
    final now = DateTime.now();
    final initialRange = (trip.checkIn != null && trip.checkOut != null)
        ? DateTimeRange(start: DateTime.parse(trip.checkIn!), end: DateTime.parse(trip.checkOut!))
        : DateTimeRange(start: now.add(const Duration(days: 30)), end: now.add(const Duration(days: 33)));

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    ref.read(tripProvider.notifier).setTripDates(
      widget.tripId,
      picked.start.toIso8601String().substring(0, 10),
      picked.end.toIso8601String().substring(0, 10),
    );
  }

  void _showBudgetPicker(BuildContext context, WidgetRef ref, Trip trip, String locale) {
    final region = trip.country == 'korea' ? 'seoul' : 'kanto';
    final budgets = AppConstants.getStayBudgets(region);
    final current = trip.maxBudget ?? 'any';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(locale, ja: '予算を選択', ko: '예산 선택', en: 'Select Budget', zh: '选择预算', fr: 'Sélectionner le budget')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: budgets.map((b) {
            final label = AppConstants.stayBudgetLabels[b]?[locale] ?? AppConstants.stayBudgetLabels[b]?['en'] ?? b;
            final isSelected = current == b;
            return ListTile(
              dense: true,
              title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? Icon(Icons.check, color: AppTheme.primary, size: 18) : null,
              onTap: () {
                ref.read(tripProvider.notifier).setTripSearchSettings(trip.id, maxBudget: b == 'any' ? null : b);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
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

    // Stay recommendation (auto-fetched for 2+ spots)
    final stayAsync = ref.watch(tripStayProvider(widget.tripId));
    final stayResult = stayAsync.valueOrNull;
    final topArea = stayResult?.areas.isNotEmpty == true ? stayResult!.areas.first : null;
    final stayLandmarks = items.map((i) => Landmark(slug: i.slug, name: i.name, lat: i.lat, lng: i.lng, region: i.region)).toList();

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
          // Map — enhanced with hotel recommendation when available
          if (hasCoords) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: topArea != null ? 220 : 180,
                child: topArea != null
                  ? StayInlineMap(area: topArea, landmarks: stayLandmarks, locale: locale, interactive: true)
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          items.map((i) => i.lat).reduce((a, b) => a + b) / items.length,
                          items.map((i) => i.lng).reduce((a, b) => a + b) / items.length,
                        ),
                        initialZoom: 12,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                      ),
                      children: [
                        TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png', userAgentPackageName: 'app.norigo'),
                        MarkerLayer(markers: items.asMap().entries.map((e) {
                          final i = e.key;
                          final item = e.value;
                          return Marker(
                            point: LatLng(item.lat, item.lng),
                            width: 28, height: 28,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                            ),
                          );
                        }).toList()),
                      ],
                    ),
              ),
            ),
            // Loading indicator
            if (stayAsync.isLoading)
              const Padding(padding: EdgeInsets.only(top: 4), child: LinearProgressIndicator()),
            // Legend + recommended area info
            if (topArea != null) ...[
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _LegendDot(color: Colors.indigo, label: tr(locale, ja: '観光地', ko: '관광지', en: 'Spots', zh: '景点', fr: 'Lieux')),
                const SizedBox(width: 12),
                _LegendDot(color: AppTheme.orange, label: tr(locale, ja: 'ホテル推薦駅', ko: '호텔 추천역', en: 'Hotel Rec.', zh: '酒店推荐站', fr: 'Hôtel rec.')),
              ]),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.hotel, size: 16, color: AppTheme.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${topArea.station.localizedName(locale)} · ~${topArea.avgEstimatedMinutes}${tr(locale, ja: '分', ko: '분', en: 'min', zh: '分', fr: 'min')}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // Summary cards (tappable)
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => _showDatePicker(context, ref, trip, locale),
              child: _InfoCard(
                icon: Icons.calendar_today,
                label: tr(locale, ja: '日程', ko: '일정', en: 'Dates', zh: '日期', fr: 'Dates'),
                value: dateLabel,
                actionHint: trip.checkIn == null ? tr(locale, ja: '設定', ko: '설정', en: 'Set', zh: '设置', fr: 'Définir') : null,
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => _showBudgetPicker(context, ref, trip, locale),
              child: _InfoCard(
                icon: Icons.payments,
                label: tr(locale, ja: '予算（1泊）', ko: '예산 (1박)', en: 'Budget / night', zh: '预算（每晚）', fr: 'Budget / nuit'),
                value: budgetLabel,
                actionHint: trip.maxBudget == null ? tr(locale, ja: '設定', ko: '설정', en: 'Set', zh: '设置', fr: 'Définir') : null,
              ),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Icon(Icons.place_outlined, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  tr(locale, ja: 'スポットを追加しましょう', ko: '관광지를 추가해보세요', en: 'Add some spots', zh: '添加一些景点吧', fr: 'Ajoutez des sites'),
                  style: TextStyle(color: Colors.grey),
                ),
              ]),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 36, height: 36,
                    child: Image.network(
                      'https://norigo.app/images/landmarks/${item.slug}.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primaryBg,
                        child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                      ),
                    ),
                  ),
                ),
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

          // Add spot button
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _showAddSpotDialog(context, ref, trip, locale),
            icon: const Icon(Icons.add_location_alt, size: 16),
            label: Text(tr(locale, ja: 'スポット・グルメ追加', ko: '관광지·음식점 추가', en: 'Add Spot / Restaurant', zh: '添加景点/餐厅', fr: 'Ajouter lieu / restaurant'), style: const TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
          )),

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
                  final notes = _notesController.text.trim();
                  notifier.setNotes(widget.tripId, notes.isEmpty ? null : notes);
                  // Set up stay search and navigate
                  final stayNotifier = ref.read(staySearchProvider.notifier);
                  final landmarks = notifier.getItemsAsLandmarks(widget.tripId);
                  stayNotifier.reset();
                  stayNotifier.setSavedSearchId(widget.tripId);
                  if (landmarks.isNotEmpty) stayNotifier.setRegion(landmarks.first.region);
                  for (final l in landmarks) { stayNotifier.addLandmark(l); }
                  if (trip.maxBudget != null) {
                    stayNotifier.setBudget(trip.maxBudget!);
                  } else {
                    final isKorea = ['seoul', 'busan'].contains(landmarks.firstOrNull?.region);
                    stayNotifier.setBudget(isKorea ? '25000-35000' : '10000-30000');
                  }
                  if (trip.checkIn != null && trip.checkOut != null) {
                    stayNotifier.setDates(trip.checkIn!, trip.checkOut!);
                  } else {
                    final checkIn = DateTime.now().add(const Duration(days: 30));
                    stayNotifier.setDates(checkIn.toIso8601String().substring(0, 10),
                      checkIn.add(const Duration(days: 3)).toIso8601String().substring(0, 10));
                  }
                  stayNotifier.search();
                  Navigator.pop(context);
                  MainShell.globalSwitchTab?.call(1);
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
  final String? actionHint;
  const _InfoCard({required this.icon, required this.label, required this.value, this.actionHint});

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
          if (actionHint != null) ...[
            const Spacer(),
            Text(actionHint!, style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ],
        ]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
    ]);
  }
}
