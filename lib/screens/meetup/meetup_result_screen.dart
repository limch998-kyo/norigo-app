import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
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
                OutlinedButton(onPressed: () => notifier.search(), child: Text(locale == 'ja' ? '再試行' : 'Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final result = state.result;
    if (result == null || result.stations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.reset())),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(locale == 'ja' ? '結果が見つかりませんでした' : 'No results found', style: theme.textTheme.titleMedium),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.reset()),
        actions: [
          IconButton(icon: const Icon(Icons.tune, size: 20), onPressed: () => notifier.reset()),
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
              text: locale == 'ja'
                  ? 'みんなの集合駅で検索したら「${result.stations.first.station.name}駅」がおすすめ！'
                  : '${result.stations.first.station.name} is recommended!',
              url: 'https://norigo.app/result',
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

  const _StationCard({required this.rec, required this.rank, required this.isExpanded, required this.onTap, required this.locale, this.participants = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = rec.station.localizedName(locale);

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
                          child: Text(l, style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
                        ),
                      ).toList()),
                    ),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(rec.finalScore.toStringAsFixed(0), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                  const SizedBox(height: 4),
                  Text(locale == 'ja' ? '平均${rec.avgEstimatedMinutes}分' : 'Avg ${rec.avgEstimatedMinutes}min',
                    style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ]),
              ]),

              // ── Inline map (always visible per card like web) ──
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(rec.station.lat, rec.station.lng),
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                    ),
                    children: [
                      TileLayer(urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png', userAgentPackageName: 'app.norigo'),
                      MarkerLayer(markers: [
                        // Participant markers (blue)
                        ...participants.where((p) => p.lat != 0).map((p) => Marker(
                          point: LatLng(p.lat, p.lng), width: 24, height: 24,
                          child: Container(decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                            child: const Icon(Icons.person, size: 12, color: Colors.white)),
                        )),
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
              ),

              // Map legend
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _buildLegendDot(AppTheme.orange, locale == 'ja' ? '推薦駅' : '추천역'),
                  const SizedBox(width: 10),
                  _buildLegendDot(Colors.blue, locale == 'ja' ? '出発駅' : '출발역'),
                  if (rec.venues.any((v) => v.lat != null)) ...[
                    const SizedBox(width: 10),
                    _buildLegendDot(AppTheme.green, locale == 'ja' ? 'お店' : '맛집'),
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
                      Expanded(child: Text(d.participantStationName, style: const TextStyle(fontSize: 13))),
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
                        child: _RouteBar(segments: d.route),
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
                  Text(locale == 'ja' ? '周辺のお店 (${rec.venues.length}件)' : 'Nearby (${rec.venues.length})',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                ...rec.venues.take(5).toList().asMap().entries.map((e) => _VenueCard(venue: e.value, locale: locale, index: e.key + 1)),

                // Vote button (ja locale only, matching web)
                if (locale == 'ja' && rec.venues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _VoteButton(stationName: rec.station.name, stationId: rec.station.id, venues: rec.venues),
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
  const _RouteBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final totalMin = segments.fold<int>(0, (s, seg) => s + seg.minutes);

    return Column(children: [
      // Color bar
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          child: Row(children: segments.map((seg) {
            final frac = totalMin > 0 ? seg.minutes / totalMin : 1.0 / segments.length;
            return Expanded(
              flex: (frac * 100).round().clamp(1, 100),
              child: Container(color: _parseColor(seg.color), margin: const EdgeInsets.only(right: 1)),
            );
          }).toList()),
        ),
      ),
      const SizedBox(height: 4),
      // Legend
      Wrap(spacing: 8, runSpacing: 2, children: segments.map((seg) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: _parseColor(seg.color), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text('${seg.line} ${seg.minutes}min', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
      ])).toList()),
    ]);
  }

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.grey; }
  }
}

class _VoteButton extends StatefulWidget {
  final String stationName;
  final String stationId;
  final List<Venue> venues;

  const _VoteButton({required this.stationName, required this.stationId, required this.venues});

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton> {
  bool _creating = false;
  String? _pollUrl;

  Future<void> _createPoll() async {
    setState(() => _creating = true);
    final api = ApiClient();
    final pollId = await api.createVotePoll(
      stationName: widget.stationName,
      stationId: widget.stationId,
      venues: widget.venues.take(10).toList(),
    );
    if (pollId != null && mounted) {
      final url = 'https://norigo.app/vote/$pollId';
      setState(() { _pollUrl = url; _creating = false; });
      // Open vote page in browser (like web app)
      // Don't use canLaunchUrl — it requires LSApplicationQueriesSchemes on iOS
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fallback: copy to clipboard
        if (mounted) {
          await Clipboard.setData(ClipboardData(text: url));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('投票リンク: $url')));
        }
      }
    } else {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pollUrl != null) {
      return OutlinedButton.icon(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: _pollUrl!));
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('リンクをコピーしました')));
        },
        icon: const Icon(Icons.how_to_vote, size: 16),
        label: const Text('投票リンクをコピー', style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
      );
    }

    return OutlinedButton.icon(
      onPressed: _creating ? null : _createPoll,
      icon: _creating
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.how_to_vote, size: 16),
      label: Text(_creating ? '作成中...' : 'お店の投票を作成', style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
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
