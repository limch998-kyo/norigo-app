import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../models/landmark.dart';
import '../../services/api_client.dart';
import '../../services/landmark_localizer.dart';
import '../../utils/tr.dart';
import '../../widgets/trip_picker_dialog.dart';
import '../../app.dart';

class NativeGuideDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const NativeGuideDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<NativeGuideDetailScreen> createState() => _NativeGuideDetailScreenState();
}

class _NativeGuideDetailScreenState extends ConsumerState<NativeGuideDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  final Set<String> _addedSlugs = {};

  void _addSpotToTrip(Map<String, dynamic> spot, String locale) {
    final slug = spot['slug'] as String? ?? '';
    final name = spot['name'] as String? ?? '';
    final region = spot['region'] as String? ?? _guessRegion();

    // Already added check
    final effectiveSlug = slug.isNotEmpty ? slug : name;
    if (_addedSlugs.contains(effectiveSlug)) return;

    // Get coordinates from bundled data
    final coords = LandmarkLocalizer.getCoordinates(slug: slug.isNotEmpty ? slug : null, name: name);
    final lat = coords?.$1 ?? 0.0;
    final lng = coords?.$2 ?? 0.0;

    final localizedName = LandmarkLocalizer.getLocalizedName(
      locale: locale, slug: slug.isNotEmpty ? slug : null, lat: lat != 0 ? lat : null, lng: lng != 0 ? lng : null,
    ) ?? name;

    final tripNotifier = ref.read(tripProvider.notifier);
    final lm = Landmark(slug: effectiveSlug, name: localizedName, lat: lat, lng: lng, region: region);
    tripNotifier.addItem(lm, locale: locale);

    // Trip picker if multiple candidates
    if (tripNotifier.needsTripPicker && mounted) {
      final candidates = tripNotifier.pendingTripCandidates;
      showTripPickerDialog(context, candidates, locale).then((picked) {
        if (picked != null) {
          tripNotifier.completePendingAdd(picked);
        } else {
          tripNotifier.cancelPendingAdd();
          return;
        }
      });
    }

    // Mark as added
    setState(() => _addedSlugs.add(effectiveSlug));

    // Snackbar — always show, auto-dismiss
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr(locale, ja: '旅行プランに追加しました', ko: '여행 플랜에 추가했습니다', en: 'Added to trip plan', zh: '已添加到旅行计划')),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: tr(locale, ja: '旅行タブへ', ko: '여행 탭으로', en: 'Go to Trip', zh: '前往旅行'),
          textColor: Colors.white,
          onPressed: () {
            MainShell.globalSwitchTab?.call(3);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ));
    }
  }

  /// Build content widgets with spot cards inserted inline at their original positions
  List<Widget> _buildContentWithSpots(String markdown, List<Map<String, dynamic>> spots, String locale) {
    final widgets = <Widget>[];

    // Build a map of spot image URLs to spot data
    final spotByImage = <String, Map<String, dynamic>>{};
    for (final spot in spots) {
      final imageUrl = spot['imageUrl'] as String? ?? '';
      if (imageUrl.isNotEmpty) spotByImage[imageUrl] = spot;
    }

    // Split markdown at spot image lines: ![name](imageUrl)
    final pattern = RegExp(r'!\[([^\]]*)\]\((https://norigo\.app/images/landmarks/[^\)]+)\)');
    final parts = <_ContentPart>[];
    int lastEnd = 0;

    for (final match in pattern.allMatches(markdown)) {
      // Text before this image
      if (match.start > lastEnd) {
        final text = markdown.substring(lastEnd, match.start).trim();
        if (text.isNotEmpty) parts.add(_ContentPart(markdown: text));
      }
      // Check if this image belongs to a spot
      final imageUrl = match.group(2)!;
      final spot = spotByImage[imageUrl];
      if (spot != null) {
        // Skip the image line + next heading line (### name\nnameEn) — spot card replaces them
        var skipEnd = match.end;
        final afterImage = markdown.substring(match.end);
        // Skip blank lines + ### heading + nameEn line
        final headingMatch = RegExp(r'^\n*### [^\n]+\n[^\n]*\n?').firstMatch(afterImage);
        if (headingMatch != null) skipEnd += headingMatch.end;
        lastEnd = skipEnd;
        parts.add(_ContentPart(spot: spot));
      } else {
        lastEnd = match.end;
        parts.add(_ContentPart(markdown: match.group(0)!));
      }
    }
    // Remaining text
    if (lastEnd < markdown.length) {
      final text = markdown.substring(lastEnd).trim();
      if (text.isNotEmpty) parts.add(_ContentPart(markdown: text));
    }

    // Convert parts to widgets
    for (final part in parts) {
      if (part.spot != null) {
        final spotSlug = part.spot!['slug'] as String? ?? part.spot!['name'] as String? ?? '';
        widgets.add(_SpotCard(
          spot: part.spot!,
          locale: locale,
          guideSlug: widget.slug,
          isAdded: _addedSlugs.contains(spotSlug),
          onAddToTrip: () => _addSpotToTrip(part.spot!, locale),
        ));
      } else if (part.markdown != null) {
        widgets.add(MarkdownBody(
          data: part.markdown!,
          selectable: true,
          styleSheet: _markdownStyle(),
          onTapLink: (text, href, title) {
            if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
          },
          imageBuilder: (uri, title, alt) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(uri.toString(), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            );
          },
        ));
      }
    }

    return widgets;
  }

  MarkdownStyleSheet _markdownStyle() {
    return MarkdownStyleSheet(
      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 2),
      h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 2),
      p: const TextStyle(fontSize: 14, height: 1.7),
      blockquote: TextStyle(fontSize: 13, color: AppTheme.primary, height: 1.6),
      blockquoteDecoration: BoxDecoration(
        color: AppTheme.primaryBg,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppTheme.primary, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.all(12),
      tableHead: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tableBody: const TextStyle(fontSize: 13),
      tableBorder: TableBorder.all(color: AppTheme.border),
      tableCellsPadding: const EdgeInsets.all(8),
      listBullet: const TextStyle(fontSize: 14),
    );
  }

  String _guessRegion() {
    final s = widget.slug;
    if (s.contains('seoul') || s.contains('myeongdong') || s.contains('hongdae') || s.contains('gangnam')) return 'seoul';
    if (s.contains('busan') || s.contains('haeundae') || s.contains('gwangalli')) return 'busan';
    if (s.contains('dotonbori') || s.contains('kiyomizu') || s.contains('fushimi') || s.contains('arashiyama')) return 'kansai';
    return 'kanto';
  }

  Future<void> _loadGuide() async {
    try {
      final locale = ref.read(localeProvider);
      final api = ref.read(apiClientProvider);
      final data = await api.getGuideDetail(widget.slug, locale: locale);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _data == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Guide not found')),
      );
    }

    final title = _data!['title'] as String? ?? '';
    final heroImage = _data!['heroImage'] as String? ?? '';
    final markdown = _data!['contentMarkdown'] as String? ?? '';
    final tags = (_data!['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final toc = (_data!['toc'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final spots = (_data!['spots'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final faq = (_data!['faq'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              background: heroImage.isNotEmpty
                ? Image.network(heroImage, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.muted))
                : Container(color: AppTheme.muted),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                      )).toList(),
                    ),

                  // Table of Contents
                  if (toc.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(locale, ja: '目次', ko: '목차', en: 'Contents', zh: '目录'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ...toc.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text('• ${item['label'] ?? ''}',
                              style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                          )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Markdown content with inline spot cards
                  ..._buildContentWithSpots(markdown, spots, locale),

                  // FAQ section
                  if (faq.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(tr(locale, ja: 'よくある質問', ko: '자주 묻는 질문', en: 'FAQ', zh: '常见问题'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...faq.map((item) => _FaqItem(
                      question: item['question'] as String? ?? '',
                      answer: item['answer'] as String? ?? '',
                    )),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  final Map<String, dynamic> spot;
  final String locale;
  final String guideSlug;
  final VoidCallback onAddToTrip;
  final bool isAdded;

  const _SpotCard({required this.spot, required this.locale, required this.guideSlug, required this.onAddToTrip, this.isAdded = false});

  @override
  Widget build(BuildContext context) {
    final name = spot['name'] as String? ?? '';
    final nameEn = spot['nameEn'] as String? ?? '';
    final imageUrl = spot['imageUrl'] as String? ?? '';
    final description = spot['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(imageUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppTheme.muted,
                  child: Center(child: Icon(Icons.place, size: 32, color: AppTheme.mutedForeground)))),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (nameEn.isNotEmpty)
                  Text(nameEn, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground, height: 1.5),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: isAdded
                    ? ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check, size: 16),
                        label: Text(tr(locale, ja: '追加済み', ko: '추가됨', en: 'Added', zh: '已添加'),
                          style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: onAddToTrip,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(tr(locale, ja: '旅行に追加', ko: '여행에 추가', en: 'Add to Trip', zh: '添加到行程'),
                          style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(widget.question,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20, color: AppTheme.mutedForeground),
              ]),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(widget.answer,
                  style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground, height: 1.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentPart {
  final String? markdown;
  final Map<String, dynamic>? spot;
  _ContentPart({this.markdown, this.spot});
}
