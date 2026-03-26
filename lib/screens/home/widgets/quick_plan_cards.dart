import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/landmark.dart';
import '../../../utils/tr.dart';

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
      'fr': {'title': 'Shibuya · Harajuku · Shinjuku', 'subtitle': 'Itinéraire classique de Tokyo'},
    },
    landmarks: [
      {'slug': 'shibuya-crossing', 'name': '渋谷', 'nameEn': 'Shibuya', 'nameKo': '시부야', 'lat': 35.6595, 'lng': 139.7004, 'region': 'kanto'},
      {'slug': 'harajuku', 'name': '原宿', 'nameEn': 'Harajuku', 'nameKo': '하라주쿠', 'lat': 35.6702, 'lng': 139.7026, 'region': 'kanto'},
      {'slug': 'shinjuku', 'name': '新宿', 'nameEn': 'Shinjuku', 'nameKo': '신주쿠', 'lat': 35.6852, 'lng': 139.7100, 'region': 'kanto'},
      {'slug': 'omotesando', 'name': '表参道', 'nameEn': 'Omotesando', 'nameKo': '오모테산도', 'lat': 35.6654, 'lng': 139.7121, 'region': 'kanto'},
      {'slug': 'ikebukuro', 'name': '池袋', 'nameEn': 'Ikebukuro', 'nameKo': '이케부쿠로', 'lat': 35.7295, 'lng': 139.7109, 'region': 'kanto'},
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
      'fr': {'title': 'Asakusa · Ueno · Gare de Tokyo', 'subtitle': 'Tradition et shopping'},
    },
    landmarks: [
      {'slug': 'asakusa-senso-ji', 'name': '浅草寺', 'nameEn': 'Asakusa (Senso-ji)', 'nameKo': '아사쿠사(센소지)', 'lat': 35.7148, 'lng': 139.7967, 'region': 'kanto'},
      {'slug': 'ueno-park', 'name': '上野公園', 'nameEn': 'Ueno Park', 'nameKo': '우에노 공원', 'lat': 35.7146, 'lng': 139.7732, 'region': 'kanto'},
      {'slug': 'tokyo-station', 'name': '東京駅', 'nameEn': 'Tokyo Station', 'nameKo': '도쿄역', 'lat': 35.6812, 'lng': 139.7671, 'region': 'kanto'},
      {'slug': 'akihabara', 'name': '秋葉原', 'nameEn': 'Akihabara', 'nameKo': '아키하바라', 'lat': 35.6984, 'lng': 139.7731, 'region': 'kanto'},
      {'slug': 'tokyo-skytree', 'name': 'スカイツリー', 'nameEn': 'Tokyo Skytree', 'nameKo': '스카이트리', 'lat': 35.7101, 'lng': 139.8107, 'region': 'kanto'},
    ],
  ),
  QuickPlan(
    id: 'tokyo-family',
    region: 'kanto',
    image: '/images/landmarks/tokyo-disneyland.webp',
    labels: {
      'en': {'title': 'Disneyland · Odaiba · Ginza', 'subtitle': 'Perfect for families'},
      'ja': {'title': 'ディズニーランド・お台場・銀座', 'subtitle': '家族旅行におすすめ'},
      'ko': {'title': '디즈니랜드・오다이바・긴자', 'subtitle': '가족 여행에 추천'},
      'zh': {'title': '迪士尼・台场・银座', 'subtitle': '家庭旅行推荐'},
      'fr': {'title': 'Disneyland · Odaiba · Ginza', 'subtitle': 'Idéal pour les familles'},
    },
    landmarks: [
      {'slug': 'tokyo-disneyland', 'name': '東京ディズニーランド', 'nameEn': 'Tokyo Disneyland', 'nameKo': '도쿄 디즈니랜드', 'lat': 35.6329, 'lng': 139.8804, 'region': 'kanto'},
      {'slug': 'odaiba', 'name': 'お台場', 'nameEn': 'Odaiba', 'nameKo': '오다이바', 'lat': 35.6267, 'lng': 139.7762, 'region': 'kanto'},
      {'slug': 'ginza', 'name': '銀座', 'nameEn': 'Ginza', 'nameKo': '긴자', 'lat': 35.6717, 'lng': 139.7649, 'region': 'kanto'},
      {'slug': 'tokyo-tower', 'name': '東京タワー', 'nameEn': 'Tokyo Tower', 'nameKo': '도쿄타워', 'lat': 35.6586, 'lng': 139.7454, 'region': 'kanto'},
      {'slug': 'tsukiji', 'name': '築地', 'nameEn': 'Tsukiji', 'nameKo': '쓰키지', 'lat': 35.6654, 'lng': 139.7707, 'region': 'kanto'},
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
      'fr': {'title': 'Dotonbori · Namba · Shinsaibashi', 'subtitle': 'Voyage gastronomique à Osaka'},
    },
    landmarks: [
      {'slug': 'dotonbori', 'name': '道頓堀', 'nameEn': 'Dotonbori', 'nameKo': '도톤보리', 'lat': 34.6687, 'lng': 135.5021, 'region': 'kansai'},
      {'slug': 'namba', 'name': 'なんば', 'nameEn': 'Namba', 'nameKo': '난바', 'lat': 34.6659, 'lng': 135.5013, 'region': 'kansai'},
      {'slug': 'shinsaibashi', 'name': '心斎橋', 'nameEn': 'Shinsaibashi', 'nameKo': '신사이바시', 'lat': 34.6751, 'lng': 135.5014, 'region': 'kansai'},
      {'slug': 'kuromon-market', 'name': '黒門市場', 'nameEn': 'Kuromon Market', 'nameKo': '구로몬시장', 'lat': 34.6681, 'lng': 135.5097, 'region': 'kansai'},
      {'slug': 'osaka-castle', 'name': '大阪城', 'nameEn': 'Osaka Castle', 'nameKo': '오사카성', 'lat': 34.6873, 'lng': 135.5262, 'region': 'kansai'},
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
      'fr': {'title': 'Kiyomizu-dera · Fushimi Inari · Arashiyama', 'subtitle': 'Excursion à Kyoto'},
    },
    landmarks: [
      {'slug': 'kiyomizu-dera', 'name': '清水寺', 'nameEn': 'Kiyomizu-dera', 'nameKo': '기요미즈데라', 'lat': 34.9949, 'lng': 135.785, 'region': 'kansai'},
      {'slug': 'fushimi-inari-taisha', 'name': '伏見稲荷大社', 'nameEn': 'Fushimi Inari', 'nameKo': '후시미이나리 타이샤', 'lat': 34.9671, 'lng': 135.7727, 'region': 'kansai'},
      {'slug': 'arashiyama', 'name': '嵐山', 'nameEn': 'Arashiyama', 'nameKo': '아라시야마', 'lat': 35.0094, 'lng': 135.667, 'region': 'kansai'},
      {'slug': 'kinkaku-ji', 'name': '金閣寺', 'nameEn': 'Kinkaku-ji', 'nameKo': '킨카쿠지', 'lat': 35.0394, 'lng': 135.7292, 'region': 'kansai'},
      {'slug': 'nijo-castle', 'name': '二条城', 'nameEn': 'Nijo Castle', 'nameKo': '니조성', 'lat': 35.0142, 'lng': 135.7481, 'region': 'kansai'},
    ],
  ),
  QuickPlan(
    id: 'fukuoka-classic',
    region: 'kyushu',
    image: '/images/landmarks/canal-city-hakata.webp',
    labels: {
      'en': {'title': 'Tenjin · Canal City · Nakasu', 'subtitle': 'Fukuoka highlights'},
      'ja': {'title': '天神・キャナルシティ・中洲', 'subtitle': '福岡の定番コース'},
      'ko': {'title': '텐진·캐널시티·나카스', 'subtitle': '후쿠오카 핵심 코스'},
      'zh': {'title': '天神・博多运河城・中洲', 'subtitle': '福冈经典路线'},
      'fr': {'title': 'Tenjin · Canal City · Nakasu', 'subtitle': 'Incontournables de Fukuoka'},
    },
    landmarks: [
      {'slug': 'tenjin', 'name': '天神', 'nameEn': 'Tenjin', 'nameKo': '텐진', 'lat': 33.5903, 'lng': 130.3990, 'region': 'kyushu'},
      {'slug': 'canal-city-hakata', 'name': 'キャナルシティ博多', 'nameEn': 'Canal City Hakata', 'nameKo': '캐널시티 하카타', 'lat': 33.5895, 'lng': 130.4107, 'region': 'kyushu'},
      {'slug': 'nakasu', 'name': '中洲', 'nameEn': 'Nakasu', 'nameKo': '나카스', 'lat': 33.5922, 'lng': 130.4042, 'region': 'kyushu'},
      {'slug': 'dazaifu-tenmangu', 'name': '太宰府天満宮', 'nameEn': 'Dazaifu Tenmangu', 'nameKo': '다자이후 텐만구', 'lat': 33.5194, 'lng': 130.5350, 'region': 'kyushu'},
      {'slug': 'hakata-station', 'name': '博多駅', 'nameEn': 'Hakata Station', 'nameKo': '하카타역', 'lat': 33.5898, 'lng': 130.4207, 'region': 'kyushu'},
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
    final kyushuPlans = _plans.where((p) => p.region == 'kyushu').toList();

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
        const SizedBox(height: 16),

        // Fukuoka / Kyushu
        _RegionSection(
          title: tr(locale, ja: '福岡・九州', ko: '후쿠오카·큐슈', en: 'Fukuoka / Kyushu', zh: '福冈·九州', fr: 'Fukuoka / Kyushu'),
          plans: kyushuPlans,
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
        // Full-width vertical cards (matching web layout)
        ...plans.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuickPlanCard(
              plan: entry.value,
              locale: locale,
              ctaText: ctaText,
              onPlanSelected: onPlanSelected,
            ),
          );
        }),
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
    // Load from web (all images available on norigo.app)
    final imageUrl = 'https://norigo.app${plan.image}';

    return GestureDetector(
      onTap: () {
        if (onPlanSelected != null) {
          final landmarks = plan.landmarks.map((l) {
            // Use localized name based on current locale
            final name = locale == 'ko' ? (l['nameKo'] as String? ?? l['nameEn'] as String? ?? l['name'] as String)
                : locale == 'ja' ? (l['name'] as String)
                : (l['nameEn'] as String? ?? l['name'] as String); // en, zh, fr → English fallback
            return Landmark(
              slug: l['slug'] as String,
              name: name,
              nameEn: l['nameEn'] as String?,
              lat: l['lat'] as double,
              lng: l['lng'] as double,
              region: l['region'] as String,
            );
          }).toList();
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
            // Image — full width with 16:9 aspect ratio
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
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
