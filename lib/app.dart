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
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final stayState = ref.watch(staySearchProvider);
    final meetupState = ref.watch(meetupSearchProvider);

    // Lazy build — only build the active tab (not all 5 at once)
    Widget buildTab() {
      switch (_currentIndex) {
        case 0:
          return HomeScreen(onSwitchTab: switchToTab);
        case 1:
          return stayState.result != null
              ? const StayResultScreen()
              : const StaySearchScreen();
        case 2:
          return meetupState.result != null
              ? const MeetupResultScreen()
              : const MeetupSearchScreen();
        case 3:
          return const TripScreen();
        case 4:
          return const SettingsScreen();
        default:
          return HomeScreen(onSwitchTab: switchToTab);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: buildTab(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
  }
}
