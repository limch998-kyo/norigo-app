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

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;
  // Track which tabs have been visited (for lazy init)
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    MainShell.globalSwitchTab = switchToTab;
    // Track initial page view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingServiceProvider).trackEvent('page_view', payload: {
        'page': '/home',
      }, path: '/home');
    });
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
    // Track page view
    ref.read(trackingServiceProvider).trackEvent('page_view', payload: {
      'page': _tabPages[index],
    }, path: _tabPages[index]);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final stayState = ref.watch(staySearchProvider);
    final meetupState = ref.watch(meetupSearchProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPhone = screenWidth < 600;
    final isDesktop = screenWidth >= 900;

    final navItems = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: tr(locale, ja: 'ホーム', ko: '홈', en: 'Home', zh: '首页', fr: 'Accueil')),
      (icon: Icons.hotel_outlined, activeIcon: Icons.hotel, label: tr(locale, ja: 'ホテル', ko: '호텔', en: 'Hotel', zh: '酒店', fr: 'Hôtel')),
      (icon: Icons.groups_outlined, activeIcon: Icons.groups, label: tr(locale, ja: '集合', ko: '만남', en: 'Meetup', zh: '聚会', fr: 'Rencontre')),
      (icon: Icons.luggage_outlined, activeIcon: Icons.luggage, label: tr(locale, ja: '旅行', ko: '여행', en: 'Trip', zh: '旅行', fr: 'Voyage')),
      (icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: tr(locale, ja: 'ガイド', ko: '가이드', en: 'Guide', zh: '指南', fr: 'Guide')),
    ];

    final pages = IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(onSwitchTab: switchToTab),
        if (_visitedTabs.contains(1))
          (stayState.result != null || stayState.isLoading) ? const StayResultScreen() : const StaySearchScreen()
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(2))
          (meetupState.result != null || meetupState.isLoading) ? const MeetupResultScreen() : const MeetupSearchScreen()
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(3))
          TripScreen(onSwitchTab: switchToTab)
        else
          const SizedBox.shrink(),
        if (_visitedTabs.contains(4))
          const GuideScreen()
        else
          const SizedBox.shrink(),
      ],
    );

    // Phone: full width + bottom nav
    // Tablet: NavigationRail + constrained content
    // Desktop: wide sidebar + full width content
    final Widget body;
    if (isPhone) {
      body = SafeArea(child: pages);
    } else if (isDesktop) {
      // Desktop: wide sidebar with labels + full content
      body = SafeArea(child: Row(children: [
        Container(
          width: 200,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Icon(Icons.flight_takeoff, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Nori GO!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ]),
            ),
            const SizedBox(height: 8),
            ...navItems.asMap().entries.map((e) {
              final i = e.key;
              final n = e.value;
              final isSelected = _currentIndex == i;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => switchToTab(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : null,
                    child: Row(children: [
                      Icon(isSelected ? n.activeIcon : n.icon, size: 20,
                        color: isSelected ? AppTheme.primary : AppTheme.mutedForeground),
                      const SizedBox(width: 12),
                      Text(n.label, style: TextStyle(
                        fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? AppTheme.primary : AppTheme.foreground)),
                    ]),
                  ),
                ),
              );
            }),
          ]),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: pages,
        ))),
      ]));
    } else {
      // Tablet: NavigationRail + constrained content
      body = SafeArea(child: Row(children: [
        NavigationRail(
          selectedIndex: _currentIndex,
          onDestinationSelected: switchToTab,
          labelType: NavigationRailLabelType.all,
          destinations: navItems.map((n) => NavigationRailDestination(
            icon: Icon(n.icon), selectedIcon: Icon(n.activeIcon), label: Text(n.label, style: const TextStyle(fontSize: 10)),
          )).toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: pages,
        ))),
      ]));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) switchToTab(0);
      },
      child: Scaffold(
        body: body,
        bottomNavigationBar: isPhone ? BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: switchToTab,
          type: BottomNavigationBarType.fixed,
          items: navItems.map((n) => BottomNavigationBarItem(
            icon: Icon(n.icon), activeIcon: Icon(n.activeIcon), label: n.label,
          )).toList(),
        ) : null,
      ),
    );
  }
}
