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
      ..addJavaScriptChannel('NorigoApp', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) {
          setState(() => _loading = false);
          _injectInterceptor();
        },
        onProgress: (p) => setState(() => _progress = p / 100),
        // Intercept spot page navigation
        onNavigationRequest: (request) {
          final url = request.url;
          // Let guide pages load normally
          if (url.contains('/guide/')) return NavigationDecision.navigate;
          // Open external links in browser
          if (!url.contains('norigo.app')) return NavigationDecision.navigate;
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse('https://norigo.app/${widget.locale}/guide/${widget.slug}'));
  }

  void _injectInterceptor() {
    _controller.runJavaScript('''
    (function() {
      // MutationObserver to catch dynamically added buttons
      function interceptButtons() {
        document.querySelectorAll('button').forEach(function(btn) {
          if (btn.dataset.norigoIntercepted) return;
          var text = btn.textContent || '';
          if (text.includes('旅行に追加') || text.includes('여행에 추가') || text.includes('Add to trip') || text.includes('添加到行程')) {
            btn.dataset.norigoIntercepted = '1';

            // Clone and replace to remove React event handlers
            var newBtn = btn.cloneNode(true);
            newBtn.addEventListener('click', function(e) {
              e.preventDefault();
              e.stopPropagation();
              e.stopImmediatePropagation();

              // Find parent card to extract data
              var card = this.closest('.rounded-xl, .rounded-lg, [class*="rounded"]');
              var link = card ? card.querySelector('a[href*="/spot/"]') : null;
              var slug = link ? link.getAttribute('href').replace(/.*\\/spot\\//, '') : '';
              var h3 = card ? card.querySelector('h3') : null;
              var name = h3 ? h3.textContent.trim() : '';

              if (slug || name) {
                // Send to Flutter
                NorigoApp.postMessage(JSON.stringify({
                  action: 'addToTrip',
                  slug: slug || name.toLowerCase().replace(/\\s+/g, '-'),
                  name: name || slug
                }));

                // Visual feedback
                this.style.backgroundColor = '#16a34a';
                this.style.color = 'white';
                this.style.borderColor = '#16a34a';
                this.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline;vertical-align:middle;margin-right:4px"><polyline points="20 6 9 17 4 12"></polyline></svg>' +
                  (document.documentElement.lang === 'ko' ? '추가됨' : document.documentElement.lang === 'ja' ? '追加済み' : 'Added');
              }
            }, true);

            if (btn.parentNode) {
              btn.parentNode.replaceChild(newBtn, btn);
            }
          }
        });
      }

      // Run immediately and observe DOM changes
      interceptButtons();
      var observer = new MutationObserver(function() { interceptButtons(); });
      observer.observe(document.body, { childList: true, subtree: true });
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

        final region = _guessRegion();
        final locale = widget.locale;

        ref.read(tripProvider.notifier).addItem(
          Landmark(slug: slug, name: name, lat: 0, lng: 0, region: region),
          locale: locale,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                locale == 'ja' ? '$name → 旅行プランに追加'
                    : locale == 'ko' ? '$name → 여행 플랜에 추가됨'
                    : '$name → Added to trip plan',
              )),
            ]),
            duration: const Duration(seconds: 2),
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
