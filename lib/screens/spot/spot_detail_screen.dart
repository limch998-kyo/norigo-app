import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../providers/stay_provider.dart';
import '../../models/landmark.dart';

class SpotDetailScreen extends ConsumerWidget {
  final Landmark landmark;

  const SpotDetailScreen({super.key, required this.landmark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final tripState = ref.watch(tripProvider);
    final tripNotifier = ref.read(tripProvider.notifier);
    final theme = Theme.of(context);

    final isInTrip = tripState.items.any((i) => i.slug == landmark.slug);

    return Scaffold(
      appBar: AppBar(
        title: Text(landmark.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(landmark.lat, landmark.lng),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png',
                    userAgentPackageName: 'app.norigo',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: LatLng(landmark.lat, landmark.lng),
                      width: 36, height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.place, size: 18, color: Colors.white),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(landmark.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  if (landmark.nameEn != null && landmark.nameEn != landmark.name)
                    Text(landmark.nameEn!, style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground)),

                  const SizedBox(height: 12),

                  // Region badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _regionLabel(landmark.region, locale),
                      style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Location info
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppTheme.mutedForeground),
                    const SizedBox(width: 6),
                    Text(
                      '${landmark.lat.toStringAsFixed(4)}, ${landmark.lng.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                    ),
                  ]),

                  if (landmark.description != null) ...[
                    const SizedBox(height: 16),
                    Text(landmark.description!, style: const TextStyle(fontSize: 14, height: 1.6)),
                  ],

                  const SizedBox(height: 20),

                  // Add to trip button
                  SizedBox(
                    width: double.infinity,
                    child: isInTrip
                        ? OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(
                              locale == 'ja' ? '追加済み' : locale == 'ko' ? '추가됨' : 'Added',
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {
                              tripNotifier.addItem(landmark, locale: locale);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                  locale == 'ja' ? '旅行に追加しました'
                                    : locale == 'ko' ? '여행에 추가했습니다'
                                    : 'Added to trip',
                                ),
                              ));
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              locale == 'ja' ? '旅行に追加' : locale == 'ko' ? '여행에 추가' : 'Add to Trip',
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Find hotels button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Add to trip if not already
                        if (!isInTrip) {
                          tripNotifier.addItem(landmark, locale: locale);
                        }
                        // Get all trip items for the same region
                        final regionItems = tripState.items.where((i) => i.region == landmark.region).toList();
                        final landmarks = [
                          landmark,
                          ...regionItems.where((i) => i.slug != landmark.slug).map((i) => Landmark(
                            slug: i.slug, name: i.name, lat: i.lat, lng: i.lng, region: i.region,
                          )),
                        ];
                        if (landmarks.length >= 2) {
                          final stayNotifier = ref.read(staySearchProvider.notifier);
                          stayNotifier.reset();
                          for (final l in landmarks) { stayNotifier.addLandmark(l); }
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          // The parent MainShell would need to switch to tab 1
                        }
                      },
                      icon: const Icon(Icons.hotel, size: 18),
                      label: Text(
                        locale == 'ja' ? 'この観光地の近くのホテルを探す'
                          : locale == 'ko' ? '이 관광지 근처 호텔 찾기'
                          : 'Find Hotels Near Here',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _regionLabel(String region, String locale) {
    const labels = {
      'kanto': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto'},
      'kansai': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai'},
      'seoul': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul'},
      'busan': {'ja': '釜山', 'ko': '부산', 'en': 'Busan'},
    };
    return labels[region]?[locale] ?? labels[region]?['en'] ?? region;
  }
}
