import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../providers/stay_provider.dart';
import '../../models/landmark.dart';
import '../../utils/tr.dart';
import '../../widgets/trip_picker_dialog.dart';
import '../../app.dart';

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
      appBar: AppBar(title: Text(landmark.name)),
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
                    urlTemplate:
                        'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png',
                    userAgentPackageName: 'app.norigo',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(landmark.lat, landmark.lng),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.place,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    landmark.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (landmark.nameEn != null &&
                      landmark.nameEn != landmark.name)
                    Text(
                      landmark.nameEn!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Region badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _regionLabel(landmark.region, locale),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Location info
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${landmark.lat.toStringAsFixed(4)}, ${landmark.lng.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),

                  if (landmark.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      landmark.description!,
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
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
                              tr(
                                locale,
                                ja: '追加済み',
                                ko: '추가됨',
                                en: 'Added',
                                zh: '已添加',
                                fr: 'Ajouté',
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              tripNotifier.addItem(landmark, locale: locale);
                              if (tripNotifier.needsTripPicker) {
                                final picked = await showTripPickerDialog(
                                  context,
                                  tripNotifier.pendingTripCandidates,
                                  locale,
                                );
                                if (picked != null) {
                                  tripNotifier.completePendingAdd(picked);
                                } else {
                                  tripNotifier.cancelPendingAdd();
                                  return;
                                }
                              }
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  content: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tr(
                                            locale,
                                            ja: '旅行に追加しました',
                                            ko: '여행에 추가됨',
                                            en: 'Added to trip',
                                            zh: '已添加到旅行',
                                            fr: 'Ajouté au voyage',
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).hideCurrentSnackBar();
                                          Navigator.of(
                                            context,
                                          ).popUntil((route) => route.isFirst);
                                          MainShell.globalSwitchTab?.call(3);
                                        },
                                        child: Text(
                                          tr(
                                            locale,
                                            ja: '表示',
                                            ko: '보기',
                                            en: 'View',
                                            zh: '查看',
                                            fr: 'Voir',
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              tr(
                                locale,
                                ja: '旅行に追加',
                                ko: '여행에 추가',
                                en: 'Add to Trip',
                                zh: '添加到旅行',
                                fr: 'Ajouter au voyage',
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Find hotels button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        var targetTripId = _tripIdForExistingLandmark(
                          tripState,
                          landmark,
                        );

                        // Add to trip if not already
                        if (!isInTrip) {
                          final candidates = tripNotifier.findTripsForRegion(
                            landmark.region,
                          );
                          if (candidates.length == 1) {
                            targetTripId = candidates.first.id;
                          }

                          tripNotifier.addItem(landmark, locale: locale);
                          if (tripNotifier.needsTripPicker) {
                            final picked = await showTripPickerDialog(
                              context,
                              tripNotifier.pendingTripCandidates,
                              locale,
                            );
                            if (picked != null) {
                              targetTripId = picked;
                              tripNotifier.completePendingAdd(picked);
                            } else {
                              tripNotifier.cancelPendingAdd();
                              return;
                            }
                          } else {
                            targetTripId ??= ref
                                .read(tripProvider)
                                .activeTripId;
                          }
                        }

                        if (!context.mounted) return;

                        // Keep the hotel search scoped to the trip the user
                        // just selected instead of every trip in this region.
                        final latestTripState = ref.read(tripProvider);
                        targetTripId ??= _tripIdForExistingLandmark(
                          latestTripState,
                          landmark,
                        );
                        targetTripId ??= latestTripState.activeTripId;
                        final regionItems = latestTripState.items
                            .where(
                              (i) =>
                                  i.region == landmark.region &&
                                  (targetTripId == null ||
                                      i.tripId == targetTripId),
                            )
                            .toList();
                        final landmarks = [
                          landmark,
                          ...regionItems
                              .where((i) => i.slug != landmark.slug)
                              .map(
                                (i) => Landmark(
                                  slug: i.slug,
                                  name: i.name,
                                  lat: i.lat,
                                  lng: i.lng,
                                  region: i.region,
                                ),
                              ),
                        ];

                        final stayNotifier = ref.read(
                          staySearchProvider.notifier,
                        );
                        final checkIn = _dateKey(
                          DateTime.now().add(const Duration(days: 30)),
                        );
                        final checkOut = _dateKey(
                          DateTime.now().add(const Duration(days: 33)),
                        );
                        stayNotifier.reset();
                        stayNotifier.setRegion(landmark.region);
                        stayNotifier.setBudget(
                          _defaultStayBudget(landmark.region),
                        );
                        stayNotifier.setDates(checkIn, checkOut);
                        for (final l in landmarks) {
                          stayNotifier.addLandmark(l);
                        }

                        if (landmarks.length < 2) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                              content: Text(
                                tr(
                                  locale,
                                  ja: 'ホテルエリア検索には観光地をもう1つ追加してください',
                                  ko: '호텔 지역 검색에는 관광지를 하나 더 추가해주세요',
                                  en: 'Add one more spot to search hotel areas',
                                  zh: '请再添加一个景点来搜索酒店区域',
                                  fr: 'Ajoutez un autre lieu pour chercher des quartiers d\'hôtel',
                                ),
                              ),
                            ),
                          );
                        }

                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        MainShell.globalSwitchTab?.call(1);

                        if (landmarks.length >= 2) {
                          await stayNotifier.search();
                        }
                      },
                      icon: const Icon(Icons.hotel, size: 18),
                      label: Text(
                        tr(
                          locale,
                          ja: 'この観光地の近くのホテルを探す',
                          ko: '이 관광지 근처 호텔 찾기',
                          en: 'Find Hotels Near Here',
                          zh: '查找附近酒店',
                          fr: 'Trouver des hôtels à proximité',
                        ),
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

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _defaultStayBudget(String region) {
    if (AppConstants.koreaRegions.contains(region)) {
      return '25000-35000';
    }
    return AppConstants.defaultStayBudgetJp;
  }

  String? _tripIdForExistingLandmark(TripState tripState, Landmark landmark) {
    final matchingItems = tripState.items
        .where((i) => i.slug == landmark.slug)
        .toList();
    if (matchingItems.isEmpty) return null;

    final activeTripId = tripState.activeTripId;
    if (activeTripId != null &&
        matchingItems.any((i) => i.tripId == activeTripId)) {
      return activeTripId;
    }
    return matchingItems.first.tripId;
  }

  String _regionLabel(String region, String locale) {
    switch (region) {
      case 'kanto':
        return tr(
          locale,
          ja: '東京・関東',
          ko: '도쿄·간토',
          en: 'Tokyo / Kanto',
          zh: '东京 / 关东',
          fr: 'Tokyo / Kanto',
        );
      case 'kansai':
        return tr(
          locale,
          ja: '大阪・関西',
          ko: '오사카·간사이',
          en: 'Osaka / Kansai',
          zh: '大阪 / 关西',
          fr: 'Osaka / Kansai',
        );
      case 'seoul':
        return tr(
          locale,
          ja: 'ソウル',
          ko: '서울',
          en: 'Seoul',
          zh: '首尔',
          fr: 'Séoul',
        );
      case 'busan':
        return tr(
          locale,
          ja: '釜山',
          ko: '부산',
          en: 'Busan',
          zh: '釜山',
          fr: 'Busan',
        );
      default:
        return region;
    }
  }
}
