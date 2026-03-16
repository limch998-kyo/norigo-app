import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/landmark.dart';

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

  TripNotifier() : super(const TripState()) {
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

    String _tripName(String country) {
      if (locale == 'ja') return country == 'korea' ? '韓国旅行' : '日本旅行';
      if (locale == 'ko') return country == 'korea' ? '한국 여행' : '일본 여행';
      return country == 'korea' ? 'Korea Trip' : 'Japan Trip';
    }

    // Auto-create or find matching trip
    if (targetTripId == null) {
      final country = ['seoul', 'busan'].contains(landmark.region) ? 'korea' : 'japan';
      final existingTrip = state.trips.where((t) => t.country == country).firstOrNull;
      if (existingTrip != null) {
        targetTripId = existingTrip.id;
        state = state.copyWith(activeTripId: targetTripId);
      } else {
        targetTripId = createTrip(_tripName(country), country: country);
      }
    } else {
      final activeTrip = state.trips.where((t) => t.id == targetTripId).firstOrNull;
      final landmarkCountry = ['seoul', 'busan'].contains(landmark.region) ? 'korea' : 'japan';
      if (activeTrip != null && activeTrip.country != landmarkCountry) {
        final existingTrip = state.trips.where((t) => t.country == landmarkCountry).firstOrNull;
        if (existingTrip != null) {
          targetTripId = existingTrip.id;
        } else {
          targetTripId = createTrip(_tripName(landmarkCountry), country: landmarkCountry);
        }
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
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier();
});
