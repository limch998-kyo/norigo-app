import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/landmark.dart';
import '../models/stay_area.dart';
import 'app_providers.dart';

class StaySearchState {
  final List<Landmark> landmarks;
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
    this.landmarks = const [],
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

  StaySearchState copyWith({
    List<Landmark>? landmarks,
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
      landmarks: landmarks ?? this.landmarks,
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

  void addLandmark(Landmark landmark) {
    if (state.landmarks.any((l) => l.slug == landmark.slug)) return;
    state = state.copyWith(landmarks: [...state.landmarks, landmark]);
    _autoDetectRegion();
  }

  void removeLandmark(String slug) {
    state = state.copyWith(
      landmarks: state.landmarks.where((l) => l.slug != slug).toList(),
    );
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

  void setLandmarks(List<Landmark> landmarks) {
    state = state.copyWith(landmarks: landmarks);
    _autoDetectRegion();
  }

  void _autoDetectRegion() {
    if (state.landmarks.isEmpty) return;
    final firstRegion = state.landmarks.first.region;
    state = state.copyWith(region: firstRegion);
  }

  Future<void> search() async {
    if (state.landmarks.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      final api = _ref.read(apiClientProvider);
      final result = await api.getStayRecommendation(
        landmarks: state.landmarks,
        region: state.region,
        mode: state.mode,
        maxBudget: state.maxBudget,
        checkIn: state.checkIn,
        checkOut: state.checkOut,
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
