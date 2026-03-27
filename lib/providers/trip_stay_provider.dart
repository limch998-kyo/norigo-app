import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/landmark.dart';
import '../models/stay_area.dart';
import 'trip_provider.dart';
import 'app_providers.dart';

/// Auto-fetches stay recommendation for a trip when it has 2+ spots.
/// Uses keepAlive + select to avoid unnecessary re-fetches.
final tripStayProvider = FutureProvider.family<StayRecommendResult?, String>((ref, tripId) async {
  // Only watch THIS trip's item slugs — not the entire tripProvider state
  final itemSlugs = ref.watch(tripProvider.select((s) =>
    s.items.where((i) => i.tripId == tripId).map((i) => i.slug).toList()..sort()
  ));
  if (itemSlugs.length < 2) return null;

  final state = ref.read(tripProvider);
  final trip = state.trips.where((t) => t.id == tripId).firstOrNull;
  if (trip == null) return null;

  final items = state.items.where((i) => i.tripId == tripId).toList();
  if (items.isEmpty) return null;

  final landmarks = items.map((i) => Landmark(
    slug: i.slug, name: i.name, lat: i.lat, lng: i.lng, region: i.region,
  )).toList();

  final api = ref.read(apiClientProvider);
  final locale = ref.read(localeProvider);
  final region = items.first.region;

  try {
    return await api.getStayRecommendation(
      landmarks: landmarks,
      region: region,
      mode: trip.searchMode ?? 'centroid',
      maxBudget: trip.maxBudget,
      checkIn: trip.checkIn,
      checkOut: trip.checkOut,
      locale: locale,
    );
  } catch (_) {
    return null;
  }
});
