import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/landmark.dart';
import '../../config/theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/stay_provider.dart';
import '../../widgets/landmark_input_list.dart';
import '../../widgets/mode_selector.dart';
import '../../config/constants.dart';

class StaySearchScreen extends ConsumerStatefulWidget {
  const StaySearchScreen({super.key});

  @override
  ConsumerState<StaySearchScreen> createState() => _StaySearchScreenState();
}

class _StaySearchScreenState extends ConsumerState<StaySearchScreen> {
  late DateTime _checkIn;
  late DateTime _checkOut;

  @override
  void initState() {
    super.initState();
    // Default: 1 month from now, 3 nights
    _checkIn = DateTime.now().add(const Duration(days: 30));
    _checkOut = _checkIn.add(const Duration(days: 3));

    // Set dates in provider after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(staySearchProvider.notifier);
      final state = ref.read(staySearchProvider);
      if (state.checkIn == null) {
        notifier.setDates(
          _checkIn.toIso8601String().substring(0, 10),
          _checkOut.toIso8601String().substring(0, 10),
        );
      } else {
        _checkIn = DateTime.parse(state.checkIn!);
        _checkOut = DateTime.parse(state.checkOut!);
      }
    });
  }

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut.isBefore(picked)) {
          _checkOut = picked.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
      }
    });

    ref.read(staySearchProvider.notifier).setDates(
      _checkIn.toIso8601String().substring(0, 10),
      _checkOut.toIso8601String().substring(0, 10),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final state = ref.watch(staySearchProvider);
    final notifier = ref.read(staySearchProvider.notifier);
    final api = ref.read(apiClientProvider);
    final theme = Theme.of(context);

    final isKorea = AppConstants.koreaRegions.contains(state.region);
    final budgets = isKorea
        ? AppConstants.hotelBudgetsKorea
        : AppConstants.hotelBudgetsJapan;

    // ja locale: show Korea regions first (since ja users are tourists visiting Korea)
    // others: show Japan regions first
    final regionOrder = locale == 'ja'
        ? ['seoul', 'busan', 'kanto', 'kansai']
        : AppConstants.allRegions;

    final landmarkSlots = state.slots;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staySearchTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Region selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: regionOrder.map((region) {
                  final isSelected = state.region == region;
                  final label = _regionLabel(region, locale);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => notifier.setRegion(region),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Landmark input (2 empty fields by default)
            Text(
              l10n.addLandmarks,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            LandmarkInputList(
              landmarks: landmarkSlots,
              onSearch: (q) => api.searchLandmarks(q, region: state.region, locale: locale),
              onSelect: (index, landmark) => notifier.setLandmark(index, landmark),
              onRemove: (index) => notifier.removeSlot(index),
              onAdd: () => notifier.addSlot(),
              locale: locale,
            ),
            const SizedBox(height: 8),

            // Suggestion chips (popular landmarks per region)
            _SuggestionChips(
              region: state.region,
              locale: locale,
              filledNames: state.landmarks.map((l) => l.name).toSet(),
              onSelect: (landmark) => notifier.addLandmark(landmark),
            ),
            // Quick Plans (shown when no landmarks selected)
            if (state.landmarks.isEmpty) ...[
              const SizedBox(height: 16),
              _QuickSearchPlans(
                region: state.region,
                locale: locale,
                onSelect: (landmarks, region) {
                  for (final l in landmarks) {
                    notifier.addLandmark(l);
                  }
                  notifier.setRegion(region);
                },
              ),
            ],
            const SizedBox(height: 20),

            // Mode selector
            Text(
              locale == 'ja' ? '検索モード' : locale == 'ko' ? '검색 모드' : 'Search mode',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ModeSelector(
              selected: state.mode,
              onChanged: (m) => notifier.setMode(m),
              locale: locale,
            ),
            const SizedBox(height: 20),

            // Date selection
            Text(
              locale == 'ja' ? '日程' : locale == 'ko' ? '일정' : 'Dates',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _formatDate(_checkIn),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _formatDate(_checkOut),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Budget selector
            Text(
              locale == 'ja' ? '予算' : locale == 'ko' ? '예산' : 'Budget',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: budgets.entries.map((entry) {
                final isSelected = state.maxBudget == entry.key;
                return ChoiceChip(
                  label: Text(entry.value[locale] ?? entry.value['en']!, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) => notifier.setBudget(selected ? entry.key : null),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Search button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: state.landmarks.length < 2 || state.isLoading
                    ? null
                    : () => notifier.search(),
                child: state.isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.searchButton),
              ),
            ),

            if (state.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(state.error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],

            // Popular spot cards (always visible below search)
            const SizedBox(height: 24),
            _PopularSpotCards(
              region: state.region,
              locale: locale,
              onSelect: (landmark) => notifier.addLandmark(landmark),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _regionLabel(String region, String locale) {
    const labels = {
      'kanto': {'ja': '東京・関東', 'en': 'Tokyo / Kanto', 'ko': '도쿄 / 간토', 'zh': '东京 / 关东'},
      'kansai': {'ja': '大阪・関西', 'en': 'Osaka / Kansai', 'ko': '오사카 / 간사이', 'zh': '大阪 / 关西'},
      'seoul': {'ja': 'ソウル', 'en': 'Seoul', 'ko': '서울', 'zh': '首尔'},
      'busan': {'ja': '釜山', 'en': 'Busan', 'ko': '부산', 'zh': '釜山'},
    };
    return labels[region]?[locale] ?? labels[region]?['en'] ?? region;
  }
}

class _PopularSpotCards extends StatelessWidget {
  final String region;
  final String locale;
  final void Function(Landmark) onSelect;

  const _PopularSpotCards({required this.region, required this.locale, required this.onSelect});

  static const _spots = {
    'kanto': [
      {'slug': 'shibuya', 'name': '渋谷スクランブル交差点', 'nameKo': '시부야 스크램블 교차로', 'nameEn': 'Shibuya Crossing', 'lat': 35.6595, 'lng': 139.7004, 'image': 'shibuya-crossing'},
      {'slug': 'asakusa', 'name': '浅草寺', 'nameKo': '센소지', 'nameEn': 'Sensoji Temple', 'lat': 35.7148, 'lng': 139.7967, 'image': 'asakusa-senso-ji'},
      {'slug': 'odaiba', 'name': 'お台場', 'nameKo': '오다이바', 'nameEn': 'Odaiba', 'lat': 35.6268, 'lng': 139.7753, 'image': 'odaiba'},
    ],
    'kansai': [
      {'slug': 'dotonbori', 'name': '道頓堀', 'nameKo': '도톤보리', 'nameEn': 'Dotonbori', 'lat': 34.6687, 'lng': 135.5013, 'image': 'dotonbori'},
      {'slug': 'fushimi', 'name': '伏見稲荷大社', 'nameKo': '후시미이나리 신사', 'nameEn': 'Fushimi Inari', 'lat': 34.9671, 'lng': 135.7727, 'image': 'fushimi-inari-taisha'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final spots = _spots[region];
    if (spots == null || spots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale == 'ja' ? '人気スポット' : locale == 'ko' ? '인기 관광지' : 'Popular Spots',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: spots.length,
          itemBuilder: (context, index) {
            final spot = spots[index];
            final name = locale == 'ko' ? spot['nameKo'] as String
                : locale == 'en' ? spot['nameEn'] as String
                : spot['name'] as String;
            final imageFile = spot['image'] as String;

            return GestureDetector(
              onTap: () => onSelect(Landmark(
                slug: spot['slug'] as String,
                name: name,
                lat: spot['lat'] as double,
                lng: spot['lng'] as double,
                region: region,
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
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.muted, child: const Icon(Icons.place, size: 32)),
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
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black45)]), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
                            child: Text('+ ${locale == 'ja' ? '追加' : locale == 'ko' ? '추가' : 'Add'}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                          ),
                        ],
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

class _QuickSearchPlans extends StatelessWidget {
  final String region;
  final String locale;
  final void Function(List<Landmark> landmarks, String region) onSelect;

  const _QuickSearchPlans({required this.region, required this.locale, required this.onSelect});

  static const _plans = {
    'kanto': [
      {'title': {'ja': '渋谷・原宿・新宿', 'ko': '시부야・하라주쿠・신주쿠', 'en': 'Shibuya · Harajuku · Shinjuku'},
       'landmarks': [
         {'name': '渋谷', 'nameKo': '시부야', 'lat': 35.6595, 'lng': 139.7004},
         {'name': '原宿', 'nameKo': '하라주쿠', 'lat': 35.6702, 'lng': 139.7026},
         {'name': '新宿', 'nameKo': '신주쿠', 'lat': 35.6938, 'lng': 139.7034},
       ]},
      {'title': {'ja': '浅草・上野・東京駅', 'ko': '아사쿠사・우에노・도쿄역', 'en': 'Asakusa · Ueno · Tokyo'},
       'landmarks': [
         {'name': '浅草', 'nameKo': '아사쿠사', 'lat': 35.7148, 'lng': 139.7967},
         {'name': '上野', 'nameKo': '우에노', 'lat': 35.7146, 'lng': 139.7714},
         {'name': '東京駅', 'nameKo': '도쿄역', 'lat': 35.6812, 'lng': 139.7671},
       ]},
    ],
    'kansai': [
      {'title': {'ja': '道頓堀・なんば・心斎橋', 'ko': '도톤보리・난바・신사이바시', 'en': 'Dotonbori · Namba'},
       'landmarks': [
         {'name': '道頓堀', 'nameKo': '도톤보리', 'lat': 34.6687, 'lng': 135.5013},
         {'name': 'なんば', 'nameKo': '난바', 'lat': 34.6659, 'lng': 135.5013},
         {'name': '心斎橋', 'nameKo': '신사이바시', 'lat': 34.6748, 'lng': 135.5016},
       ]},
    ],
    'seoul': [
      {'title': {'ja': '明洞・弘大・江南', 'ko': '명동・홍대・강남', 'en': 'Myeongdong · Hongdae · Gangnam'},
       'landmarks': [
         {'name': '明洞', 'nameKo': '명동', 'lat': 37.5636, 'lng': 126.9869},
         {'name': '弘大', 'nameKo': '홍대', 'lat': 37.5563, 'lng': 126.9237},
         {'name': '江南', 'nameKo': '강남', 'lat': 37.4979, 'lng': 127.0276},
       ]},
    ],
    'busan': [
      {'title': {'ja': '海雲台・広安里・南浦', 'ko': '해운대・광안리・남포동', 'en': 'Haeundae · Gwangalli'},
       'landmarks': [
         {'name': '海雲台', 'nameKo': '해운대', 'lat': 35.1586, 'lng': 129.1604},
         {'name': '広安里', 'nameKo': '광안리', 'lat': 35.1532, 'lng': 129.1187},
         {'name': '南浦', 'nameKo': '남포동', 'lat': 35.0975, 'lng': 129.0326},
       ]},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final plans = _plans[region];
    if (plans == null || plans.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale == 'ja' ? '人気プランで検索' : locale == 'ko' ? '인기 플랜으로 검색' : 'Quick search plans',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.mutedForeground),
        ),
        const SizedBox(height: 8),
        ...plans.map((plan) {
          final titleMap = plan['title'] as Map<String, String>;
          final title = titleMap[locale] ?? titleMap['en'] ?? '';
          final landmarkData = plan['landmarks'] as List<Map<String, Object>>;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                final landmarks = landmarkData.map((l) {
                  final name = locale == 'ko' ? (l['nameKo'] as String? ?? l['name'] as String) : l['name'] as String;
                  return Landmark(
                    slug: name,
                    name: name,
                    lat: l['lat'] as double,
                    lng: l['lng'] as double,
                    region: region,
                  );
                }).toList();
                onSelect(landmarks, region);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.mutedForeground),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final String region;
  final String locale;
  final Set<String> filledNames;
  final void Function(Landmark) onSelect;

  const _SuggestionChips({required this.region, required this.locale, required this.filledNames, required this.onSelect});

  static const _popularByRegion = {
    'kanto': [
      {'slug': 'shibuya-crossing', 'name': '渋谷', 'nameKo': '시부야', 'nameEn': 'Shibuya', 'lat': 35.6595, 'lng': 139.7004},
      {'slug': 'shinjuku', 'name': '新宿', 'nameKo': '신주쿠', 'nameEn': 'Shinjuku', 'lat': 35.6938, 'lng': 139.7034},
      {'slug': 'asakusa', 'name': '浅草', 'nameKo': '아사쿠사', 'nameEn': 'Asakusa', 'lat': 35.7148, 'lng': 139.7967},
      {'slug': 'harajuku', 'name': '原宿', 'nameKo': '하라주쿠', 'nameEn': 'Harajuku', 'lat': 35.6702, 'lng': 139.7026},
      {'slug': 'ikebukuro', 'name': '池袋', 'nameKo': '이케부쿠로', 'nameEn': 'Ikebukuro', 'lat': 35.7295, 'lng': 139.7109},
      {'slug': 'tokyo-tower', 'name': '東京タワー', 'nameKo': '도쿄타워', 'nameEn': 'Tokyo Tower', 'lat': 35.6586, 'lng': 139.7454},
      {'slug': 'akihabara', 'name': '秋葉原', 'nameKo': '아키하바라', 'nameEn': 'Akihabara', 'lat': 35.6984, 'lng': 139.7731},
      {'slug': 'ueno', 'name': '上野', 'nameKo': '우에노', 'nameEn': 'Ueno', 'lat': 35.7146, 'lng': 139.7714},
    ],
    'kansai': [
      {'slug': 'dotonbori', 'name': '道頓堀', 'nameKo': '도톤보리', 'nameEn': 'Dotonbori', 'lat': 34.6687, 'lng': 135.5013},
      {'slug': 'kiyomizu', 'name': '清水寺', 'nameKo': '기요미즈데라', 'nameEn': 'Kiyomizu-dera', 'lat': 34.9949, 'lng': 135.7850},
      {'slug': 'fushimi-inari', 'name': '伏見稲荷', 'nameKo': '후시미이나리', 'nameEn': 'Fushimi Inari', 'lat': 34.9671, 'lng': 135.7727},
      {'slug': 'namba', 'name': 'なんば', 'nameKo': '난바', 'nameEn': 'Namba', 'lat': 34.6659, 'lng': 135.5013},
      {'slug': 'umeda', 'name': '梅田', 'nameKo': '우메다', 'nameEn': 'Umeda', 'lat': 34.7024, 'lng': 135.4959},
      {'slug': 'arashiyama', 'name': '嵐山', 'nameKo': '아라시야마', 'nameEn': 'Arashiyama', 'lat': 35.0094, 'lng': 135.6672},
    ],
    'seoul': [
      {'slug': 'myeongdong', 'name': '明洞', 'nameKo': '명동', 'nameEn': 'Myeongdong', 'lat': 37.5636, 'lng': 126.9869},
      {'slug': 'hongdae', 'name': '弘大', 'nameKo': '홍대', 'nameEn': 'Hongdae', 'lat': 37.5563, 'lng': 126.9237},
      {'slug': 'gangnam', 'name': '江南', 'nameKo': '강남', 'nameEn': 'Gangnam', 'lat': 37.4979, 'lng': 127.0276},
      {'slug': 'itaewon', 'name': '梨泰院', 'nameKo': '이태원', 'nameEn': 'Itaewon', 'lat': 37.5345, 'lng': 126.9946},
      {'slug': 'insadong', 'name': '仁寺洞', 'nameKo': '인사동', 'nameEn': 'Insadong', 'lat': 37.5742, 'lng': 126.9857},
      {'slug': 'dongdaemun', 'name': '東大門', 'nameKo': '동대문', 'nameEn': 'Dongdaemun', 'lat': 37.5712, 'lng': 127.0091},
    ],
    'busan': [
      {'slug': 'haeundae', 'name': '海雲台', 'nameKo': '해운대', 'nameEn': 'Haeundae', 'lat': 35.1586, 'lng': 129.1604},
      {'slug': 'gwangalli', 'name': '広安里', 'nameKo': '광안리', 'nameEn': 'Gwangalli', 'lat': 35.1532, 'lng': 129.1187},
      {'slug': 'nampo', 'name': '南浦', 'nameKo': '남포동', 'nameEn': 'Nampo-dong', 'lat': 35.0975, 'lng': 129.0326},
      {'slug': 'seomyeon', 'name': '西面', 'nameKo': '서면', 'nameEn': 'Seomyeon', 'lat': 35.1577, 'lng': 129.0596},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final spots = _popularByRegion[region] ?? [];
    final suggestions = spots.where((s) {
      final name = _getName(s);
      return !filledNames.contains(name);
    }).take(8).toList();

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: suggestions.map((s) {
        final name = _getName(s);
        return GestureDetector(
          onTap: () => onSelect(Landmark(
            slug: s['slug'] as String,
            name: name,
            lat: s['lat'] as double,
            lng: s['lng'] as double,
            region: region,
          )),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(name, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
          ),
        );
      }).toList(),
    );
  }

  String _getName(Map<String, Object> spot) {
    switch (locale) {
      case 'ko': return spot['nameKo'] as String? ?? spot['name'] as String;
      case 'en': return spot['nameEn'] as String? ?? spot['name'] as String;
      default: return spot['name'] as String;
    }
  }
}
