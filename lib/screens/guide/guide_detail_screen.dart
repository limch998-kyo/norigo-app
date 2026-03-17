import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../models/landmark.dart';
import '../../services/landmark_localizer.dart';
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
  bool _shownAddSnackbar = false;

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

  void _onMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      if (data['action'] == 'addToTrip') {
        final slug = data['slug'] as String? ?? '';
        final name = data['name'] as String? ?? '';
        if (name.isEmpty) return;

        // Resolve from bundled data: coordinates + region
        final effectiveSlug = slug.isNotEmpty ? slug : name;
        final coords = LandmarkLocalizer.getCoordinates(slug: slug.isNotEmpty ? slug : null, name: name);
        final resolvedRegion = LandmarkLocalizer.getRegion(slug: slug.isNotEmpty ? slug : null, name: name) ?? _guessRegion();
        final lat = coords?.$1 ?? 0.0;
        final lng = coords?.$2 ?? 0.0;

        // Get locale-specific name
        final localizedName = LandmarkLocalizer.getLocalizedName(
          locale: widget.locale,
          slug: slug.isNotEmpty ? slug : null,
          lat: lat != 0 ? lat : null,
          lng: lng != 0 ? lng : null,
        ) ?? name;

        ref.read(tripProvider.notifier).addItem(
          Landmark(slug: effectiveSlug, name: localizedName, lat: lat, lng: lng, region: resolvedRegion),
          locale: widget.locale,
        );

        // Show snackbar once per guide page
        if (mounted && !_shownAddSnackbar) {
          _shownAddSnackbar = true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                widget.locale == 'ja' ? '旅行プランに追加しました'
                    : widget.locale == 'ko' ? '여행 플랜에 추가했습니다'
                    : 'Added to trip plan',
              )),
            ]),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: widget.locale == 'ja' ? '旅行タブへ' : widget.locale == 'ko' ? '여행 탭으로' : 'Go to Trip',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                MainShell.globalSwitchTab?.call(3);
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
