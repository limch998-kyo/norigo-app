import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/constants.dart';

class QuickPlan {
  final String id;
  final String region;
  final String image;
  final Map<String, Map<String, String>> labels;

  const QuickPlan({
    required this.id,
    required this.region,
    required this.image,
    required this.labels,
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
  ),
];

class QuickPlanCards extends StatelessWidget {
  const QuickPlanCards({super.key});

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
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.quickPlanDesc,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Tokyo
        _RegionSection(
          title: l10n.tokyoTitle,
          plans: kantoPlans,
          locale: locale,
          ctaText: l10n.quickPlanCta,
        ),
        const SizedBox(height: 16),

        // Osaka / Kyoto
        _RegionSection(
          title: l10n.osakaTitle,
          plans: kansaiPlans,
          locale: locale,
          ctaText: l10n.quickPlanCta,
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

  const _RegionSection({
    required this.title,
    required this.plans,
    required this.locale,
    required this.ctaText,
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
        ...plans.map((plan) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _QuickPlanCard(plan: plan, locale: locale, ctaText: ctaText),
        )),
      ],
    );
  }
}

class _QuickPlanCard extends StatelessWidget {
  final QuickPlan plan;
  final String locale;
  final String ctaText;

  const _QuickPlanCard({
    required this.plan,
    required this.locale,
    required this.ctaText,
  });

  @override
  Widget build(BuildContext context) {
    final labels = plan.labels[locale] ?? plan.labels['en']!;
    final imageUrl = '${AppConstants.apiBaseUrl}${plan.image}';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to stay search with pre-filled landmarks
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
            AspectRatio(
              aspectRatio: 16 / 9,
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
                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                  // Title on image
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      labels['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      labels['subtitle']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          ctaText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
