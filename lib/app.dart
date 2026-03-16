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
import 'providers/stay_provider.dart';
import 'providers/meetup_provider.dart';

class NorigoApp extends ConsumerWidget {
  const NorigoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Norigo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _MainShell(),
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final stayState = ref.watch(staySearchProvider);
    final meetupState = ref.watch(meetupSearchProvider);

    // Determine which screen to show for search tabs
    Widget searchScreen;
    if (_currentIndex == 1) {
      searchScreen = stayState.result != null
          ? const StayResultScreen()
          : const StaySearchScreen();
    } else if (_currentIndex == 2) {
      searchScreen = meetupState.result != null
          ? const MeetupResultScreen()
          : const MeetupSearchScreen();
    } else {
      searchScreen = const SizedBox.shrink();
    }

    return DefaultTabController(
      length: 5,
      child: Builder(
        builder: (context) {
          // Listen for tab changes from Home screen buttons
          final tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              setState(() => _currentIndex = tabController.index);
            }
          });

          return Scaffold(
            body: SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  const HomeScreen(),
                  searchScreen,
                  _currentIndex == 2 ? searchScreen : const MeetupSearchScreen(),
                  const TripScreen(),
                  const SettingsScreen(),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() => _currentIndex = index);
                tabController.animateTo(index);
              },
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: locale == 'ja'
                      ? 'ホーム'
                      : locale == 'ko'
                          ? '홈'
                          : 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.hotel_outlined),
                  activeIcon: const Icon(Icons.hotel),
                  label: locale == 'ja'
                      ? 'ホテル'
                      : locale == 'ko'
                          ? '호텔'
                          : 'Hotel',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.groups_outlined),
                  activeIcon: const Icon(Icons.groups),
                  label: locale == 'ja'
                      ? '集合'
                      : locale == 'ko'
                          ? '만남'
                          : 'Meetup',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.luggage_outlined),
                  activeIcon: const Icon(Icons.luggage),
                  label: locale == 'ja'
                      ? '旅行'
                      : locale == 'ko'
                          ? '여행'
                          : 'Trip',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  label: locale == 'ja'
                      ? '設定'
                      : locale == 'ko'
                          ? '설정'
                          : 'Settings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
