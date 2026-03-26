import 'dart:math';
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
import '../spot/spot_detail_screen.dart';
import '../../services/landmark_localizer.dart';
import '../../utils/tr.dart';

class StaySearchScreen extends ConsumerStatefulWidget {
  const StaySearchScreen({super.key});

  @override
  ConsumerState<StaySearchScreen> createState() => _StaySearchScreenState();
}

class _StaySearchScreenState extends ConsumerState<StaySearchScreen> {
  String _stayStyle = 'auto'; // auto = let API decide

  @override
  void initState() {
    super.initState();
    // Set defaults in provider after build (only if not already set)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(staySearchProvider.notifier);
      final state = ref.read(staySearchProvider);
      if (state.checkIn == null) {
        // Default: +7 days check-in, +2 nights (matching web's defaultDates)
        final checkIn = DateTime.now().add(const Duration(days: 30));
        notifier.setDates(
          checkIn.toIso8601String().substring(0, 10),
          checkIn.add(const Duration(days: 3)).toIso8601String().substring(0, 10),
        );
      }
      if (state.maxBudget == null) {
        notifier.setBudget('10000-30000');
      }
    });
  }

  DateTime get _checkIn {
    final ci = ref.read(staySearchProvider).checkIn;
    return ci != null ? DateTime.parse(ci) : DateTime.now().add(const Duration(days: 30));
  }

  DateTime get _checkOut {
    final co = ref.read(staySearchProvider).checkOut;
    return co != null ? DateTime.parse(co) : _checkIn.add(const Duration(days: 3));
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

    final notifier = ref.read(staySearchProvider.notifier);
    final pickedStr = picked.toIso8601String().substring(0, 10);

    if (isCheckIn) {
      final newCheckOut = _checkOut.isBefore(picked)
          ? picked.add(const Duration(days: 1)).toIso8601String().substring(0, 10)
          : _checkOut.toIso8601String().substring(0, 10);
      notifier.setDates(pickedStr, newCheckOut);
    } else {
      notifier.setDates(_checkIn.toIso8601String().substring(0, 10), pickedStr);
    }
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

    final stayBudgets = AppConstants.getStayBudgets(state.region);

    // ja locale: show Korea regions first (since ja users are tourists visiting Korea)
    // others: show Japan regions first
    final regionOrder = locale == 'ja'
        ? ['seoul', 'busan', 'kanto', 'kansai', 'kyushu']
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
              filledSlugs: state.landmarks.map((l) => l.slug).toSet(),
              onSelect: (landmark) => notifier.addLandmark(landmark),
            ),
            // Quick Plans (shown when no landmarks selected)
            if (state.landmarks.isEmpty) ...[
              const SizedBox(height: 16),
              _QuickSearchPlans(
                region: state.region,
                locale: locale,
                onSelect: (landmarks, region) {
                  // Set region FIRST, then add landmarks (setRegion restores cached slots)
                  notifier.setRegion(region);
                  for (final l in landmarks) {
                    notifier.addLandmark(l);
                  }
                  // Auto-set budget based on region (matching web defaults)
                  final isKorea = ['seoul', 'busan'].contains(region);
                  final budget = isKorea ? '25000-35000' : '10000-30000';
                  notifier.setBudget(budget);
                },
              ),
            ],
            const SizedBox(height: 20),

            // Mode selector
            Text(
              tr(locale, ja: '検索モード', ko: '검색 모드', en: 'Search mode', zh: '搜索模式', fr: 'Mode de recherche'),
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
              tr(locale, ja: '日程', ko: '일정', en: 'Dates', zh: '日期', fr: 'Dates'),
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
            // Stay style toggle (3+ landmarks)
            if (state.landmarks.length >= 3) ...[
              const SizedBox(height: 20),
              Text(
                tr(locale, ja: '宿泊スタイル', ko: '숙박 스타일', en: 'Stay style', zh: '住宿方式', fr: 'Style de séjour'),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _StayStyleToggle(
                locale: locale,
                isSplit: _stayStyle == 'split',
                onChanged: (split) => setState(() => _stayStyle = split ? 'split' : 'single'),
                landmarks: state.landmarks,
              ),
            ],
            const SizedBox(height: 20),

            // Budget selector
            Row(children: [
              Text(
                tr(locale, ja: '予算', ko: '예산', en: 'Budget', zh: '预算', fr: 'Budget'),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              Text(
                tr(locale, ja: '（1泊あたり）', ko: '(1박 기준)', en: '(per night)', zh: '（每晚）', fr: '(par nuit)'),
                style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stayBudgets.map((budget) {
                final isSelected = state.maxBudget == budget;
                final label = AppConstants.stayBudgetLabels[budget]?[locale]
                    ?? AppConstants.stayBudgetLabels[budget]?['en'] ?? budget;
                return ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onSelected: (selected) => notifier.setBudget(selected ? budget : 'any'),
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
                    : () {
                        notifier.setStayStyle(_stayStyle);
                        notifier.search();
                      },
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

            // Popular spot cards (hide already-added, matching web)
            const SizedBox(height: 24),
            _PopularSpotCards(
              region: state.region,
              locale: locale,
              filledSlugs: state.landmarks.map((l) => l.slug).toSet(),
              filledLandmarks: state.landmarks,
              onSelect: (landmark) => notifier.addLandmark(landmark),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _regionLabel(String region, String locale) {
    switch (region) {
      case 'kanto': return tr(locale, ja: '東京・関東', en: 'Tokyo / Kanto', ko: '도쿄 / 간토', zh: '东京 / 关东', fr: 'Tokyo / Kanto');
      case 'kansai': return tr(locale, ja: '大阪・関西', en: 'Osaka / Kansai', ko: '오사카 / 간사이', zh: '大阪 / 关西', fr: 'Osaka / Kansai');
      case 'seoul': return tr(locale, ja: 'ソウル', en: 'Seoul', ko: '서울', zh: '首尔', fr: 'Séoul');
      case 'busan': return tr(locale, ja: '釜山', en: 'Busan', ko: '부산', zh: '釜山', fr: 'Busan');
      default: return region;
    }
  }
}

class _PopularSpotCards extends StatefulWidget {
  final String region;
  final String locale;
  final Set<String> filledSlugs;
  final List<Landmark> filledLandmarks;
  final void Function(Landmark) onSelect;

  const _PopularSpotCards({required this.region, required this.locale, required this.filledSlugs, this.filledLandmarks = const [], required this.onSelect});

  @override
  State<_PopularSpotCards> createState() => _PopularSpotCardsState();
}

class _PopularSpotCardsState extends State<_PopularSpotCards> {
  String? _expandedSlug;

  static const _spots = {
    'kanto': [
      {'slug': 'tokyo-tower', 'name': '東京タワー', 'nameKo': '도쿄타워', 'nameEn': 'Tokyo Tower', 'lat': 35.6586, 'lng': 139.7454, 'image': 'tokyo-tower',
       'desc': {'ja': '1958年完成の東京のシンボル。展望台から都内を一望。', 'ko': '1958년에 완공된 도쿄의 상징. 전망대에서 도쿄 전경 감상.', 'en': 'Tokyo\'s iconic 1958 tower with panoramic views.'}},
      {'slug': 'asakusa-senso-ji', 'name': '浅草寺', 'nameKo': '아사쿠사 센소지', 'nameEn': 'Sensoji Temple', 'lat': 35.7148, 'lng': 139.7967, 'image': 'asakusa-senso-ji',
       'desc': {'ja': '東京最古の寺院。雷門と仲見世通りが人気。', 'ko': '도쿄에서 가장 오래된 사찰. 가미나리몬과 나카미세 거리.', 'en': 'Tokyo\'s oldest temple with Thunder Gate.'}},
      {'slug': 'shibuya-crossing', 'name': '渋谷スクランブル交差点', 'nameKo': '시부야스크램블교차점', 'nameEn': 'Shibuya Crossing', 'lat': 35.6595, 'lng': 139.7004, 'image': 'shibuya-crossing',
       'desc': {'ja': '世界で最も有名な交差点。渋谷のシンボル。', 'ko': '세계에서 가장 유명한 교차로. 시부야의 상징.', 'en': 'The world\'s most famous crossing.'}},
      {'slug': 'meiji-shrine', 'name': '明治神宮', 'nameKo': '메이지신궁', 'nameEn': 'Meiji Shrine', 'lat': 35.6764, 'lng': 139.6993, 'image': 'meiji-shrine',
       'desc': {'ja': '渋谷の森の中にある荘厳な神社。', 'ko': '시부야 숲 속에 자리한 장엄한 신사.', 'en': 'Serene shrine in Shibuya\'s forest.'}},
      {'slug': 'shinjuku-gyoen', 'name': '新宿御苑', 'nameKo': '신주쿠교엔', 'nameEn': 'Shinjuku Gyoen', 'lat': 35.6852, 'lng': 139.71, 'image': 'shinjuku-gyoen',
       'desc': {'ja': '日本庭園・英国式・フランス式の3つの庭園。', 'ko': '일본식·영국식·프랑스식 3개의 정원.', 'en': 'Three-style gardens in central Tokyo.'}},
      {'slug': 'tokyo-skytree', 'name': '東京スカイツリー', 'nameKo': '도쿄스카이트리', 'nameEn': 'Tokyo Skytree', 'lat': 35.7101, 'lng': 139.8107, 'image': 'tokyo-skytree',
       'desc': {'ja': '高さ634mの世界一高い電波塔。', 'ko': '높이 634m의 세계에서 가장 높은 전파탑.', 'en': 'World\'s tallest broadcasting tower at 634m.'}},
    ],
    'kansai': [
      {'slug': 'kinkaku-ji', 'name': '金閣寺', 'nameKo': '금각사', 'nameEn': 'Kinkaku-ji', 'lat': 35.0394, 'lng': 135.7292, 'image': 'kinkaku-ji',
       'desc': {'ja': '金箔で覆われた美しい寺院。池に映る姿が絶景。', 'ko': '금박으로 덮인 아름다운 사찰. 연못에 비치는 모습이 절경.', 'en': 'Golden pavilion reflected in mirror pond.'}},
      {'slug': 'fushimi-inari-taisha', 'name': '伏見稲荷大社', 'nameKo': '후시미이나리타이샤', 'nameEn': 'Fushimi Inari', 'lat': 34.9671, 'lng': 135.7727, 'image': 'fushimi-inari-taisha',
       'desc': {'ja': '千本鳥居で有名な京都の神社。', 'ko': '붉은 도리이 터널로 유명한 교토의 신사.', 'en': 'Famous for thousands of vermillion torii gates.'}},
      {'slug': 'kiyomizu-dera', 'name': '清水寺', 'nameKo': '기요미즈데라', 'nameEn': 'Kiyomizu-dera', 'lat': 34.9949, 'lng': 135.785, 'image': 'kiyomizu-dera',
       'desc': {'ja': '清水の舞台から京都を一望。世界遺産。', 'ko': '기요미즈 무대에서 교토 전경을 한눈에. 세계유산.', 'en': 'UNESCO World Heritage temple with wooden stage.'}},
      {'slug': 'dotonbori', 'name': '道頓堀', 'nameKo': '도톤보리', 'nameEn': 'Dotonbori', 'lat': 34.6687, 'lng': 135.5013, 'image': 'dotonbori',
       'desc': {'ja': '大阪グルメの中心地。グリコサインが有名。', 'ko': '오사카 먹거리의 중심. 글리코 사인이 유명.', 'en': 'Osaka\'s food capital with famous Glico sign.'}},
      {'slug': 'arashiyama', 'name': '嵐山', 'nameKo': '아라시야마', 'nameEn': 'Arashiyama', 'lat': 35.0094, 'lng': 135.667, 'image': 'arashiyama',
       'desc': {'ja': '竹林と渡月橋で有名な景勝地。', 'ko': '대나무숲과 토게츠교로 유명한 명소.', 'en': 'Scenic area with bamboo grove and Togetsukyo Bridge.'}},
      {'slug': 'nijo-castle', 'name': '二条城', 'nameKo': '니조성', 'nameEn': 'Nijo Castle', 'lat': 35.0142, 'lng': 135.748, 'image': 'nijo-castle',
       'desc': {'ja': '徳川家康が建てた世界遺産の城。', 'ko': '도쿠가와 이에야스가 세운 세계유산 성.', 'en': 'Tokugawa-era castle, UNESCO World Heritage.'}},
    ],
    'seoul': [
      {'slug': 'myeongdong', 'name': '明洞', 'nameKo': '명동', 'nameEn': 'Myeongdong', 'lat': 37.5609, 'lng': 126.9858, 'image': 'myeongdong',
       'desc': {'ja': 'ソウル最大のショッピング・グルメエリア。', 'ko': '서울 최대의 쇼핑·먹거리 거리. 화장품과 패션.', 'en': 'Seoul\'s biggest shopping and food district.'}},
      {'slug': 'hongdae', 'name': '弘大', 'nameKo': '홍대', 'nameEn': 'Hongdae', 'lat': 37.5574, 'lng': 126.9248, 'image': 'hongdae',
       'desc': {'ja': '若者文化の中心地。カフェやクラブが多い。', 'ko': '젊은이 문화의 중심지. 카페와 공연이 가득.', 'en': 'Youth culture hub with cafes and clubs.'}},
      {'slug': 'gangnam', 'name': '江南', 'nameKo': '강남', 'nameEn': 'Gangnam', 'lat': 37.4979, 'lng': 127.0276, 'image': 'gangnam',
       'desc': {'ja': 'K-POPで有名な高級エリア。', 'ko': 'K-pop으로 유명한 고급 상업지구.', 'en': 'Upscale district famous from K-pop.'}},
      {'slug': 'gyeongbokgung', 'name': '景福宮', 'nameKo': '경복궁', 'nameEn': 'Gyeongbokgung', 'lat': 37.5796, 'lng': 126.977, 'image': 'gyeongbokgung',
       'desc': {'ja': '朝鮮王朝の正宮。守門将交代式が人気。', 'ko': '조선 왕조의 정궁. 수문장 교대식이 인기.', 'en': 'Joseon dynasty\'s main palace with guard ceremony.'}},
      {'slug': 'itaewon', 'name': '梨泰院', 'nameKo': '이태원', 'nameEn': 'Itaewon', 'lat': 37.5344, 'lng': 126.9946, 'image': 'itaewon',
       'desc': {'ja': '多国籍レストランとバーが集まる国際的なエリア。', 'ko': '다양한 외국 음식점과 루프탑 바가 있는 국제적 동네.', 'en': 'International dining and nightlife hub.'}},
      {'slug': 'insadong', 'name': '仁寺洞', 'nameKo': '인사동', 'nameEn': 'Insadong', 'lat': 37.5746, 'lng': 126.985, 'image': 'insadong',
       'desc': {'ja': '伝統的な茶屋やギャラリーが並ぶ文化通り。', 'ko': '전통 찻집과 미술관이 늘어선 문화 거리.', 'en': 'Cultural street with tea houses and galleries.'}},
    ],
    'busan': [
      {'slug': 'haeundae', 'name': '海雲台', 'nameKo': '해운대', 'nameEn': 'Haeundae', 'lat': 35.1588, 'lng': 129.1604, 'image': 'haeundae',
       'desc': {'ja': '韓国最高のビーチリゾート。1.5kmの白砂浜。', 'ko': '한국 최고의 해수욕장. 1.5km 백사장.', 'en': 'Korea\'s premier beach with 1.5km white sand.'}},
      {'slug': 'gwangalli', 'name': '広安里', 'nameKo': '광안리', 'nameEn': 'Gwangalli', 'lat': 35.1534, 'lng': 129.1187, 'image': 'gwangalli',
       'desc': {'ja': '広安大橋の夜景が美しいビーチエリア。', 'ko': '광안대교 야경이 아름다운 해변 지역.', 'en': 'Beach area with beautiful bridge night view.'}},
      {'slug': 'gamcheon-culture-village', 'name': '甘川文化村', 'nameKo': '감천문화마을', 'nameEn': 'Gamcheon Culture Village', 'lat': 35.0966, 'lng': 129.0105, 'image': 'gamcheon-culture-village',
       'desc': {'ja': '釜山のマチュピチュ。カラフルな家々と壁画。', 'ko': '부산의 마추픽추. 알록달록한 집과 벽화.', 'en': 'Busan\'s Machu Picchu with colorful houses.'}},
      {'slug': 'jagalchi-market', 'name': 'チャガルチ市場', 'nameKo': '자갈치시장', 'nameEn': 'Jagalchi Market', 'lat': 35.0966, 'lng': 129.0308, 'image': 'jagalchi-market',
       'desc': {'ja': '韓国最大の海鮮市場。新鮮な刺身が食べられる。', 'ko': '한국 최대의 해산물 시장. 신선한 회를 즐길 수 있는 곳.', 'en': 'Korea\'s largest seafood market with fresh sashimi.'}},
      {'slug': 'nampo-dong', 'name': '南浦洞', 'nameKo': '남포동', 'nameEn': 'Nampo-dong', 'lat': 35.0978, 'lng': 129.0267, 'image': 'nampo-dong',
       'desc': {'ja': '国際市場やBIFF広場がある釜山の繁華街。', 'ko': '국제시장과 BIFF광장이 있는 부산의 번화가.', 'en': 'Busan\'s bustling downtown with markets.'}},
      {'slug': 'centum-city', 'name': 'センタムシティ', 'nameKo': '센텀시티', 'nameEn': 'Centum City', 'lat': 35.1696, 'lng': 129.1289, 'image': 'centum-city',
       'desc': {'ja': '世界最大のデパートがある現代的商業エリア。', 'ko': '세계 최대 백화점이 있는 현대적 상업 중심지.', 'en': 'Modern hub with world\'s largest department store.'}},
    ],
  };

  List<Map<String, Object>> _getDynamicSpots() {
    // Get up to 16 spots from bundled data, filtered by filled slugs, show 6
    final bundled = LandmarkLocalizer.getLandmarksForRegion(widget.region);
    if (bundled != null && bundled.isNotEmpty) {
      return bundled
        .where((lm) {
          final slug = lm['slug'] as String? ?? '';
          if (widget.filledSlugs.contains(slug)) return false;
          // Also filter by proximity (~100m) to avoid near-duplicate spots
          final lat = (lm['lat'] as num).toDouble();
          final lng = (lm['lng'] as num).toDouble();
          return !widget.filledLandmarks.any((f) =>
            (f.lat - lat).abs() < 0.001 && (f.lng - lng).abs() < 0.001);
        })
        .take(6)
        .map((lm) => <String, Object>{
          'slug': lm['slug'] as String? ?? '',
          'name': lm['name'] as String? ?? '',
          'nameKo': lm['nameKo'] as String? ?? '',
          'nameEn': lm['nameEn'] as String? ?? '',
          'lat': (lm['lat'] as num).toDouble(),
          'lng': (lm['lng'] as num).toDouble(),
          'image': lm['slug'] as String? ?? '',
          'desc': <String, String>{
            'ja': (lm['description'] as Map?)?['ja'] as String? ?? '',
            'ko': (lm['description'] as Map?)?['ko'] as String? ?? '',
            'en': (lm['description'] as Map?)?['en'] as String? ?? '',
          },
        }).toList();
    }
    // Fallback to hardcoded
    return (_spots[widget.region] ?? [])
      .where((s) => !widget.filledSlugs.contains(s['slug'] as String))
      .toList();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getDynamicSpots();

    if (spots.isEmpty) return const SizedBox.shrink();

    final addLabel = tr(widget.locale, ja: '検索に追加', ko: '검색에 추가', en: 'Add to search', zh: '添加到搜索', fr: 'Ajouter à la recherche');
    final tripLabel = tr(widget.locale, ja: '旅行に追加', ko: '여행에 추가', en: 'Add to trip', zh: '添加到旅行', fr: 'Ajouter au voyage');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.place, size: 16, color: AppTheme.mutedForeground),
          const SizedBox(width: 6),
          Text(
            tr(widget.locale, ja: '人気スポット', ko: '인기 관광지', en: 'Popular Spots', zh: '热门景点', fr: 'Sites populaires'),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.mutedForeground),
          ),
        ]),
        const SizedBox(height: 10),
        // Full-width vertical cards (matching web)
        ...spots.map((spot) {
          final name = _getName(spot);
          final imageFile = spot['image'] as String;
          final isExpanded = _expandedSlug == spot['slug'];
          final descMap = spot['desc'] as Map<String, String>?;
          final desc = descMap?[widget.locale] ?? descMap?['en'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                // Image (tap to navigate to detail)
                GestureDetector(
                  onTap: () {
                    final nameEn = spot['nameEn'] as String?;
                    final descMap = spot['desc'] as Map<String, String>?;
                    final spotDesc = descMap?[widget.locale] ?? descMap?['en'] ?? '';
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SpotDetailScreen(
                        landmark: Landmark(
                          slug: spot['slug'] as String,
                          name: name,
                          nameEn: nameEn,
                          lat: spot['lat'] as double,
                          lng: spot['lng'] as double,
                          region: widget.region,
                          description: spotDesc.isNotEmpty ? spotDesc : null,
                        ),
                      ),
                    ));
                  },
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      'https://norigo.app/images/landmarks/$imageFile.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppTheme.muted, child: Center(child: Icon(Icons.place, size: 32, color: AppTheme.mutedForeground))),
                    ),
                  ),
                ),
                // Title + expand toggle
                GestureDetector(
                  onTap: () => setState(() => _expandedSlug = isExpanded ? null : spot['slug'] as String),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 18, color: AppTheme.mutedForeground),
                    ]),
                  ),
                ),

                // Expanded: description + buttons
                if (isExpanded)
                  Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      if (desc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(desc, style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground, height: 1.5)),
                        ),
                      Row(children: [
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () => _addToSearch(spot),
                          icon: const Icon(Icons.search, size: 14),
                          label: Text(addLabel, style: const TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                        )),
                      ]),
                    ]),
                  ),

                // Collapsed: quick add button
                if (!isExpanded)
                  Container(
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _addToSearch(spot),
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(addLabel, style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                      ),
                    ),
                  ),
              ]),
            ),
          );
        }),
      ],
    );
  }

  void _addToSearch(Map<String, Object> spot) {
    final name = _getName(spot);
    widget.onSelect(Landmark(
      slug: spot['slug'] as String,
      name: name,
      lat: spot['lat'] as double,
      lng: spot['lng'] as double,
      region: widget.region,
    ));
  }

  String _getName(Map<String, Object> spot) {
    switch (widget.locale) {
      case 'ko': return spot['nameKo'] as String? ?? spot['nameEn'] as String? ?? spot['name'] as String;
      case 'ja': return spot['name'] as String;
      default: return spot['nameEn'] as String? ?? spot['name'] as String; // en, zh, fr
    }
  }
}

class _QuickSearchPlans extends StatelessWidget {
  final String region;
  final String locale;
  final void Function(List<Landmark> landmarks, String region) onSelect;

  const _QuickSearchPlans({required this.region, required this.locale, required this.onSelect});

  static const _plans = {
    'kanto': [
      {'title': {'ja': '渋谷・原宿・新宿', 'ko': '시부야・하라주쿠・신주쿠', 'en': 'Shibuya · Harajuku · Shinjuku', 'fr': 'Shibuya · Harajuku · Shinjuku'},
       'landmarks': [
         {'name': '渋谷', 'nameKo': '시부야', 'nameEn': 'Shibuya', 'lat': 35.6595, 'lng': 139.7004},
         {'name': '原宿', 'nameKo': '하라주쿠', 'nameEn': 'Harajuku', 'lat': 35.6702, 'lng': 139.7026},
         {'name': '新宿', 'nameKo': '신주쿠', 'nameEn': 'Shinjuku', 'lat': 35.6852, 'lng': 139.7100},
         {'name': '表参道', 'nameKo': '오모테산도', 'nameEn': 'Omotesando', 'lat': 35.6654, 'lng': 139.7121},
         {'name': '池袋', 'nameKo': '이케부쿠로', 'nameEn': 'Ikebukuro', 'lat': 35.7295, 'lng': 139.7109},
       ]},
      {'title': {'ja': '浅草・上野・東京駅', 'ko': '아사쿠사・우에노・도쿄역', 'en': 'Asakusa · Ueno · Tokyo', 'fr': 'Asakusa · Ueno · Tokyo'},
       'landmarks': [
         {'name': '浅草', 'nameKo': '아사쿠사', 'nameEn': 'Asakusa', 'lat': 35.7148, 'lng': 139.7967},
         {'name': '上野', 'nameKo': '우에노', 'nameEn': 'Ueno', 'lat': 35.7146, 'lng': 139.7732},
         {'name': '東京駅', 'nameKo': '도쿄역', 'nameEn': 'Tokyo Station', 'lat': 35.6812, 'lng': 139.7671},
         {'name': '秋葉原', 'nameKo': '아키하바라', 'nameEn': 'Akihabara', 'lat': 35.6984, 'lng': 139.7731},
         {'name': 'スカイツリー', 'nameKo': '스카이트리', 'nameEn': 'Tokyo Skytree', 'lat': 35.7101, 'lng': 139.8107},
       ]},
    ],
    'kansai': [
      {'title': {'ja': '道頓堀・なんば・心斎橋', 'ko': '도톤보리・난바・신사이바시', 'en': 'Dotonbori · Namba · Shinsaibashi', 'fr': 'Dotonbori · Namba · Shinsaibashi'},
       'landmarks': [
         {'name': '道頓堀', 'nameKo': '도톤보리', 'nameEn': 'Dotonbori', 'lat': 34.6687, 'lng': 135.5021},
         {'name': 'なんば', 'nameKo': '난바', 'nameEn': 'Namba', 'lat': 34.6659, 'lng': 135.5013},
         {'name': '心斎橋', 'nameKo': '신사이바시', 'nameEn': 'Shinsaibashi', 'lat': 34.6751, 'lng': 135.5014},
         {'name': '黒門市場', 'nameKo': '구로몬시장', 'nameEn': 'Kuromon Market', 'lat': 34.6681, 'lng': 135.5097},
         {'name': '大阪城', 'nameKo': '오사카성', 'nameEn': 'Osaka Castle', 'lat': 34.6873, 'lng': 135.5262},
       ]},
    ],
    'seoul': [
      {'title': {'ja': '明洞・弘大・江南', 'ko': '명동・홍대・강남', 'en': 'Myeongdong · Hongdae · Gangnam', 'fr': 'Myeongdong · Hongdae · Gangnam'},
       'landmarks': [
         {'name': '明洞', 'nameKo': '명동', 'nameEn': 'Myeongdong', 'lat': 37.5636, 'lng': 126.9869},
         {'name': '弘大', 'nameKo': '홍대', 'nameEn': 'Hongdae', 'lat': 37.5563, 'lng': 126.9237},
         {'name': '江南', 'nameKo': '강남', 'nameEn': 'Gangnam', 'lat': 37.4979, 'lng': 127.0276},
       ]},
    ],
    'busan': [
      {'title': {'ja': '海雲台・広安里・南浦', 'ko': '해운대・광안리・남포동', 'en': 'Haeundae · Gwangalli', 'fr': 'Haeundae · Gwangalli'},
       'landmarks': [
         {'name': '海雲台', 'nameKo': '해운대', 'nameEn': 'Haeundae', 'lat': 35.1586, 'lng': 129.1604},
         {'name': '広安里', 'nameKo': '광안리', 'nameEn': 'Gwangalli', 'lat': 35.1532, 'lng': 129.1187},
         {'name': '南浦', 'nameKo': '남포동', 'nameEn': 'Nampo-dong', 'lat': 35.0975, 'lng': 129.0326},
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
          tr(locale, ja: '人気プランで検索', ko: '인기 플랜으로 검색', en: 'Quick search plans', zh: '热门方案搜索', fr: 'Plans de recherche rapide'),
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
                  final name = locale == 'ko' ? (l['nameKo'] as String? ?? l['nameEn'] as String? ?? l['name'] as String)
                      : locale == 'ja' ? (l['name'] as String)
                      : (l['nameEn'] as String? ?? l['name'] as String);
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
  final Set<String> filledSlugs;
  final void Function(Landmark) onSelect;

  const _SuggestionChips({required this.region, required this.locale, required this.filledSlugs, required this.onSelect});

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
      return !filledSlugs.contains(s['slug'] as String? ?? name);
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
      case 'ko': return spot['nameKo'] as String? ?? spot['nameEn'] as String? ?? spot['name'] as String;
      case 'ja': return spot['name'] as String;
      default: return spot['nameEn'] as String? ?? spot['name'] as String; // en, zh, fr
    }
  }
}

class _StayStyleToggle extends StatelessWidget {
  final String locale;
  final bool isSplit;
  final ValueChanged<bool> onChanged;
  final List<Landmark> landmarks;

  const _StayStyleToggle({required this.locale, required this.isSplit, required this.onChanged, required this.landmarks});

  /// Simple zone clustering: count how many 10km-apart groups exist
  int _countZones() {
    if (landmarks.length < 2) return 1;
    // Greedy clustering with 10km radius
    final assigned = <int>{};
    int zones = 0;
    for (var i = 0; i < landmarks.length; i++) {
      if (assigned.contains(i)) continue;
      zones++;
      assigned.add(i);
      for (var j = i + 1; j < landmarks.length; j++) {
        if (assigned.contains(j)) continue;
        final dist = _haversine(landmarks[i].lat, landmarks[i].lng, landmarks[j].lat, landmarks[j].lng);
        if (dist < 10.0) assigned.add(j);
      }
    }
    return zones;
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * 3.14159265 / 180;
    final dLng = (lng2 - lng1) * 3.14159265 / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * 3.14159265 / 180) * cos(lat2 * 3.14159265 / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    final zoneCount = _countZones();
    final recommendSplit = zoneCount >= 2;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          _buildOption(
            selected: !isSplit,
            icon: Icons.hotel,
            label: tr(locale, ja: '1箇所に宿泊', ko: '한 곳에 숙박', en: 'Single hotel', zh: '单一酒店', fr: 'Hôtel unique'),
            showRecommended: !recommendSplit && landmarks.length >= 3,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 8),
          _buildOption(
            selected: isSplit,
            icon: Icons.swap_horiz,
            label: tr(locale, ja: '分散して宿泊', ko: '분산 숙박', en: 'Split stay', zh: '分区住宿', fr: 'Séjour divisé'),
            showRecommended: recommendSplit,
            onTap: () => onChanged(true),
          ),
        ]),
      ),
      // Explanation text (matching web)
      if (landmarks.length >= 3) ...[
        const SizedBox(height: 8),
        Text(
          recommendSplit
            ? tr(locale, ja: '観光地が離れているため、分散宿泊がおすすめです', ko: '관광지가 떨어져 있어 분산 숙박을 추천합니다', en: 'Your spots are spread out — splitting into areas is recommended', zh: '景点较分散，建议分区住宿', fr: 'Vos sites sont éloignés - un séjour divisé est recommandé')
            : tr(locale, ja: '観光地が近いため、1箇所の宿泊で十分です', ko: '관광지가 가까워 한 곳 숙박으로 충분합니다', en: 'Your spots are close together — one hotel works great', zh: '景点较集中，住一家酒店即可', fr: 'Vos sites sont proches - un seul hôtel suffit'),
          style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
          textAlign: TextAlign.center,
        ),
      ],
    ]);
  }

  Widget _buildOption({
    required bool selected,
    required IconData icon,
    required String label,
    required bool showRecommended,
    required VoidCallback onTap,
  }) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Column(children: [
          if (showRecommended)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: Text(tr(locale, ja: 'おすすめ', ko: '추천', en: 'Rec', zh: '推荐', fr: 'Rec.'),
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          Icon(icon, size: 18, color: selected ? AppTheme.primary : AppTheme.mutedForeground),
          const SizedBox(height: 4),
          Text(label,
            style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppTheme.primary : AppTheme.foreground),
            textAlign: TextAlign.center),
        ]),
      ),
    ));
  }
}
