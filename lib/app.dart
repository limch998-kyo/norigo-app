import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'config/theme.dart';
import 'screens/home/home_screen.dart';

class NorigoApp extends StatefulWidget {
  const NorigoApp({super.key});

  @override
  State<NorigoApp> createState() => _NorigoAppState();
}

class _NorigoAppState extends State<NorigoApp> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Norigo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              const HomeScreen(),
              const Center(child: Text('Search')), // TODO: StaySearchScreen
              const Center(child: Text('Trip')),   // TODO: TripScreen
              const Center(child: Text('Guide')),  // TODO: GuideScreen
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.luggage_outlined), activeIcon: Icon(Icons.luggage), label: 'Trip'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Guide'),
          ],
        ),
      ),
    );
  }
}
