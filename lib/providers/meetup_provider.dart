import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../models/meetup_result.dart';
import 'app_providers.dart';

class MeetupSearchState {
  final List<Station> stations;
  final String region;
  final String mode;
  final String? category;
  final String? budget;
  final List<String> options;
  final MeetupResult? result;
  final bool isLoading;
  final String? error;

  const MeetupSearchState({
    this.stations = const [],
    this.region = 'kanto',
    this.mode = 'centroid',
    this.category,
    this.budget,
    this.options = const [],
    this.result,
    this.isLoading = false,
    this.error,
  });

  MeetupSearchState copyWith({
    List<Station>? stations,
    String? region,
    String? mode,
    String? category,
    String? budget,
    List<String>? options,
    MeetupResult? result,
    bool? isLoading,
    String? error,
    bool clearCategory = false,
    bool clearBudget = false,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return MeetupSearchState(
      stations: stations ?? this.stations,
      region: region ?? this.region,
      mode: mode ?? this.mode,
      category: clearCategory ? null : (category ?? this.category),
      budget: clearBudget ? null : (budget ?? this.budget),
      options: options ?? this.options,
      result: clearResult ? null : (result ?? this.result),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MeetupSearchNotifier extends StateNotifier<MeetupSearchState> {
  final Ref _ref;

  MeetupSearchNotifier(this._ref) : super(const MeetupSearchState());

  void addStation(Station station) {
    if (state.stations.any((s) => s.id == station.id)) return;
    if (state.stations.length >= 5) return;
    state = state.copyWith(stations: [...state.stations, station]);
    _autoDetectRegion();
  }

  void removeStation(String stationId) {
    state = state.copyWith(
      stations: state.stations.where((s) => s.id != stationId).toList(),
    );
  }

  void setRegion(String region) {
    state = state.copyWith(region: region);
  }

  void setMode(String mode) {
    state = state.copyWith(mode: mode);
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category, clearCategory: category == null);
  }

  void setBudget(String? budget) {
    state = state.copyWith(budget: budget, clearBudget: budget == null);
  }

  void toggleOption(String option) {
    final opts = List<String>.from(state.options);
    if (opts.contains(option)) {
      opts.remove(option);
    } else {
      opts.add(option);
    }
    state = state.copyWith(options: opts);
  }

  void _autoDetectRegion() {
    if (state.stations.isEmpty) return;
    final firstRegion = state.stations.first.region;
    state = state.copyWith(region: firstRegion);
  }

  Future<void> search() async {
    if (state.stations.length < 2) return;

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      final api = _ref.read(apiClientProvider);
      final result = await api.getMeetupRecommendation(
        stationIds: state.stations.map((s) => s.id).toList(),
        mode: state.mode,
        region: state.region,
        category: state.category,
        budget: state.budget,
        options: state.options.isNotEmpty ? state.options : null,
      );
      state = state.copyWith(result: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void reset() {
    state = const MeetupSearchState();
  }
}

final meetupSearchProvider =
    StateNotifierProvider<MeetupSearchNotifier, MeetupSearchState>((ref) {
  return MeetupSearchNotifier(ref);
});
