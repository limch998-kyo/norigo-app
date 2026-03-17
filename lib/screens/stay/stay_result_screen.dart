import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../models/stay_area.dart';
import '../../models/hotel.dart';
import '../../models/landmark.dart';
import '../../models/meetup_result.dart';
import '../../widgets/mode_tabs.dart';
import '../../widgets/share_buttons.dart';
import '../../widgets/skeleton_loader.dart';
import '../../services/api_client.dart';
import '../../providers/trip_provider.dart';
import '../../providers/saved_searches_provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/line_localize.dart';
import '../../config/constants.dart';
import '../../config/booking_provider.dart';

class StayResultScreen extends ConsumerStatefulWidget {
  const StayResultScreen({super.key});

  @override
  ConsumerState<StayResultScreen> createState() => _StayResultScreenState();
}

class _StayResultScreenState extends ConsumerState<StayResultScreen> {
  int _expandedIndex = 0;

  void _saveSearch(BuildContext context, WidgetRef ref, StaySearchState state, String locale) {
    final savedNotifier = ref.read(savedSearchesProvider.notifier);
    final alreadySaved = ref.read(savedSearchesProvider.notifier).hasSearch(state.landmarks, state.region);

    if (alreadySaved) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(locale == 'ja' ? 'すでに保存済みです' : locale == 'ko' ? '이미 저장되어 있습니다' : 'Already saved'),
      ));
      return;
    }

    // Build descriptive title from landmark names
    final title = state.landmarks.map((l) => l.name).join(' · ');

    savedNotifier.add(SavedSearch(
      id: const Uuid().v4(),
      title: title,
      landmarks: state.landmarks,
      region: state.region,
      mode: state.mode,
      maxBudget: state.maxBudget,
      checkIn: state.checkIn,
      checkOut: state.checkOut,
      savedAt: DateTime.now(),
    ));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(locale == 'ja' ? '検索を保存しました' : locale == 'ko' ? '검색을 저장했습니다' : 'Search saved'),
      action: SnackBarAction(
        label: locale == 'ja' ? '旅行タブで確認' : locale == 'ko' ? '여행 탭에서 확인' : 'View in Trip',
        onPressed: () {},
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final state = ref.watch(staySearchProvider);
    final notifier = ref.read(staySearchProvider.notifier);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(appBar: AppBar(title: Text(l10n.staySearchTitle)), body: const SkeletonLoader(count: 3));
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staySearchTitle)),
        body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(state.error!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: () => notifier.search(), child: Text(locale == 'ja' ? '再試行' : 'Retry')),
          ],
        ))),
      );
    }

    final result = state.result;
    final hasResults = result != null && (result.areas.isNotEmpty || result.clusters.any((c) => c.areas.isNotEmpty));
    if (!hasResults) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staySearchTitle), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.clearResult())),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(l10n.noResults, style: theme.textTheme.titleMedium),
        ])),
      );
    }

    // For split results, show clusters grouped
    final isSplit = result.split;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ja' ? '推薦宿泊エリア' : locale == 'ko' ? '추천 숙박 지역' : 'Recommended Areas'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.clearResult()),
        actions: [
          // Save search button (changes icon when saved)
          Builder(builder: (ctx) {
            final isSaved = ref.watch(savedSearchesProvider.notifier).hasSearch(state.landmarks, state.region);
            return IconButton(
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline, size: 20,
                color: isSaved ? AppTheme.primary : null),
              tooltip: locale == 'ja' ? '保存' : locale == 'ko' ? '저장' : 'Save',
              onPressed: isSaved ? null : () => _saveSearch(context, ref, state, locale),
            );
          }),
          // Edit search button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () => notifier.clearResult(),
              icon: const Icon(Icons.tune, size: 14),
              label: Text(locale == 'ja' ? '検索修正' : locale == 'ko' ? '검색 수정' : 'Edit', style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ModeTabs(selected: state.mode, onChanged: (m) { notifier.setMode(m); notifier.search(); }, locale: locale),
          ),
          // Stay style toggle (single ↔ split) — like web
          if (state.landmarks.length >= 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                // Single stay option
                Expanded(child: GestureDetector(
                  onTap: () {
                    if (isSplit) { notifier.setStayStyle('single'); notifier.search(); }
                  },
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isSplit ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: !isSplit ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Center(child: Text(
                        locale == 'ja' ? '1箇所 宿泊' : locale == 'ko' ? '한 곳 숙박' : 'Single hotel',
                        style: TextStyle(fontSize: 12, fontWeight: !isSplit ? FontWeight.w600 : FontWeight.normal,
                          color: !isSplit ? AppTheme.primary : AppTheme.foreground),
                      )),
                    ),
                    // Recommended badge for single (when API chose single)
                    if (!isSplit)
                      Positioned(right: -4, top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                          child: Text(locale == 'ja' ? 'おすすめ' : locale == 'ko' ? '추천' : 'Rec',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ]),
                )),
                const SizedBox(width: 8),
                // Split stay option
                Expanded(child: GestureDetector(
                  onTap: () {
                    if (!isSplit) { notifier.setStayStyle('split'); notifier.search(); }
                  },
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSplit ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSplit ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Center(child: Text(
                        locale == 'ja' ? '分散 宿泊' : locale == 'ko' ? '분산 숙박' : 'Split stay',
                        style: TextStyle(fontSize: 12, fontWeight: isSplit ? FontWeight.w600 : FontWeight.normal,
                          color: isSplit ? AppTheme.primary : AppTheme.foreground),
                      )),
                    ),
                    // Recommended badge for split (when API chose split)
                    if (isSplit)
                      Positioned(right: -4, top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                          child: Text(locale == 'ja' ? 'おすすめ' : locale == 'ko' ? '추천' : 'Rec',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ]),
                )),
              ]),
            ),
          // Share at top (matching web)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ShareButtons(
              title: 'Norigo',
              text: locale == 'ko'
                  ? '${state.landmarks.map((l) => l.name).join('・')} 여행에 최적의 호텔 지역'
                  : 'Best hotel area for ${state.landmarks.map((l) => l.name).join(', ')}',
              url: 'https://norigo.app/stay/result',
              locale: locale,
            ),
          ),
          // Save search prompt (visible, not just icon)
          Builder(builder: (ctx) {
            final isSaved = ref.watch(savedSearchesProvider.notifier).hasSearch(state.landmarks, state.region);
            if (isSaved) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  Icon(Icons.bookmark, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(locale == 'ja' ? '保存済み' : locale == 'ko' ? '저장됨' : 'Saved',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                ]),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _saveSearch(context, ref, state, locale),
                  icon: const Icon(Icons.bookmark_outline, size: 16),
                  label: Text(
                    locale == 'ja' ? 'この検索を保存' : locale == 'ko' ? '이 검색 저장하기' : 'Save this search',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            );
          }),
          // Results list
          Expanded(
            child: isSplit
                ? _SplitResultsList(
                    clusters: result.clusters,
                    expandedIndex: _expandedIndex,
                    onTap: (i) => setState(() => _expandedIndex = _expandedIndex == i ? -1 : i),
                    locale: locale,
                    l10n: l10n,
                    landmarks: state.landmarks,
                    maxBudget: state.maxBudget,
                    checkIn: state.checkIn,
                    checkOut: state.checkOut,
                    searchRegion: state.region,
                  )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: result.areas.length,
              itemBuilder: (context, index) {
                return _AreaCard(
                  area: result.areas[index],
                  rank: index + 1,
                  isExpanded: _expandedIndex == index,
                  onTap: () => setState(() => _expandedIndex = _expandedIndex == index ? -1 : index),
                  locale: locale,
                  l10n: l10n,
                  landmarks: state.landmarks,
                  localNames: result.localNames,
                  maxBudget: state.maxBudget,
                  checkIn: state.checkIn,
                  checkOut: state.checkOut,
                  searchRegion: state.region,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitResultsList extends StatefulWidget {
  final List<StayCluster> clusters;
  final int expandedIndex;
  final void Function(int) onTap;
  final String locale;
  final AppLocalizations l10n;
  final List<Landmark> landmarks;
  final String? maxBudget;
  final String? checkIn;
  final String? checkOut;
  final String searchRegion;

  const _SplitResultsList({
    required this.clusters, required this.expandedIndex, required this.onTap,
    required this.locale, required this.l10n, required this.landmarks,
    this.maxBudget, this.checkIn, this.checkOut, this.searchRegion = 'kanto',
  });

  @override
  State<_SplitResultsList> createState() => _SplitResultsListState();
}

class _SplitResultsListState extends State<_SplitResultsList> {
  static const _defaultVisible = 2;
  // Track which clusters are expanded to show all results
  final Set<int> _expandedClusters = {};

  @override
  Widget build(BuildContext context) {
    int globalIndex = 0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        ...widget.clusters.asMap().entries.expand((clusterEntry) {
          final ci = clusterEntry.key;
          final cluster = clusterEntry.value;
          final isClusterExpanded = _expandedClusters.contains(ci);
          final visibleAreas = isClusterExpanded ? cluster.areas : cluster.areas.take(_defaultVisible).toList();
          final hasMore = cluster.areas.length > _defaultVisible;

          // Need to track globalIndex for all areas, not just visible ones
          final startGlobalIndex = globalIndex;

          return [
            // Cluster header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ci == 0 ? AppTheme.primaryBg : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: ci == 0 ? AppTheme.primary : AppTheme.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('${ci + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${widget.locale == 'ja' ? 'エリア' : widget.locale == 'ko' ? '지역' : 'Area'} ${ci + 1}: ${cluster.landmarks.join(' · ')}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  )),
                  Text(
                    '${cluster.areas.length}${widget.locale == 'ja' ? '件' : widget.locale == 'ko' ? '개' : ''}',
                    style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                  ),
                ]),
              ),
            ),
            // Filter landmarks to only those in this cluster
            ...(() {
              final clusterLandmarkNames = cluster.landmarks.map((n) => n.toLowerCase()).toSet();
              final clusterLandmarks = widget.landmarks.where((l) =>
                clusterLandmarkNames.contains(l.name.toLowerCase()) ||
                clusterLandmarkNames.contains(l.slug.toLowerCase())
              ).toList();
              // Fallback: if no match (name mismatch), use all landmarks
              final effectiveLandmarks = clusterLandmarks.isNotEmpty ? clusterLandmarks : widget.landmarks;

              return visibleAreas.asMap().entries.map((areaEntry) {
                final idx = startGlobalIndex + areaEntry.key;
                globalIndex = startGlobalIndex + areaEntry.key + 1;
                return _AreaCard(
                  area: areaEntry.value,
                  rank: idx + 1,
                  isExpanded: widget.expandedIndex == idx,
                  onTap: () => widget.onTap(idx),
                  locale: widget.locale,
                  l10n: widget.l10n,
                  landmarks: effectiveLandmarks,
                  localNames: cluster.localNames,
                  maxBudget: widget.maxBudget,
                  checkIn: widget.checkIn,
                  checkOut: widget.checkOut,
                  searchRegion: widget.searchRegion,
                );
              });
            })(),
            // Adjust globalIndex for hidden areas
            if (!isClusterExpanded)
              ...(() { globalIndex = startGlobalIndex + cluster.areas.length; return <Widget>[]; })(),
            // Show more / show less button
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Center(child: TextButton(
                  onPressed: () => setState(() {
                    if (isClusterExpanded) {
                      _expandedClusters.remove(ci);
                    } else {
                      _expandedClusters.add(ci);
                    }
                  }),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      isClusterExpanded
                        ? (widget.locale == 'ja' ? '閉じる' : widget.locale == 'ko' ? '접기' : 'Show less')
                        : (widget.locale == 'ja' ? '他${cluster.areas.length - _defaultVisible}件を表示'
                          : widget.locale == 'ko' ? '${cluster.areas.length - _defaultVisible}개 더 보기'
                          : 'Show ${cluster.areas.length - _defaultVisible} more'),
                      style: TextStyle(fontSize: 12, color: AppTheme.primary),
                    ),
                    Icon(isClusterExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppTheme.primary),
                  ]),
                )),
              ),
            if (cluster.areas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.locale == 'ja' ? 'このエリアの推薦結果がありません' : widget.locale == 'ko' ? '이 지역의 추천 결과가 없습니다' : 'No results for this area',
                  style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                ),
              ),
          ];
        }),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? AppTheme.primary : AppTheme.foreground)),
      ),
    ));
  }
}

class _AreaCard extends StatefulWidget {
  final StayArea area;
  final int rank;
  final bool isExpanded;
  final VoidCallback onTap;
  final String locale;
  final AppLocalizations l10n;
  final List<Landmark> landmarks;
  final Map<String, String> localNames;
  final String? maxBudget;
  final String? checkIn;
  final String? checkOut;
  final String searchRegion; // The region from search state, not from station

  const _AreaCard({required this.area, required this.rank, required this.isExpanded, required this.onTap, required this.locale, required this.l10n, required this.landmarks, this.localNames = const {}, this.maxBudget, this.checkIn, this.checkOut, this.searchRegion = 'kanto'});

  @override
  State<_AreaCard> createState() => _AreaCardState();
}

class _AreaCardState extends State<_AreaCard> {
  List<Hotel> _hotelMarkers = [];

  void _onHotelsLoaded(List<Hotel> hotels) {
    if (mounted) setState(() => _hotelMarkers = hotels);
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final rank = widget.rank;
    final isExpanded = widget.isExpanded;
    final locale = widget.locale;
    final l10n = widget.l10n;
    final localNames = widget.localNames;
    final landmarks = widget.landmarks;
    final theme = Theme.of(context);
    final name = localNames[area.station.id] ?? area.station.localizedName(locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header ──
            Row(children: [
              _RankBadge(rank: rank),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text('${locale == 'ja' ? '平均 約' : 'avg'} ${area.avgEstimatedMinutes}${locale == 'ja' ? '分' : 'min'}',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ])),
            ]),

            // ── Inline map (always visible like web) ──
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _InlineMap(area: area, landmarks: landmarks, locale: locale, hotels: _hotelMarkers),
              ),
            ),
            // Map legend
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _LegendDot(color: AppTheme.orange, label: locale == 'ja' ? 'ホテル推薦駅' : '호텔 추천역'),
                const SizedBox(width: 10),
                _LegendDot(color: Colors.indigo, label: locale == 'ja' ? '観光地' : '관광지'),
                const SizedBox(width: 10),
                _LegendDot(color: AppTheme.green, label: locale == 'ja' ? '周辺ホテル' : '주변 호텔'),
              ]),
            ),

            // ── Station lines ──
            if (area.station.lines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(locale == 'ja' ? '路線' : locale == 'ko' ? '노선' : 'Lines', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
              const SizedBox(height: 4),
              Wrap(spacing: 4, runSpacing: 4, children: area.station.lines.take(4).map((l) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppTheme.primaryBg),
                  child: Text(LineLocalizer.localizeSync(l, locale), style: TextStyle(fontSize: 10, color: AppTheme.primary)),
                ),
              ).toList()),
            ],

            // ── Area tags ──
            if (area.areaTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 4, children: area.areaTags.map((tag) {
                final tagInfo = _areaTagInfo(tag, locale);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagInfo.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tagInfo.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(tagInfo.icon, size: 12, color: tagInfo.color),
                    const SizedBox(width: 4),
                    Text(tagInfo.label, style: TextStyle(fontSize: 11, color: tagInfo.color, fontWeight: FontWeight.w500)),
                  ]),
                );
              }).toList()),
            ],

            // ── POI counts ──
            if (area.poiCounts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                if ((area.poiCounts['convenience'] ?? 0) > 0)
                  _PoiCount(icon: Icons.store, count: area.poiCounts['convenience']!, label: locale == 'ja' ? 'コンビニ' : locale == 'ko' ? '편의점' : 'Convenience'),
                if ((area.poiCounts['restaurant'] ?? 0) > 0) ...[
                  const SizedBox(width: 12),
                  _PoiCount(icon: Icons.restaurant, count: area.poiCounts['restaurant']!, label: locale == 'ja' ? '飲食店' : locale == 'ko' ? '음식점' : 'Restaurant'),
                ],
                if ((area.poiCounts['cafe'] ?? 0) > 0) ...[
                  const SizedBox(width: 12),
                  _PoiCount(icon: Icons.coffee, count: area.poiCounts['cafe']!, label: locale == 'ja' ? 'カフェ' : locale == 'ko' ? '카페' : 'Cafe'),
                ],
              ]),
            ],

            // ── Area description ──
            if (area.areaDescription != null && area.areaDescription!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(area.areaDescription!, style: TextStyle(fontSize: 12, color: AppTheme.foreground, height: 1.5)),
              ),
            ],

            // ── Landmark distances with routes ──
            const SizedBox(height: 12),
            Text(locale == 'ja' ? '観光地までの距離' : locale == 'ko' ? '관광지까지 거리' : 'Distance to landmarks',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
            const SizedBox(height: 6),
            ...area.landmarkDistances.map((ld) => _LandmarkDistanceTile(ld: ld, locale: locale, isExpanded: isExpanded, localNames: localNames)),

            // Stats
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${locale == 'ja' ? '最大 約' : 'max'} ${area.maxEstimatedMinutes}${locale == 'ja' ? '分' : 'min'}  ·  ${locale == 'ja' ? '合計' : 'total'} ${area.landmarkDistances.fold<double>(0, (s, d) => s + d.distanceKm).toStringAsFixed(1)}km',
                style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
              ),
            ),

            // ── Reachable destinations ──
            if (isExpanded && area.reachableDestinations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(locale == 'ja' ? '周辺スポット' : locale == 'ko' ? '주변 명소' : 'Nearby Spots',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: area.reachableDestinations.take(6).map((rd) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: AppTheme.primaryBg),
                  child: Text('${rd.name} ${rd.minutes}min', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                ),
              ).toList()),
            ],

            // ── Hotels ──
            // ko → Agoda cards (all regions)
            // ja + Korea → Agoda cards
            // ja + Japan → Jalan link only
            // en/zh → Booking.com link only
            const Divider(height: 24),
            if (locale == 'ko' || (locale == 'ja' && ['seoul', 'busan'].contains(widget.searchRegion)))
              _HotelSection(stationId: area.station.id, locale: locale, region: widget.searchRegion, stationName: name, l10n: l10n, checkIn: widget.checkIn, checkOut: widget.checkOut, initialBudget: widget.maxBudget, lat: area.station.lat, lng: area.station.lng, onLoaded: _onHotelsLoaded)
            else
              _ExternalHotelLinks(stationName: name, stationId: area.station.id, locale: locale, region: widget.searchRegion, lat: area.station.lat, lng: area.station.lng, checkIn: widget.checkIn, checkOut: widget.checkOut),
          ]),
        ),
      ),
    );
  }
}

class _TagInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _TagInfo(this.label, this.icon, this.color);
}

_TagInfo _areaTagInfo(String tag, String locale) {
  switch (tag) {
    case 'transit_hub': return _TagInfo(
      locale == 'ja' ? '交通の要所' : locale == 'ko' ? '교통 요충지' : 'Transit Hub',
      Icons.train, Colors.blue);
    case 'nightlife': return _TagInfo(
      locale == 'ja' ? 'ナイトライフ' : locale == 'ko' ? '나이트라이프' : 'Nightlife',
      Icons.nightlife, Colors.purple);
    case 'shopping': return _TagInfo(
      locale == 'ja' ? 'ショッピング' : locale == 'ko' ? '쇼핑' : 'Shopping',
      Icons.shopping_bag, Colors.pink);
    case 'quiet_residential': return _TagInfo(
      locale == 'ja' ? '閑静な住宅街' : locale == 'ko' ? '조용한 주거지' : 'Quiet Area',
      Icons.park, Colors.green);
    case 'tourist_area': return _TagInfo(
      locale == 'ja' ? '観光エリア' : locale == 'ko' ? '관광 지역' : 'Tourist Area',
      Icons.camera_alt, Colors.orange);
    case 'airport_access': return _TagInfo(
      locale == 'ja' ? '空港アクセス' : locale == 'ko' ? '공항 접근' : 'Airport Access',
      Icons.flight, Colors.teal);
    default: return _TagInfo(tag, Icons.label, Colors.grey);
  }
}

class _PoiCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  const _PoiCount({required this.icon, required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppTheme.mutedForeground),
      const SizedBox(width: 4),
      Text('$label $count', style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
    ]);
  }
}

class _LandmarkDistanceTile extends StatelessWidget {
  final LandmarkDistance ld;
  final String locale;
  final bool isExpanded;
  final Map<String, String> localNames;

  const _LandmarkDistanceTile({required this.ld, required this.locale, required this.isExpanded, this.localNames = const {}});

  @override
  Widget build(BuildContext context) {
    final isWalking = ld.distanceKm <= 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.place, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(ld.landmarkName, style: const TextStyle(fontSize: 13))),
          Text(
            '${locale == 'ja' ? '約' : '~'}${ld.estimatedMinutes}${locale == 'ja' ? '分' : 'min'}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _timeColor(ld.estimatedMinutes)),
          ),
          const SizedBox(width: 6),
          Text('${ld.distanceKm.toStringAsFixed(1)}km', style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
        ]),
        // Walking or route
        if (isExpanded) ...[
          if (isWalking)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4),
              child: Row(children: [
                Icon(Icons.directions_walk, size: 14, color: AppTheme.mutedForeground),
                const SizedBox(width: 4),
                Text(locale == 'ja' ? '徒歩圏内' : locale == 'ko' ? '도보 거리' : 'Walkable',
                  style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
              ]),
            )
          else if (ld.route.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 4),
              child: _RouteBar(segments: ld.route, localNames: localNames, locale: locale),
            ),
        ],
      ]),
    );
  }

  Color _timeColor(int min) {
    if (min <= 10) return AppTheme.green;
    if (min <= 30) return Colors.blue.shade700;
    if (min <= 60) return AppTheme.orange;
    return Colors.red.shade700;
  }
}

class _RouteBar extends StatelessWidget {
  final List<RouteSegment> segments;
  final Map<String, String> localNames;
  final String locale;
  const _RouteBar({required this.segments, this.localNames = const {}, this.locale = 'ja'});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final totalSqrt = segments.fold<double>(0, (s, seg) => s + sqrt(seg.minutes.clamp(1, 999).toDouble()));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Station dots + bars
      SizedBox(
        height: 28,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _StationDot(color: _parseColor(segments.first.color)),
          ...segments.asMap().entries.expand((e) {
            final seg = e.value;
            final isLast = e.key == segments.length - 1;
            final frac = totalSqrt > 0 ? sqrt(seg.minutes.clamp(1, 999).toDouble()) / totalSqrt : 1.0 / segments.length;
            return [
              Expanded(
                flex: (frac * 100).round().clamp(1, 100),
                child: Container(height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: _parseColor(seg.color), borderRadius: BorderRadius.circular(3))),
              ),
              if (isLast)
                _StationDot(color: _parseColor(seg.color))
              else
                _TransferDot(
                  leftColor: _parseColor(seg.color),
                  rightColor: _parseColor(segments[e.key + 1].color),
                ),
            ];
          }),
        ]),
      ),
      const SizedBox(height: 4),
      // Line names + durations
      Row(children: segments.map((seg) {
        final localLine = LineLocalizer.localizeSync(seg.line, locale);
        final unit = locale == 'ja' ? '分' : locale == 'ko' ? '분' : 'min';
        return Expanded(child: Center(child: Text(
          '$localLine ${seg.minutes}$unit',
          style: TextStyle(fontSize: 9, color: AppTheme.mutedForeground),
          overflow: TextOverflow.ellipsis,
        )));
      }).toList()),
    ]);
  }

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.grey; }
  }
}

class _StationDot extends StatelessWidget {
  final Color color;
  const _StationDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)));
  }
}

class _TransferDot extends StatelessWidget {
  final Color leftColor;
  final Color rightColor;
  const _TransferDot({required this.leftColor, required this.rightColor});
  @override
  Widget build(BuildContext context) {
    return Container(width: 12, height: 12, decoration: BoxDecoration(
      shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5),
      gradient: SweepGradient(colors: [rightColor, rightColor, leftColor, leftColor], stops: const [0.0, 0.5, 0.5, 1.0]),
    ));
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
    ]);
  }
}

class _InlineMap extends StatelessWidget {
  final StayArea area;
  final List<Landmark> landmarks;
  final String locale;
  final List<Hotel> hotels;

  const _InlineMap({required this.area, required this.landmarks, this.locale = 'en', this.hotels = const []});

  @override
  Widget build(BuildContext context) {
    final allPoints = [
      LatLng(area.station.lat, area.station.lng),
      ...landmarks.map((l) => LatLng(l.lat, l.lng)),
      ...hotels.where((h) => h.lat != 0).map((h) => LatLng(h.lat, h.lng)),
    ];
    final center = LatLng(
      allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length,
      allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length,
    );
    // Auto-zoom to fit all points
    final latSpan = allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b) - allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    final lngSpan = allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b) - allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    final span = latSpan > lngSpan ? latSpan : lngSpan;
    final zoom = span < 0.01 ? 15.0 : span < 0.05 ? 14.0 : span < 0.1 ? 13.0 : span < 0.3 ? 12.0 : span < 1.0 ? 10.0 : 8.0;

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: zoom, interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag)),
      children: [
        TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png', userAgentPackageName: 'app.norigo'),
        MarkerLayer(markers: [
          // Landmarks (indigo)
          ...landmarks.map((l) => Marker(
            point: LatLng(l.lat, l.lng), width: 24, height: 24,
            child: Container(decoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.place, size: 12, color: Colors.white)),
          )),
          // Hotel station (orange with rank)
          Marker(
            point: LatLng(area.station.lat, area.station.lng), width: 32, height: 32,
            child: Container(
              decoration: BoxDecoration(color: AppTheme.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
              child: Center(child: Text('${area.landmarkDistances.isEmpty ? 1 : 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ),
          ),
          // Hotel markers (green numbered)
          ...hotels.where((h) => h.lat != 0 && h.lng != 0).take(5).toList().asMap().entries.map((e) {
            final h = e.value;
            return Marker(
              point: LatLng(h.lat, h.lng), width: 22, height: 22,
              child: Container(
                decoration: BoxDecoration(color: AppTheme.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              ),
            );
          }),
        ]),
      ],
    );
  }
}

class _HotelSection extends StatefulWidget {
  final String stationId;
  final String locale;
  final String region;
  final String stationName;
  final AppLocalizations l10n;
  final String? checkIn;
  final String? checkOut;
  final String? initialBudget;
  final double? lat;
  final double? lng;
  final void Function(List<Hotel>)? onLoaded;

  const _HotelSection({required this.stationId, required this.locale, required this.region, required this.stationName, required this.l10n, this.checkIn, this.checkOut, this.initialBudget, this.lat, this.lng, this.onLoaded});

  @override
  State<_HotelSection> createState() => _HotelSectionState();
}

class _HotelSectionState extends State<_HotelSection> {
  List<Hotel>? _hotels;
  bool _loading = true;
  bool _expanded = false;
  Set<String> _selectedBudgets = {}; // empty = show all

  @override
  void initState() {
    super.initState();
    // Auto-select budget ranges that fall within the search max budget
    _selectedBudgets = _findMatchingTiers(widget.initialBudget);
    _loadHotels();
  }

  /// Find all range tiers that fall within the search max budget
  Set<String> _findMatchingTiers(String? searchBudget) {
    if (searchBudget == null || searchBudget == 'any') return {};
    final tiers = AppConstants.getStayBudgets(widget.region);
    final searchMatch = RegExp(r'^under(\d+)$').firstMatch(searchBudget);
    if (searchMatch == null) return {};
    final searchJpy = int.parse(searchMatch.group(1)!);

    // Select all "underX" tiers where X <= searchJpy
    final result = <String>{};
    for (final tier in tiers) {
      if (tier == 'any') continue;
      final m = RegExp(r'^under(\d+)$').firstMatch(tier);
      if (m != null && int.parse(m.group(1)!) <= searchJpy) {
        result.add(tier);
      }
    }
    return result;
  }
  static const _defaultVisible = 3;

  // JPY conversion rates (matching web)
  static const _jpyRates = {'JPY': 1.0, 'KRW': 9.0, 'USD': 0.007};

  /// Check if a hotel falls within a specific range tier
  bool _hotelInRange(Hotel h, String budget) {
    if (h.dailyRate == null) return true;
    final tiers = AppConstants.getStayBudgets(widget.region);
    final tierIndex = tiers.indexOf(budget);
    final rate = _jpyRates[h.currency] ?? 1.0;
    final jpyPrice = h.dailyRate! / rate;

    final underMatch = RegExp(r'^under(\d+)$').firstMatch(budget);
    final overMatch = RegExp(r'^over(\d+)$').firstMatch(budget);

    if (underMatch != null) {
      final upper = int.parse(underMatch.group(1)!);
      int lower = 0;
      if (tierIndex > 1) {
        final prevMatch = RegExp(r'^under(\d+)$').firstMatch(tiers[tierIndex - 1]);
        if (prevMatch != null) lower = int.parse(prevMatch.group(1)!);
      }
      return jpyPrice > lower && jpyPrice <= upper;
    }
    if (overMatch != null) {
      return jpyPrice > int.parse(overMatch.group(1)!);
    }
    return true;
  }

  /// Filter by selected budget ranges (multi-select)
  List<Hotel> _filterBySelectedBudgets(List<Hotel> hotels) {
    if (_selectedBudgets.isEmpty) return hotels; // empty = show all
    return hotels.where((h) => _selectedBudgets.any((b) => _hotelInRange(h, b))).toList();
  }

  String _buildBudgetLabel(String budget, int index, List<String> tiers, String locale) {
    if (budget == 'any') {
      return locale == 'ja' ? 'すべて' : locale == 'ko' ? '전체' : 'All';
    }

    String fmtJpy(int v) {
      if (v >= 10000) return '¥${(v / 10000).toStringAsFixed(v % 10000 == 0 ? 0 : 1)}万';
      return '¥${(v / 1000).round()}k';
    }

    final underMatch = RegExp(r'^under(\d+)$').firstMatch(budget);
    final overMatch = RegExp(r'^over(\d+)$').firstMatch(budget);

    if (underMatch != null) {
      final upper = int.parse(underMatch.group(1)!);
      int lower = 0;
      if (index > 1) {
        final prevMatch = RegExp(r'^under(\d+)$').firstMatch(tiers[index - 1]);
        if (prevMatch != null) lower = int.parse(prevMatch.group(1)!);
      }
      if (lower == 0) return '~${fmtJpy(upper)}';
      return '${fmtJpy(lower)}~${fmtJpy(upper)}';
    }
    if (overMatch != null) {
      return '${fmtJpy(int.parse(overMatch.group(1)!))}~';
    }
    return budget;
  }

  int _countForBudget(String budget) {
    if (_hotels == null) return 0;
    if (budget == 'any') return _hotels!.length;
    return _hotels!.where((h) => _hotelInRange(h, budget)).length;
  }

  Future<void> _loadHotels() async {
    try {
      final api = ApiClient();
      final checkIn = widget.checkIn ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);
      final checkOut = widget.checkOut ?? DateTime.now().add(const Duration(days: 32)).toIso8601String().substring(0, 10);
      final hotels = await api.getHotels(stationId: widget.stationId, checkIn: checkIn, checkOut: checkOut, locale: widget.locale);
      if (mounted) {
        setState(() { _hotels = hotels; _loading = false; });
        widget.onLoaded?.call(hotels);
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))));

    if (_hotels == null || _hotels!.isEmpty) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(widget.locale == 'ja' ? 'ホテル情報を取得できませんでした' : 'No hotel data', style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)));
    }

    final filtered = _filterBySelectedBudgets(_hotels!);
    final displayed = _expanded ? filtered : filtered.take(_defaultVisible).toList();
    final hasMore = filtered.length > _defaultVisible;

    // Use region-specific budget tiers
    final budgetTiers = AppConstants.getStayBudgets(widget.region);
    final isAllSelected = _selectedBudgets.isEmpty;
    final noResultsInBudget = filtered.isEmpty && _selectedBudgets.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Budget range filter (multi-select)
      if (_hotels!.length > 3) ...[
        Row(children: [
          Text(
            widget.locale == 'ja' ? '予算' : widget.locale == 'ko' ? '예산' : 'Budget',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground),
          ),
          const SizedBox(width: 6),
          Text(
            widget.locale == 'ja' ? '（複数選択可）' : widget.locale == 'ko' ? '(복수 선택 가능)' : '(multi-select)',
            style: TextStyle(fontSize: 9, color: AppTheme.mutedForeground),
          ),
        ]),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            // "All" chip
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() { _selectedBudgets = {}; _expanded = false; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isAllSelected ? AppTheme.primary : Colors.transparent,
                    border: Border.all(color: isAllSelected ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Text(
                    '${widget.locale == 'ja' ? 'すべて' : widget.locale == 'ko' ? '전체' : 'All'}(${_hotels!.length})',
                    style: TextStyle(fontSize: 10, fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isAllSelected ? Colors.white : AppTheme.foreground),
                  ),
                ),
              ),
            ),
            // Range chips
            ...budgetTiers.asMap().entries.where((e) => e.value != 'any').map((entry) {
            final b = entry.value;
            final count = _countForBudget(b);
            if (count == 0) return const SizedBox.shrink();
            final isSelected = _selectedBudgets.contains(b);
            final label = _buildBudgetLabel(b, entry.key, budgetTiers, widget.locale);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() {
                  final newSet = Set<String>.from(_selectedBudgets);
                  if (isSelected) { newSet.remove(b); } else { newSet.add(b); }
                  _selectedBudgets = newSet;
                  _expanded = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Text(
                    '$label($count)',
                    style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : AppTheme.foreground),
                  ),
                ),
              ),
            );
          }),
          ]),
        ),
        const SizedBox(height: 10),
      ],

      // Header
      Row(children: [
        Text(widget.locale == 'ja' ? '周辺ホテル' : widget.locale == 'ko' ? '주변 호텔' : 'Nearby Hotels', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(
          widget.locale == 'ja' ? '1泊2人基準' : widget.locale == 'ko' ? '1박 2인 기준' : 'Per night, 2 guests',
          style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
        ),
      ]),
      const SizedBox(height: 8),

      // Hotel cards
      // No results in selected budget range
      if (noResultsInBudget)
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(
              widget.locale == 'ja' ? '選択した予算範囲のホテルが見つかりませんでした'
                : widget.locale == 'ko' ? '선택한 예산 범위의 호텔이 없습니다'
                : 'No hotels found in the selected budget range',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
            )),
          ]),
        ),

      ...displayed.asMap().entries.map((e) => _HotelCard(hotel: e.value, index: e.key + 1, l10n: widget.l10n)),

      // Show more / show less
      if (hasMore)
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_expanded
                ? (widget.locale == 'ja' ? '閉じる' : 'Show less')
                : (widget.locale == 'ja' ? '他${_hotels!.length - _defaultVisible}件を表示' : 'Show ${_hotels!.length - _defaultVisible} more'),
              style: TextStyle(fontSize: 12, color: AppTheme.primary)),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppTheme.primary),
          ]),
        ),

      // Provider attribution + search link
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text('Powered by ', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
            Text(BookingProvider.providerName(widget.locale, widget.region), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
          ]),
          GestureDetector(
            onTap: () {
              final url = BookingProvider.buildSearchUrl(
                locale: widget.locale,
                region: widget.region,
                stationName: widget.stationName,
                stationId: widget.stationId,
                lat: widget.lat,
                lng: widget.lng,
                checkIn: widget.checkIn,
                checkOut: widget.checkOut,
              );
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: Text(
              '${widget.locale == 'ja' ? '' : 'Search on '}${BookingProvider.providerName(widget.locale, widget.region)}${widget.locale == 'ja' ? 'で検索' : ''} →',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.primary),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel hotel;
  final int index;
  final AppLocalizations l10n;

  const _HotelCard({required this.hotel, required this.index, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Index badge + Image
        Column(children: [
          Container(
            width: 20, height: 20, margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hotel.imageUrl != null
                ? Image.network(hotel.imageUrl!, width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: AppTheme.muted, child: const Icon(Icons.hotel)))
                : Container(width: 80, height: 80, color: AppTheme.muted, child: const Icon(Icons.hotel)),
          ),
        ]),
        const SizedBox(width: 10),

        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hotel.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),

          // Price row
          Row(children: [
            if (hotel.formattedCrossedOutPrice != null) ...[
              Text(hotel.formattedCrossedOutPrice!, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground, decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 4),
            ],
            Text(hotel.formattedPrice, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            Text(l10n.perNight, style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
          ]),

          const SizedBox(height: 4),

          // Rating
          Row(children: [
            if (hotel.reviewScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(4)),
                child: Text(hotel.formattedRating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            if (hotel.reviewScore != null) Text('/10', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
            if (hotel.reviewCount != null) ...[
              const SizedBox(width: 4),
              Text('(${_formatCount(hotel.reviewCount!)})', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
            ],
          ]),

          // Amenities
          if (hotel.includeBreakfast || hotel.freeWifi) ...[
            const SizedBox(height: 4),
            Wrap(spacing: 4, children: [
              if (hotel.freeWifi) _AmenityBadge(icon: Icons.wifi, label: 'Wi-Fi'),
              if (hotel.includeBreakfast) _AmenityBadge(icon: Icons.restaurant, label: '朝食'),
            ]),
          ],
        ])),

        // Book button
        if (hotel.bookingUrl != null)
          GestureDetector(
            onTap: () {
              launchUrl(Uri.parse(hotel.bookingUrl!), mode: LaunchMode.externalApplication);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
              child: Text(l10n.bookNow, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

class _AmenityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AmenityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: AppTheme.mutedForeground),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: AppTheme.mutedForeground)),
      ]),
    );
  }
}

/// External hotel link — ja+Japan=Jalan, en/zh=Booking.com
class _ExternalHotelLinks extends StatelessWidget {
  final String stationName;
  final String stationId;
  final String locale;
  final String region;
  final double lat;
  final double lng;
  final String? checkIn;
  final String? checkOut;

  const _ExternalHotelLinks({required this.stationName, this.stationId = '', required this.locale, required this.region, required this.lat, required this.lng, this.checkIn, this.checkOut});

  @override
  Widget build(BuildContext context) {
    final isJalan = locale == 'ja' && ['kanto', 'kansai'].contains(region);
    final title = locale == 'ja' ? 'ホテルを探す' : 'Find Hotels';
    final providerName = isJalan ? 'じゃらん' : 'Booking.com';
    final buttonColor = isJalan ? const Color(0xFFE4007F) : const Color(0xFF003580);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            final url = BookingProvider.buildSearchUrl(
              locale: locale,
              region: isJalan ? region : 'global',
              stationName: stationName,
              lat: lat, lng: lng,
              checkIn: checkIn, checkOut: checkOut,
              stationId: stationId,
            );
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          },
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(
            locale == 'ja' ? '$providerNameで検索' : 'Search on $providerName',
            style: const TextStyle(fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Center(child: Text(
        'Powered by $providerName',
        style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground),
      )),
    ]);
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.amber.shade700, Colors.grey.shade500, Colors.brown.shade400];
    final color = rank <= 3 ? colors[rank - 1] : AppTheme.border;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
    );
  }
}
