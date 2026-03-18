import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/landmark.dart';
import '../services/landmark_localizer.dart';

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

  void update(String id, SavedSearch updated) {
    state = state.map((s) => s.id == id ? updated : s).toList();
    _save();
  }

  /// Find an existing saved search with the same landmarks and region
  SavedSearch? findExisting(List<Landmark> landmarks, String region) {
    final slugs = landmarks.map((l) => l.slug).toSet();
    return state.cast<SavedSearch?>().firstWhere(
      (s) => s!.region == region &&
        s.landmarks.map((l) => l.slug).toSet().difference(slugs).isEmpty &&
        slugs.difference(s.landmarks.map((l) => l.slug).toSet()).isEmpty,
      orElse: () => null,
    );
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
    // Match by slug/coordinates, not name (names change with locale)
    final slugs = landmarks.map((l) => l.slug).toSet();
    return state.any((s) => s.region == region &&
      s.landmarks.map((l) => l.slug).toSet().difference(slugs).isEmpty &&
      slugs.difference(s.landmarks.map((l) => l.slug).toSet()).isEmpty);
  }

  /// Re-translate landmark names and titles using bundled offline data
  void refreshNames(String locale) {
    bool changed = false;
    final newState = state.map((search) {
      bool searchChanged = false;
      final newLandmarks = search.landmarks.map((lm) {
        final newName = LandmarkLocalizer.getLocalizedName(
          locale: locale,
          slug: lm.slug,
          lat: lm.lat,
          lng: lm.lng,
        );
        if (newName != null && newName != lm.name) {
          searchChanged = true;
          return Landmark(slug: lm.slug, name: newName, nameEn: lm.nameEn, lat: lm.lat, lng: lm.lng, region: lm.region);
        }
        return lm;
      }).toList();

      if (searchChanged) {
        changed = true;
        // Rebuild title from new landmark names
        final newTitle = newLandmarks.map((l) => l.name).join(' · ');
        return SavedSearch(
          id: search.id,
          title: newTitle,
          landmarks: newLandmarks,
          region: search.region,
          mode: search.mode,
          maxBudget: search.maxBudget,
          checkIn: search.checkIn,
          checkOut: search.checkOut,
          savedAt: search.savedAt,
        );
      }
      return search;
    }).toList();

    if (changed) {
      state = newState;
      _save();
    }
  }
}

final savedSearchesProvider = StateNotifierProvider<SavedSearchesNotifier, List<SavedSearch>>((ref) {
  return SavedSearchesNotifier();
});
