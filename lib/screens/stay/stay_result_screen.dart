import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../models/stay_area.dart';
import '../../models/hotel.dart';
import '../../models/landmark.dart';
import '../../widgets/mode_tabs.dart';
import '../../widgets/share_buttons.dart';
import '../../widgets/skeleton_loader.dart';
import '../../services/api_client.dart';
import '../../config/theme.dart';

class StayResultScreen extends ConsumerStatefulWidget {
  const StayResultScreen({super.key});

  @override
  ConsumerState<StayResultScreen> createState() => _StayResultScreenState();
}

class _StayResultScreenState extends ConsumerState<StayResultScreen> {
  int _selectedAreaIndex = 0;
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final state = ref.watch(staySearchProvider);
    final notifier = ref.read(staySearchProvider.notifier);
    final theme = Theme.of(context);

    // Loading state with skeleton
    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staySearchTitle)),
        body: const SkeletonLoader(count: 3),
      );
    }

    // Error state
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staySearchTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  locale == 'ja'
                      ? 'エラーが発生しました'
                      : locale == 'ko'
                          ? '오류가 발생했습니다'
                          : 'An error occurred',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
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
    if (result == null || result.areas.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.staySearchTitle),
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
              Text(l10n.noResults, style: theme.textTheme.titleMedium),
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

    final displayAreas = state.showSplit && result.splitAreas != null
        ? result.splitAreas!
        : result.areas;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staySearchTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => notifier.reset(),
        ),
        actions: [
          // Edit search
          IconButton(
            icon: const Icon(Icons.tune, size: 20),
            tooltip: locale == 'ja' ? '検索を編集' : locale == 'ko' ? '검색 수정' : 'Edit search',
            onPressed: () => notifier.reset(),
          ),
          // Map/list toggle
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ModeTabs(
              selected: state.mode,
              onChanged: (mode) {
                notifier.setMode(mode);
                notifier.search();
              },
              locale: locale,
            ),
          ),

          // ── Split/Single Toggle ──
          if (result.split && result.splitAreas != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: locale == 'ja' ? '通常（1ホテル）' : locale == 'ko' ? '통합 (1호텔)' : 'Single Hotel',
                      isSelected: !state.showSplit,
                      onTap: () {
                        if (state.showSplit) notifier.toggleSplit();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleButton(
                      label: locale == 'ja' ? '分泊（2ホテル）' : locale == 'ko' ? '분할 (2호텔)' : 'Split Stay',
                      isSelected: state.showSplit,
                      badge: locale == 'ja' ? 'おすすめ' : locale == 'ko' ? '추천' : 'Recommended',
                      onTap: () {
                        if (!state.showSplit) notifier.toggleSplit();
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Content ──
          Expanded(
            child: _showMap
                ? _MapView(areas: displayAreas, landmarks: state.landmarks)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayAreas.length + 1, // +1 for share buttons
                    itemBuilder: (context, index) {
                      if (index == displayAreas.length) {
                        // Share buttons at bottom
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: ShareButtons(
                            title: 'Norigo',
                            text: locale == 'ja'
                                ? '${state.landmarks.map((l) => l.name).join('・')}への旅行にぴったりのホテルエリア'
                                : locale == 'ko'
                                    ? '${state.landmarks.map((l) => l.name).join('・')} 여행에 최적의 호텔 지역'
                                    : 'Best hotel area for ${state.landmarks.map((l) => l.name).join(', ')}',
                            url: 'https://norigo.app/stay/result',
                            locale: locale,
                          ),
                        );
                      }

                      final area = displayAreas[index];
                      return _AreaCard(
                        area: area,
                        rank: index + 1,
                        isExpanded: _selectedAreaIndex == index,
                        onTap: () => setState(() => _selectedAreaIndex = index),
                        locale: locale,
                        l10n: l10n,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final StayArea area;
  final int rank;
  final bool isExpanded;
  final VoidCallback onTap;
  final String locale;
  final AppLocalizations l10n;

  const _AreaCard({
    required this.area,
    required this.rank,
    required this.isExpanded,
    required this.onTap,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stationName = area.station.localizedName(locale);

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
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.minutesAway(area.avgEstimatedMinutes),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'max ${area.maxEstimatedMinutes}min',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _ScoreBadge(score: area.finalScore),
                ],
              ),

              // Landmark distances
              if (area.landmarkDistances.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...area.landmarkDistances.map((ld) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.place, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(ld.landmarkName, style: const TextStyle(fontSize: 13)),
                          ),
                          Text(
                            '${ld.estimatedMinutes}min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ld.estimatedMinutes <= 30
                                  ? Colors.green.shade700
                                  : ld.estimatedMinutes <= 60
                                      ? Colors.orange.shade700
                                      : Colors.red.shade700,
                            ),
                          ),
                          if (ld.distanceKm > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${ld.distanceKm.toStringAsFixed(1)}km',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )),
              ],

              // Area description
              if (isExpanded && area.areaDescription != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    area.areaDescription!,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ],

              // Reachable destinations (expanded)
              if (isExpanded && area.reachableDestinations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  locale == 'ja' ? '周辺のスポット' : locale == 'ko' ? '주변 명소' : 'Nearby Spots',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: area.reachableDestinations.take(6).map((rd) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    ),
                    child: Text('${rd.name} ${rd.minutes}min', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary)),
                  )).toList(),
                ),
              ],

              // Hotels section (expanded) — loaded via separate API
              if (isExpanded) ...[
                const Divider(height: 24),
                _HotelSection(stationId: area.station.id, locale: locale, l10n: l10n),
              ],

              // Expand hint
              if (!isExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.expand_more, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        Text(
                          locale == 'ja' ? 'ホテルを表示'
                              : locale == 'ko' ? '호텔 보기'
                              : 'Show hotels',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.amber.shade700, Colors.grey.shade500, Colors.brown.shade400];
    final color = rank <= 3
        ? colors[rank - 1]
        : Theme.of(context).colorScheme.outline;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$rank',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        score.toStringAsFixed(0),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Lazy-loads hotels for a station when the card is expanded
class _HotelSection extends StatefulWidget {
  final String stationId;
  final String locale;
  final AppLocalizations l10n;

  const _HotelSection({required this.stationId, required this.locale, required this.l10n});

  @override
  State<_HotelSection> createState() => _HotelSectionState();
}

class _HotelSectionState extends State<_HotelSection> {
  List<Hotel>? _hotels;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    try {
      final api = ApiClient();
      final checkIn = DateTime.now().add(const Duration(days: 30));
      final checkOut = checkIn.add(const Duration(days: 2));
      final hotels = await api.getHotels(
        stationId: widget.stationId,
        checkIn: checkIn.toIso8601String().substring(0, 10),
        checkOut: checkOut.toIso8601String().substring(0, 10),
      );
      if (mounted) setState(() { _hotels = hotels; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))),
      );
    }

    if (_error != null || _hotels == null || _hotels!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          widget.locale == 'ja' ? 'ホテル情報を取得できませんでした' : 'No hotel data available',
          style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.hotel, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '${widget.l10n.recommendedHotels} (${_hotels!.length})',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ]),
        const SizedBox(height: 8),
        ..._hotels!.take(5).map((hotel) => _HotelTile(hotel: hotel, l10n: widget.l10n)),
      ],
    );
  }
}

class _HotelTile extends StatelessWidget {
  final Hotel hotel;
  final AppLocalizations l10n;

  const _HotelTile({required this.hotel, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          // Hotel image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: hotel.imageUrl != null
                ? Image.network(
                    hotel.imageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                  )
                : _ImagePlaceholder(),
          ),
          const SizedBox(width: 12),

          // Hotel info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (hotel.starRating != null) ...[
                      ...List.generate(
                        hotel.starRating!.round().clamp(0, 5),
                        (_) => Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (hotel.reviewScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _scoreColor(hotel.reviewScore!).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hotel.formattedRating,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(hotel.reviewScore!),
                          ),
                        ),
                      ),
                    if (hotel.reviewCount != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${hotel.reviewCount})',
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                    ],
                  ],
                ),
                // Amenity badges
                if (hotel.includeBreakfast || hotel.freeWifi) ...[
                  const SizedBox(height: 4),
                  Wrap(spacing: 4, children: [
                    if (hotel.includeBreakfast)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.restaurant, size: 10, color: Colors.green.shade700),
                          const SizedBox(width: 3),
                          Text('朝食付', style: TextStyle(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    if (hotel.freeWifi)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.wifi, size: 10, color: Colors.blue.shade700),
                          const SizedBox(width: 3),
                          Text('WiFi', style: TextStyle(fontSize: 9, color: Colors.blue.shade700, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                  ]),
                ],
              ],
            ),
          ),

          // Price + Book
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hotel.dailyRate != null) ...[
                // Crossed out original price
                if (hotel.formattedCrossedOutPrice != null)
                  Text(
                    hotel.formattedCrossedOutPrice!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  hotel.formattedPrice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  l10n.perNight,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                // Discount badge
                if (hotel.discountPercent > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text('-${hotel.discountPercent}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  ),
              ],
              const SizedBox(height: 6),
              if (hotel.bookingUrl != null)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(hotel.bookingUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.bookNow,
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 8.5) return Colors.green.shade700;
    if (score >= 7.0) return Colors.blue.shade700;
    if (score >= 5.0) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.hotel, size: 24),
    );
  }
}

class _MapView extends StatelessWidget {
  final List<StayArea> areas;
  final List<Landmark> landmarks;

  const _MapView({required this.areas, required this.landmarks});

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();

    final allPoints = [
      ...areas.map((a) => LatLng(a.station.lat, a.station.lng)),
      ...landmarks.map((l) => LatLng(l.lat, l.lng)),
    ];

    final center = LatLng(
      allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length,
      allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length,
    );

    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 11),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'app.norigo',
        ),
        MarkerLayer(
          markers: [
            // Landmark markers (blue)
            ...landmarks.map((l) => Marker(
                  point: LatLng(l.lat, l.lng),
                  width: 28,
                  height: 28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.place, size: 16, color: Colors.white),
                  ),
                )),
            // Area markers (coral)
            ...areas.asMap().entries.map((entry) {
              final area = entry.value;
              final rank = entry.key + 1;
              return Marker(
                point: LatLng(area.station.lat, area.station.lng),
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
