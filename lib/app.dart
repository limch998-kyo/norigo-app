import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'screens/guide/native_guide_detail_screen.dart';
import 'screens/spot/spot_detail_screen.dart';
import 'screens/vote/vote_screen.dart';
import 'providers/stay_provider.dart';
import 'providers/meetup_provider.dart';
import 'models/landmark.dart';
import 'models/station.dart';
import 'services/deep_link_parser.dart';
import 'services/deep_link_service.dart';
import 'services/landmark_localizer.dart';
import 'services/station_localizer.dart';

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
      // zh-TW maps to zh-Hant so Flutter's Material/Cupertino localizations
      // (date/time pickers, etc.) render in Traditional Chinese. Our own UI
      // strings come from tr(locale) using the raw 'zh-TW' value.
      locale: locale == 'zh-TW'
          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
          : Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: [
        ...AppLocalizations.supportedLocales,
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ],
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
  final DeepLinkService _deepLinks = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MainShell.globalSwitchTab = switchToTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingServiceProvider).trackEvent('page_view', payload: {
        'page': '/home',
      }, path: '/home');
      // Begin listening for shared norigo.app links (cold start + runtime).
      _deepLinks.start(_handleDeepLink);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MainShell.globalSwitchTab = null;
    _deepLinks.dispose();
    super.dispose();
  }

  // ── Deep link handling ──────────────────────────────────────────────

  Future<void> _handleDeepLink(DeepLinkTarget target) async {
    if (!mounted) return;
    final locale = ref.read(localeProvider);
    ref.read(trackingServiceProvider).trackEvent('deep_link_open', payload: {
      'kind': target.kind.name,
      'path': target.uri.path,
    });
    switch (target.kind) {
      case DeepLinkKind.stay:
        _restoreStaySearch(target);
      case DeepLinkKind.meetup:
        _restoreMeetupSearch(target, locale);
      case DeepLinkKind.guide:
        _pushRoot(NativeGuideDetailScreen(slug: target.slug!));
      case DeepLinkKind.spot:
        await _openSpot(target.slug!, locale, target.uri);
      case DeepLinkKind.vote:
        _pushRoot(VoteScreen(pollId: target.id!));
      case DeepLinkKind.shortLink:
        // Already expanded by the service; if it ever reaches here, open it.
        _openExternally(target.uri);
      case DeepLinkKind.external:
        _openExternally(target.uri);
    }
  }

  void _restoreStaySearch(DeepLinkTarget t) {
    if (t.landmarks.length < 2) {
      _openExternally(t.uri);
      return;
    }
    final region = t.region ?? 'kanto';
    final notifier = ref.read(staySearchProvider.notifier);
    notifier.reset();
    notifier.setRegion(region);
    for (final lm in t.landmarks) {
      notifier.addLandmark(Landmark(
        // Coordinate-based slug keeps each landmark distinct (addLandmark
        // de-dupes by slug, so a shared empty slug would collapse them).
        slug: '${lm.lat},${lm.lng}',
        name: lm.name,
        lat: lm.lat,
        lng: lm.lng,
        region: region,
      ));
    }
    if (t.mode != null) notifier.setMode(t.mode!);
    if (t.budget != null) notifier.setBudget(t.budget);
    if (t.checkIn != null || t.checkOut != null) {
      notifier.setDates(t.checkIn, t.checkOut);
    }
    if (t.stayStyle != null) notifier.setStayStyle(t.stayStyle!);
    _goToTab(1);
    notifier.search();
  }

  void _restoreMeetupSearch(DeepLinkTarget t, String locale) {
    final region = t.region ?? 'kanto';
    final stations = <Station>[];
    for (final id in t.stationIds) {
      final coords = StationLocalizer.getCoordinates(id);
      if (coords == null) {
        // Can't resolve a station reliably — open in browser instead of
        // running a search with bad coordinates.
        _openExternally(t.uri);
        return;
      }
      stations.add(Station(
        id: id,
        name: StationLocalizer.getLocalizedName(id, locale) ?? id,
        lat: coords.$1,
        lng: coords.$2,
        region: region,
      ));
    }
    if (stations.length < 2) {
      _openExternally(t.uri);
      return;
    }
    final notifier = ref.read(meetupSearchProvider.notifier);
    notifier.reset();
    notifier.setRegion(region);
    notifier.setStations(stations);
    if (t.mode != null) notifier.setMode(t.mode!);
    if (t.category != null) notifier.setCategory(t.category);
    if (t.budget != null) notifier.setBudget(t.budget);
    if (t.options.isNotEmpty) notifier.setOptions(t.options);
    _goToTab(2);
    notifier.search();
  }

  Future<void> _openSpot(String slug, String locale, Uri fallback) async {
    Landmark? lm;
    final coords = LandmarkLocalizer.getCoordinates(slug: slug);
    if (coords != null) {
      lm = Landmark(
        slug: slug,
        name: LandmarkLocalizer.getLocalizedName(locale: locale, slug: slug) ?? slug,
        lat: coords.$1,
        lng: coords.$2,
        region: LandmarkLocalizer.getRegion(slug: slug) ?? 'kanto',
      );
    } else {
      // Not in the bundle — ask the API to resolve the slug.
      final resolved = await ref
          .read(apiClientProvider)
          .resolveLandmarks([slug], locale: locale);
      if (resolved.isNotEmpty) lm = resolved.first;
    }
    if (!mounted) return;
    if (lm == null) {
      _openExternally(fallback);
      return;
    }
    _pushRoot(SpotDetailScreen(landmark: lm));
  }

  /// Pop any pushed routes, then switch the shell to [index].
  void _goToTab(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    switchToTab(index);
  }

  void _pushRoot(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openExternally(Uri uri) async {
    var target = uri;
    if (target.scheme == 'norigo') {
      // A norigo:// URI can't load in a browser — map it onto the website
      // (norigo://stay/result?x → https://norigo.app/stay/result?x). The
      // custom scheme puts the first path segment in the authority.
      final segments = [
        if (target.host.isNotEmpty &&
            target.host != 'norigo.app' &&
            target.host != 'www.norigo.app')
          target.host,
        ...target.pathSegments,
      ];
      target = Uri(
        scheme: 'https',
        host: 'norigo.app',
        path: '/${segments.join('/')}',
        query: target.query.isEmpty ? null : target.query,
      );
    }
    // Our own URLs open in an in-app browser view (Custom Tabs / Safari VC)
    // instead of a plain VIEW intent: Android App Links would resolve a
    // claimed norigo.app URL right back into this app and loop. Everything
    // else keeps the external browser.
    final isOurs =
        target.host == 'norigo.app' || target.host == 'www.norigo.app';
    try {
      await launchUrl(
        target,
        mode: isOurs
            ? LaunchMode.inAppBrowserView
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('MainShell: failed to open $target externally: $e');
    }
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
