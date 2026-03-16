import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../models/landmark.dart';
import 'widgets/quick_plan_cards.dart';

/// Callback to switch tabs from home screen
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
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
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
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.homeSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Service buttons
                Row(
                  children: [
                    Expanded(
                      child: _ServiceButton(
                        icon: Icons.hotel,
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
                      child: _ServiceButton(
                        icon: Icons.groups,
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
              ],
            ),
          ),

          // ── How It Works ──
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
          const SizedBox(height: 40),

          // ── Popular Spots ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PopularSpots(locale: locale, onSpotTap: (landmark) {
              final notifier = ref.read(staySearchProvider.notifier);
              notifier.addLandmark(landmark);
              onSwitchTab?.call(1);
            }),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceButton({
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
          border: Border.all(color: theme.colorScheme.outline),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: theme.colorScheme.primary),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['title']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(step['desc']!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
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
    {'slug': 'shibuya-crossing', 'name': '渋谷スクランブル交差点', 'nameEn': 'Shibuya Crossing', 'nameKo': '시부야 스크램블 교차로', 'lat': 35.6595, 'lng': 139.7004, 'region': 'kanto'},
    {'slug': 'sensoji-temple', 'name': '浅草寺', 'nameEn': 'Sensoji Temple', 'nameKo': '센소지', 'lat': 35.7148, 'lng': 139.7967, 'region': 'kanto'},
    {'slug': 'tokyo-tower', 'name': '東京タワー', 'nameEn': 'Tokyo Tower', 'nameKo': '도쿄 타워', 'lat': 35.6586, 'lng': 139.7454, 'region': 'kanto'},
    {'slug': 'dotonbori', 'name': '道頓堀', 'nameEn': 'Dotonbori', 'nameKo': '도톤보리', 'lat': 34.6687, 'lng': 135.5013, 'region': 'kansai'},
    {'slug': 'fushimi-inari', 'name': '伏見稲荷大社', 'nameEn': 'Fushimi Inari Shrine', 'nameKo': '후시미이나리 신사', 'lat': 34.9671, 'lng': 135.7727, 'region': 'kansai'},
    {'slug': 'myeongdong', 'name': '明洞', 'nameEn': 'Myeongdong', 'nameKo': '명동', 'lat': 37.5636, 'lng': 126.9869, 'region': 'seoul'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale == 'ja' ? '人気スポット' : locale == 'ko' ? '인기 관광지' : 'Popular Spots',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _spots.map((spot) {
            final name = locale == 'ko' ? spot['nameKo'] as String : locale == 'en' ? spot['nameEn'] as String : spot['name'] as String;
            return ActionChip(
              avatar: const Icon(Icons.place, size: 16),
              label: Text(name, style: const TextStyle(fontSize: 13)),
              onPressed: () => onSpotTap(Landmark(
                slug: spot['slug'] as String,
                name: spot['name'] as String,
                nameEn: spot['nameEn'] as String,
                lat: spot['lat'] as double,
                lng: spot['lng'] as double,
                region: spot['region'] as String,
              )),
            );
          }).toList(),
        ),
      ],
    );
  }
}
