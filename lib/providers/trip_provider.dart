import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/landmark.dart';
import '../services/landmark_localizer.dart';
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

    // Always route by REGION — no active trip bias
    // Priority: explicit tripId → find trip for region → create new
    String? targetTripId = tripId;

    if (targetTripId == null) {
      // Find existing trip for this region
      for (final trip in state.trips) {
        final tripItems = state.items.where((i) => i.tripId == trip.id).toList();
        if (tripItems.any((i) => i.region == landmark.region)) {
          targetTripId = trip.id;
          break;
        }
      }
    }

    if (targetTripId == null) {
      // Find empty trip for same country
      final country = regionCountry(landmark.region);
      final emptyTrip = state.trips.where((t) => t.country == country &&
          state.items.where((i) => i.tripId == t.id).isEmpty).firstOrNull;
      if (emptyTrip != null) {
        targetTripId = emptyTrip.id;
      }
    }

    if (targetTripId == null) {
      // Create new trip for this region
      targetTripId = createTrip(tripName(landmark.region), country: regionCountry(landmark.region));
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

  /// Re-resolve all item names using bundled offline data (instant, no API)
  void refreshNames() {
    if (state.items.isEmpty || _ref == null) return;

    final locale = _ref!.read(localeProvider);
    bool changed = false;

    final newItems = state.items.map((item) {
      final newName = LandmarkLocalizer.getLocalizedName(
        locale: locale,
        slug: item.slug,
        lat: item.lat,
        lng: item.lng,
      );
      if (newName != null && newName != item.name) {
        changed = true;
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

    if (changed) {
      state = state.copyWith(items: newItems);
      _saveToStorage();
    }
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier(ref);
});
