class AppConstants {
  static const String apiBaseUrl = 'https://norigo.app';
  static const String appName = 'Norigo';

  // API endpoints
  static const String searchUnifiedEndpoint = '/api/search/unified';
  static const String searchLandmarkEndpoint = '/api/search/landmark';
  static const String stayRecommendEndpoint = '/api/stay/recommend';
  static const String stayHotelsEndpoint = '/api/stay/hotels';
  static const String recommendEndpoint = '/api/recommend';
  static const String tripOptimizeEndpoint = '/api/trip/optimize';
  static const String tripResolveEndpoint = '/api/trip/resolve';
  static const String eventLogEndpoint = '/api/log';
  static const String stationSearchEndpoint = '/api/stations/search';
  static const String affiliateOutEndpoint = '/api/out';
  static const String voteCreateEndpoint = '/api/vote/create';

  // Regions
  static const List<String> japanRegions = ['kanto', 'kansai'];
  static const List<String> koreaRegions = ['seoul', 'busan'];
  static const List<String> allRegions = ['kanto', 'kansai', 'seoul', 'busan'];

  // Meetup modes
  static const String modeCentroid = 'centroid';
  static const String modeMinTotal = 'minTotal';
  static const String modeBalanced = 'balanced';

  // Restaurant categories
  static const Map<String, Map<String, String>> categories = {
    'izakaya': {'ja': '居酒屋', 'en': 'Izakaya', 'ko': '이자카야', 'zh': '居酒屋', 'fr': 'Izakaya'},
    'japanese': {'ja': '和食', 'en': 'Japanese', 'ko': '일식', 'zh': '日料', 'fr': 'Japonais'},
    'italian': {'ja': 'イタリアン', 'en': 'Italian', 'ko': '이탈리안', 'zh': '意大利菜', 'fr': 'Italien'},
    'chinese': {'ja': '中華', 'en': 'Chinese', 'ko': '중식', 'zh': '中餐', 'fr': 'Chinois'},
    'korean': {'ja': '韓国料理', 'en': 'Korean', 'ko': '한식', 'zh': '韩餐', 'fr': 'Coréen'},
    'yakiniku': {'ja': '焼肉', 'en': 'Yakiniku', 'ko': '야키니쿠', 'zh': '烤肉', 'fr': 'Yakiniku'},
    'ramen': {'ja': 'ラーメン', 'en': 'Ramen', 'ko': '라멘', 'zh': '拉面', 'fr': 'Ramen'},
    'cafe': {'ja': 'カフェ', 'en': 'Cafe', 'ko': '카페', 'zh': '咖啡厅', 'fr': 'Café'},
  };

  // Restaurant budgets
  static const Map<String, Map<String, String>> budgets = {
    '2000': {'ja': '〜2,000円', 'en': '~¥2,000', 'ko': '~2,000엔 (약 ₩18,000)', 'zh': '~¥2,000', 'fr': '~¥2 000 (~15€)'},
    '3000': {'ja': '〜3,000円', 'en': '~¥3,000', 'ko': '~3,000엔 (약 ₩27,000)', 'zh': '~¥3,000', 'fr': '~¥3 000 (~20€)'},
    '4000': {'ja': '〜4,000円', 'en': '~¥4,000', 'ko': '~4,000엔 (약 ₩36,000)', 'zh': '~¥4,000', 'fr': '~¥4 000 (~25€)'},
    '5000': {'ja': '〜5,000円', 'en': '~¥5,000', 'ko': '~5,000엔 (약 ₩45,000)', 'zh': '~¥5,000', 'fr': '~¥5 000 (~30€)'},
    '8000': {'ja': '〜8,000円', 'en': '~¥8,000', 'ko': '~8,000엔 (약 ₩72,000)', 'zh': '~¥8,000', 'fr': '~¥8 000 (~50€)'},
    '10000': {'ja': '10,000円〜', 'en': '¥10,000+', 'ko': '10,000엔~ (₩90,000~)', 'zh': '¥10,000+', 'fr': '¥10 000+ (65€+)'},
  };

  // Stay budgets (matching web STAY_BUDGETS_JP / STAY_BUDGETS_KR exactly)
  static const List<String> stayBudgetsJp = ['any', 'under10000', '10000-30000', '30000-50000', 'over50000'];
  static const List<String> stayBudgetsKr = ['any', 'under15000', '15000-25000', '25000-35000', '35000-50000', '50000-80000', 'over80000'];
  static const String defaultStayBudgetJp = '10000-30000';

  static List<String> getStayBudgets(String region) {
    return koreaRegions.contains(region) ? stayBudgetsKr : stayBudgetsJp;
  }

  /// Budget label with dual currency matching web's messages/*.json stayBudgets
  static const Map<String, Map<String, String>> stayBudgetLabels = {
    'any': {'ja': '指定なし', 'en': 'Any', 'ko': '지정 없음', 'zh': '不限', 'fr': 'Tout'},
    'under10000': {'ja': '〜10,000円', 'en': '~¥10,000 (~\$70)', 'ko': '~10,000엔 (약 ₩90,000)', 'zh': '~10,000日元 (~¥500)', 'fr': '~¥10 000 (~70\$)'},
    '10000-30000': {'ja': '10,000〜30,000円', 'en': '¥10,000~¥30,000 (\$70~\$210)', 'ko': '10,000~30,000엔 (₩90,000~₩270,000)', 'zh': '10,000~30,000日元 (¥500~¥1,500)', 'fr': '¥10 000~¥30 000 (70\$~210\$)'},
    '30000-50000': {'ja': '30,000〜50,000円', 'en': '¥30,000~¥50,000 (\$210~\$350)', 'ko': '30,000~50,000엔 (₩270,000~₩450,000)', 'zh': '30,000~50,000日元 (¥1,500~¥2,500)', 'fr': '¥30 000~¥50 000 (210\$~350\$)'},
    'over50000': {'ja': '50,000円〜', 'en': '¥50,000+ (\$350+)', 'ko': '50,000엔~ (₩450,000~)', 'zh': '50,000日元~ (¥2,500~)', 'fr': '¥50 000+ (350\$+)'},
    'under15000': {'ja': '〜15,000円', 'en': '~¥15,000 (~\$105)', 'ko': '~15,000엔 (약 ₩135,000)', 'zh': '~15,000日元 (~¥750)', 'fr': '~¥15 000 (~105\$)'},
    '15000-25000': {'ja': '15,000〜25,000円', 'en': '¥15,000~¥25,000 (\$105~\$175)', 'ko': '15,000~25,000엔 (₩135,000~₩225,000)', 'zh': '15,000~25,000日元 (¥750~¥1,250)', 'fr': '¥15 000~¥25 000 (105\$~175\$)'},
    '25000-35000': {'ja': '25,000〜35,000円', 'en': '¥25,000~¥35,000 (\$175~\$245)', 'ko': '25,000~35,000엔 (₩225,000~₩315,000)', 'zh': '25,000~35,000日元 (¥1,250~¥1,750)', 'fr': '¥25 000~¥35 000 (175\$~245\$)'},
    '35000-50000': {'ja': '35,000〜50,000円', 'en': '¥35,000~¥50,000 (\$245~\$350)', 'ko': '35,000~50,000엔 (₩270,000~₩450,000)', 'zh': '35,000~50,000日元 (¥1,500~¥2,500)', 'fr': '¥35 000~¥50 000 (245\$~350\$)'},
    '50000-80000': {'ja': '50,000〜80,000円', 'en': '¥50,000~¥80,000 (\$350~\$560)', 'ko': '50,000~80,000엔 (₩450,000~₩720,000)', 'zh': '50,000~80,000日元 (¥2,500~¥4,000)', 'fr': '¥50 000~¥80 000 (350\$~560\$)'},
    'over80000': {'ja': '80,000円〜', 'en': '¥80,000+ (\$560+)', 'ko': '80,000엔~ (₩720,000~)', 'zh': '80,000日元~ (¥4,000~)', 'fr': '¥80 000+ (560\$+)'},
    // Legacy keys (for backward compat with existing saved searches)
    'under5000': {'ja': '〜5,000円', 'en': '~¥5,000 (~\$35)', 'ko': '~5,000엔 (약 ₩45,000)', 'zh': '~5,000日元 (~¥250)', 'fr': '~¥5 000 (~35\$)'},
    'under8000': {'ja': '〜8,000円', 'en': '~¥8,000 (~\$55)', 'ko': '~8,000엔 (약 ₩72,000)', 'zh': '~8,000日元 (~¥400)', 'fr': '~¥8 000 (~55\$)'},
    'under20000': {'ja': '〜20,000円', 'en': '~¥20,000 (~\$140)', 'ko': '~20,000엔 (약 ₩180,000)', 'zh': '~20,000日元 (~¥1,000)', 'fr': '~¥20 000 (~140\$)'},
    'under25000': {'ja': '〜25,000円', 'en': '~¥25,000 (~\$175)', 'ko': '~25,000엔 (약 ₩225,000)', 'zh': '~25,000日元 (~¥1,250)', 'fr': '~¥25 000 (~175\$)'},
    'under30000': {'ja': '〜30,000円', 'en': '~¥30,000 (~\$210)', 'ko': '~30,000엔 (약 ₩270,000)', 'zh': '~30,000日元 (~¥1,500)', 'fr': '~¥30 000 (~210\$)'},
    'under35000': {'ja': '〜35,000円', 'en': '~¥35,000 (~\$245)', 'ko': '~35,000엔 (약 ₩315,000)', 'zh': '~35,000日元 (~¥1,750)', 'fr': '~¥35 000 (~245\$)'},
    'under50000': {'ja': '〜50,000円', 'en': '~¥50,000 (~\$350)', 'ko': '~50,000엔 (약 ₩450,000)', 'zh': '~50,000日元 (~¥2,500)', 'fr': '~¥50 000 (~350\$)'},
    'under80000': {'ja': '〜80,000円', 'en': '~¥80,000 (~\$560)', 'ko': '~80,000엔 (약 ₩720,000)', 'zh': '~80,000日元 (~¥4,000)', 'fr': '~¥80 000 (~560\$)'},
  };

  // Filter options
  static const Map<String, Map<String, String>> filterOptions = {
    'ps': {'ja': '個室', 'en': 'Private room', 'ko': '개인실', 'zh': '包间', 'fr': 'Salle privée'},
    'ns': {'ja': '禁煙', 'en': 'No smoking', 'ko': '금연', 'zh': '禁烟', 'fr': 'Non-fumeur'},
    'fd': {'ja': '飲み放題', 'en': 'Free drink', 'ko': '무한리필', 'zh': '畅饮', 'fr': 'Boissons à volonté'},
    'wf': {'ja': 'WiFi', 'en': 'WiFi', 'ko': 'WiFi', 'zh': 'WiFi', 'fr': 'WiFi'},
  };
}
