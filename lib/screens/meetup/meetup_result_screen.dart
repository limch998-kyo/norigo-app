import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../services/line_localize.dart';
import '../../providers/app_providers.dart';
import '../../providers/meetup_provider.dart';
import '../../models/meetup_result.dart';
import '../../models/station.dart';
import '../../widgets/mode_tabs.dart';
import '../vote/vote_screen.dart';
import '../../widgets/share_buttons.dart';
import '../../widgets/skeleton_loader.dart';
import '../../config/booking_provider.dart';
import '../../utils/tr.dart';

class MeetupResultScreen extends ConsumerStatefulWidget {
  const MeetupResultScreen({super.key});

  @override
  ConsumerState<MeetupResultScreen> createState() => _MeetupResultScreenState();
}

/// Build web-compatible share URL with search params (matching web's result page)
String _buildMeetupShareUrl(dynamic state, String locale) {
  final stations = state.filledStations as List;
  final stationIds = stations.map((s) => s.id as String).join(',');
  final params = <String, String>{
    'p': stationIds,
    'm': state.mode as String,
    'r': state.region as String,
  };
  if (state.category != null) params['c'] = state.category as String;
  if (state.budget != null) params['b'] = state.budget as String;
  return Uri.parse('https://norigo.app/$locale/result').replace(queryParameters: params).toString();
}

class _MeetupResultScreenState extends ConsumerState<MeetupResultScreen> {
  int _expandedIndex = 0;
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final state = ref.watch(meetupSearchProvider);
    final notifier = ref.read(meetupSearchProvider.notifier);
    final theme = Theme.of(context);
    final title = tr(locale, ja: '検索結果', ko: '검색 결과', en: 'Results', zh: '搜索结果', fr: 'Résultats');

    if (state.isLoading) {
      return Scaffold(appBar: AppBar(title: Text(title)), body: const SkeletonLoader(count: 3));
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(state.error!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                OutlinedButton(onPressed: () => notifier.search(), child: Text(tr(locale, ja: '再試行', ko: '재시도', en: 'Retry', zh: '重试', fr: 'Réessayer'))),
              ],
            ),
          ),
        ),
      );
    }

    final result = state.result;
    if (result == null || result.stations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.clearResult())),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(tr(locale, ja: '結果が見つかりませんでした', ko: '결과를 찾을 수 없습니다', en: 'No results found', zh: '未找到结果', fr: 'Aucun résultat'), style: theme.textTheme.titleMedium),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.clearResult()),
        actions: [
          // Edit search
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: OutlinedButton.icon(
              onPressed: () => notifier.clearResult(),
              icon: const Icon(Icons.tune, size: 14),
              label: Text(tr(locale, ja: '検索修正', ko: '검색 수정', en: 'Edit', zh: '编辑', fr: 'Modifier'), style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), visualDensity: VisualDensity.compact),
            ),
          ),
          IconButton(icon: Icon(_showMap ? Icons.list : Icons.map, size: 20), onPressed: () => setState(() => _showMap = !_showMap)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ModeTabs(selected: state.mode, onChanged: (mode) { notifier.setMode(mode); notifier.search(); }, locale: locale),
          ),
          // Share buttons at top (matching web)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ShareButtons(
              title: 'Norigo',
              text: tr(locale,
                  ja: 'みんなの集合駅で検索したら「${result.stations.first.station.name}駅」がおすすめ！',
                  ko: '모두의 만남역을 검색하니 「${result.stations.first.station.name}역」을 추천합니다!',
                  en: '${result.stations.first.station.name} is recommended!',
                  zh: '搜索大家的集合站，推荐「${result.stations.first.station.name}站」！',
                  fr: '${result.stations.first.station.name} est recommandé !'),
              url: _buildMeetupShareUrl(state, locale),
              locale: locale,
            ),
          ),
          Expanded(
            child: _showMap
                ? _MeetupMapView(recommended: result.stations, participants: state.filledStations)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: result.stations.length,
                    itemBuilder: (context, index) {
                      return _StationCard(
                        rec: result.stations[index],
                        rank: index + 1,
                        isExpanded: _expandedIndex == index,
                        onTap: () => setState(() => _expandedIndex = _expandedIndex == index ? -1 : index),
                        locale: locale,
                        participants: state.filledStations,
                        localNames: result.localNames,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final RecommendedStation rec;
  final int rank;
  final bool isExpanded;
  final VoidCallback onTap;
  final String locale;
  final List<Station> participants;

  final Map<String, String> localNames;
  const _StationCard({required this.rec, required this.rank, required this.isExpanded, required this.onTap, required this.locale, this.participants = const [], this.localNames = const {}});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = localNames[rec.station.id] ?? rec.station.localizedName(locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                _RankBadge(rank: rank),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (rec.station.lines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(spacing: 4, runSpacing: 4, children: rec.station.lines.take(4).map((l) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(LineLocalizer.localizeSync(l, locale), style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
                        ),
                      ).toList()),
                    ),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    tr(locale,
                      ja: '平均${rec.avgEstimatedMinutes}分',
                      ko: '평균 ${rec.avgEstimatedMinutes}분',
                      en: 'Avg ${rec.avgEstimatedMinutes}min',
                      zh: '平均${rec.avgEstimatedMinutes}分钟',
                      fr: 'Moy. ${rec.avgEstimatedMinutes}min'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ),
              ]),

              // ── Inline map (always visible per card like web) ──
              // ── Inline map (auto-zoom to fit all markers) ──
              Builder(builder: (context) {
                final allMapPoints = [
                  LatLng(rec.station.lat, rec.station.lng),
                  ...participants.where((p) => p.lat != 0).map((p) => LatLng(p.lat, p.lng)),
                  ...rec.venues.where((v) => v.lat != null).take(5).map((v) => LatLng(v.lat!, v.lng!)),
                ];
                final mapCenter = LatLng(
                  allMapPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allMapPoints.length,
                  allMapPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allMapPoints.length,
                );
                final latSpan = allMapPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b) - allMapPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
                final lngSpan = allMapPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b) - allMapPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
                final span = latSpan > lngSpan ? latSpan : lngSpan;
                final autoZoom = span < 0.005 ? 15.0 : span < 0.01 ? 14.5 : span < 0.03 ? 14.0 : span < 0.05 ? 13.0 : span < 0.1 ? 12.0 : span < 0.3 ? 11.0 : span < 1.0 ? 9.0 : 7.0;

                return SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: autoZoom,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png', userAgentPackageName: 'app.norigo'),
                      MarkerLayer(markers: [
                        // Participant markers (blue) with name label
                        ...participants.where((p) => p.lat != 0).map((p) {
                          final pName = localNames[p.id] ?? p.localizedName(locale);
                          return Marker(
                            point: LatLng(p.lat, p.lng), width: 80, height: 40,
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                                child: Text(pName, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 1),
                              ),
                              Container(width: 16, height: 16,
                                decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                                child: const Icon(Icons.person, size: 9, color: Colors.white)),
                            ]),
                          );
                        }),
                        // Recommended station (orange)
                        Marker(
                          point: LatLng(rec.station.lat, rec.station.lng), width: 32, height: 32,
                          child: Container(
                            decoration: BoxDecoration(color: AppTheme.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]),
                            child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                          ),
                        ),
                        // Venue markers (numbered green markers)
                        ...rec.venues.where((v) => v.lat != null).take(5).toList().asMap().entries.map((e) {
                          final v = e.value;
                          return Marker(
                            point: LatLng(v.lat!, v.lng!), width: 24, height: 24,
                            child: Container(
                              decoration: BoxDecoration(color: AppTheme.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            ),
                          );
                        }),
                      ]),
                    ],
                  ),
                ),
              );
              }),

              // Map legend
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _buildLegendDot(AppTheme.orange, tr(locale, ja: '推薦駅', ko: '추천역', en: 'Recommended', zh: '推荐站', fr: 'Recommandé')),
                  const SizedBox(width: 10),
                  _buildLegendDot(Colors.blue, tr(locale, ja: '出発駅', ko: '출발역', en: 'Departure', zh: '出发站', fr: 'Départ')),
                  if (rec.venues.any((v) => v.lat != null)) ...[
                    const SizedBox(width: 10),
                    _buildLegendDot(AppTheme.green, tr(locale, ja: 'お店', ko: '맛집', en: 'Restaurant', zh: '餐厅', fr: 'Restaurant')),
                  ],
                ]),
              ),

              // Participant distances
              const SizedBox(height: 12),
              ...rec.distances.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.person_outline, size: 16, color: AppTheme.mutedForeground),
                      const SizedBox(width: 8),
                      Expanded(child: Text(localNames[d.participantStationId] ?? d.participantStationName, style: const TextStyle(fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: _timeColor(d.estimatedMinutes).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text('${d.estimatedMinutes}min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _timeColor(d.estimatedMinutes))),
                      ),
                      const SizedBox(width: 6),
                      Text('${d.distanceKm.toStringAsFixed(1)}km', style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
                    ]),
                    // Route bar per participant
                    if (isExpanded && d.route.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: _RouteBar(segments: d.route, localNames: localNames, locale: locale),
                      ),
                    ],
                  ],
                ),
              )),

              // Venues (expanded)
              if (isExpanded && rec.venues.isNotEmpty) ...[
                const Divider(height: 20),
                Row(children: [
                  Icon(Icons.restaurant, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(tr(locale, ja: '周辺のお店 (${rec.venues.length}件)', ko: '주변 맛집 (${rec.venues.length}개)', en: 'Nearby (${rec.venues.length})', zh: '附近餐厅 (${rec.venues.length}家)', fr: 'À proximité (${rec.venues.length})'),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                // ja → HotPepper cards, non-ja → Tabelog link only
                if (locale == 'ja')
                  ...rec.venues.take(5).toList().asMap().entries.map((e) => _VenueCard(venue: e.value, locale: locale, index: e.key + 1))
                else ...[
                  // Google Maps restaurant search (matching web app)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final stationName = localNames[rec.station.id] ?? rec.station.localizedName('ja');
                        final query = Uri.encodeComponent('$stationName駅 レストラン');
                        final url = 'https://www.google.com/maps/search/$query/@${rec.station.lat},${rec.station.lng},16z';
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.map, size: 16),
                      label: Text(
                        tr(locale, ko: '주변 맛집 검색 (Google Maps)', en: 'Search restaurants (Google Maps)', zh: '搜索附近餐厅 (Google Maps)', fr: 'Rechercher des restaurants (Google Maps)'),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],

                // Vote button (ja locale only, matching web)
                if (locale == 'ja' && rec.venues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _VoteButton(stationName: rec.station.name, stationId: rec.station.id, venues: rec.venues, locale: locale),
                ],
              ],

              // Expand hint
              if (!isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(child: Icon(Icons.expand_more, size: 20, color: AppTheme.mutedForeground.withValues(alpha: 0.5))),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _timeColor(int min) {
    if (min <= 20) return AppTheme.green;
    if (min <= 40) return Colors.blue.shade700;
    if (min <= 60) return AppTheme.orange;
    return Colors.red.shade700;
  }
}

Widget _buildLegendDot(Color color, String label) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
  ]);
}

class _VenueCard extends StatelessWidget {
  final Venue venue;
  final String locale;
  final int index;

  const _VenueCard({required this.venue, required this.locale, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index + Photo
          Column(children: [
            if (index > 0) Container(
              width: 20, height: 20, margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(color: AppTheme.green, borderRadius: BorderRadius.circular(4)),
              child: Center(child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: venue.imageUrl != null
                ? Image.network(venue.imageUrl!, width: 72, height: 72, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          ]),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(venue.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (venue.catchText != null)
              Text(venue.catchText!, style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              if (venue.genre != null)
                _Badge(text: venue.genre!),
              if (venue.budget != null) ...[
                const SizedBox(width: 4),
                _Badge(text: venue.budget!, color: AppTheme.primary),
              ],
            ]),
            // Venue features
            if (venue.privateRoom || venue.noSmoking || venue.freeDrink || venue.wifi) ...[
              const SizedBox(height: 4),
              Wrap(spacing: 4, runSpacing: 4, children: [
                if (venue.privateRoom) _FeatureBadge(icon: Icons.meeting_room, label: tr(locale, ja: '個室', ko: '개인실', en: 'Private', zh: '包间', fr: 'Privé')),
                if (venue.noSmoking) _FeatureBadge(icon: Icons.smoke_free, label: tr(locale, ja: '禁煙', ko: '금연', en: 'No smoking', zh: '禁烟', fr: 'Non-fumeur')),
                if (venue.freeDrink) _FeatureBadge(icon: Icons.local_bar, label: tr(locale, ja: '飲み放題', ko: '무한리필', en: 'Free drink', zh: '畅饮', fr: 'Boissons à volonté')),
                if (venue.wifi) _FeatureBadge(icon: Icons.wifi, label: 'WiFi'),
              ]),
            ],
            if (venue.access != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(Icons.directions_walk, size: 12, color: AppTheme.mutedForeground),
                  const SizedBox(width: 4),
                  Expanded(child: Text(venue.access!, style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
          ])),
          // Link
          if (venue.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () async {
                final uri = Uri.parse(venue.url!);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(width: 72, height: 72, decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.restaurant, size: 24));
}

class _Badge extends StatelessWidget {
  final String text;
  final Color? color;
  const _Badge({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.mutedForeground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: c.withValues(alpha: 0.1)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: c)),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: AppTheme.green),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: AppTheme.green, fontWeight: FontWeight.w500)),
      ]),
    );
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
      // Station dots + colored bars
      SizedBox(
        height: 28,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Start station dot
          _StationDot(color: _parseColor(segments.first.color), isFilled: true),
          ...segments.asMap().entries.expand((e) {
            final seg = e.value;
            final isLast = e.key == segments.length - 1;
            final frac = totalSqrt > 0 ? sqrt(seg.minutes.clamp(1, 999).toDouble()) / totalSqrt : 1.0 / segments.length;
            return [
              // Colored bar
              Expanded(
                flex: (frac * 100).round().clamp(1, 100),
                child: Container(height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(color: _parseColor(seg.color), borderRadius: BorderRadius.circular(3))),
              ),
              // End station dot (transfer = ring, terminal = filled)
              if (isLast)
                _StationDot(color: _parseColor(seg.color), isFilled: true)
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
        final localLine = LineLocalizer.localizeSync(seg.line, locale, operator: seg.operator);
        final unit = tr(locale, ja: '分', ko: '분', en: 'min', zh: '分钟', fr: 'min');
        return Expanded(child: Center(child: Text(
          '$localLine ${seg.minutes}$unit',
          style: TextStyle(fontSize: 9, color: AppTheme.mutedForeground),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
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
  final bool isFilled;
  const _StationDot({required this.color, this.isFilled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        color: isFilled ? color : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _TransferDot extends StatelessWidget {
  final Color leftColor;
  final Color rightColor;
  const _TransferDot({required this.leftColor, required this.rightColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        gradient: SweepGradient(
          colors: [rightColor, rightColor, leftColor, leftColor],
          stops: const [0.0, 0.5, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _VoteButton extends StatefulWidget {
  final String stationName;
  final String stationId;
  final List<Venue> venues;
  final String locale;

  const _VoteButton({required this.stationName, required this.stationId, required this.venues, required this.locale});

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton> {
  bool _creating = false;
  String? _pollId;

  Future<void> _createPoll() async {
    setState(() => _creating = true);
    final api = ApiClient();
    final pollId = await api.createVotePoll(
      stationName: widget.stationName,
      stationId: widget.stationId,
      venues: widget.venues.take(10).toList(),
    );
    if (pollId != null && mounted) {
      setState(() { _pollId = pollId; _creating = false; });
      // Open native vote screen
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VoteScreen(pollId: pollId),
      ));
    } else {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pollId != null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VoteScreen(pollId: _pollId!),
          )),
          icon: const Icon(Icons.how_to_vote, size: 14),
          label: FittedBox(child: Text(tr(widget.locale, ja: '投票を開く', ko: '투표 열기', en: 'Open Vote', zh: '打开投票'), style: const TextStyle(fontSize: 12))),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _creating ? null : _createPoll,
        icon: _creating
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.how_to_vote, size: 14),
        label: FittedBox(child: Text(
          _creating
            ? tr(widget.locale, ja: '作成中...', ko: '생성 중...', en: 'Creating...', zh: '创建中...')
            : tr(widget.locale, ja: 'お店の投票を作成', ko: '맛집 투표 만들기', en: 'Create Vote', zh: '创建投票'),
          style: const TextStyle(fontSize: 12))),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
      ),
    );
  }
}

class _MeetupMapView extends StatelessWidget {
  final List<RecommendedStation> recommended;
  final List<Station> participants;

  const _MeetupMapView({required this.recommended, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (recommended.isEmpty) return const SizedBox.shrink();

    final allPoints = [
      ...recommended.map((r) => LatLng(r.station.lat, r.station.lng)),
      ...participants.where((p) => p.lat != 0).map((p) => LatLng(p.lat, p.lng)),
    ];
    if (allPoints.isEmpty) return const Center(child: Text('No map data'));

    final center = LatLng(
      allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length,
      allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length,
    );

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png', userAgentPackageName: 'app.norigo'),
        MarkerLayer(markers: [
          // Participant markers (blue)
          ...participants.where((p) => p.lat != 0).map((p) => Marker(
            point: LatLng(p.lat, p.lng), width: 28, height: 28,
            child: Container(
              decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
          )),
          // Recommended stations (primary color)
          ...recommended.asMap().entries.map((e) {
            final rec = e.value;
            return Marker(
              point: LatLng(rec.station.lat, rec.station.lng), width: 36, height: 36,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                ),
                child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
              ),
            );
          }),
          // Venue markers (orange dots)
          ...recommended.take(1).expand((r) => r.venues.where((v) => v.lat != null && v.lng != null).map((v) => Marker(
            point: LatLng(v.lat!, v.lng!), width: 20, height: 20,
            child: Container(
              decoration: BoxDecoration(color: AppTheme.orange, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: const Icon(Icons.restaurant, size: 10, color: Colors.white),
            ),
          ))),
        ]),
      ],
    );
  }
}
