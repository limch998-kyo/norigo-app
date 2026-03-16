import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_providers.dart';
import '../../providers/meetup_provider.dart';
import '../../models/meetup_result.dart';
import '../../models/station.dart';
import '../../widgets/mode_tabs.dart';
import '../../widgets/share_buttons.dart';
import '../../widgets/skeleton_loader.dart';

class MeetupResultScreen extends ConsumerStatefulWidget {
  const MeetupResultScreen({super.key});

  @override
  ConsumerState<MeetupResultScreen> createState() => _MeetupResultScreenState();
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

    final title = locale == 'ja' ? '検索結果' : locale == 'ko' ? '검색 결과' : 'Results';

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const SkeletonLoader(count: 3),
      );
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
                OutlinedButton(
                  onPressed: () => notifier.search(),
                  child: Text(locale == 'ja' ? '再試行' : locale == 'ko' ? '재시도' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final result = state.result;
    if (result == null || result.stations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => notifier.reset(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                locale == 'ja' ? '結果が見つかりませんでした' : locale == 'ko' ? '결과를 찾을 수 없습니다' : 'No results found',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => notifier.reset(),
                child: Text(locale == 'ja' ? '検索に戻る' : locale == 'ko' ? '검색으로 돌아가기' : 'Back to search'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => notifier.reset(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            onPressed: () => notifier.reset(),
          ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map, size: 20),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mode Tabs ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ModeTabs(
              selected: state.mode,
              onChanged: (mode) {
                notifier.setMode(mode);
                notifier.search();
              },
              locale: locale,
            ),
          ),

          // ── Content ──
          Expanded(
            child: _showMap
                ? _MeetupMapView(
                    recommended: result.stations,
                    participants: state.filledStations,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: result.stations.length + 1,
                    itemBuilder: (context, index) {
                      if (index == result.stations.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: ShareButtons(
                            title: 'Norigo',
                            text: locale == 'ja'
                                ? '${result.stations.first.station.name}が集合駅としておすすめです！'
                                : locale == 'ko'
                                    ? '${result.stations.first.station.name}이(가) 만남역으로 추천됩니다!'
                                    : '${result.stations.first.station.name} is recommended as meetup station!',
                            url: 'https://norigo.app/result',
                            locale: locale,
                          ),
                        );
                      }

                      final rec = result.stations[index];
                      return _MeetupStationCard(
                        rec: rec,
                        rank: index + 1,
                        isExpanded: _expandedIndex == index,
                        onTap: () => setState(() => _expandedIndex = index),
                        locale: locale,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MeetupStationCard extends StatelessWidget {
  final RecommendedStation rec;
  final int rank;
  final bool isExpanded;
  final VoidCallback onTap;
  final String locale;

  const _MeetupStationCard({
    required this.rec,
    required this.rank,
    required this.isExpanded,
    required this.onTap,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stationName = rec.station.localizedName(locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _RankBadge(rank: rank),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        // Lines
                        if (rec.station.lines.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              rec.station.lines.take(3).join(' · '),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rec.finalScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locale == 'ja'
                            ? '平均${rec.avgEstimatedMinutes}分'
                            : locale == 'ko'
                                ? '평균 ${rec.avgEstimatedMinutes}분'
                                : 'Avg ${rec.avgEstimatedMinutes}min',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Stats row
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.straighten,
                      label: '${rec.avgDistanceKm.toStringAsFixed(1)}km',
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.timer_outlined,
                      label: 'max ${rec.maxEstimatedMinutes}min',
                      theme: theme,
                    ),
                  ],
                ),
              ),

              // Participant distances
              const SizedBox(height: 12),
              ...rec.distances.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(d.participantStationName, style: const TextStyle(fontSize: 13)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _timeColor(d.estimatedMinutes).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${d.estimatedMinutes}min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _timeColor(d.estimatedMinutes),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${d.distanceKm.toStringAsFixed(1)}km',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  )),

              // Route Bar (expanded)
              if (isExpanded && rec.route != null && rec.route!.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  locale == 'ja' ? 'ルート' : locale == 'ko' ? '경로' : 'Route',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _RouteBar(segments: rec.route!),
              ],

              // Venues (expanded)
              if (isExpanded && rec.venues.isNotEmpty) ...[
                const Divider(height: 20),
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      locale == 'ja' ? '周辺のお店' : locale == 'ko' ? '주변 맛집' : 'Nearby Venues',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...rec.venues.take(5).map((venue) => _VenueTile(venue: venue)),
              ],

              // Expand hint
              if (!isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Icon(Icons.expand_more, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _timeColor(int minutes) {
    if (minutes <= 20) return Colors.green.shade700;
    if (minutes <= 40) return Colors.blue.shade700;
    if (minutes <= 60) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.amber.shade700, Colors.grey.shade500, Colors.brown.shade400];
    final color = rank <= 3 ? colors[rank - 1] : Theme.of(context).colorScheme.outline;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _StatChip({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

/// Colored bar showing transit line segments
class _RouteBar extends StatelessWidget {
  final List<RouteSegment> segments;

  const _RouteBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    final totalMinutes = segments.fold<int>(0, (sum, s) => sum + s.minutes + (s.transferMinutes ?? 0));

    return Column(
      children: [
        // Visual bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: segments.map((seg) {
                final fraction = totalMinutes > 0 ? (seg.minutes / totalMinutes) : 1.0 / segments.length;
                Color lineColor;
                try {
                  lineColor = Color(int.parse(seg.color.replaceFirst('#', '0xFF')));
                } catch (_) {
                  lineColor = Colors.grey;
                }
                return Expanded(
                  flex: (fraction * 100).round().clamp(1, 100),
                  child: Container(
                    color: lineColor,
                    margin: const EdgeInsets.only(right: 1),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Segment details
        ...segments.map((seg) {
          Color lineColor;
          try {
            lineColor = Color(int.parse(seg.color.replaceFirst('#', '0xFF')));
          } catch (_) {
            lineColor = Colors.grey;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Expanded(child: Text(seg.line, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                Text('${seg.minutes}min', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                if (seg.transferMinutes != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(3)),
                    child: Text('↔${seg.transferMinutes}min', style: TextStyle(fontSize: 9, color: Colors.orange.shade700)),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _VenueTile extends StatelessWidget {
  final Venue venue;
  const _VenueTile({required this.venue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: venue.imageUrl != null
                ? Image.network(venue.imageUrl!, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: theme.colorScheme.surfaceContainerHighest, child: const Icon(Icons.restaurant, size: 20)))
                : Container(width: 48, height: 48, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.restaurant, size: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(venue.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (venue.genre != null) Text(venue.genre!, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                if (venue.budget != null) Text(venue.budget!, style: TextStyle(fontSize: 11, color: theme.colorScheme.primary)),
              ],
            ),
          ),
          if (venue.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () async {
                final uri = Uri.parse(venue.url!);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
        ],
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
      ...participants.map((p) => LatLng(p.lat, p.lng)),
    ];
    final center = LatLng(
      allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length,
      allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length,
    );

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'app.norigo'),
        MarkerLayer(
          markers: [
            // Participant markers (blue)
            ...participants.map((p) => Marker(
                  point: LatLng(p.lat, p.lng),
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                )),
            // Recommended station markers (coral)
            ...recommended.asMap().entries.map((entry) {
              final rec = entry.value;
              final rank = entry.key + 1;
              return Marker(
                point: LatLng(rec.station.lat, rec.station.lng),
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                  ),
                  child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
