import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/landmark.dart';
import 'app_providers.dart';

class TripState {
  final List<Trip> trips;
  final List<TripItem> items;
  final String? activeTripId;
  final String country;

  const TripState({
    this.trips = const [],
    this.items = const [],
    this.activeTripId,
    this.country = 'japan',
  });

  Trip? get activeTrip {
    if (activeTripId == null) return null;
    try {
      return trips.firstWhere((t) => t.id == activeTripId);
    } catch (_) {
      return null;
    }
  }

  List<TripItem> get activeItems {
    if (activeTripId == null) return [];
    return items.where((i) => i.tripId == activeTripId).toList();
  }

  List<Trip> get filteredTrips {
    return trips.where((t) {
      if (country == 'japan') {
        return t.country == 'japan' || t.country == null;
      }
      return t.country == 'korea';
    }).toList();
  }

  TripState copyWith({
    List<Trip>? trips,
    List<TripItem>? items,
    String? activeTripId,
    String? country,
    bool clearActiveTrip = false,
  }) {
    return TripState(
      trips: trips ?? this.trips,
      items: items ?? this.items,
      activeTripId: clearActiveTrip ? null : (activeTripId ?? this.activeTripId),
      country: country ?? this.country,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  static const _storageKey = 'norigo_trips_v2';
  static const _uuid = Uuid();
  final Ref? _ref;

  TripNotifier([this._ref]) : super(const TripState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final trips = (data['trips'] as List<dynamic>?)
              ?.map((e) => Trip.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final items = (data['items'] as List<dynamic>?)
              ?.map((e) => TripItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final activeTripId = data['activeTripId'] as String?;

      state = state.copyWith(
        trips: trips,
        items: items,
        activeTripId: activeTripId,
      );
    } catch (_) {
      // Corrupted data, start fresh
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'version': 2,
      'trips': state.trips.map((t) => t.toJson()).toList(),
      'items': state.items.map((i) => i.toJson()).toList(),
      'activeTripId': state.activeTripId,
    };
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  String createTrip(String name, {String? country}) {
    final trip = Trip(
      id: _uuid.v4(),
      name: name,
      country: country ?? state.country,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(
      trips: [...state.trips, trip],
      activeTripId: trip.id,
    );
    _saveToStorage();
    return trip.id;
  }

  void setActiveTrip(String tripId) {
    state = state.copyWith(activeTripId: tripId);
    _saveToStorage();
  }

  void renameTrip(String tripId, String newName) {
    state = state.copyWith(
      trips: state.trips.map((t) {
        if (t.id == tripId) return t.copyWith(name: newName);
        return t;
      }).toList(),
    );
    _saveToStorage();
  }

  void deleteTrip(String tripId) {
    state = state.copyWith(
      trips: state.trips.where((t) => t.id != tripId).toList(),
      items: state.items.where((i) => i.tripId != tripId).toList(),
      clearActiveTrip: state.activeTripId == tripId,
    );
    _saveToStorage();
  }

  void addItem(Landmark landmark, {String? tripId, String locale = 'en'}) {
    var targetTripId = tripId ?? state.activeTripId;

    final regionNames = {
      'kanto': {'ja': '東京・関東', 'ko': '도쿄·간토', 'en': 'Tokyo / Kanto'},
      'kansai': {'ja': '大阪・関西', 'ko': '오사카·간사이', 'en': 'Osaka / Kansai'},
      'seoul': {'ja': 'ソウル', 'ko': '서울', 'en': 'Seoul'},
      'busan': {'ja': '釜山', 'ko': '부산', 'en': 'Busan'},
    };

    String tripName(String region) {
      return regionNames[region]?[locale] ?? regionNames[region]?['en'] ?? region;
    }

    String regionCountry(String region) {
      return ['seoul', 'busan'].contains(region) ? 'korea' : 'japan';
    }

    // Find or create trip for this REGION (not just country)
    // Check if we already have a trip that contains items for this region
    Trip? findTripForRegion(String region) {
      // First: find trip with items in same region
      for (final trip in state.trips) {
        final tripItems = state.items.where((i) => i.tripId == trip.id).toList();
        if (tripItems.any((i) => i.region == region)) return trip;
      }
      // Second: find trip for same country with no items yet
      final country = regionCountry(region);
      return state.trips.where((t) => t.country == country &&
          state.items.where((i) => i.tripId == t.id).isEmpty).firstOrNull;
    }

    if (targetTripId != null) {
      // Check if active trip's region matches
      final activeItems = state.items.where((i) => i.tripId == targetTripId).toList();
      final activeRegions = activeItems.map((i) => i.region).toSet();
      if (activeRegions.isNotEmpty && !activeRegions.contains(landmark.region)) {
        // Different region — find or create correct trip
        final existing = findTripForRegion(landmark.region);
        if (existing != null) {
          targetTripId = existing.id;
        } else {
          targetTripId = createTrip(tripName(landmark.region), country: regionCountry(landmark.region));
        }
      }
    } else {
      // No active trip — find or create
      final existing = findTripForRegion(landmark.region);
      if (existing != null) {
        targetTripId = existing.id;
        state = state.copyWith(activeTripId: targetTripId);
      } else {
        targetTripId = createTrip(tripName(landmark.region), country: regionCountry(landmark.region));
      }
    }

    // Don't add duplicates
    if (state.items.any(
        (i) => i.slug == landmark.slug && i.tripId == targetTripId)) {
      return;
    }

    final item = TripItem(
      slug: landmark.slug,
      name: landmark.name,
      lat: landmark.lat,
      lng: landmark.lng,
      region: landmark.region,
      tripId: targetTripId,
      addedAt: DateTime.now(),
    );
    state = state.copyWith(items: [...state.items, item]);
    _saveToStorage();
  }

  void removeItem(String slug, String tripId) {
    state = state.copyWith(
      items: state.items
          .where((i) => !(i.slug == slug && i.tripId == tripId))
          .toList(),
    );
    _saveToStorage();
  }

  void setCountry(String country) {
    state = state.copyWith(country: country, clearActiveTrip: true);
    // Auto-select first trip for this country
    final filtered = state.filteredTrips;
    if (filtered.isNotEmpty) {
      state = state.copyWith(activeTripId: filtered.first.id);
    }
  }

  List<Landmark> getItemsAsLandmarks(String tripId) {
    return state.items
        .where((i) => i.tripId == tripId)
        .map((i) => Landmark(
              slug: i.slug,
              name: i.name,
              lat: i.lat,
              lng: i.lng,
              region: i.region,
            ))
        .toList();
  }

  /// Re-resolve all item names + trip names in the current locale
  Future<void> refreshNames() async {
    if (state.items.isEmpty || _ref == null) return;

    final api = _ref!.read(apiClientProvider);
    final locale = _ref!.read(localeProvider);

    // Re-search each unique item by name/slug to get locale-specific name
    final nameMap = <String, String>{}; // slug → new name
    final processed = <String>{};

    for (final item in state.items) {
      if (processed.contains(item.slug)) continue;
      processed.add(item.slug);
      try {
        final results = await api.searchLandmarks(
          item.name,
          region: item.region,
          locale: locale,
        );
        if (results.isNotEmpty) {
          // Match by coordinates
          Landmark? best;
          double bestDist = double.infinity;
          for (final r in results) {
            final d = (r.lat - item.lat).abs() + (r.lng - item.lng).abs();
            if (d < bestDist) { bestDist = d; best = r; }
          }
          if (best != null && bestDist < 0.01) {
            nameMap[item.slug] = best.name;
          }
        }
      } catch (_) {}
    }

    if (nameMap.isEmpty) return;

    // Update item names
    final newItems = state.items.map((item) {
      final newName = nameMap[item.slug];
      if (newName != null && newName != item.name) {
        return TripItem(
          slug: item.slug,
          name: newName,
          lat: item.lat,
          lng: item.lng,
          region: item.region,
          tripId: item.tripId,
          addedAt: item.addedAt,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: newItems);
    _saveToStorage();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier(ref);
});
