import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/landmark.dart';
import '../models/stay_area.dart';
import '../services/landmark_localizer.dart';
import 'app_providers.dart';

class StaySearchState {
  /// Nullable slots — null means empty input field
  final List<Landmark?> slots;
  final String region;
  final String mode;
  final String? maxBudget;
  final String? checkIn;
  final String? checkOut;
  final StayRecommendResult? result;
  final bool isLoading;
  final String? error;
  final bool showSplit;
  final String stayStyle;
  /// Track which saved search this was loaded from (for update instead of create)
  final String? savedSearchId;

  const StaySearchState({
    this.slots = const [null, null],
    this.region = 'kanto',
    this.mode = 'centroid',
    this.maxBudget,
    this.checkIn,
    this.checkOut,
    this.result,
    this.isLoading = false,
    this.error,
    this.showSplit = false,
    this.stayStyle = 'auto',
    this.savedSearchId,
  });

  /// Only filled (non-null) landmarks
  List<Landmark> get landmarks => slots.whereType<Landmark>().toList();

  StaySearchState copyWith({
    List<Landmark?>? slots,
    String? region,
    String? mode,
    String? maxBudget,
    String? checkIn,
    String? checkOut,
    StayRecommendResult? result,
    bool? isLoading,
    String? error,
    bool? showSplit,
    String? stayStyle,
    String? savedSearchId,
    bool clearBudget = false,
    bool clearError = false,
    bool clearResult = false,
    bool clearSavedSearchId = false,
  }) {
    return StaySearchState(
      slots: slots ?? this.slots,
      region: region ?? this.region,
      mode: mode ?? this.mode,
      maxBudget: clearBudget ? null : (maxBudget ?? this.maxBudget),
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      result: clearResult ? null : (result ?? this.result),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      showSplit: showSplit ?? this.showSplit,
      stayStyle: stayStyle ?? this.stayStyle,
      savedSearchId: clearSavedSearchId ? null : (savedSearchId ?? this.savedSearchId),
    );
  }
}

class StaySearchNotifier extends StateNotifier<StaySearchState> {
  final Ref _ref;

  /// Per-region saved slots: when user switches region, we save current slots
  /// and restore previously saved slots for the new region.
  final Map<String, List<Landmark?>> _regionSlots = {};

  StaySearchNotifier(this._ref) : super(const StaySearchState());

  void setLandmark(int index, Landmark landmark) {
    // Prevent duplicates (allow replacing same slot)
    final existingIndex = state.slots.indexWhere((l) => l != null && (l.name == landmark.name || l.slug == landmark.slug));
    if (existingIndex >= 0 && existingIndex != index) return;

    final newSlots = List<Landmark?>.from(state.slots);
    if (index < newSlots.length) {
      newSlots[index] = landmark;
    } else {
      newSlots.add(landmark);
    }
    state = state.copyWith(slots: newSlots);
    // Save to region cache
    _regionSlots[state.region] = List.from(newSlots);
  }

  void addLandmark(Landmark landmark) {
    // Prevent duplicates: same slug OR very close coordinates (~100m)
    final filled = state.landmarks;
    if (filled.any((l) => l.slug == landmark.slug ||
        ((l.lat - landmark.lat).abs() < 0.001 && (l.lng - landmark.lng).abs() < 0.001 && l.lat != 0))) return;

    // Find first empty slot, or add new slot
    final newSlots = List<Landmark?>.from(state.slots);
    final emptyIndex = newSlots.indexWhere((s) => s == null);
    if (emptyIndex >= 0) {
      newSlots[emptyIndex] = landmark;
    } else if (newSlots.length < 10) {
      newSlots.add(landmark);
    }
    state = state.copyWith(slots: newSlots);
    // Save to region cache
    _regionSlots[state.region] = List.from(newSlots);
  }

  void removeSlot(int index) {
    if (state.slots.length <= 2) {
      // Don't remove, just clear
      final newSlots = List<Landmark?>.from(state.slots);
      newSlots[index] = null;
      state = state.copyWith(slots: newSlots);
      _regionSlots[state.region] = List.from(newSlots);
      return;
    }
    final newSlots = List<Landmark?>.from(state.slots);
    newSlots.removeAt(index);
    state = state.copyWith(slots: newSlots);
    _regionSlots[state.region] = List.from(newSlots);
  }

  void removeLandmark(String slug) {
    final newSlots = List<Landmark?>.from(state.slots);
    final idx = newSlots.indexWhere((l) => l?.slug == slug);
    if (idx >= 0) {
      if (newSlots.length <= 2) {
        newSlots[idx] = null;
      } else {
        newSlots.removeAt(idx);
      }
    }
    state = state.copyWith(slots: newSlots);
    _regionSlots[state.region] = List.from(newSlots);
  }

  void addSlot() {
    if (state.slots.length >= 10) return;
    final newSlots = [...state.slots, null];
    state = state.copyWith(slots: newSlots);
    _regionSlots[state.region] = List.from(newSlots);
  }

  /// Switch region: save current slots, restore saved slots for new region
  void setRegion(String region) {
    if (region == state.region) return;

    // Save current region's slots
    _regionSlots[state.region] = List.from(state.slots);

    // Restore new region's slots (or default empty)
    final savedSlots = _regionSlots[region] ?? const [null, null];

    state = state.copyWith(
      region: region,
      slots: savedSlots,
      clearResult: true,
      clearError: true,
    );
  }

  void setMode(String mode) {
    state = state.copyWith(mode: mode);
  }

  void setBudget(String? budget) {
    state = state.copyWith(maxBudget: budget, clearBudget: budget == null);
  }

  void setDates(String? checkIn, String? checkOut) {
    state = state.copyWith(checkIn: checkIn, checkOut: checkOut);
  }

  void toggleSplit() {
    state = state.copyWith(showSplit: !state.showSplit);
  }

  void setSavedSearchId(String? id) {
    state = state.copyWith(savedSearchId: id, clearSavedSearchId: id == null);
  }

  void setStayStyle(String style) {
    state = state.copyWith(stayStyle: style);
  }

  Future<void> search() async {
    final filled = state.landmarks;
    if (filled.length < 2) return; // API requires minimum 2 landmarks

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      final api = _ref.read(apiClientProvider);
      final locale = _ref.read(localeProvider);
      debugPrint('Stay search: ${filled.length} landmarks, region=${state.region}, mode=${state.mode}, stayStyle=${state.stayStyle}');
      for (final l in filled) {
        debugPrint('  Landmark: ${l.name} (${l.lat}, ${l.lng}) region=${l.region}');
      }
      final result = await api.getStayRecommendation(
        landmarks: filled,
        region: state.region,
        mode: state.mode,
        stayStyle: state.stayStyle,
        maxBudget: state.maxBudget != 'any' ? state.maxBudget : null,
        checkIn: state.checkIn,
        checkOut: state.checkOut,
        locale: locale,
      );
      debugPrint('Stay result: areas=${result.areas.length}, split=${result.split}, clusters=${result.clusters.length}');
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Re-resolve landmark names using bundled offline data (instant, no API calls)
  void refreshLandmarkNames() {
    final locale = _ref.read(localeProvider);

    Landmark? _localize(Landmark lm) {
      final newName = LandmarkLocalizer.getLocalizedName(
        locale: locale,
        slug: lm.slug,
        lat: lm.lat,
        lng: lm.lng,
      );
      if (newName != null && newName != lm.name) {
        return Landmark(slug: lm.slug, name: newName, nameEn: lm.nameEn, lat: lm.lat, lng: lm.lng, region: lm.region);
      }
      return null;
    }

    // Update current state slots
    bool changed = false;
    final newSlots = state.slots.map((slot) {
      if (slot == null) return slot;
      final updated = _localize(slot);
      if (updated != null) { changed = true; return updated; }
      return slot;
    }).toList();

    if (changed) {
      state = state.copyWith(slots: newSlots);
      _regionSlots[state.region] = List.from(newSlots);
    }

    // Update cached regions
    for (final region in _regionSlots.keys.toList()) {
      if (region == state.region) continue;
      bool regionChanged = false;
      final cachedSlots = _regionSlots[region]!.map((slot) {
        if (slot == null) return slot;
        final updated = _localize(slot);
        if (updated != null) { regionChanged = true; return updated; }
        return slot;
      }).toList();
      if (regionChanged) _regionSlots[region] = cachedSlots;
    }
  }

  /// Clear result only (go back to search with inputs preserved)
  void clearResult() {
    state = state.copyWith(clearResult: true, clearError: true);
  }

  /// Full reset (clear everything)
  void reset() {
    _regionSlots.clear();
    state = const StaySearchState();
  }
}

final staySearchProvider =
    StateNotifierProvider<StaySearchNotifier, StaySearchState>((ref) {
  return StaySearchNotifier(ref);
});
