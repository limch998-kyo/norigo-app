import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/trip_provider.dart';
import '../../models/landmark.dart';
import 'guide_detail_screen.dart';

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
      'all': locale == 'ja' ? 'すべて' : locale == 'ko' ? '전체' : 'All',
      'kanto': locale == 'ja' ? '東京・関東' : locale == 'ko' ? '도쿄·간토' : 'Tokyo',
      'kansai': locale == 'ja' ? '大阪・関西' : locale == 'ko' ? '오사카·간사이' : 'Osaka',
      'seoul': locale == 'ja' ? 'ソウル' : locale == 'ko' ? '서울' : 'Seoul',
      'busan': locale == 'ja' ? '釜山' : locale == 'ko' ? '부산' : 'Busan',
    };

    final filtered = _selectedRegion == 'all'
        ? _guides
        : _guides.where((g) => g['region'] == _selectedRegion).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'ja' ? '旅行ガイド' : locale == 'ko' ? '여행 가이드' : 'Travel Guides'),
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
                ? Center(child: Text(locale == 'ja' ? 'ガイドがありません' : 'No guides', style: TextStyle(color: AppTheme.mutedForeground)))
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
                              builder: (_) => GuideDetailScreen(slug: slug, title: title, locale: locale),
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
                                      Row(
                                        children: [
                                          // Read guide
                                          Expanded(child: Row(children: [
                                            Icon(Icons.menu_book, size: 14, color: AppTheme.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              locale == 'ja' ? 'ガイドを読む' : locale == 'ko' ? '가이드 읽기' : 'Read Guide',
                                              style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
                                            ),
                                          ])),
                                          // Add to trip
                                          if (guide['lat'] != null)
                                            GestureDetector(
                                              onTap: () {
                                                final lat = (guide['lat'] as num).toDouble();
                                                final lng = (guide['lng'] as num).toDouble();
                                                final region = guide['region'] as String;
                                                final lmName = locale == 'ko'
                                                    ? (guide['landmarkNameKo'] as String? ?? title)
                                                    : (guide['landmarkName'] as String? ?? title);
                                                ref.read(tripProvider.notifier).addItem(
                                                  Landmark(slug: slug, name: lmName, lat: lat, lng: lng, region: region),
                                                  locale: locale,
                                                );
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                  content: Text(locale == 'ja' ? '$lmNameを旅行に追加しました' : locale == 'ko' ? '$lmName을(를) 여행에 추가했습니다' : 'Added $lmName to trip'),
                                                  duration: const Duration(seconds: 2),
                                                ));
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppTheme.border),
                                                ),
                                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                  Icon(Icons.add, size: 12, color: AppTheme.foreground),
                                                  const SizedBox(width: 3),
                                                  Text(locale == 'ja' ? '旅行に追加' : locale == 'ko' ? '여행에 추가' : 'Add to trip',
                                                    style: const TextStyle(fontSize: 11)),
                                                ]),
                                              ),
                                            ),
                                        ],
                                      ),
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
