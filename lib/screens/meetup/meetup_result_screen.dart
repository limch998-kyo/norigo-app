import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_providers.dart';
import '../../providers/meetup_provider.dart';
import '../../models/meetup_result.dart';

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
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(locale == 'ja' ? '検索結果' : locale == 'ko' ? '검색 결과' : 'Results'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final result = state.result;
    if (result == null || result.stations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(locale == 'ja' ? '検索結果' : locale == 'ko' ? '검색 결과' : 'Results'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                locale == 'ja'
                    ? '結果が見つかりませんでした'
                    : locale == 'ko'
                        ? '결과를 찾을 수 없습니다'
                        : 'No results found',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ja' ? '検索結果' : locale == 'ko' ? '검색 결과' : 'Results'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: _showMap
          ? _MeetupMapView(
              stations: result.stations,
              participants: state.stations,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: result.stations.length,
              itemBuilder: (context, index) {
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              locale == 'ja'
                                  ? '平均 ${rec.avgEstimatedMinutes}分'
                                  : locale == 'ko'
                                      ? '평균 ${rec.avgEstimatedMinutes}분'
                                      : 'Avg ${rec.avgEstimatedMinutes} min',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                ],
              ),

              // Participant distances
              const SizedBox(height: 12),
              ...rec.distances.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d.participantStationName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${d.estimatedMinutes}min',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )),

              // Route segments (expanded)
              if (isExpanded && rec.route != null && rec.route!.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  locale == 'ja' ? 'ルート' : locale == 'ko' ? '경로' : 'Route',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...rec.route!.map((seg) => _RouteSegmentTile(segment: seg)),
              ],

              // Venues (expanded)
              if (isExpanded && rec.venues.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  locale == 'ja'
                      ? '周辺のお店'
                      : locale == 'ko'
                          ? '주변 맛집'
                          : 'Nearby Venues',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...rec.venues.take(5).map((venue) => _VenueTile(venue: venue)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSegmentTile extends StatelessWidget {
  final RouteSegment segment;

  const _RouteSegmentTile({required this.segment});

  @override
  Widget build(BuildContext context) {
    Color lineColor;
    try {
      lineColor = Color(int.parse(segment.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      lineColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              segment.line,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${segment.minutes}min',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (segment.transferMinutes != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '+${segment.transferMinutes}min',
                style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
              ),
            ),
          ],
        ],
      ),
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
          if (venue.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                venue.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.restaurant, size: 20),
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.restaurant, size: 20),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (venue.genre != null)
                  Text(
                    venue.genre!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                if (venue.budget != null)
                  Text(
                    venue.budget!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (venue.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () async {
                final uri = Uri.parse(venue.url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _MeetupMapView extends StatelessWidget {
  final List<RecommendedStation> stations;
  final List<dynamic> participants;

  const _MeetupMapView({required this.stations, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (stations.isEmpty) return const SizedBox.shrink();

    final center = LatLng(stations.first.station.lat, stations.first.station.lng);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'app.norigo',
        ),
        MarkerLayer(
          markers: stations.asMap().entries.map((entry) {
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
