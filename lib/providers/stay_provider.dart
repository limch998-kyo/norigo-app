import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/landmark.dart';
import '../models/stay_area.dart';
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
    bool clearBudget = false,
    bool clearError = false,
    bool clearResult = false,
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
    );
  }
}

class StaySearchNotifier extends StateNotifier<StaySearchState> {
  final Ref _ref;

  StaySearchNotifier(this._ref) : super(const StaySearchState());

  void setLandmark(int index, Landmark landmark) {
    final newSlots = List<Landmark?>.from(state.slots);
    if (index < newSlots.length) {
      newSlots[index] = landmark;
    } else {
      newSlots.add(landmark);
    }
    state = state.copyWith(slots: newSlots);
    _autoDetectRegion();
  }

  void addLandmark(Landmark landmark) {
    // Find first empty slot
    final newSlots = List<Landmark?>.from(state.slots);
    final emptyIndex = newSlots.indexWhere((s) => s == null);
    if (emptyIndex >= 0) {
      newSlots[emptyIndex] = landmark;
    } else if (newSlots.length < 10) {
      newSlots.add(landmark);
    }
    state = state.copyWith(slots: newSlots);
    _autoDetectRegion();
  }

  void removeSlot(int index) {
    if (state.slots.length <= 2) {
      // Don't remove, just clear
      final newSlots = List<Landmark?>.from(state.slots);
      newSlots[index] = null;
      state = state.copyWith(slots: newSlots);
      return;
    }
    final newSlots = List<Landmark?>.from(state.slots);
    newSlots.removeAt(index);
    state = state.copyWith(slots: newSlots);
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
  }

  void addSlot() {
    if (state.slots.length >= 10) return;
    state = state.copyWith(slots: [...state.slots, null]);
  }

  void setRegion(String region) {
    state = state.copyWith(region: region);
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

  void _autoDetectRegion() {
    final filled = state.landmarks;
    if (filled.isEmpty) return;
    state = state.copyWith(region: filled.first.region);
  }

  Future<void> search() async {
    final filled = state.landmarks;
    if (filled.length < 2) return; // API requires minimum 2 landmarks

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      final api = _ref.read(apiClientProvider);
      final locale = _ref.read(localeProvider);
      debugPrint('Stay search: ${filled.length} landmarks, region=${state.region}, mode=${state.mode}');
      for (final l in filled) {
        debugPrint('  Landmark: ${l.name} (${l.lat}, ${l.lng}) region=${l.region}');
      }
      final result = await api.getStayRecommendation(
        landmarks: filled,
        region: state.region,
        mode: state.mode,
        stayStyle: 'auto',
        maxBudget: state.maxBudget,
        checkIn: state.checkIn,
        checkOut: state.checkOut,
        locale: locale,
      );
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void reset() {
    state = const StaySearchState();
  }
}

final staySearchProvider =
    StateNotifierProvider<StaySearchNotifier, StaySearchState>((ref) {
  return StaySearchNotifier(ref);
});
