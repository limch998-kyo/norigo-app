import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../utils/tr.dart';
import 'native_guide_detail_screen.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> {
  List<Map<String, dynamic>> _guides = [];
  String _selectedRegion = 'all';

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    final raw = await rootBundle.loadString('assets/data/featured-guides.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    if (mounted) setState(() => _guides = list);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    final regions = ['all', 'kanto', 'kansai', 'seoul', 'busan'];
    final regionLabels = {
      'all': tr(locale, ja: 'すべて', ko: '전체', en: 'All', zh: '全部', fr: 'Tout'),
      'kanto': tr(locale, ja: '東京・関東', ko: '도쿄·간토', en: 'Tokyo', zh: '东京', fr: 'Tokyo'),
      'kansai': tr(locale, ja: '大阪・関西', ko: '오사카·간사이', en: 'Osaka', zh: '大阪', fr: 'Osaka'),
      'seoul': tr(locale, ja: 'ソウル', ko: '서울', en: 'Seoul', zh: '首尔', fr: 'Séoul'),
      'busan': tr(locale, ja: '釜山', ko: '부산', en: 'Busan', zh: '釜山', fr: 'Busan'),
    };

    final filtered = _selectedRegion == 'all'
        ? _guides
        : _guides.where((g) => g['region'] == _selectedRegion).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(locale, ja: '旅行ガイド', ko: '여행 가이드', en: 'Travel Guides', zh: '旅行指南', fr: 'Guides de voyage')),
      ),
      body: Column(
        children: [
          // Region tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: regions.map((r) {
                final isSelected = _selectedRegion == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRegion = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        regionLabels[r] ?? r,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.white : AppTheme.foreground,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Guide list
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(tr(locale, ja: 'ガイドがありません', ko: '가이드가 없습니다', en: 'No guides', zh: '没有指南', fr: 'Aucun guide'), style: TextStyle(color: AppTheme.mutedForeground)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final guide = filtered[index];
                      final title = (guide['title'] as Map<String, dynamic>?)?[locale] ??
                          (guide['title'] as Map<String, dynamic>?)?['en'] ?? '';
                      final desc = (guide['description'] as Map<String, dynamic>?)?[locale] ??
                          (guide['description'] as Map<String, dynamic>?)?['en'] ?? '';
                      final imageUrl = 'https://norigo.app${guide['heroImage']}';
                      final slug = guide['slug'] as String;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => NativeGuideDetailScreen(slug: slug),
                            ));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.muted,
                                      child: Center(child: Icon(Icons.menu_book, size: 32, color: AppTheme.mutedForeground)),
                                    ),
                                  ),
                                ),
                                // Content
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Region badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          regionLabels[guide['region']] ?? '',
                                          style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Text(
                                        title,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        desc,
                                        style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground, height: 1.4),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        Icon(Icons.menu_book, size: 14, color: AppTheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          tr(locale, ja: 'ガイドを読む', ko: '가이드 읽기', en: 'Read Guide', zh: '阅读指南', fr: 'Lire le guide'),
                                          style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
