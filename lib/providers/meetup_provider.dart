import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../models/meetup_result.dart';
import 'app_providers.dart';

class MeetupSearchState {
  /// Nullable slots — null means empty input field
  final List<Station?> slots;
  final String region;
  final String mode;
  final String? category;
  final String? budget;
  final List<String> options;
  final MeetupResult? result;
  final bool isLoading;
  final String? error;

  const MeetupSearchState({
    this.slots = const [null, null],
    this.region = 'kanto',
    this.mode = 'centroid',
    this.category,
    this.budget,
    this.options = const [],
    this.result,
    this.isLoading = false,
    this.error,
  });

  /// Only filled (non-null) stations
  List<Station> get filledStations => slots.whereType<Station>().toList();

  MeetupSearchState copyWith({
    List<Station?>? slots,
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
      slots: slots ?? this.slots,
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

  void setStation(int index, Station station) {
    final newSlots = List<Station?>.from(state.slots);
    if (index < newSlots.length) {
      newSlots[index] = station;
    }
    state = state.copyWith(slots: newSlots);
    _autoDetectRegion();
  }

  void removeSlot(int index) {
    if (state.slots.length <= 2) return; // min 2
    final newSlots = List<Station?>.from(state.slots);
    newSlots.removeAt(index);
    state = state.copyWith(slots: newSlots);
  }

  void addSlot() {
    if (state.slots.length >= 10) return; // max 10
    state = state.copyWith(slots: [...state.slots, null]);
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
    final filled = state.filledStations;
    if (filled.isEmpty) return;
    state = state.copyWith(region: filled.first.region);
  }

  Future<void> search() async {
    final filled = state.filledStations;
    if (filled.length < 2) return;

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);

    try {
      final api = _ref.read(apiClientProvider);
      final result = await api.getMeetupRecommendation(
        stationIds: filled.map((s) => s.id).toList(),
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

  void clearResult() {
    state = state.copyWith(clearResult: true, clearError: true);
  }

  void reset() {
    state = const MeetupSearchState();
  }
}

final meetupSearchProvider =
    StateNotifierProvider<MeetupSearchNotifier, MeetupSearchState>((ref) {
  return MeetupSearchNotifier(ref);
});
