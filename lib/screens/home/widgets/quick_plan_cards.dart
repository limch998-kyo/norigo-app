import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/constants.dart';
import '../../../models/landmark.dart';

class QuickPlan {
  final String id;
  final String region;
  final String image;
  final Map<String, Map<String, String>> labels;
  final List<Map<String, dynamic>> landmarks;

  const QuickPlan({
    required this.id,
    required this.region,
    required this.image,
    required this.labels,
    required this.landmarks,
  });
}

const _plans = [
  QuickPlan(
    id: 'tokyo-classic',
    region: 'kanto',
    image: '/images/landmarks/shibuya-crossing.webp',
    labels: {
      'en': {'title': 'Shibuya · Harajuku · Shinjuku', 'subtitle': 'Essential Tokyo itinerary'},
      'ja': {'title': '渋谷・原宿・新宿', 'subtitle': '東京の定番コース'},
      'ko': {'title': '시부야・하라주쿠・신주쿠', 'subtitle': '도쿄 핵심 코스'},
      'zh': {'title': '涩谷・原宿・新宿', 'subtitle': '东京经典路线'},
    },
    landmarks: [
      {'slug': 'shibuya-crossing', 'name': '渋谷スクランブル交差点', 'nameEn': 'Shibuya Crossing', 'lat': 35.6595, 'lng': 139.7004, 'region': 'kanto'},
      {'slug': 'harajuku-takeshita', 'name': '原宿竹下通り', 'nameEn': 'Harajuku Takeshita', 'lat': 35.6702, 'lng': 139.7026, 'region': 'kanto'},
      {'slug': 'shinjuku-gyoen', 'name': '新宿御苑', 'nameEn': 'Shinjuku Gyoen', 'lat': 35.6852, 'lng': 139.7100, 'region': 'kanto'},
    ],
  ),
  QuickPlan(
    id: 'tokyo-traditional',
    region: 'kanto',
    image: '/images/landmarks/asakusa-senso-ji.webp',
    labels: {
      'en': {'title': 'Asakusa · Ueno · Tokyo Station', 'subtitle': 'Tradition meets shopping'},
      'ja': {'title': '浅草・上野・東京駅', 'subtitle': '伝統とショッピングを一度に'},
      'ko': {'title': '아사쿠사・우에노・도쿄역', 'subtitle': '전통과 쇼핑을 한번에'},
      'zh': {'title': '浅草・上野・东京站', 'subtitle': '传统与购物一次搞定'},
    },
    landmarks: [
      {'slug': 'sensoji-temple', 'name': '浅草寺', 'nameEn': 'Sensoji Temple', 'lat': 35.7148, 'lng': 139.7967, 'region': 'kanto'},
      {'slug': 'ueno-park', 'name': '上野恩賜公園', 'nameEn': 'Ueno Park', 'lat': 35.7146, 'lng': 139.7714, 'region': 'kanto'},
      {'slug': 'tokyo-station', 'name': '東京駅', 'nameEn': 'Tokyo Station', 'lat': 35.6812, 'lng': 139.7671, 'region': 'kanto'},
    ],
  ),
  QuickPlan(
    id: 'tokyo-family',
    region: 'kanto',
    image: '/images/landmarks/odaiba.webp',
    labels: {
      'en': {'title': 'Odaiba · Akihabara · Ikebukuro', 'subtitle': 'Family & pop culture'},
      'ja': {'title': 'お台場・秋葉原・池袋', 'subtitle': 'ファミリー＆ポップカルチャー'},
      'ko': {'title': '오다이바・아키하바라・이케부쿠로', 'subtitle': '가족 & 팝컬처'},
      'zh': {'title': '台场・秋叶原・池袋', 'subtitle': '家庭与流行文化'},
    },
    landmarks: [
      {'slug': 'odaiba', 'name': 'お台場', 'nameEn': 'Odaiba', 'lat': 35.6268, 'lng': 139.7753, 'region': 'kanto'},
      {'slug': 'akihabara', 'name': '秋葉原', 'nameEn': 'Akihabara', 'lat': 35.6984, 'lng': 139.7731, 'region': 'kanto'},
      {'slug': 'ikebukuro-sunshine', 'name': '池袋サンシャインシティ', 'nameEn': 'Ikebukuro Sunshine City', 'lat': 35.7295, 'lng': 139.7186, 'region': 'kanto'},
    ],
  ),
  QuickPlan(
    id: 'osaka-gourmet',
    region: 'kansai',
    image: '/images/landmarks/dotonbori.webp',
    labels: {
      'en': {'title': 'Dotonbori · Namba · Shinsaibashi', 'subtitle': 'Osaka food trip'},
      'ja': {'title': '道頓堀・なんば・心斎橋', 'subtitle': '大阪グルメ旅'},
      'ko': {'title': '도톤보리・난바・신사이바시', 'subtitle': '오사카 먹방 여행'},
      'zh': {'title': '道顿堀・难波・心斋桥', 'subtitle': '大阪美食之旅'},
    },
    landmarks: [
      {'slug': 'dotonbori', 'name': '道頓堀', 'nameEn': 'Dotonbori', 'lat': 34.6687, 'lng': 135.5013, 'region': 'kansai'},
      {'slug': 'namba', 'name': 'なんば', 'nameEn': 'Namba', 'lat': 34.6659, 'lng': 135.5013, 'region': 'kansai'},
      {'slug': 'shinsaibashi', 'name': '心斎橋', 'nameEn': 'Shinsaibashi', 'lat': 34.6748, 'lng': 135.5016, 'region': 'kansai'},
    ],
  ),
  QuickPlan(
    id: 'kyoto-daytrip',
    region: 'kansai',
    image: '/images/landmarks/fushimi-inari-taisha.webp',
    labels: {
      'en': {'title': 'Kiyomizu-dera · Fushimi Inari · Arashiyama', 'subtitle': 'Kyoto day trip'},
      'ja': {'title': '清水寺・伏見稲荷・嵐山', 'subtitle': '京都日帰りプラン'},
      'ko': {'title': '기요미즈데라・후시미이나리・아라시야마', 'subtitle': '교토 당일치기'},
      'zh': {'title': '清水寺・伏见稻荷・岚山', 'subtitle': '京都一日游'},
    },
    landmarks: [
      {'slug': 'kiyomizu-dera', 'name': '清水寺', 'nameEn': 'Kiyomizu-dera', 'lat': 34.9949, 'lng': 135.7850, 'region': 'kansai'},
      {'slug': 'fushimi-inari', 'name': '伏見稲荷大社', 'nameEn': 'Fushimi Inari Shrine', 'lat': 34.9671, 'lng': 135.7727, 'region': 'kansai'},
      {'slug': 'arashiyama', 'name': '嵐山', 'nameEn': 'Arashiyama', 'lat': 35.0094, 'lng': 135.6672, 'region': 'kansai'},
    ],
  ),
];

class QuickPlanCards extends StatelessWidget {
  final void Function(String planId, String region, List<Landmark> landmarks)? onPlanSelected;

  const QuickPlanCards({super.key, this.onPlanSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final kantoPlans = _plans.where((p) => p.region == 'kanto').toList();
    final kansaiPlans = _plans.where((p) => p.region == 'kansai').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickPlanTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.quickPlanDesc,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),

        // Tokyo
        _RegionSection(
          title: l10n.tokyoTitle,
          plans: kantoPlans,
          locale: locale,
          ctaText: l10n.quickPlanCta,
          onPlanSelected: onPlanSelected,
        ),
        const SizedBox(height: 16),

        // Osaka / Kyoto
        _RegionSection(
          title: l10n.osakaTitle,
          plans: kansaiPlans,
          locale: locale,
          ctaText: l10n.quickPlanCta,
          onPlanSelected: onPlanSelected,
        ),
      ],
    );
  }
}

class _RegionSection extends StatelessWidget {
  final String title;
  final List<QuickPlan> plans;
  final String locale;
  final String ctaText;
  final void Function(String, String, List<Landmark>)? onPlanSelected;

  const _RegionSection({
    required this.title,
    required this.plans,
    required this.locale,
    required this.ctaText,
    this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 260,
                child: _QuickPlanCard(
                  plan: plans[index],
                  locale: locale,
                  ctaText: ctaText,
                  onPlanSelected: onPlanSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickPlanCard extends StatelessWidget {
  final QuickPlan plan;
  final String locale;
  final String ctaText;
  final void Function(String, String, List<Landmark>)? onPlanSelected;

  const _QuickPlanCard({
    required this.plan,
    required this.locale,
    required this.ctaText,
    this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    final labels = plan.labels[locale] ?? plan.labels['en']!;
    final imageUrl = '${AppConstants.apiBaseUrl}${plan.image}';

    return GestureDetector(
      onTap: () {
        if (onPlanSelected != null) {
          final landmarks = plan.landmarks.map((l) => Landmark(
            slug: l['slug'] as String,
            name: l['name'] as String,
            nameEn: l['nameEn'] as String?,
            lat: l['lat'] as double,
            lng: l['lng'] as double,
            region: l['region'] as String,
          )).toList();
          onPlanSelected!(plan.id, plan.region, landmarks);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, url) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    errorWidget: (_, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Text(
                      labels['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      labels['subtitle']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          ctaText,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
