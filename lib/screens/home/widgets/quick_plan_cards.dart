import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/landmark.dart';
import '../../../services/landmark_localizer.dart';
import '../../../utils/tr.dart';
import '../../../widgets/cached_image.dart';

/// A beginner-friendly "starter plan" — an intent ("First Tokyo trip") with a
/// suggested hotel base, who it fits, the reasoning, and a caveat, mirroring the
/// web's starterPlans so a first-time visitor can decide without knowing any
/// place names yet. [labels] holds per-locale copy with keys: title, subtitle,
/// recommendedBase, bestFor, why1, why2, caveat.
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

/// Public so data-integrity tests can validate the copy and landmark sets.
const quickPlans = <QuickPlan>[
  QuickPlan(
    id: 'tokyo-classic',
    region: 'kanto',
    image: '/images/landmarks/shibuya-crossing.webp',
    labels: {
      'ja': {
        'title': '東京はじめて3泊',
        'subtitle': '渋谷・原宿・新宿中心',
        'recommendedBase': 'おすすめ宿泊ベース: 新宿・代々木・池袋',
        'bestFor': '予定がまだ固まっていない初めての東京旅行',
        'why1': '西側の人気エリアが近く、移動時間の偏りが小さめです。',
        'why2': 'ホテル数と夜の交通手段が多く、初旅行でも動きやすいです。',
        'caveat': '新宿中心部は価格と混雑が高くなりやすいです。',
      },
      'ko': {
        'title': '도쿄 처음 3박',
        'subtitle': '시부야・하라주쿠・신주쿠 중심',
        'recommendedBase': '추천 숙소 베이스: 신주쿠・요요기・이케부쿠로',
        'bestFor': '일정이 아직 불확실한 첫 도쿄 여행',
        'why1': '서쪽 인기 지역이 한 덩어리라 이동시간 편차가 작습니다.',
        'why2': '호텔과 늦은 시간 교통 선택지가 많아 첫 여행 리스크가 낮습니다.',
        'caveat': '신주쿠 핵심부는 가격과 혼잡도가 높을 수 있습니다.',
      },
      'en': {
        'title': 'First Tokyo Trip',
        'subtitle': 'Shibuya · Harajuku · Shinjuku',
        'recommendedBase': 'Suggested base: Shinjuku · Yoyogi · Ikebukuro',
        'bestFor': 'First-time visitors who have not fixed every stop yet',
        'why1':
            'The west-side highlights sit close together, so travel times stay balanced.',
        'why2':
            'Hotel choice and late-evening transit options are broad for beginners.',
        'caveat': 'Central Shinjuku can be crowded and more expensive.',
      },
      'zh': {
        'title': '第一次东京3晚',
        'subtitle': '涩谷・原宿・新宿',
        'recommendedBase': '推荐住宿据点：新宿・代代木・池袋',
        'bestFor': '行程还没完全确定的首次东京旅行',
        'why1': '东京西侧热门区域距离近，移动时间比较均衡。',
        'why2': '酒店和夜间交通选择多，第一次来更稳妥。',
        'caveat': '新宿核心区价格和拥挤度可能较高。',
      },
      'fr': {
        'title': 'Premier séjour à Tokyo',
        'subtitle': 'Shibuya · Harajuku · Shinjuku',
        'recommendedBase': 'Base conseillée : Shinjuku · Yoyogi · Ikebukuro',
        'bestFor': "Un premier voyage dont l'itinéraire n'est pas encore fixé",
        'why1':
            'Les quartiers ouest restent proches, avec des temps de trajet équilibrés.',
        'why2':
            "Le choix d'hôtels et les transports tardifs sont larges pour débuter.",
        'caveat':
            'Le centre de Shinjuku peut être plus cher et très fréquenté.',
      },
    },
    landmarks: [
      {
        'slug': 'shibuya-crossing',
        'name': '渋谷',
        'nameEn': 'Shibuya',
        'nameKo': '시부야',
        'lat': 35.6595,
        'lng': 139.7004,
        'region': 'kanto',
      },
      {
        'slug': 'harajuku',
        'name': '原宿',
        'nameEn': 'Harajuku',
        'nameKo': '하라주쿠',
        'lat': 35.6702,
        'lng': 139.7026,
        'region': 'kanto',
      },
      {
        'slug': 'shinjuku',
        'name': '新宿',
        'nameEn': 'Shinjuku',
        'nameKo': '신주쿠',
        'lat': 35.6852,
        'lng': 139.7100,
        'region': 'kanto',
      },
      {
        'slug': 'omotesando',
        'name': '表参道',
        'nameEn': 'Omotesando',
        'nameKo': '오모테산도',
        'lat': 35.6654,
        'lng': 139.7121,
        'region': 'kanto',
      },
      {
        'slug': 'ikebukuro',
        'name': '池袋',
        'nameEn': 'Ikebukuro',
        'nameKo': '이케부쿠로',
        'lat': 35.7295,
        'lng': 139.7109,
        'region': 'kanto',
      },
    ],
  ),
  QuickPlan(
    id: 'tokyo-traditional',
    region: 'kanto',
    image: '/images/landmarks/asakusa-senso-ji.webp',
    labels: {
      'ja': {
        'title': '東京下町・コスパ重視',
        'subtitle': '浅草・上野・東京駅中心',
        'recommendedBase': 'おすすめ宿泊ベース: 上野・浅草橋・蔵前',
        'bestFor': '宿泊費を抑えながら定番観光を回りたい旅行',
        'why1': '東側の観光地が近く、短い移動で複数スポットを回れます。',
        'why2': '上野/浅草周辺はホテル選択肢が広く、空港アクセスも安定します。',
        'caveat': '渋谷・原宿中心の予定では西側への移動が長めです。',
      },
      'ko': {
        'title': '가성비 도쿄 전통 코스',
        'subtitle': '아사쿠사・우에노・도쿄역 중심',
        'recommendedBase': '추천 숙소 베이스: 우에노・아사쿠사바시・구라마에',
        'bestFor': '숙박비를 아끼면서 대표 관광지를 보고 싶은 여행',
        'why1': '동쪽 관광지가 가까워 짧은 이동으로 여러 곳을 묶기 쉽습니다.',
        'why2': '우에노/아사쿠사 주변은 호텔 선택지가 넓고 공항 접근도 안정적입니다.',
        'caveat': '시부야・하라주쿠 위주의 일정이면 서쪽 이동이 길어집니다.',
      },
      'en': {
        'title': 'Budget-Friendly Classic Tokyo',
        'subtitle': 'Asakusa · Ueno · Tokyo Station',
        'recommendedBase': 'Suggested base: Ueno · Asakusabashi · Kuramae',
        'bestFor': 'Travelers who want classic sights with wider hotel options',
        'why1': 'East-side sights are close enough to bundle with short rides.',
        'why2':
            'Ueno/Asakusa has broad hotel supply and stable airport access.',
        'caveat': 'Shibuya and Harajuku days will take longer from this side.',
      },
      'zh': {
        'title': '高性价比东京经典',
        'subtitle': '浅草・上野・东京站',
        'recommendedBase': '推荐住宿据点：上野・浅草桥・藏前',
        'bestFor': '想节省住宿费并游览经典景点的行程',
        'why1': '东京东侧景点集中，短距离移动即可串联。',
        'why2': '上野/浅草一带酒店选择多，机场交通也稳定。',
        'caveat': '如果主玩涩谷・原宿，西侧移动会更久。',
      },
      'fr': {
        'title': 'Tokyo classique et budget',
        'subtitle': 'Asakusa · Ueno · Gare de Tokyo',
        'recommendedBase': 'Base conseillée : Ueno · Asakusabashi · Kuramae',
        'bestFor':
            "Voir les classiques avec plus d'options d'hôtels abordables",
        'why1': "Les sites de l'est se combinent avec de courts trajets.",
        'why2':
            "Ueno/Asakusa offre un bon choix d'hôtels et un accès aéroport stable.",
        'caveat': 'Les journées Shibuya et Harajuku seront plus longues.',
      },
    },
    landmarks: [
      {
        'slug': 'asakusa-senso-ji',
        'name': '浅草寺',
        'nameEn': 'Asakusa (Senso-ji)',
        'nameKo': '아사쿠사(센소지)',
        'lat': 35.7148,
        'lng': 139.7967,
        'region': 'kanto',
      },
      {
        'slug': 'ueno-park',
        'name': '上野公園',
        'nameEn': 'Ueno Park',
        'nameKo': '우에노 공원',
        'lat': 35.7146,
        'lng': 139.7732,
        'region': 'kanto',
      },
      {
        'slug': 'tokyo-station',
        'name': '東京駅',
        'nameEn': 'Tokyo Station',
        'nameKo': '도쿄역',
        'lat': 35.6812,
        'lng': 139.7671,
        'region': 'kanto',
      },
      {
        'slug': 'akihabara',
        'name': '秋葉原',
        'nameEn': 'Akihabara',
        'nameKo': '아키하바라',
        'lat': 35.6984,
        'lng': 139.7731,
        'region': 'kanto',
      },
      {
        'slug': 'tokyo-skytree',
        'name': 'スカイツリー',
        'nameEn': 'Tokyo Skytree',
        'nameKo': '스카이트리',
        'lat': 35.7101,
        'lng': 139.8107,
        'region': 'kanto',
      },
    ],
  ),
  QuickPlan(
    id: 'tokyo-family',
    region: 'kanto',
    image: '/images/landmarks/tokyo-disneyland.webp',
    labels: {
      'ja': {
        'title': '家族・ディズニー込み東京',
        'subtitle': 'ディズニーランド・お台場・銀座中心',
        'recommendedBase': 'おすすめ宿泊ベース: 新橋・銀座・豊洲',
        'bestFor': '子連れ、親子旅行、移動負担を減らしたい旅行',
        'why1': 'ディズニー方面と都心観光の中間を取りやすいです。',
        'why2': '銀座/新橋はタクシーやエレベーター移動も組みやすいです。',
        'caveat': '価格重視なら上野/浅草側も比較してください。',
      },
      'ko': {
        'title': '가족・디즈니 포함 도쿄',
        'subtitle': '디즈니랜드・오다이바・긴자 중심',
        'recommendedBase': '추천 숙소 베이스: 신바시・긴자・도요스',
        'bestFor': '아이 동반, 부모님 동반, 택시/전철 이동을 줄이고 싶은 여행',
        'why1': '디즈니와 도심 관광 사이의 이동 균형이 좋습니다.',
        'why2': '긴자/신바시는 엘리베이터와 택시 이동 선택지가 비교적 안정적입니다.',
        'caveat': '가성비만 보면 우에노/아사쿠사보다 비쌀 수 있습니다.',
      },
      'en': {
        'title': 'Tokyo With Disney or Family',
        'subtitle': 'Disneyland · Odaiba · Ginza',
        'recommendedBase': 'Suggested base: Shimbashi · Ginza · Toyosu',
        'bestFor': 'Families, parents, and trips where easy transfers matter',
        'why1':
            'It balances Disney-side travel with central Tokyo sightseeing.',
        'why2':
            'Ginza/Shimbashi also work well when taxi or elevator access matters.',
        'caveat': 'For pure budget travel, compare Ueno or Asakusa too.',
      },
      'zh': {
        'title': '家庭・迪士尼东京',
        'subtitle': '迪士尼・台场・银座',
        'recommendedBase': '推荐住宿据点：新桥・银座・丰洲',
        'bestFor': '亲子、父母同行、想减少换乘压力的旅行',
        'why1': '能平衡迪士尼方向和东京市中心观光。',
        'why2': '银座/新桥在出租车和电梯移动上也较方便。',
        'caveat': '若只看预算，上野/浅草可能更划算。',
      },
      'fr': {
        'title': 'Tokyo avec Disney ou famille',
        'subtitle': 'Disneyland · Odaiba · Ginza',
        'recommendedBase': 'Base conseillée : Shimbashi · Ginza · Toyosu',
        'bestFor':
            'Familles et voyages où les correspondances simples comptent',
        'why1': 'Bon équilibre entre Disney et les visites du centre de Tokyo.',
        'why2': 'Ginza/Shimbashi facilite aussi les taxis et les ascenseurs.',
        'caveat': 'Pour le budget pur, comparez aussi Ueno ou Asakusa.',
      },
    },
    landmarks: [
      {
        'slug': 'tokyo-disneyland',
        'name': '東京ディズニーランド',
        'nameEn': 'Tokyo Disneyland',
        'nameKo': '도쿄 디즈니랜드',
        'lat': 35.6329,
        'lng': 139.8804,
        'region': 'kanto',
      },
      {
        'slug': 'odaiba',
        'name': 'お台場',
        'nameEn': 'Odaiba',
        'nameKo': '오다이바',
        'lat': 35.6267,
        'lng': 139.7762,
        'region': 'kanto',
      },
      {
        'slug': 'ginza',
        'name': '銀座',
        'nameEn': 'Ginza',
        'nameKo': '긴자',
        'lat': 35.6717,
        'lng': 139.7649,
        'region': 'kanto',
      },
      {
        'slug': 'tokyo-tower',
        'name': '東京タワー',
        'nameEn': 'Tokyo Tower',
        'nameKo': '도쿄타워',
        'lat': 35.6586,
        'lng': 139.7454,
        'region': 'kanto',
      },
      {
        'slug': 'tsukiji',
        'name': '築地',
        'nameEn': 'Tsukiji',
        'nameKo': '쓰키지',
        'lat': 35.6654,
        'lng': 139.7707,
        'region': 'kanto',
      },
    ],
  ),
  QuickPlan(
    id: 'osaka-gourmet',
    region: 'kansai',
    image: '/images/landmarks/dotonbori.webp',
    labels: {
      'ja': {
        'title': '大阪はじめて・グルメ',
        'subtitle': '道頓堀・なんば・心斎橋中心',
        'recommendedBase': 'おすすめ宿泊ベース: なんば・心斎橋・本町',
        'bestFor': '大阪市内の食べ歩きと買い物を楽に回りたい旅行',
        'why1': '主要なグルメ/買い物エリアが徒歩と短い地下鉄でつながります。',
        'why2': '大阪城方面も大きく遠回りせずに移動できます。',
        'caveat': '京都へ何度も行くなら梅田側も比較してください。',
      },
      'ko': {
        'title': '오사카 처음・먹방 코스',
        'subtitle': '도톤보리・난바・신사이바시 중심',
        'recommendedBase': '추천 숙소 베이스: 난바・신사이바시・혼마치',
        'bestFor': '오사카 시내 맛집과 쇼핑을 가장 쉽게 돌고 싶은 여행',
        'why1': '주요 먹거리/쇼핑 지역이 도보와 짧은 지하철로 이어집니다.',
        'why2': '오사카성까지도 크게 돌아가지 않아 첫 방문 동선이 단순합니다.',
        'caveat': '교토를 여러 날 갈 계획이면 우메다 쪽도 같이 비교하세요.',
      },
      'en': {
        'title': 'First Osaka Food Trip',
        'subtitle': 'Dotonbori · Namba · Shinsaibashi',
        'recommendedBase': 'Suggested base: Namba · Shinsaibashi · Hommachi',
        'bestFor': 'Travelers focused on food, shopping, and easy city walks',
        'why1':
            'Food and shopping districts connect by foot or short subway rides.',
        'why2':
            'Osaka Castle still stays simple without crossing the whole city.',
        'caveat': 'If Kyoto is the main focus, compare Umeda as well.',
      },
      'zh': {
        'title': '第一次大阪美食',
        'subtitle': '道顿堀・难波・心斋桥',
        'recommendedBase': '推荐住宿据点：难波・心斋桥・本町',
        'bestFor': '以美食、购物和步行为主的大阪旅行',
        'why1': '主要美食和购物区可以步行或短程地铁连接。',
        'why2': '去大阪城也不需要跨很远的区域。',
        'caveat': '如果会多次去京都，也建议比较梅田。',
      },
      'fr': {
        'title': 'Premier Osaka gourmand',
        'subtitle': 'Dotonbori · Namba · Shinsaibashi',
        'recommendedBase': 'Base conseillée : Namba · Shinsaibashi · Hommachi',
        'bestFor': 'Cuisine, shopping et quartiers faciles à parcourir',
        'why1':
            'Les zones de restaurants et de shopping se relient à pied ou en métro court.',
        'why2': 'Osaka Castle reste simple sans traverser toute la ville.',
        'caveat': 'Si Kyoto domine le voyage, comparez aussi Umeda.',
      },
    },
    landmarks: [
      {
        'slug': 'dotonbori',
        'name': '道頓堀',
        'nameEn': 'Dotonbori',
        'nameKo': '도톤보리',
        'lat': 34.6687,
        'lng': 135.5021,
        'region': 'kansai',
      },
      {
        'slug': 'namba',
        'name': 'なんば',
        'nameEn': 'Namba',
        'nameKo': '난바',
        'lat': 34.6659,
        'lng': 135.5013,
        'region': 'kansai',
      },
      {
        'slug': 'shinsaibashi',
        'name': '心斎橋',
        'nameEn': 'Shinsaibashi',
        'nameKo': '신사이바시',
        'lat': 34.6751,
        'lng': 135.5014,
        'region': 'kansai',
      },
      {
        'slug': 'kuromon-market',
        'name': '黒門市場',
        'nameEn': 'Kuromon Market',
        'nameKo': '구로몬시장',
        'lat': 34.6681,
        'lng': 135.5097,
        'region': 'kansai',
      },
      {
        'slug': 'osaka-castle',
        'name': '大阪城',
        'nameEn': 'Osaka Castle',
        'nameKo': '오사카성',
        'lat': 34.6873,
        'lng': 135.5262,
        'region': 'kansai',
      },
    ],
  ),
  QuickPlan(
    id: 'kyoto-daytrip',
    region: 'kansai',
    image: '/images/landmarks/fushimi-inari-taisha.webp',
    labels: {
      'ja': {
        'title': '大阪泊 + 京都日帰り',
        'subtitle': '清水寺・伏見稲荷・嵐山中心',
        'recommendedBase': 'おすすめ宿泊ベース: 梅田・大阪駅・京都駅',
        'bestFor': '大阪に泊まりながら京都も1日から2日回りたい旅行',
        'why1': '京都の東西スポットを同時に比較し、偏った宿泊地を避けます。',
        'why2': '大阪/京都移動も含めて、荷物移動の負担を抑えられます。',
        'caveat': '京都の夜散歩が目的なら京都1泊も検討してください。',
      },
      'ko': {
        'title': '오사카 숙박 + 교토 당일치기',
        'subtitle': '기요미즈데라・후시미이나리・아라시야마 중심',
        'recommendedBase': '추천 숙소 베이스: 우메다・오사카역・교토역',
        'bestFor': '호텔은 오사카에 두고 교토를 하루나 이틀 다녀오려는 여행',
        'why1': '교토 동서 관광지를 한 번에 비교해 과하게 치우친 숙소를 피합니다.',
        'why2': '오사카/교토 이동을 함께 보므로 짐 이동 부담을 줄일 수 있습니다.',
        'caveat': '교토 야간 산책이 핵심이면 교토 1박 분할도 고려하세요.',
      },
      'en': {
        'title': 'Osaka Base + Kyoto Day Trip',
        'subtitle': 'Kiyomizu-dera · Fushimi Inari · Arashiyama',
        'recommendedBase':
            'Suggested base: Umeda · Osaka Station · Kyoto Station',
        'bestFor':
            'Travelers staying in Osaka but visiting Kyoto for one or two days',
        'why1':
            "It compares Kyoto's east and west sides before you choose a base.",
        'why2':
            'It also shows whether moving hotels would save meaningful time.',
        'caveat': 'If Kyoto nights are important, consider one night in Kyoto.',
      },
      'zh': {
        'title': '住大阪 + 京都一日游',
        'subtitle': '清水寺・伏见稻荷・岚山',
        'recommendedBase': '推荐住宿据点：梅田・大阪站・京都站',
        'bestFor': '住在大阪，同时安排1到2天京都的旅行',
        'why1': '同时比较京都东西两侧景点，避免住宿点过偏。',
        'why2': '也能判断换酒店是否真的节省时间。',
        'caveat': '如果重视京都夜晚散步，可考虑京都住一晚。',
      },
      'fr': {
        'title': 'Base Osaka + excursion Kyoto',
        'subtitle': 'Kiyomizu-dera · Fushimi Inari · Arashiyama',
        'recommendedBase':
            "Base conseillée : Umeda · Gare d'Osaka · Gare de Kyoto",
        'bestFor': 'Dormir à Osaka tout en visitant Kyoto un ou deux jours',
        'why1': "Compare l'est et l'ouest de Kyoto avant de choisir la base.",
        'why2': "Montre aussi si changer d'hôtel économise vraiment du temps.",
        'caveat': 'Pour les soirées à Kyoto, envisagez une nuit sur place.',
      },
    },
    landmarks: [
      {
        'slug': 'kiyomizu-dera',
        'name': '清水寺',
        'nameEn': 'Kiyomizu-dera',
        'nameKo': '기요미즈데라',
        'lat': 34.9949,
        'lng': 135.785,
        'region': 'kansai',
      },
      {
        'slug': 'fushimi-inari-taisha',
        'name': '伏見稲荷大社',
        'nameEn': 'Fushimi Inari',
        'nameKo': '후시미이나리 타이샤',
        'lat': 34.9671,
        'lng': 135.7727,
        'region': 'kansai',
      },
      {
        'slug': 'arashiyama',
        'name': '嵐山',
        'nameEn': 'Arashiyama',
        'nameKo': '아라시야마',
        'lat': 35.0094,
        'lng': 135.667,
        'region': 'kansai',
      },
      {
        'slug': 'kinkaku-ji',
        'name': '金閣寺',
        'nameEn': 'Kinkaku-ji',
        'nameKo': '킨카쿠지',
        'lat': 35.0394,
        'lng': 135.7292,
        'region': 'kansai',
      },
      {
        'slug': 'nijo-castle',
        'name': '二条城',
        'nameEn': 'Nijo Castle',
        'nameKo': '니조성',
        'lat': 35.0142,
        'lng': 135.7481,
        'region': 'kansai',
      },
    ],
  ),
  QuickPlan(
    id: 'fukuoka-classic',
    region: 'kyushu',
    image: '/images/landmarks/canal-city-hakata.webp',
    labels: {
      'ja': {
        'title': '福岡はじめて3泊',
        'subtitle': '中洲・太宰府・門司港中心',
        'recommendedBase': 'おすすめ宿泊ベース: 博多・天神・中洲',
        'bestFor': '福岡市内と近郊をまとめて見たい旅行',
        'why1': '空港/新幹線/市内移動の基準点が分かりやすいです。',
        'why2': '太宰府や門司港のような別方向の近郊移動も一緒に比較します。',
        'caveat': '温泉地が主目的なら市内泊だけでは移動が長くなります。',
      },
      'ko': {
        'title': '후쿠오카 처음 3박',
        'subtitle': '나카스・다자이후・모지코 중심',
        'recommendedBase': '추천 숙소 베이스: 하카타・텐진・나카스',
        'bestFor': '후쿠오카 시내와 근교를 한 번에 보고 싶은 여행',
        'why1': '공항/신칸센/시내 이동의 기준점이 명확합니다.',
        'why2': '다자이후와 모지코처럼 방향이 다른 근교 이동을 함께 비교합니다.',
        'caveat': '온천지가 주목적이면 시내 숙소만으로는 이동이 길어집니다.',
      },
      'en': {
        'title': 'First Fukuoka Trip',
        'subtitle': 'Nakasu · Dazaifu · Mojiko',
        'recommendedBase': 'Suggested base: Hakata · Tenjin · Nakasu',
        'bestFor': 'Travelers mixing Fukuoka city with a few side trips',
        'why1': 'Airport, Shinkansen, and city access all have clear hubs.',
        'why2':
            'Side trips in different directions are compared in the same result.',
        'caveat':
            'If hot springs are the main goal, city-only stays create long rides.',
      },
      'zh': {
        'title': '第一次福冈3晚',
        'subtitle': '中洲・太宰府・门司港',
        'recommendedBase': '推荐住宿据点：博多・天神・中洲',
        'bestFor': '想同时看福冈市区和近郊的旅行',
        'why1': '机场、新干线、市内移动都有明确据点。',
        'why2': '不同方向的近郊行程也会一起比较。',
        'caveat': '如果温泉是重点，只住市区会增加移动时间。',
      },
      'fr': {
        'title': 'Premier séjour à Fukuoka',
        'subtitle': 'Nakasu · Dazaifu · Mojiko',
        'recommendedBase': 'Base conseillée : Hakata · Tenjin · Nakasu',
        'bestFor': 'Mixer Fukuoka ville et quelques excursions',
        'why1': "Aéroport, Shinkansen et ville ont des points d'accès clairs.",
        'why2':
            'Les excursions dans des directions différentes sont comparées ensemble.',
        'caveat':
            "Si les onsens sont l'objectif principal, la ville seule rallonge les trajets.",
      },
    },
    landmarks: [
      {
        'slug': 'tenjin',
        'name': '天神',
        'nameEn': 'Tenjin',
        'nameKo': '텐진',
        'lat': 33.5903,
        'lng': 130.3990,
        'region': 'kyushu',
      },
      {
        'slug': 'canal-city-hakata',
        'name': 'キャナルシティ博多',
        'nameEn': 'Canal City Hakata',
        'nameKo': '캐널시티 하카타',
        'lat': 33.5895,
        'lng': 130.4107,
        'region': 'kyushu',
      },
      {
        'slug': 'nakasu',
        'name': '中洲',
        'nameEn': 'Nakasu',
        'nameKo': '나카스',
        'lat': 33.5922,
        'lng': 130.4042,
        'region': 'kyushu',
      },
      {
        'slug': 'dazaifu-tenmangu',
        'name': '太宰府天満宮',
        'nameEn': 'Dazaifu Tenmangu',
        'nameKo': '다자이후 텐만구',
        'lat': 33.5194,
        'lng': 130.5350,
        'region': 'kyushu',
      },
      {
        'slug': 'hakata-station',
        'name': '博多駅',
        'nameEn': 'Hakata Station',
        'nameKo': '하카타역',
        'lat': 33.5898,
        'lng': 130.4207,
        'region': 'kyushu',
      },
    ],
  ),
  QuickPlan(
    id: 'kyushu-onsen',
    region: 'kyushu',
    image: '/images/landmarks/beppu-onsen.webp',
    labels: {
      'ja': {
        'title': '九州温泉ルート',
        'subtitle': '由布院・別府・黒川中心',
        'recommendedBase': 'おすすめ宿泊ベース: 由布院・別府・福岡の分割比較',
        'bestFor': '温泉地を複数回るために宿泊分割も比較したい旅行',
        'why1': '温泉地同士は距離があり、1拠点と分泊の差が大きいです。',
        'why2': '市内観光と温泉移動を同時に見て、無理な日帰りを減らします。',
        'caveat': '鉄道だけで弱い区間はバス/レンタカーも確認してください。',
      },
      'ko': {
        'title': '큐슈 온천 루트',
        'subtitle': '유후인・벳푸・구로카와 중심',
        'recommendedBase': '추천 숙소 베이스: 유후인・벳푸・후쿠오카 분할 비교',
        'bestFor': '한 숙소로 버티기보다 온천 지역 동선을 비교하고 싶은 여행',
        'why1': '온천지는 서로 멀어 단일 숙박과 분할 숙박 차이가 큽니다.',
        'why2': '시내 관광과 온천 이동을 같이 보며 무리한 당일치기를 줄입니다.',
        'caveat': '철도만으로 부족한 구간은 버스/렌터카 이동도 확인해야 합니다.',
      },
      'en': {
        'title': 'Kyushu Hot Spring Route',
        'subtitle': 'Yufuin · Beppu · Kurokawa',
        'recommendedBase':
            'Suggested base: compare Yufuin · Beppu · Fukuoka splits',
        'bestFor': 'Travelers deciding between one base and split stays',
        'why1':
            'The hot spring towns are far apart, so base choice changes the trip.',
        'why2': 'The result helps avoid unrealistic day-trip routing.',
        'caveat': 'Some legs need bus or car checks beyond rail time.',
      },
      'zh': {
        'title': '九州温泉路线',
        'subtitle': '由布院・别府・黑川',
        'recommendedBase': '推荐住宿据点：由布院・别府・福冈分段比较',
        'bestFor': '想比较单一住宿和分段住宿的温泉旅行',
        'why1': '温泉地彼此较远，住宿据点会大幅影响行程。',
        'why2': '结果可以帮助避免不现实的一日往返。',
        'caveat': '部分路段还需要确认巴士或租车交通。',
      },
      'fr': {
        'title': 'Route onsens au Kyushu',
        'subtitle': 'Yufuin · Beppu · Kurokawa',
        'recommendedBase':
            'Base conseillée : comparer Yufuin · Beppu · Fukuoka',
        'bestFor': 'Choisir entre une seule base et des nuits séparées',
        'why1':
            'Les villes thermales sont éloignées, donc la base change beaucoup le voyage.',
        'why2': 'Le résultat aide à éviter des excursions trop ambitieuses.',
        'caveat':
            'Certaines étapes demandent aussi une vérification bus ou voiture.',
      },
    },
    landmarks: [
      {
        'slug': 'dazaifu-tenmangu',
        'name': '太宰府天満宮',
        'nameEn': 'Dazaifu Tenmangu',
        'nameKo': '다자이후 텐만구',
        'lat': 33.5214,
        'lng': 130.5353,
        'region': 'kyushu',
      },
      {
        'slug': 'yufuin',
        'name': '由布院',
        'nameEn': 'Yufuin',
        'nameKo': '유후인',
        'lat': 33.2667,
        'lng': 131.3686,
        'region': 'kyushu',
      },
      {
        'slug': 'beppu-onsen',
        'name': '別府温泉',
        'nameEn': 'Beppu Onsen',
        'nameKo': '벳푸 온천',
        'lat': 33.2846,
        'lng': 131.5004,
        'region': 'kyushu',
      },
      {
        'slug': 'beppu-hells',
        'name': '別府地獄めぐり',
        'nameEn': 'Beppu Hells',
        'nameKo': '벳푸 지옥온천',
        'lat': 33.3192,
        'lng': 131.4564,
        'region': 'kyushu',
      },
      {
        'slug': 'kurokawa-onsen',
        'name': '黒川温泉',
        'nameEn': 'Kurokawa Onsen',
        'nameKo': '구로카와 온천',
        'lat': 33.1161,
        'lng': 131.0914,
        'region': 'kyushu',
      },
    ],
  ),
];

class QuickPlanCards extends StatefulWidget {
  final void Function(String planId, String region, List<Landmark> landmarks)?
  onPlanSelected;

  /// Fired once when the section first renders — a section-level impression so
  /// quick_plan_selected clicks have a denominator. This is a section render,
  /// not a viewport-visibility impression.
  final VoidCallback? onImpression;

  const QuickPlanCards({super.key, this.onPlanSelected, this.onImpression});

  @override
  State<QuickPlanCards> createState() => _QuickPlanCardsState();
}

class _QuickPlanCardsState extends State<QuickPlanCards> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onImpression?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final onPlanSelected = widget.onPlanSelected;

    final kantoPlans = quickPlans.where((p) => p.region == 'kanto').toList();
    final kansaiPlans = quickPlans.where((p) => p.region == 'kansai').toList();
    final kyushuPlans = quickPlans.where((p) => p.region == 'kyushu').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Beginner framing: "no itinerary yet? start from a hotel base".
        Text(
          tr(
            locale,
            ja: '行きたい場所がまだ決まっていなくても大丈夫',
            ko: '관광지를 몰라도 시작할 수 있어요',
            en: 'No itinerary yet? Start here',
            zh: '还不知道要去哪里也没关系',
            fr: "Pas encore d'itinéraire ? Commencez ici",
          ),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.quickPlanTitle,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.quickPlanDesc,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
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
          title: tr(
            locale,
            ja: '福岡・九州',
            ko: '후쿠오카·큐슈',
            en: 'Fukuoka / Kyushu',
            zh: '福冈·九州',
            fr: 'Fukuoka / Kyushu',
          ),
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
            Icon(
              Icons.location_on,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...plans.map((plan) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _QuickPlanCard(
              plan: plan,
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

class _QuickPlanCard extends StatefulWidget {
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
  State<_QuickPlanCard> createState() => _QuickPlanCardState();
}

class _QuickPlanCardState extends State<_QuickPlanCard> {
  bool _expanded = false;

  /// Build the localized landmark list and trigger the stay search.
  void _select() {
    final onPlanSelected = widget.onPlanSelected;
    if (onPlanSelected == null) return;
    final locale = widget.locale;
    final landmarks = widget.plan.landmarks.map((l) {
      final slug = l['slug'] as String;
      final ja = l['name'] as String;
      final nameEn = l['nameEn'] as String?;
      final lat = l['lat'] as double;
      final lng = l['lng'] as double;
      // zh names live in the bundled landmark data, not in this card's map, so
      // look them up — otherwise Chinese users see English place names. ja/ko
      // keep the card's short names; fr uses English by app convention.
      final String name;
      if (locale == 'ja') {
        name = ja;
      } else if (locale == 'ko') {
        name = (l['nameKo'] as String?) ?? nameEn ?? ja;
      } else if (locale == 'zh') {
        name =
            LandmarkLocalizer.getLocalizedName(
              locale: 'zh',
              slug: slug,
              name: ja,
              lat: lat,
              lng: lng,
            ) ??
            nameEn ??
            ja;
      } else {
        name = nameEn ?? ja; // en, fr
      }
      return Landmark(
        slug: slug,
        name: name,
        nameEn: nameEn,
        lat: lat,
        lng: lng,
        region: l['region'] as String,
      );
    }).toList();
    onPlanSelected(widget.plan.id, widget.plan.region, landmarks);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels =
        widget.plan.labels[widget.locale] ?? widget.plan.labels['en']!;
    final imageUrl = 'https://norigo.app${widget.plan.image}';
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final recommendedBase = labels['recommendedBase'] ?? '';
    final bestFor = labels['bestFor'] ?? '';
    final why1 = labels['why1'] ?? '';
    final why2 = labels['why2'] ?? '';
    final caveat = labels['caveat'] ?? '';
    final hasDetail = why1.isNotEmpty || why2.isNotEmpty || caveat.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      // The whole card starts the search; the why/caveat toggle below keeps its
      // own InkWell, which wins taps within its own bounds.
      child: Semantics(
        button: true,
        label: '${labels['title']}. ${widget.ctaText}',
        child: GestureDetector(
          onTap: _select,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedImage(imageUrl, fit: BoxFit.cover),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black45),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        labels['subtitle']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.ctaText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Decision content — what turns this card into a planning aid.
              if (recommendedBase.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: _InfoLine(
                    icon: Icons.hotel_outlined,
                    text: recommendedBase,
                    color: theme.colorScheme.primary,
                  ),
                ),
              if (bestFor.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _InfoLine(
                    icon: Icons.person_pin_circle_outlined,
                    text: bestFor,
                    color: muted,
                  ),
                ),

              if (hasDetail) ...[
                const Divider(height: 1),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 14, color: muted),
                        const SizedBox(width: 6),
                        Text(
                          tr(
                            widget.locale,
                            ja: '根拠と注意',
                            ko: '근거 · 주의',
                            en: 'Why & caveats',
                            zh: '依据与注意',
                            fr: 'Pourquoi & à noter',
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: muted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (why1.isNotEmpty) _ReasonLine(text: why1),
                        if (why2.isNotEmpty) _ReasonLine(text: why2),
                        if (caveat.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 15,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    caveat,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _ReasonLine extends StatelessWidget {
  final String text;

  const _ReasonLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 15,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: muted, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
