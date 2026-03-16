import 'package:flutter/material.dart';
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

class StayResultScreen extends ConsumerStatefulWidget {
  const StayResultScreen({super.key});

  @override
  ConsumerState<StayResultScreen> createState() => _StayResultScreenState();
}

class _StayResultScreenState extends ConsumerState<StayResultScreen> {
  int _expandedIndex = 0;

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
    if (result == null || result.areas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staySearchTitle), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.reset())),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(l10n.noResults, style: theme.textTheme.titleMedium),
        ])),
      );
    }

    final displayAreas = state.showSplit && result.splitAreas != null ? result.splitAreas! : result.areas;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ja' ? '推薦宿泊エリア' : locale == 'ko' ? '추천 숙박 지역' : 'Recommended Areas'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => notifier.reset()),
        actions: [
          IconButton(icon: const Icon(Icons.tune, size: 20), onPressed: () => notifier.reset()),
        ],
      ),
      body: Column(
        children: [
          // Mode tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ModeTabs(selected: state.mode, onChanged: (m) { notifier.setMode(m); notifier.search(); }, locale: locale),
          ),
          // Split toggle
          if (result.split && result.splitAreas != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                _ToggleChip(label: locale == 'ja' ? '1곳 숙박' : '1곳 숙박', selected: !state.showSplit, onTap: () { if (state.showSplit) notifier.toggleSplit(); }),
                const SizedBox(width: 8),
                _ToggleChip(label: locale == 'ja' ? '分散 숙박' : '분산 숙박', selected: state.showSplit, onTap: () { if (!state.showSplit) notifier.toggleSplit(); }),
              ]),
            ),
          const SizedBox(height: 8),
          // Results list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displayAreas.length + 1,
              itemBuilder: (context, index) {
                if (index == displayAreas.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ShareButtons(
                      title: 'Norigo',
                      text: locale == 'ko'
                          ? '${state.landmarks.map((l) => l.name).join('・')} 여행에 최적의 호텔 지역'
                          : 'Best hotel area for ${state.landmarks.map((l) => l.name).join(', ')}',
                      url: 'https://norigo.app/stay/result',
                      locale: locale,
                    ),
                  );
                }
                return _AreaCard(
                  area: displayAreas[index],
                  rank: index + 1,
                  isExpanded: _expandedIndex == index,
                  onTap: () => setState(() => _expandedIndex = _expandedIndex == index ? -1 : index),
                  locale: locale,
                  l10n: l10n,
                  landmarks: state.landmarks,
                  checkIn: state.checkIn,
                  checkOut: state.checkOut,
                );
              },
            ),
          ),
        ],
      ),
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

class _AreaCard extends StatelessWidget {
  final StayArea area;
  final int rank;
  final bool isExpanded;
  final VoidCallback onTap;
  final String locale;
  final AppLocalizations l10n;
  final List<Landmark> landmarks;
  final String? checkIn;
  final String? checkOut;

  const _AreaCard({required this.area, required this.rank, required this.isExpanded, required this.onTap, required this.locale, required this.l10n, required this.landmarks, this.checkIn, this.checkOut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = area.station.localizedName(locale);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
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
                child: _InlineMap(area: area, landmarks: landmarks, locale: locale),
              ),
            ),
            // Map legend
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _LegendDot(color: AppTheme.orange, label: locale == 'ja' ? 'ホテル推薦駅' : '호텔 추천역'),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.indigo, label: locale == 'ja' ? '観光地' : '관광지'),
              ]),
            ),

            // ── Station lines ──
            if (area.station.lines.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(locale == 'ja' ? 'ノ선' : 'Lines', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
              const SizedBox(height: 4),
              Wrap(spacing: 4, runSpacing: 4, children: area.station.lines.take(4).map((l) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: AppTheme.primaryBg),
                  child: Text(l, style: TextStyle(fontSize: 10, color: AppTheme.primary)),
                ),
              ).toList()),
            ],

            // ── Landmark distances with routes ──
            const SizedBox(height: 12),
            Text(locale == 'ja' ? '観光地까지の距離' : locale == 'ko' ? '관광지까지 거리' : 'Distance to landmarks',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
            const SizedBox(height: 6),
            ...area.landmarkDistances.map((ld) => _LandmarkDistanceTile(ld: ld, locale: locale, isExpanded: isExpanded)),

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
              Text(locale == 'ja' ? '周辺の便利施設 (500m以内)' : locale == 'ko' ? '주변 편의시설 (500m 이내)' : 'Nearby (500m)',
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

            // ── Hotels (lazy loaded) ──
            if (isExpanded) ...[
              const Divider(height: 24),
              _HotelSection(stationId: area.station.id, locale: locale, l10n: l10n, checkIn: checkIn, checkOut: checkOut),
            ],

            // Expand hint
            if (!isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: Icon(Icons.expand_more, size: 20, color: AppTheme.mutedForeground.withValues(alpha: 0.5))),
              ),
          ]),
        ),
      ),
    );
  }
}

class _LandmarkDistanceTile extends StatelessWidget {
  final LandmarkDistance ld;
  final String locale;
  final bool isExpanded;

  const _LandmarkDistanceTile({required this.ld, required this.locale, required this.isExpanded});

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
              child: _RouteBar(segments: ld.route),
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
  const _RouteBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final totalMin = segments.fold<int>(0, (s, seg) => s + seg.minutes);

    return Column(children: [
      // Station names + dots + colored bars
      Row(children: segments.expand((seg) {
        final frac = totalMin > 0 ? seg.minutes / totalMin : 1.0 / segments.length;
        return [
          Expanded(
            flex: (frac * 100).round().clamp(1, 100),
            child: Column(children: [
              // From station name
              Text(seg.fromStationName ?? '', style: TextStyle(fontSize: 9, color: AppTheme.mutedForeground), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              // Color bar
              Container(height: 6, decoration: BoxDecoration(color: _parseColor(seg.color), borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 2),
              // Line name + time
              Text('${seg.line}', style: TextStyle(fontSize: 9, color: AppTheme.mutedForeground), overflow: TextOverflow.ellipsis),
              Text('${seg.minutes}${seg.minutes > 0 ? "分" : ""}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _parseColor(seg.color))),
            ]),
          ),
        ];
      }).toList()),
    ]);
  }

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); } catch (_) { return Colors.grey; }
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

  const _InlineMap({required this.area, required this.landmarks, this.locale = 'en'});

  @override
  Widget build(BuildContext context) {
    final allPoints = [
      LatLng(area.station.lat, area.station.lng),
      ...landmarks.map((l) => LatLng(l.lat, l.lng)),
    ];
    final center = LatLng(
      allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length,
      allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length,
    );

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 13, interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag)),
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
        ]),
      ],
    );
  }
}

class _HotelSection extends StatefulWidget {
  final String stationId;
  final String locale;
  final AppLocalizations l10n;
  final String? checkIn;
  final String? checkOut;

  const _HotelSection({required this.stationId, required this.locale, required this.l10n, this.checkIn, this.checkOut});

  @override
  State<_HotelSection> createState() => _HotelSectionState();
}

class _HotelSectionState extends State<_HotelSection> {
  List<Hotel>? _hotels;
  bool _loading = true;
  bool _expanded = false;
  static const _defaultVisible = 3;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    try {
      final api = ApiClient();
      final checkIn = widget.checkIn ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);
      final checkOut = widget.checkOut ?? DateTime.now().add(const Duration(days: 32)).toIso8601String().substring(0, 10);
      final hotels = await api.getHotels(stationId: widget.stationId, checkIn: checkIn, checkOut: checkOut, locale: widget.locale);
      if (mounted) setState(() { _hotels = hotels; _loading = false; });
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

    final displayed = _expanded ? _hotels! : _hotels!.take(_defaultVisible).toList();
    final hasMore = _hotels!.length > _defaultVisible;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Text(widget.locale == 'ja' ? '周辺ホテル' : widget.locale == 'ko' ? '주변 호텔' : 'Nearby Hotels', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text('1泊2人基準', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
      ]),
      const SizedBox(height: 8),

      // Hotel cards
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

      // Powered by Agoda
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Powered by ', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground)),
          Text('Agoda', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground)),
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
            onTap: () async {
              final uri = Uri.parse(hotel.bookingUrl!);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
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
