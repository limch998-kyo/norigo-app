import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'config/theme.dart';
import 'providers/app_providers.dart';
import 'screens/home/home_screen.dart';
import 'screens/stay/stay_search_screen.dart';
import 'screens/stay/stay_result_screen.dart';
import 'screens/meetup/meetup_search_screen.dart';
import 'screens/meetup/meetup_result_screen.dart';
import 'screens/trip/trip_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/guide/guide_screen.dart';
import 'providers/stay_provider.dart';
import 'providers/meetup_provider.dart';

class NorigoApp extends ConsumerWidget {
  const NorigoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Norigo',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  /// Global callback for tab switching from anywhere (e.g. snackbar actions).
  static void Function(int)? globalSwitchTab;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  // Track which tabs have been visited (for lazy init)
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    MainShell.globalSwitchTab = switchToTab;
  }

  @override
  void dispose() {
    MainShell.globalSwitchTab = null;
    super.dispose();
  }

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final stayState = ref.watch(staySearchProvider);
    final meetupState = ref.watch(meetupSearchProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // If not on home tab, go to home
        if (_currentIndex != 0) {
          switchToTab(0);
        }
        // On home tab, do nothing (don't exit app)
      },
      child: Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // 0: Home (always built)
            HomeScreen(onSwitchTab: switchToTab),
            // 1: Stay (lazy) — keep result screen during re-search (isLoading)
            if (_visitedTabs.contains(1))
              (stayState.result != null || stayState.isLoading) ? const StayResultScreen() : const StaySearchScreen()
            else
              const SizedBox.shrink(),
            // 2: Meetup (lazy) — keep result screen during re-search
            if (_visitedTabs.contains(2))
              (meetupState.result != null || meetupState.isLoading) ? const MeetupResultScreen() : const MeetupSearchScreen()
            else
              const SizedBox.shrink(),
            // 3: Trip (lazy)
            if (_visitedTabs.contains(3))
              TripScreen(onSwitchTab: switchToTab)
            else
              const SizedBox.shrink(),
            // 4: Guide (lazy)
            if (_visitedTabs.contains(4))
              const GuideScreen()
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: switchToTab,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home),
            label: locale == 'ja' ? 'ホーム' : locale == 'ko' ? '홈' : 'Home'),
          BottomNavigationBarItem(icon: const Icon(Icons.hotel_outlined), activeIcon: const Icon(Icons.hotel),
            label: locale == 'ja' ? 'ホテル' : locale == 'ko' ? '호텔' : 'Hotel'),
          BottomNavigationBarItem(icon: const Icon(Icons.groups_outlined), activeIcon: const Icon(Icons.groups),
            label: locale == 'ja' ? '集合' : locale == 'ko' ? '만남' : 'Meetup'),
          BottomNavigationBarItem(icon: const Icon(Icons.luggage_outlined), activeIcon: const Icon(Icons.luggage),
            label: locale == 'ja' ? '旅行' : locale == 'ko' ? '여행' : 'Trip'),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), activeIcon: const Icon(Icons.menu_book),
            label: locale == 'ja' ? 'ガイド' : locale == 'ko' ? '가이드' : 'Guide'),
        ],
      ),
    ),
    );
  }
}
