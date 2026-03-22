import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../services/api_client.dart';
import '../../utils/tr.dart';

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

                  // Markdown content
                  MarkdownBody(
                    data: markdown,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
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
                    ),
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
                  ),

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
