import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../models/landmark.dart';
import '../../config/theme.dart';
import 'widgets/quick_plan_cards.dart';
import '../settings/settings_screen.dart';

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
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
                child: Column(
                  children: [
                    Text(
                      _koreaMode
                          ? (locale == 'ja' ? '韓国旅行、最適なホテルを見つけよう' : locale == 'ko' ? '한국 여행, 딱 좋은 호텔을 찾아줄게요' : 'Korea trip? Find the perfect hotel.')
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
                          ? (locale == 'ja' ? 'ソウル・釜山の観光地を入力するだけで、すべてに近い最適なホテルエリアを提案。' : locale == 'ko' ? '서울·부산의 관광지를 입력하면 최적의 호텔 지역을 추천합니다.' : 'Enter Seoul/Busan landmarks, we find the best hotel area.')
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
                                    ? (locale == 'ja' ? 'ソウルでホテルを探す' : locale == 'ko' ? '서울 호텔 찾기' : 'Seoul Hotels')
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
                                    ? (locale == 'ja' ? '釜山でホテルを探す' : locale == 'ko' ? '부산 호텔 찾기' : 'Busan Hotels')
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
                    subtitle: locale == 'ja'
                        ? 'みんなの中間地点'
                        : locale == 'ko'
                            ? '관광지에서 호텔 찾기'
                            : 'Find hotels near landmarks',
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
                    subtitle: locale == 'ja'
                        ? '観光地からホテルを探す'
                        : locale == 'ko'
                            ? '모두의 중간 지점'
                            : 'Find the middle point',
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

          // ── Quick Plans ──
          if (!_koreaMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickPlanCards(
                onPlanSelected: (planId, region, landmarks) {
                  final notifier = ref.read(staySearchProvider.notifier);
                  notifier.reset();
                  for (final l in landmarks) {
                    notifier.addLandmark(l);
                  }
                  notifier.setRegion(region);
                  final budget = locale == 'ja' ? 'under20000' : locale == 'ko' ? 'under30000' : 'under50000';
                  notifier.setBudget(budget);
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
                for (final l in landmarks) { notifier.addLandmark(l); }
                notifier.setRegion(region);
                notifier.setBudget('under35000');
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
              final notifier = ref.read(staySearchProvider.notifier);
              notifier.addLandmark(landmark);
              if (_koreaMode) notifier.setRegion(landmark.region);
              onSwitchTab?.call(1);
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
                  '© 2024 Norigo. All rights reserved.',
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
          locale == 'ja' ? '使い方' : locale == 'ko' ? '이용 방법' : 'How It Works',
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
          locale == 'ja' ? '人気スポット' : locale == 'ko' ? '인기 관광지' : 'Popular Spots',
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
                : locale == 'en'
                    ? spot['nameEn'] as String
                    : spot['name'] as String;
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
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)], // blue-50 to indigo-50
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
                    locale == 'ja' ? '韓国もサポート！' : 'Korea Now Available!',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locale == 'ja'
                        ? 'ソウル・釜山のホテル検索ができます'
                        : 'Search hotels in Seoul & Busan',
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
          gradient: const LinearGradient(colors: [Color(0xFFFEF2F2), Color(0xFFFFF7ED)]),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('🇯🇵', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(locale == 'ja' ? '日本の旅行に戻る' : locale == 'ko' ? '일본 여행으로 돌아가기' : 'Back to Japan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(locale == 'ja' ? '東京・大阪のホテルと集合場所を探す' : locale == 'ko' ? '도쿄·오사카 호텔과 모임 장소' : 'Hotels in Tokyo & Osaka',
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
      {'title': locale == 'ja' ? '韓国の観光地を入力' : locale == 'ko' ? '한국 관광지 입력' : 'Enter Korea landmarks',
       'desc': locale == 'ja' ? 'ソウル・釜山の行きたいスポットを入力' : locale == 'ko' ? '서울·부산의 가고 싶은 관광지를 입력' : 'Add Seoul/Busan spots you want to visit',
       'icon': Icons.edit_location_alt},
      {'title': locale == 'ja' ? 'ベストなエリアを提案' : locale == 'ko' ? '최적 지역 추천' : 'Best area recommended',
       'desc': locale == 'ja' ? 'すべての観光地にアクセスしやすいホテルエリアを算出' : locale == 'ko' ? '모든 관광지에 접근하기 좋은 호텔 지역을 계산' : 'We find the hotel area closest to all spots',
       'icon': Icons.auto_awesome},
      {'title': locale == 'ja' ? 'ホテルを予約' : locale == 'ko' ? '호텔 예약' : 'Book hotel',
       'desc': locale == 'ja' ? 'Agodaでそのまま予約。韓国ウォンで表示。' : locale == 'ko' ? 'Agoda에서 바로 예약. 원화로 표시.' : 'Book on Agoda with local currency.',
       'icon': Icons.hotel},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(locale == 'ja' ? '使い方' : locale == 'ko' ? '이용 방법' : 'How It Works',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.3)),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((e) {
          final i = e.key;
          final step = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: Icon(step['icon'] as IconData, size: 22, color: AppTheme.primary)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 24, height: 24,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                  const SizedBox(width: 8),
                  Text(step['title'] as String, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Padding(padding: const EdgeInsets.only(left: 32),
                  child: Text(step['desc'] as String, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.mutedForeground))),
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
    {'id': 'seoul-classic', 'region': 'seoul', 'image': '/images/landmarks/myeongdong.webp',
     'title': {'ja': '明洞・景福宮・弘大', 'ko': '명동·경복궁·홍대', 'en': 'Myeongdong · Gyeongbokgung · Hongdae'},
     'subtitle': {'ja': 'ソウル定番コース', 'ko': '서울 핵심 코스', 'en': 'Classic Seoul'},
     'landmarks': [
       {'name': '明洞', 'nameKo': '명동', 'lat': 37.5609, 'lng': 126.9858, 'region': 'seoul'},
       {'name': '景福宮', 'nameKo': '경복궁', 'lat': 37.5796, 'lng': 126.977, 'region': 'seoul'},
       {'name': '弘大', 'nameKo': '홍대', 'lat': 37.5574, 'lng': 126.9248, 'region': 'seoul'},
     ]},
    {'id': 'seoul-trend', 'region': 'seoul', 'image': '/images/landmarks/lotte-world.webp',
     'title': {'ja': '江南・梨泰院・ロッテタワー', 'ko': '강남·이태원·롯데타워', 'en': 'Gangnam · Itaewon · Lotte Tower'},
     'subtitle': {'ja': 'トレンド＆ショッピング', 'ko': '트렌드 & 쇼핑', 'en': 'Trend & Shopping'},
     'landmarks': [
       {'name': '江南', 'nameKo': '강남', 'lat': 37.4979, 'lng': 127.0276, 'region': 'seoul'},
       {'name': '梨泰院', 'nameKo': '이태원', 'lat': 37.5344, 'lng': 126.9946, 'region': 'seoul'},
       {'name': 'ロッテワールドタワー', 'nameKo': '롯데월드타워', 'lat': 37.5126, 'lng': 127.1025, 'region': 'seoul'},
     ]},
    {'id': 'seoul-culture', 'region': 'seoul', 'image': '/images/landmarks/insadong.webp',
     'title': {'ja': '仁寺洞・北村・Nタワー', 'ko': '인사동·북촌·N타워', 'en': 'Insadong · Bukchon · N Tower'},
     'subtitle': {'ja': '歴史＆文化', 'ko': '역사 & 문화', 'en': 'History & Culture'},
     'landmarks': [
       {'name': '仁寺洞', 'nameKo': '인사동', 'lat': 37.5746, 'lng': 126.985, 'region': 'seoul'},
       {'name': '北村韓屋村', 'nameKo': '북촌한옥마을', 'lat': 37.5826, 'lng': 126.9849, 'region': 'seoul'},
       {'name': 'Nソウルタワー', 'nameKo': 'N서울타워', 'lat': 37.5512, 'lng': 126.9882, 'region': 'seoul'},
     ]},
    {'id': 'busan-classic', 'region': 'busan', 'image': '/images/landmarks/haeundae.webp',
     'title': {'ja': '海雲台・広安里・西面', 'ko': '해운대·광안리·서면', 'en': 'Haeundae · Gwangalli · Seomyeon'},
     'subtitle': {'ja': '釜山ビーチ＆グルメ', 'ko': '부산 해변 & 먹거리', 'en': 'Busan Beach & Food'},
     'landmarks': [
       {'name': '海雲台', 'nameKo': '해운대', 'lat': 35.1588, 'lng': 129.1604, 'region': 'busan'},
       {'name': '広安里', 'nameKo': '광안리', 'lat': 35.1534, 'lng': 129.1187, 'region': 'busan'},
       {'name': '西面', 'nameKo': '서면', 'lat': 35.1579, 'lng': 129.0596, 'region': 'busan'},
     ]},
    {'id': 'busan-culture', 'region': 'busan', 'image': '/images/landmarks/gamcheon-culture-village.webp',
     'title': {'ja': '甘川文化村・南浦洞', 'ko': '감천문화마을·남포동', 'en': 'Gamcheon · Nampo-dong'},
     'subtitle': {'ja': 'アート＆ローカル', 'ko': '예술 & 로컬', 'en': 'Art & Local'},
     'landmarks': [
       {'name': '甘川文化村', 'nameKo': '감천문화마을', 'lat': 35.0966, 'lng': 129.0105, 'region': 'busan'},
       {'name': '南浦洞', 'nameKo': '남포동', 'lat': 35.0978, 'lng': 129.0267, 'region': 'busan'},
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
        Text(locale == 'ja' ? '人気プランですぐ検索' : locale == 'ko' ? '인기 플랜으로 바로 검색' : 'Popular Plans',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(locale == 'ja' ? 'タップするだけで最適なホテルエリアがわかります' : locale == 'ko' ? '탭하면 바로 최적의 호텔 지역을 찾아줍니다' : 'Tap to find the best hotel area',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.mutedForeground)),
        const SizedBox(height: 16),

        // Seoul section
        _regionHeader(context, locale == 'ja' ? 'ソウルの人気スポット' : locale == 'ko' ? '서울 인기 코스' : 'Seoul'),
        const SizedBox(height: 8),
        ...seoulPlans.map((p) => _planCard(context, p)),

        const SizedBox(height: 16),
        // Busan section
        _regionHeader(context, locale == 'ja' ? '釜山の人気スポット' : locale == 'ko' ? '부산 인기 코스' : 'Busan'),
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
    final ctaLabel = locale == 'ja' ? 'ホテルを探す' : locale == 'ko' ? '호텔 찾기' : 'Find Hotels';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          final landmarks = landmarkData.map((l) {
            final name = locale == 'ko' ? (l['nameKo'] as String? ?? l['name'] as String) : l['name'] as String;
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
