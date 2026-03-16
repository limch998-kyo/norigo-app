import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../models/landmark.dart';
import '../../config/theme.dart';
import 'widgets/quick_plan_cards.dart';

typedef TabSwitcher = void Function(int index);

class HomeScreen extends ConsumerWidget {
  final TabSwitcher? onSwitchTab;

  const HomeScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero Section ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBg,
                  theme.colorScheme.surface,
                ],
              ),
            ),
                child: Column(
                  children: [
                    Text(
                      l10n.homeTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.homeSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // CTA Buttons — ja: meetup primary, others: stay primary
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => onSwitchTab?.call(locale == 'ja' ? 2 : 1),
                            icon: Icon(locale == 'ja' ? Icons.groups : Icons.hotel, size: 18),
                            label: Text(locale == 'ja' ? l10n.meetupTitle : l10n.staySearchTitle),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onSwitchTab?.call(locale == 'ja' ? 1 : 2),
                            icon: Icon(locale == 'ja' ? Icons.hotel : Icons.groups, size: 18),
                            label: Text(locale == 'ja' ? l10n.staySearchTitle : l10n.meetupTitle),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),

          // ── Service Cards with illustrations ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: _ServiceCard(
                    icon: Icons.hotel_rounded,
                    label: l10n.staySearchTitle,
                    subtitle: locale == 'ja'
                        ? '観光地からホテルを探す'
                        : locale == 'ko'
                            ? '관광지에서 호텔 찾기'
                            : 'Find hotels near landmarks',
                    onTap: () => onSwitchTab?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceCard(
                    icon: Icons.groups_rounded,
                    label: l10n.meetupTitle,
                    subtitle: locale == 'ja'
                        ? 'みんなの中間地点'
                        : locale == 'ko'
                            ? '모두의 중간 지점'
                            : 'Find the middle point',
                    onTap: () => onSwitchTab?.call(2),
                  ),
                ),
              ],
            ),
          ),

          // ── How It Works (with step illustrations) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HowItWorks(locale: locale),
          ),
          const SizedBox(height: 32),

          // ── Quick Plans ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: QuickPlanCards(
              onPlanSelected: (planId, region, landmarks) {
                final notifier = ref.read(staySearchProvider.notifier);
                notifier.reset();
                for (final l in landmarks) {
                  notifier.addLandmark(l);
                }
                final checkIn = DateTime.now().add(const Duration(days: 30));
                final checkOut = checkIn.add(const Duration(days: 2));
                notifier.setDates(
                  checkIn.toIso8601String().substring(0, 10),
                  checkOut.toIso8601String().substring(0, 10),
                );
                onSwitchTab?.call(1);
                notifier.search();
              },
            ),
          ),
          const SizedBox(height: 32),

          // ── Popular Spots ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PopularSpots(locale: locale, onSpotTap: (landmark) {
              final notifier = ref.read(staySearchProvider.notifier);
              notifier.addLandmark(landmark);
              onSwitchTab?.call(1);
            }),
          ),
          const SizedBox(height: 24),

          // ── Korea Banner ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _KoreaBanner(locale: locale, onTap: () => onSwitchTab?.call(1)),
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
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: AppTheme.primary),
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
                // Step number badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    [Icons.edit_location_alt, Icons.auto_awesome, Icons.hotel][i],
                    size: 22,
                    color: AppTheme.primary,
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
          {'title': '観光地を入力', 'desc': '行きたい観光スポットを2つ以上入力'},
          {'title': 'AIが最適エリアを分析', 'desc': '全スポットへのアクセスが良いホテルエリアを算出'},
          {'title': 'ホテルを予約', 'desc': 'おすすめエリアからホテルを選んで予約'},
        ];
      case 'ko':
        return [
          {'title': '관광지 입력', 'desc': '가고 싶은 관광지를 2개 이상 입력'},
          {'title': 'AI가 최적 지역 분석', 'desc': '모든 관광지에 접근하기 좋은 호텔 지역 계산'},
          {'title': '호텔 예약', 'desc': '추천 지역에서 호텔을 골라 예약'},
        ];
      default:
        return [
          {'title': 'Enter Landmarks', 'desc': 'Add 2+ tourist spots you want to visit'},
          {'title': 'AI Finds Best Area', 'desc': 'We calculate the hotel area with best access to all spots'},
          {'title': 'Book Your Hotel', 'desc': 'Choose and book from recommended hotels'},
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
