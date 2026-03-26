import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../models/landmark.dart';
import '../../config/theme.dart';
import '../../utils/tr.dart';
import '../../providers/trip_provider.dart';
import '../../services/landmark_localizer.dart';
import 'widgets/quick_plan_cards.dart';
import '../settings/settings_screen.dart';
import '../spot/spot_detail_screen.dart';

typedef TabSwitcher = void Function(int index);

class HomeScreen extends ConsumerStatefulWidget {
  final TabSwitcher? onSwitchTab;

  const HomeScreen({super.key, this.onSwitchTab});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _koreaMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final onSwitchTab = widget.onSwitchTab;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Settings button top-right
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, size: 22),
                color: AppTheme.mutedForeground,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ));
                },
              ),
            ),
          ),
          // ── Hero Section with illustration background ──
          Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: SvgPicture.asset(
                    _koreaMode ? 'assets/images/illustrations/korea-hero-bg.svg' : 'assets/images/illustrations/hero-bg.svg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    Text(
                      _koreaMode
                          ? tr(locale, ja: '韓国旅行、\n最適なホテルを見つけよう', ko: '한국 여행,\n딱 좋은 호텔을 찾아줄게요', en: 'Korea trip?\nFind the perfect hotel.', zh: '韩国旅行，\n找到最合适的酒店', fr: 'Voyage en Corée ?\nTrouvez l\'hôtel idéal.')
                          : l10n.homeTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _koreaMode
                          ? tr(locale, ja: 'ソウル・釜山の観光地を入力するだけで、すべてに近い最適なホテルエリアを提案。', ko: '서울·부산의 관광지를 입력하면 최적의 호텔 지역을 추천합니다.', en: 'Enter Seoul/Busan landmarks, we find the best hotel area.', zh: '输入首尔·釜山的景点，为您推荐最佳酒店区域。', fr: 'Entrez vos sites à Séoul/Busan, nous trouvons le meilleur quartier hôtelier.')
                          : l10n.homeSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // CTA Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_koreaMode) {
                                final n = ref.read(staySearchProvider.notifier);
                                n.reset();
                                n.setRegion('seoul');
                              }
                              onSwitchTab?.call(_koreaMode ? 1 : (locale == 'ja' ? 2 : 1));
                            },
                            icon: Icon(_koreaMode ? Icons.hotel : (locale == 'ja' ? Icons.groups : Icons.hotel), size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _koreaMode
                                    ? tr(locale, ja: 'ソウルでホテルを探す', ko: '서울 호텔 찾기', en: 'Seoul Hotels', zh: '搜索首尔酒店', fr: 'Hôtels à Séoul')
                                    : (locale == 'ja' ? l10n.meetupTitle : l10n.staySearchTitle),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (_koreaMode) {
                                final n = ref.read(staySearchProvider.notifier);
                                n.reset();
                                n.setRegion('busan');
                              }
                              onSwitchTab?.call(_koreaMode ? 1 : (locale == 'ja' ? 1 : 2));
                            },
                            icon: Icon(_koreaMode ? Icons.hotel : (locale == 'ja' ? Icons.hotel : Icons.groups), size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _koreaMode
                                    ? tr(locale, ja: '釜山でホテルを探す', ko: '부산 호텔 찾기', en: 'Busan Hotels', zh: '搜索釜山酒店', fr: 'Hôtels à Busan')
                                    : (locale == 'ja' ? l10n.staySearchTitle : l10n.meetupTitle),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Service Cards (Japan only, Korea has no meetup) ──
          if (!_koreaMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: _ServiceCard(
                    svgAsset: locale == 'ja'
                        ? 'assets/images/illustrations/service-meetup.svg'
                        : 'assets/images/illustrations/service-stay.svg',
                    label: locale == 'ja' ? l10n.meetupTitle : l10n.staySearchTitle,
                    subtitle: tr(locale, ja: 'みんなの中間地点', ko: '관광지에서 호텔 찾기', en: 'Find hotels near landmarks', zh: '在景点附近找酒店', fr: 'Trouvez des hôtels près des sites'),
                    onTap: () => onSwitchTab?.call(locale == 'ja' ? 2 : 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceCard(
                    svgAsset: locale == 'ja'
                        ? 'assets/images/illustrations/service-stay.svg'
                        : 'assets/images/illustrations/service-meetup.svg',
                    label: locale == 'ja' ? l10n.staySearchTitle : l10n.meetupTitle,
                    subtitle: tr(locale, ja: '観光地からホテルを探す', ko: '모두의 중간 지점', en: 'Find the middle point', zh: '找到大家的中间地点', fr: 'Trouvez le point central'),
                    onTap: () => onSwitchTab?.call(2),
                  ),
                ),
              ],
            ),
          ),

          // ── How It Works ──
          if (!_koreaMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HowItWorks(locale: locale),
            ),
          if (_koreaMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _KoreaHowItWorks(locale: locale),
            ),
          const SizedBox(height: 32),

          // ── Continue Planning (recent trips) ──
          _ContinuePlanningSection(locale: locale, onSwitchTab: onSwitchTab),

          // ── Quick Plans ──
          if (!_koreaMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickPlanCards(
                onPlanSelected: (planId, region, landmarks) {
                  final notifier = ref.read(staySearchProvider.notifier);
                  notifier.reset();
                  notifier.setRegion(region);
                  for (final l in landmarks) {
                    notifier.addLandmark(l);
                  }
                  notifier.setBudget('10000-30000');
                  final checkIn = DateTime.now().add(const Duration(days: 30));
                  final checkOut = checkIn.add(const Duration(days: 3));
                  notifier.setDates(checkIn.toIso8601String().substring(0, 10), checkOut.toIso8601String().substring(0, 10));
                  onSwitchTab?.call(1);
                },
              ),
            ),
          if (_koreaMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _KoreaQuickPlans(locale: locale, onSelect: (landmarks, region) {
                final notifier = ref.read(staySearchProvider.notifier);
                notifier.reset();
                notifier.setRegion(region);
                for (final l in landmarks) { notifier.addLandmark(l); }
                notifier.setBudget('25000-35000');
                final checkIn = DateTime.now().add(const Duration(days: 30));
                final checkOut = checkIn.add(const Duration(days: 3));
                notifier.setDates(checkIn.toIso8601String().substring(0, 10), checkOut.toIso8601String().substring(0, 10));
                onSwitchTab?.call(1);
              }),
            ),
          const SizedBox(height: 32),

          // ── Popular Spots ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PopularSpots(locale: locale, onSpotTap: (landmark) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SpotDetailScreen(landmark: landmark),
              ));
            }),
          ),
          const SizedBox(height: 24),

          // ── Korea/Japan toggle banner ──
          if (!_koreaMode && locale != 'ko')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _KoreaBanner(locale: locale, onTap: () => setState(() => _koreaMode = true)),
            ),
          if (_koreaMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _JapanBanner(locale: locale, onTap: () => setState(() => _koreaMode = false)),
            ),
          const SizedBox(height: 32),

          // ── Footer ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                Text(
                  'Norigo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 Norigo. All rights reserved.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedForeground,
                    fontSize: 11,
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

class _ServiceCard extends StatelessWidget {
  final String svgAsset;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.svgAsset,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 72,
              width: double.infinity,
              child: SvgPicture.asset(
                svgAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedForeground,
                fontSize: 11,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  final String locale;
  const _HowItWorks({required this.locale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _getSteps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(locale, ja: '使い方', ko: '이용 방법', en: 'How It Works', zh: '使用方法', fr: 'Comment ça marche'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step SVG illustration (centered in box)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SvgPicture.asset(
                      step['illustration']!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            step['title']!,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          step['desc']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<Map<String, String>> _getSteps() {
    switch (locale) {
      case 'ja':
        return [
          {'title': '出発駅を入力', 'desc': '友達の出発駅を入力するだけでOK', 'illustration': 'assets/images/illustrations/meetup-step1.svg'},
          {'title': '最適な中間駅を提案', 'desc': 'みんなに公平な駅と周辺のお店を表示', 'illustration': 'assets/images/illustrations/meetup-step2.svg'},
          {'title': '共有して決定', 'desc': 'LINEやリンクで友達にそのまま送信', 'illustration': 'assets/images/illustrations/meetup-step3.svg'},
        ];
      case 'ko':
        return [
          {'title': '관광지 입력', 'desc': '가고 싶은 관광지를 2개 이상 입력', 'illustration': 'assets/images/illustrations/stay-step1.svg'},
          {'title': 'AI가 최적 지역 분석', 'desc': '모든 관광지에 접근하기 좋은 호텔 지역 계산', 'illustration': 'assets/images/illustrations/stay-step2.svg'},
          {'title': '호텔 예약', 'desc': '추천 지역에서 호텔을 골라 예약', 'illustration': 'assets/images/illustrations/stay-step3.svg'},
        ];
      case 'fr':
        return [
          {'title': 'Entrez vos sites', 'desc': 'Ajoutez 2+ sites touristiques à visiter', 'illustration': 'assets/images/illustrations/stay-step1.svg'},
          {'title': 'L\'IA trouve le meilleur quartier', 'desc': 'Nous calculons le quartier hôtelier le mieux situé', 'illustration': 'assets/images/illustrations/stay-step2.svg'},
          {'title': 'Réservez votre hôtel', 'desc': 'Choisissez et réservez parmi les hôtels recommandés', 'illustration': 'assets/images/illustrations/stay-step3.svg'},
        ];
      default:
        return [
          {'title': 'Enter Landmarks', 'desc': 'Add 2+ tourist spots you want to visit', 'illustration': 'assets/images/illustrations/stay-step1.svg'},
          {'title': 'AI Finds Best Area', 'desc': 'We calculate the hotel area with best access to all spots', 'illustration': 'assets/images/illustrations/stay-step2.svg'},
          {'title': 'Book Your Hotel', 'desc': 'Choose and book from recommended hotels', 'illustration': 'assets/images/illustrations/stay-step3.svg'},
        ];
    }
  }
}

class _PopularSpots extends StatelessWidget {
  final String locale;
  final void Function(Landmark) onSpotTap;

  const _PopularSpots({required this.locale, required this.onSpotTap});

  static const _spots = [
    {'slug': 'shibuya-crossing', 'name': '渋谷スクランブル交差点', 'nameEn': 'Shibuya Crossing', 'nameKo': '시부야 스크램블 교차로', 'lat': 35.6595, 'lng': 139.7004, 'region': 'kanto', 'image': 'shibuya-crossing'},
    {'slug': 'sensoji-temple', 'name': '浅草寺', 'nameEn': 'Sensoji Temple', 'nameKo': '센소지', 'lat': 35.7148, 'lng': 139.7967, 'region': 'kanto', 'image': 'asakusa-senso-ji'},
    {'slug': 'dotonbori', 'name': '道頓堀', 'nameEn': 'Dotonbori', 'nameKo': '도톤보리', 'lat': 34.6687, 'lng': 135.5013, 'region': 'kansai', 'image': 'dotonbori'},
    {'slug': 'fushimi-inari', 'name': '伏見稲荷大社', 'nameEn': 'Fushimi Inari Shrine', 'nameKo': '후시미이나리 신사', 'lat': 34.9671, 'lng': 135.7727, 'region': 'kansai', 'image': 'fushimi-inari-taisha'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(locale, ja: '人気スポット', ko: '인기 관광지', en: 'Popular Spots', zh: '热门景点', fr: 'Sites populaires'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: _spots.length,
          itemBuilder: (context, index) {
            final spot = _spots[index];
            final name = locale == 'ko'
                ? spot['nameKo'] as String
                : locale == 'ja'
                    ? spot['name'] as String
                    : spot['nameEn'] as String; // en, zh, fr
            final imageFile = spot['image'] as String;

            return GestureDetector(
              onTap: () => onSpotTap(Landmark(
                slug: spot['slug'] as String,
                name: spot['name'] as String,
                nameEn: spot['nameEn'] as String,
                lat: spot['lat'] as double,
                lng: spot['lng'] as double,
                region: spot['region'] as String,
              )),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/landmarks/$imageFile.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.place, size: 32),
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
                    // Name
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _KoreaBanner extends StatelessWidget {
  final String locale;
  final VoidCallback onTap;

  const _KoreaBanner({required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (locale == 'ko') return const SizedBox.shrink(); // Don't show for Korean users

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          gradient: LinearGradient(
            colors: AppTheme.isDark ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)] : [const Color(0xFFEFF6FF), const Color(0xFFEEF2FF)],
          ),
        ),
        child: Row(
          children: [
            // Korea flag emoji replacement
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🇰🇷', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(locale, ja: '韓国もサポート！', en: 'Korea Now Available!', zh: '韩国现已支持！', fr: 'Corée maintenant disponible !'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(locale, ja: 'ソウル・釜山のホテル検索ができます', en: 'Search hotels in Seoul & Busan', zh: '可搜索首尔·釜山的酒店', fr: 'Recherchez des hôtels à Séoul et Busan'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _JapanBanner extends StatelessWidget {
  final String locale;
  final VoidCallback onTap;

  const _JapanBanner({required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          gradient: LinearGradient(colors: AppTheme.isDark ? [const Color(0xFF2D1B1B), const Color(0xFF2D2418)] : [const Color(0xFFFEF2F2), const Color(0xFFFFF7ED)]),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('🇯🇵', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(locale, ja: '日本の旅行に戻る', ko: '일본 여행으로 돌아가기', en: 'Back to Japan', zh: '返回日本旅行', fr: 'Retour au Japon'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(tr(locale, ja: '東京・大阪のホテルと集合場所を探す', ko: '도쿄·오사카 호텔과 모임 장소', en: 'Hotels in Tokyo & Osaka', zh: '搜索东京·大阪的酒店和聚会地点', fr: 'Hôtels à Tokyo et Osaka'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground)),
          ])),
          Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.mutedForeground),
        ]),
      ),
    );
  }
}

class _KoreaHowItWorks extends StatelessWidget {
  final String locale;
  const _KoreaHowItWorks({required this.locale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = [
      {'title': tr(locale, ja: '韓国の観光地を入力', ko: '한국 관광지 입력', en: 'Enter Korea landmarks', zh: '输入韩国景点', fr: 'Entrez les sites coréens'),
       'desc': tr(locale, ja: 'ソウル・釜山の行きたいスポットを入力', ko: '서울·부산의 가고 싶은 관광지를 입력', en: 'Add Seoul/Busan spots', zh: '输入想去的首尔·釜山景点', fr: 'Ajoutez des sites à Séoul/Busan'),
       'illustration': 'assets/images/illustrations/korea-stay-step1.svg'},
      {'title': tr(locale, ja: 'ベストなエリアを提案', ko: '최적 지역 추천', en: 'Best area recommended', zh: '推荐最佳区域', fr: 'Meilleur quartier recommandé'),
       'desc': tr(locale, ja: 'すべての観光地にアクセスしやすいホテルエリアを算出', ko: '모든 관광지에 접근하기 좋은 호텔 지역을 계산', en: 'Hotel area closest to all spots', zh: '计算距所有景点最近的酒店区域', fr: 'Quartier hôtelier le plus proche de tous les sites'),
       'illustration': 'assets/images/illustrations/korea-stay-step2.svg'},
      {'title': tr(locale, ja: 'ホテルを予約', ko: '호텔 예약', en: 'Book hotel', zh: '预订酒店', fr: 'Réserver un hôtel'),
       'desc': tr(locale, ja: 'Agodaでそのまま予約', ko: 'Agoda에서 바로 예약', en: 'Book on Agoda', zh: '在Agoda上直接预订', fr: 'Réservez sur Agoda'),
       'illustration': 'assets/images/illustrations/stay-step3.svg'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(locale, ja: '使い方', ko: '이용 방법', en: 'How It Works', zh: '使用方法', fr: 'Comment ça marche'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((e) {
          final i = e.key;
          final step = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 48, height: 48,
                child: Center(child: SvgPicture.asset(step['illustration']!, width: 44, height: 44, fit: BoxFit.contain))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 24, height: 24,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                  const SizedBox(width: 8),
                  Flexible(child: Text(step['title']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 4),
                Padding(padding: const EdgeInsets.only(left: 32),
                  child: Text(step['desc']!, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground))),
              ])),
            ]),
          );
        }),
      ],
    );
  }
}

class _KoreaQuickPlans extends StatelessWidget {
  final String locale;
  final void Function(List<Landmark> landmarks, String region) onSelect;

  const _KoreaQuickPlans({required this.locale, required this.onSelect});

  static const _plans = [
    {'id': 'seoul-myeongdong', 'region': 'seoul', 'image': '/images/landmarks/myeongdong.webp',
     'title': {'ja': '明洞・景福宮・北村', 'ko': '명동・경복궁・북촌', 'en': 'Myeongdong · Gyeongbokgung · Bukchon', 'zh': '明洞・景福宫・北村', 'fr': 'Myeongdong · Gyeongbokgung · Bukchon'},
     'subtitle': {'ja': '初めての韓国旅行におすすめ', 'ko': '처음 서울 여행하는 분에게 추천', 'en': 'Perfect for first-time visitors', 'zh': '首次韩国旅行推荐', 'fr': 'Parfait pour une première visite'},
     'landmarks': [
       {'name': '明洞', 'nameKo': '명동', 'nameEn': 'Myeongdong', 'lat': 37.5609, 'lng': 126.9858, 'region': 'seoul'},
       {'name': '景福宮', 'nameKo': '경복궁', 'nameEn': 'Gyeongbokgung', 'lat': 37.5796, 'lng': 126.977, 'region': 'seoul'},
       {'name': '仁寺洞', 'nameKo': '인사동', 'nameEn': 'Insadong', 'lat': 37.5746, 'lng': 126.985, 'region': 'seoul'},
       {'name': 'Nソウルタワー', 'nameKo': 'N서울타워', 'nameEn': 'N Seoul Tower', 'lat': 37.5512, 'lng': 126.9882, 'region': 'seoul'},
       {'name': '東大門', 'nameKo': '동대문', 'nameEn': 'Dongdaemun', 'lat': 37.5709, 'lng': 127.0096, 'region': 'seoul'},
       {'name': '北村韓屋村', 'nameKo': '북촌한옥마을', 'nameEn': 'Bukchon Hanok Village', 'lat': 37.5827, 'lng': 126.9837, 'region': 'seoul'},
     ]},
    {'id': 'seoul-hongdae', 'region': 'seoul', 'image': '/images/landmarks/hongdae.webp',
     'title': {'ja': '弘大・延南洞・新村', 'ko': '홍대・연남동・신촌', 'en': 'Hongdae · Yeonnam · Sinchon', 'zh': '弘大・延南洞・新村', 'fr': 'Hongdae · Yeonnam · Sinchon'},
     'subtitle': {'ja': 'カフェ・ショッピング好きに', 'ko': '카페・쇼핑을 좋아하는 분에게', 'en': 'For café & shopping lovers', 'zh': '适合喜欢咖啡厅购物的人', 'fr': 'Pour les amateurs de cafés et shopping'},
     'landmarks': [
       {'name': '弘大', 'nameKo': '홍대', 'nameEn': 'Hongdae', 'lat': 37.5574, 'lng': 126.9248, 'region': 'seoul'},
       {'name': '延南洞', 'nameKo': '연남동', 'nameEn': 'Yeonnam-dong', 'lat': 37.5663, 'lng': 126.9238, 'region': 'seoul'},
       {'name': '新村', 'nameKo': '신촌', 'nameEn': 'Sinchon', 'lat': 37.5553, 'lng': 126.9366, 'region': 'seoul'},
       {'name': '梨大', 'nameKo': '이대', 'nameEn': 'Ewha', 'lat': 37.5568, 'lng': 126.9462, 'region': 'seoul'},
       {'name': '望遠', 'nameKo': '망원', 'nameEn': 'Mangwon', 'lat': 37.5562, 'lng': 126.9093, 'region': 'seoul'},
     ]},
    {'id': 'seoul-gangnam', 'region': 'seoul', 'image': '/images/landmarks/lotte-world.webp',
     'title': {'ja': '江南・COEX・ロッテタワー', 'ko': '강남・코엑스・롯데타워', 'en': 'Gangnam · COEX · Lotte Tower', 'zh': '江南・COEX・乐天塔', 'fr': 'Gangnam · COEX · Lotte Tower'},
     'subtitle': {'ja': 'K-POP・トレンド好きに', 'ko': 'K-POP・트렌드를 좋아하는 분에게', 'en': 'For K-pop & trend lovers', 'zh': '适合喜欢K-POP潮流的人', 'fr': 'Pour les fans de K-pop et tendances'},
     'landmarks': [
       {'name': '江南', 'nameKo': '강남', 'nameEn': 'Gangnam', 'lat': 37.4979, 'lng': 127.0276, 'region': 'seoul'},
       {'name': 'COEX', 'nameKo': '코엑스', 'nameEn': 'COEX', 'lat': 37.5116, 'lng': 127.0592, 'region': 'seoul'},
       {'name': '狎鷗亭', 'nameKo': '압구정', 'nameEn': 'Apgujeong', 'lat': 37.5271, 'lng': 127.0283, 'region': 'seoul'},
       {'name': 'ロッテワールドタワー', 'nameKo': '롯데월드타워', 'nameEn': 'Lotte World Tower', 'lat': 37.5112, 'lng': 127.0981, 'region': 'seoul'},
       {'name': 'カロスキル', 'nameKo': '가로수길', 'nameEn': 'Garosu-gil', 'lat': 37.5185, 'lng': 127.0234, 'region': 'seoul'},
     ]},
    {'id': 'seoul-culture', 'region': 'seoul', 'image': '/images/landmarks/insadong.webp',
     'title': {'ja': '昌徳宮・光化門・宗廟', 'ko': '창덕궁・광화문・종묘', 'en': 'Changdeokgung · Gwanghwamun · Jongmyo', 'zh': '昌德宫・光化门・宗庙', 'fr': 'Changdeokgung · Gwanghwamun · Jongmyo'},
     'subtitle': {'ja': '歴史と文化を楽しみたい方に', 'ko': '역사와 문화를 즐기고 싶은 분에게', 'en': 'For history & culture enthusiasts', 'zh': '适合喜欢历史文化的人', 'fr': 'Pour les passionnés d\'histoire et culture'},
     'landmarks': [
       {'name': '昌徳宮', 'nameKo': '창덕궁', 'nameEn': 'Changdeokgung', 'lat': 37.5792, 'lng': 126.991, 'region': 'seoul'},
       {'name': '光化門', 'nameKo': '광화문', 'nameEn': 'Gwanghwamun', 'lat': 37.5718, 'lng': 126.9769, 'region': 'seoul'},
       {'name': '宗廟', 'nameKo': '종묘', 'nameEn': 'Jongmyo', 'lat': 37.5742, 'lng': 126.9941, 'region': 'seoul'},
       {'name': '北村韓屋村', 'nameKo': '북촌한옥마을', 'nameEn': 'Bukchon Hanok Village', 'lat': 37.5827, 'lng': 126.9837, 'region': 'seoul'},
       {'name': '仁寺洞', 'nameKo': '인사동', 'nameEn': 'Insadong', 'lat': 37.5746, 'lng': 126.985, 'region': 'seoul'},
     ]},
    {'id': 'busan-beach', 'region': 'busan', 'image': '/images/landmarks/haeundae.webp',
     'title': {'ja': '海雲台・広安里・海東龍宮寺', 'ko': '해운대・광안리・해동용궁사', 'en': 'Haeundae · Gwangalli · Haedong Yonggungsa', 'zh': '海云台・广安里・海东龙宫寺', 'fr': 'Haeundae · Gwangalli · Haedong Yonggungsa'},
     'subtitle': {'ja': 'ビーチ・絶景を楽しみたい方に', 'ko': '바다・절경을 즐기고 싶은 분에게', 'en': 'For beach & scenic views', 'zh': '适合喜欢海滩绝景的人', 'fr': 'Pour les amateurs de plage et panoramas'},
     'landmarks': [
       {'name': '海雲台', 'nameKo': '해운대', 'nameEn': 'Haeundae', 'lat': 35.1588, 'lng': 129.1604, 'region': 'busan'},
       {'name': '広安里', 'nameKo': '광안리', 'nameEn': 'Gwangalli', 'lat': 35.1534, 'lng': 129.1187, 'region': 'busan'},
       {'name': 'センタムシティ', 'nameKo': '센텀시티', 'nameEn': 'Centum City', 'lat': 35.1696, 'lng': 129.1289, 'region': 'busan'},
       {'name': '海東龍宮寺', 'nameKo': '해동용궁사', 'nameEn': 'Haedong Yonggungsa', 'lat': 35.1884, 'lng': 129.2233, 'region': 'busan'},
     ]},
    {'id': 'busan-culture', 'region': 'busan', 'image': '/images/landmarks/gamcheon-culture-village.webp',
     'title': {'ja': '甘川文化村・南浦洞', 'ko': '감천문화마을・남포동', 'en': 'Gamcheon · Nampo-dong · Jagalchi', 'zh': '甘川文化村・南浦洞', 'fr': 'Gamcheon · Nampo-dong · Jagalchi'},
     'subtitle': {'ja': 'アートとローカル体験が好きな方に', 'ko': '아트와 로컬 체험을 좋아하는 분에게', 'en': 'For art & local experiences', 'zh': '适合喜欢艺术本地体验的人', 'fr': 'Pour l\'art et les expériences locales'},
     'landmarks': [
       {'name': '甘川文化村', 'nameKo': '감천문화마을', 'nameEn': 'Gamcheon Culture Village', 'lat': 35.0966, 'lng': 129.0105, 'region': 'busan'},
       {'name': '南浦洞', 'nameKo': '남포동', 'nameEn': 'Nampo-dong', 'lat': 35.0978, 'lng': 129.0267, 'region': 'busan'},
       {'name': 'チャガルチ市場', 'nameKo': '자갈치시장', 'nameEn': 'Jagalchi Market', 'lat': 35.0969, 'lng': 129.0306, 'region': 'busan'},
       {'name': '龍頭山公園', 'nameKo': '용두산공원', 'nameEn': 'Yongdusan Park', 'lat': 35.1006, 'lng': 129.0321, 'region': 'busan'},
       {'name': 'BIFF広場', 'nameKo': 'BIFF 광장', 'nameEn': 'BIFF Square', 'lat': 35.0989, 'lng': 129.0273, 'region': 'busan'},
     ]},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seoulPlans = _plans.where((p) => p['region'] == 'seoul').toList();
    final busanPlans = _plans.where((p) => p['region'] == 'busan').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(locale, ja: '人気プランですぐ検索', ko: '인기 플랜으로 바로 검색', en: 'Popular Plans', zh: '热门方案快速搜索', fr: 'Plans populaires'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(tr(locale, ja: 'タップするだけで最適なホテルエリアがわかります', ko: '탭하면 바로 최적의 호텔 지역을 찾아줍니다', en: 'Tap to find the best hotel area', zh: '点击即可找到最佳酒店区域', fr: 'Appuyez pour trouver le meilleur quartier hôtelier'),
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground)),
        const SizedBox(height: 16),

        // Seoul section
        _regionHeader(context, tr(locale, ja: 'ソウルの人気スポット', ko: '서울 인기 코스', en: 'Seoul', zh: '首尔热门景点', fr: 'Séoul')),
        const SizedBox(height: 8),
        ...seoulPlans.map((p) => _planCard(context, p)),

        const SizedBox(height: 16),
        // Busan section
        _regionHeader(context, tr(locale, ja: '釜山の人気スポット', ko: '부산 인기 코스', en: 'Busan', zh: '釜山热门景点', fr: 'Busan')),
        const SizedBox(height: 8),
        ...busanPlans.map((p) => _planCard(context, p)),
      ],
    );
  }

  Widget _regionHeader(BuildContext context, String title) {
    return Row(children: [
      Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _planCard(BuildContext context, Map<String, Object> plan) {
    final titleMap = plan['title'] as Map<String, String>;
    final subtitleMap = plan['subtitle'] as Map<String, String>;
    final title = titleMap[locale] ?? titleMap['en'] ?? '';
    final subtitle = subtitleMap[locale] ?? subtitleMap['en'] ?? '';
    final landmarkData = plan['landmarks'] as List<Map<String, Object>>;
    final region = plan['region'] as String;
    final image = plan['image'] as String?;
    final imageUrl = image != null ? 'https://norigo.app$image' : null;
    final ctaLabel = tr(locale, ja: 'ホテルを探す', ko: '호텔 찾기', en: 'Find Hotels', zh: '搜索酒店', fr: 'Trouver des hôtels');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          final landmarks = landmarkData.map((l) {
            final name = locale == 'ko' ? (l['nameKo'] as String? ?? l['nameEn'] as String? ?? l['name'] as String)
                : locale == 'ja' ? (l['name'] as String)
                : (l['nameEn'] as String? ?? l['name'] as String);
            return Landmark(slug: name, name: name, lat: l['lat'] as double, lng: l['lng'] as double, region: l['region'] as String);
          }).toList();
          onSelect(landmarks, region);
        },
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            // 16:9 image with gradient + title
            if (imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(fit: StackFit.expand, children: [
                  Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.muted, child: const Icon(Icons.place, size: 32))),
                  Container(decoration: const BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.center,
                    colors: [Colors.black54, Colors.transparent]))),
                  Positioned(bottom: 12, left: 12, right: 12,
                    child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black45)]))),
                ]),
              ),
            // Bottom bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Expanded(child: Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(ctaLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Shows recent trips as horizontal cards on the home screen
class _ContinuePlanningSection extends ConsumerWidget {
  final String locale;
  final TabSwitcher? onSwitchTab;
  const _ContinuePlanningSection({required this.locale, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripProvider);
    final recentTrips = state.trips.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final trips = recentTrips.take(3).toList();
    if (trips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flight_takeoff, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            tr(locale, ja: '旅行プラン', ko: '여행 플랜', en: 'My Trips', zh: '我的旅行', fr: 'Mes voyages'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => onSwitchTab?.call(3),
            child: Text(
              tr(locale, ja: 'すべて見る', ko: '전체 보기', en: 'View all', zh: '查看全部', fr: 'Voir tout'),
              style: TextStyle(fontSize: 12, color: AppTheme.primary),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final trip = trips[index];
              final items = state.items.where((i) => i.tripId == trip.id).toList();
              final heroSlug = items.isNotEmpty ? items.first.slug : null;
              const regionImages = {
                'kanto': '/images/landmarks/shibuya-crossing.webp',
                'kansai': '/images/landmarks/dotonbori.webp',
                'kyushu': '/images/landmarks/tenjin.webp',
                'seoul': '/images/landmarks/myeongdong.webp',
                'busan': '/images/landmarks/haeundae.webp',
              };
              final fallback = regionImages[items.isNotEmpty ? items.first.region : (trip.country == 'korea' ? 'seoul' : 'kanto')];
              final imageUrl = heroSlug != null
                  ? 'https://norigo.app/images/landmarks/$heroSlug.webp'
                  : (fallback != null ? 'https://norigo.app$fallback' : null);
              final spotNames = items.take(3).map((i) =>
                LandmarkLocalizer.getLocalizedName(locale: locale, slug: i.slug, name: i.name) ?? i.name
              ).join(' · ');

              return GestureDetector(
                onTap: () => onSwitchTab?.call(3),
                child: Container(
                  width: 180,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (imageUrl != null)
                      Image.network(imageUrl, height: 60, width: 180, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 60, color: AppTheme.primaryBg)),
                    if (imageUrl == null)
                      Container(height: 60, color: AppTheme.primaryBg),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(trip.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (spotNames.isNotEmpty)
                          Text(spotNames, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
