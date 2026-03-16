import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../models/landmark.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('FlutterTrip', onMessageReceived: _onTripMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) {
          setState(() => _loading = false);
          // Inject JS to intercept "Add to trip" button clicks
          _injectTripInterceptor();
        },
        onProgress: (p) => setState(() => _progress = p / 100),
      ))
      ..loadRequest(Uri.parse('https://norigo.app/${widget.locale}/guide/${widget.slug}'));
  }

  /// Inject JavaScript that intercepts the trip provider's addItem calls
  void _injectTripInterceptor() {
    _controller.runJavaScript('''
      // Override the trip provider to send data to Flutter
      (function() {
        // Watch for "Add to trip" button clicks
        document.addEventListener('click', function(e) {
          const btn = e.target.closest('button');
          if (!btn) return;

          // Check if it's an "add to trip" button
          const text = btn.textContent.trim();
          if (text.includes('旅行に追加') || text.includes('여행에 추가') || text.includes('Add to trip') || text.includes('添加到行程')) {
            // Find the spot card parent to get landmark data
            const card = btn.closest('[class*="rounded"]');
            if (!card) return;

            // Try to extract data from the page
            const link = card.querySelector('a[href*="/spot/"]');
            const slug = link ? link.getAttribute('href').split('/spot/')[1] : '';
            const nameEl = card.querySelector('h3');
            const name = nameEl ? nameEl.textContent.trim() : '';

            if (slug && name) {
              // Send to Flutter
              FlutterTrip.postMessage(JSON.stringify({
                action: 'add',
                slug: slug,
                name: name,
              }));

              // Visual feedback
              btn.style.backgroundColor = '#22c55e';
              btn.textContent = '✓ ' + (document.documentElement.lang === 'ko' ? '추가됨' : '追加済み');
              setTimeout(() => {
                btn.style.backgroundColor = '';
              }, 2000);
            }
          }
        }, true);
      })();
    ''');
  }

  /// Handle messages from WebView JavaScript
  void _onTripMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      if (data['action'] == 'add') {
        final slug = data['slug'] as String;
        final name = data['name'] as String;
        final locale = widget.locale;

        // We don't have lat/lng from the page, but we can look up from guide data
        // For now, add with region derived from guide slug
        final region = _guessRegion();

        ref.read(tripProvider.notifier).addItem(
          Landmark(slug: slug, name: name, lat: 0, lng: 0, region: region),
          locale: locale,
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(locale == 'ja' ? '$nameを旅行に追加しました' : locale == 'ko' ? '$name을(를) 여행에 추가했습니다' : 'Added $name to trip'),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {}
  }

  String _guessRegion() {
    final slug = widget.slug;
    if (slug.contains('seoul') || slug.contains('myeongdong') || slug.contains('hongdae') || slug.contains('gangnam') || slug.contains('insadong') || slug.contains('itaewon') || slug.contains('gyeongbok') || slug.contains('bukchon')) return 'seoul';
    if (slug.contains('busan') || slug.contains('haeundae') || slug.contains('gwangalli') || slug.contains('gamcheon') || slug.contains('nampo') || slug.contains('haedong') || slug.contains('taejong')) return 'busan';
    if (slug.contains('osaka') || slug.contains('dotonbori') || slug.contains('kiyomizu') || slug.contains('fushimi') || slug.contains('arashiyama') || slug.contains('nara') || slug.contains('kinkaku') || slug.contains('nijo')) return 'kansai';
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
