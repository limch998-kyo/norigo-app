import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/landmark.dart';
import '../models/stay_area.dart';
import 'trip_provider.dart';
import 'app_providers.dart';

/// The inputs that should trigger a fresh stay recommendation for [tripId]:
/// the trip's sorted spot slugs plus the search parameters that actually change
/// the result (dates, budget, mode). Editing the trip name — or any *other*
/// trip — must NOT change this string.
///
/// Returned from `select` as a plain String so it compares by value: the old
/// selector returned a fresh `List` each call (identity-compared), which both
/// failed to memoise and ignored date/budget/mode edits.
String tripStaySignature(TripState state, String tripId) {
  final slugs = state.items
      .where((i) => i.tripId == tripId)
      .map((i) => i.slug)
      .toList()
    ..sort();
  final trip = state.trips.where((t) => t.id == tripId).firstOrNull;
  return [
    slugs.join(','),
    trip?.checkIn ?? '',
    trip?.checkOut ?? '',
    trip?.maxBudget ?? '',
    trip?.searchMode ?? '',
  ].join('|');
}

/// Auto-fetches stay recommendation for a trip when it has 2+ spots.
/// Recomputes when the spots OR the trip's dates/budget/mode change.
final tripStayProvider = FutureProvider.family<StayRecommendResult?, String>((ref, tripId) async {
  ref.watch(tripProvider.select((s) => tripStaySignature(s, tripId)));

  final state = ref.read(tripProvider);
  final items = state.items.where((i) => i.tripId == tripId).toList();
  if (items.length < 2) return null;

  final trip = state.trips.where((t) => t.id == tripId).firstOrNull;
  if (trip == null) return null;

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
  } catch (e) {
    debugPrint('tripStayProvider: stay recommendation fetch failed: $e');
    return null;
  }
});
