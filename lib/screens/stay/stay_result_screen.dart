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
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staySearchTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final result = state.result;
    if (result == null || result.areas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.staySearchTitle)),
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

    final displayAreas = state.showSplit && result.splitAreas != null
        ? result.splitAreas!
        : result.areas;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.staySearchTitle),
        actions: [
          if (result.split && result.splitAreas != null)
            TextButton.icon(
              onPressed: () => ref.read(staySearchProvider.notifier).toggleSplit(),
              icon: Icon(
                state.showSplit ? Icons.hotel : Icons.swap_horiz,
                size: 18,
              ),
              label: Text(
                state.showSplit
                    ? (locale == 'ja' ? '通常' : locale == 'ko' ? '통합' : 'Single')
                    : (locale == 'ja' ? '分泊' : locale == 'ko' ? '분할' : 'Split'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: _showMap
          ? _MapView(areas: displayAreas, landmarks: state.landmarks)
          : _ListView(
              areas: displayAreas,
              selectedIndex: _selectedAreaIndex,
              onSelect: (i) => setState(() => _selectedAreaIndex = i),
              locale: locale,
              l10n: l10n,
            ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<StayArea> areas;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String locale;
  final AppLocalizations l10n;

  const _ListView({
    required this.areas,
    required this.selectedIndex,
    required this.onSelect,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: areas.length,
      itemBuilder: (context, index) {
        final area = areas[index];
        return _AreaCard(
          area: area,
          rank: index + 1,
          isExpanded: selectedIndex == index,
          onTap: () => onSelect(index),
          locale: locale,
          l10n: l10n,
        );
      },
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
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: rank <= 3 ? Colors.white : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                        Text(
                          l10n.minutesAway(area.avgEstimatedMinutes),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
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
                            child: Text(
                              ld.landmarkName,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            '${ld.estimatedMinutes}min',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              // Hotels (expanded)
              if (isExpanded && area.hotels.isNotEmpty) ...[
                const Divider(height: 24),
                Text(
                  locale == 'ja'
                      ? 'おすすめホテル'
                      : locale == 'ko'
                          ? '추천 호텔'
                          : 'Recommended Hotels',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...area.hotels.take(5).map((hotel) => _HotelTile(
                      hotel: hotel,
                      l10n: l10n,
                    )),
              ],
            ],
          ),
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
          if (hotel.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                hotel.imageUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.hotel, size: 24),
                ),
              ),
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hotel, size: 24),
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
                      Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                      Text(
                        hotel.starRating!.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (hotel.reviewScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hotel.formattedRating,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Price + Book
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hotel.pricePerNight != null) ...[
                Text(
                  hotel.formattedPrice,
                  style: TextStyle(
                    fontSize: 15,
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
              ],
              const SizedBox(height: 4),
              if (hotel.bookingUrl != null)
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(hotel.bookingUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.bookNow,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapView extends StatelessWidget {
  final List<StayArea> areas;
  final List<dynamic> landmarks;

  const _MapView({required this.areas, required this.landmarks});

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();

    final center = LatLng(areas.first.station.lat, areas.first.station.lng);

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
          markers: [
            // Area markers
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
            }),
          ],
        ),
      ],
    );
  }
}
