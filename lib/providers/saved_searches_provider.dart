import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/landmark.dart';

class SavedSearch {
  final String id;
  final String title;
  final List<Landmark> landmarks;
  final String region;
  final String mode;
  final String? maxBudget;
  final String? checkIn;
  final String? checkOut;
  final DateTime savedAt;

  SavedSearch({
    required this.id,
    required this.title,
    required this.landmarks,
    required this.region,
    required this.mode,
    this.maxBudget,
    this.checkIn,
    this.checkOut,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'landmarks': landmarks.map((l) => l.toJson()).toList(),
    'region': region,
    'mode': mode,
    'maxBudget': maxBudget,
    'checkIn': checkIn,
    'checkOut': checkOut,
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedSearch.fromJson(Map<String, dynamic> json) => SavedSearch(
    id: json['id'] as String,
    title: json['title'] as String,
    landmarks: (json['landmarks'] as List).map((e) => Landmark.fromJson(e as Map<String, dynamic>)).toList(),
    region: json['region'] as String,
    mode: json['mode'] as String,
    maxBudget: json['maxBudget'] as String?,
    checkIn: json['checkIn'] as String?,
    checkOut: json['checkOut'] as String?,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}

class SavedSearchesNotifier extends StateNotifier<List<SavedSearch>> {
  static const _key = 'norigo_saved_searches';

  SavedSearchesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => SavedSearch.fromJson(e as Map<String, dynamic>)).toList();
      state = list;
    } catch (e) {
      debugPrint('Failed to load saved searches: $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((s) => s.toJson()).toList()));
  }

  void add(SavedSearch search) {
    state = [search, ...state];
    _save();
  }

  void rename(String id, String newTitle) {
    state = state.map((s) {
      if (s.id == id) {
        return SavedSearch(
          id: s.id, title: newTitle, landmarks: s.landmarks,
          region: s.region, mode: s.mode, maxBudget: s.maxBudget,
          checkIn: s.checkIn, checkOut: s.checkOut, savedAt: s.savedAt,
        );
      }
      return s;
    }).toList();
    _save();
  }

  void remove(String id) {
    state = state.where((s) => s.id != id).toList();
    _save();
  }

  /// Get searches filtered by country
  List<SavedSearch> byCountry(String country) {
    const koreaRegions = ['seoul', 'busan'];
    return state.where((s) {
      final isKorea = koreaRegions.contains(s.region);
      return country == 'korea' ? isKorea : !isKorea;
    }).toList();
  }

  bool hasSearch(List<Landmark> landmarks, String region) {
    final names = landmarks.map((l) => l.name).toSet();
    return state.any((s) => s.region == region && s.landmarks.map((l) => l.name).toSet().difference(names).isEmpty && names.difference(s.landmarks.map((l) => l.name).toSet()).isEmpty);
  }
}

final savedSearchesProvider = StateNotifierProvider<SavedSearchesNotifier, List<SavedSearch>>((ref) {
  return SavedSearchesNotifier();
});
