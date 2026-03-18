import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../models/landmark.dart';
import '../../services/landmark_localizer.dart';
import '../../widgets/trip_picker_dialog.dart';
import '../../app.dart';

class GuideDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  final String title;
  final String locale;

  const GuideDetailScreen({super.key, required this.slug, required this.title, required this.locale});

  @override
  ConsumerState<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends ConsumerState<GuideDetailScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;

  /// Global flag: show "added to trip" snackbar only once across entire app session
  static bool _shownAddSnackbar = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('NorigoApp', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) {
          setState(() => _loading = false);
          _injectInterceptor();
        },
        onProgress: (p) => setState(() => _progress = p / 100),
      ))
      ..loadRequest(Uri.parse('https://norigo.app/${widget.locale}/guide/${widget.slug}'));
  }

  void _injectInterceptor() {
    // Hide web app's own UI elements (header, footer, floating cart, nav)
    _controller.runJavaScript('''
    (function() {
      var style = document.createElement('style');
      style.textContent = 'header, footer, nav, [class*="TripCart"], [class*="trip-cart"], [class*="floating"], [class*="Fab"], button[class*="fixed"] { display: none !important; } main { padding-top: 0 !important; }';
      document.head.appendChild(style);
    })();
    ''');

    // Capture phase listener — fires BEFORE React's handler
    // Does NOT prevent default or stop propagation — React button still works normally
    _controller.runJavaScript('''
    (function() {
      if (window._norigoIntercepted) return;
      window._norigoIntercepted = true;

      document.addEventListener('click', function(e) {
        // Find closest button
        var btn = e.target.closest('button');
        if (!btn) return;

        var text = btn.textContent || '';
        // Check if this is "Add to trip" button
        if (text.indexOf('旅行に追加') >= 0 || text.indexOf('여행에 추가') >= 0 || text.indexOf('Add to trip') >= 0 || text.indexOf('添加到行程') >= 0) {
          // Extract spot data from parent card
          var card = btn.closest('.my-6, [class*="my-6"]');
          if (!card) card = btn.parentElement && btn.parentElement.parentElement;

          var slug = '';
          var name = '';

          if (card) {
            var link = card.querySelector('a[href*="/spot/"]');
            if (link) slug = link.getAttribute('href').replace(/.*\\/spot\\//, '');
            var h3 = card.querySelector('h3');
            if (h3) name = h3.textContent.trim();
          }

          if (name) {
            // Send to Flutter — does NOT block the original React click
            try {
              NorigoApp.postMessage(JSON.stringify({
                action: 'addToTrip',
                slug: slug || name,
                name: name
              }));
            } catch(e) {}
          }
        }
      }, true);  // true = capture phase = fires BEFORE React
    })();
    ''');
  }

  void _onMessage(JavaScriptMessage message) async {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      if (data['action'] == 'addToTrip') {
        final slug = data['slug'] as String? ?? '';
        final name = data['name'] as String? ?? '';
        if (name.isEmpty) return;

        // Resolve from bundled data: coordinates + region
        final effectiveSlug = slug.isNotEmpty ? slug : name;
        final coords = LandmarkLocalizer.getCoordinates(slug: slug.isNotEmpty ? slug : null, name: name);
        final lat = coords?.$1 ?? 0.0;
        final lng = coords?.$2 ?? 0.0;
        var resolvedRegion = LandmarkLocalizer.getRegion(slug: slug.isNotEmpty ? slug : null, name: name);
        // Fallback: infer region from coordinates
        if (resolvedRegion == null && lat != 0) {
          if (lat > 36.0) resolvedRegion = 'kanto';
          else if (lat > 33.5 && lat < 36.0) resolvedRegion = 'kansai';
          else if (lat > 37.0 && lng < 128.0) resolvedRegion = 'seoul';
          else if (lat > 34.5 && lat < 36.0 && lng > 128.5) resolvedRegion = 'busan';
        }
        resolvedRegion ??= _guessRegion();

        // Get locale-specific name
        final localizedName = LandmarkLocalizer.getLocalizedName(
          locale: widget.locale,
          slug: slug.isNotEmpty ? slug : null,
          lat: lat != 0 ? lat : null,
          lng: lng != 0 ? lng : null,
        ) ?? name;

        final tripNotifier = ref.read(tripProvider.notifier);
        final lm = Landmark(slug: effectiveSlug, name: localizedName, lat: lat, lng: lng, region: resolvedRegion);
        tripNotifier.addItem(lm, locale: widget.locale);

        // If multiple trips match, show picker
        if (tripNotifier.needsTripPicker && mounted) {
          final candidates = tripNotifier.pendingTripCandidates;
          final picked = await showTripPickerDialog(context, candidates, widget.locale);
          if (picked != null) {
            tripNotifier.completePendingAdd(picked);
          } else {
            tripNotifier.cancelPendingAdd();
            return;
          }
        }

        // Show snackbar once per session with action to go to trip tab
        if (mounted && !_shownAddSnackbar) {
          _shownAddSnackbar = true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              widget.locale == 'ja' ? '旅行プランに追加しました'
                  : widget.locale == 'ko' ? '여행 플랜에 추가했습니다'
                  : 'Added to trip plan',
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: widget.locale == 'ja' ? '旅行タブへ' : widget.locale == 'ko' ? '여행 탭으로' : 'Go to Trip',
              textColor: Colors.white,
              onPressed: () {
                // Switch tab first, then pop back
                MainShell.globalSwitchTab?.call(3);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ));
        }
      }
    } catch (_) {}
  }

  String _guessRegion() {
    final s = widget.slug;
    if (s.contains('seoul') || s.contains('myeongdong') || s.contains('hongdae') || s.contains('gangnam') || s.contains('insadong') || s.contains('itaewon') || s.contains('gyeongbok') || s.contains('bukchon')) return 'seoul';
    if (s.contains('busan') || s.contains('haeundae') || s.contains('gwangalli') || s.contains('gamcheon') || s.contains('nampo') || s.contains('haedong') || s.contains('taejong')) return 'busan';
    if (s.contains('dotonbori') || s.contains('kiyomizu') || s.contains('fushimi') || s.contains('arashiyama') || s.contains('nara') || s.contains('kinkaku') || s.contains('nijo')) return 'kansai';
    return 'kanto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress, color: AppTheme.primary, backgroundColor: AppTheme.border),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
