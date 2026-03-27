import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'config/theme.dart';
import 'providers/app_providers.dart';
import 'utils/tr.dart';
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

const _tabPages = ['/home', '/stay', '/meetup', '/trip', '/guide'];

class NorigoApp extends ConsumerWidget {
  const NorigoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Update AppTheme.isDark for static color references
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    AppTheme.isDark = switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };

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

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MainShell.globalSwitchTab = switchToTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingServiceProvider).trackEvent('page_view', payload: {
        'page': '/home',
      }, path: '/home');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MainShell.globalSwitchTab = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Update theme mode on resume (system dark mode may have changed)
      final themeMode = ref.read(themeModeProvider);
      if (themeMode == ThemeMode.system) {
        // Force rebuild to pick up system brightness change
        (context as Element).markNeedsBuild();
      }
    }
  }

  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
    // Track page view
    ref.read(trackingServiceProvider).trackEvent('page_view', payload: {
      'page': _tabPages[index],
    }, path: _tabPages[index]);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    // Only watch result/loading state — not the entire provider (avoids unnecessary rebuilds)
    final stayHasResult = ref.watch(staySearchProvider.select((s) => s.result != null || s.isLoading));
    final meetupHasResult = ref.watch(meetupSearchProvider.select((s) => s.result != null || s.isLoading));

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
              stayHasResult ? const StayResultScreen() : const StaySearchScreen()
            else
              const SizedBox.shrink(),
            // 2: Meetup (lazy) — keep result screen during re-search
            if (_visitedTabs.contains(2))
              meetupHasResult ? const MeetupResultScreen() : const MeetupSearchScreen()
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
            label: tr(locale, ja: 'ホーム', ko: '홈', en: 'Home', zh: '首页', fr: 'Accueil')),
          BottomNavigationBarItem(icon: const Icon(Icons.hotel_outlined), activeIcon: const Icon(Icons.hotel),
            label: tr(locale, ja: 'ホテル', ko: '호텔', en: 'Hotel', zh: '酒店', fr: 'Hôtel')),
          BottomNavigationBarItem(icon: const Icon(Icons.groups_outlined), activeIcon: const Icon(Icons.groups),
            label: tr(locale, ja: '集合', ko: '만남', en: 'Meetup', zh: '聚会', fr: 'Rencontre')),
          BottomNavigationBarItem(icon: const Icon(Icons.luggage_outlined), activeIcon: const Icon(Icons.luggage),
            label: tr(locale, ja: '旅行', ko: '여행', en: 'Trip', zh: '旅行', fr: 'Voyage')),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), activeIcon: const Icon(Icons.menu_book),
            label: tr(locale, ja: 'ガイド', ko: '가이드', en: 'Guide', zh: '指南', fr: 'Guide')),
        ],
      ),
    ),
    );
  }
}
