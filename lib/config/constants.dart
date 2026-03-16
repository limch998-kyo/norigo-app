class AppConstants {
  static const String apiBaseUrl = 'https://norigo.app';
  static const String appName = 'Norigo';

  // API endpoints (reuse existing Next.js API)
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

  /// CARTO tile URL with locale support
  static String cartoTileUrl(String locale) {
    final lang = locale == 'ja' ? 'ja' : locale == 'ko' ? 'ko' : locale == 'zh' ? 'zh' : 'en';
    return 'https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png';
  }

  // Regions
  static const List<String> japanRegions = ['kanto', 'kansai'];
  static const List<String> koreaRegions = ['seoul', 'busan'];
  static const List<String> allRegions = ['kanto', 'kansai', 'seoul', 'busan'];

  // Meetup modes
  static const String modeCentroid = 'centroid';
  static const String modeMinTotal = 'minTotal';
  static const String modeBalanced = 'balanced';

  // Restaurant categories (Hot Pepper)
  static const Map<String, Map<String, String>> categories = {
    'izakaya': {'ja': '居酒屋', 'en': 'Izakaya', 'ko': '이자카야', 'zh': '居酒屋'},
    'japanese': {'ja': '和食', 'en': 'Japanese', 'ko': '일식', 'zh': '日料'},
    'italian': {'ja': 'イタリアン', 'en': 'Italian', 'ko': '이탈리안', 'zh': '意大利菜'},
    'chinese': {'ja': '中華', 'en': 'Chinese', 'ko': '중식', 'zh': '中餐'},
    'korean': {'ja': '韓国料理', 'en': 'Korean', 'ko': '한식', 'zh': '韩餐'},
    'yakiniku': {'ja': '焼肉', 'en': 'Yakiniku', 'ko': '야키니쿠', 'zh': '烤肉'},
    'ramen': {'ja': 'ラーメン', 'en': 'Ramen', 'ko': '라멘', 'zh': '拉面'},
    'cafe': {'ja': 'カフェ', 'en': 'Cafe', 'ko': '카페', 'zh': '咖啡厅'},
  };

  // Budget tiers
  static const Map<String, Map<String, String>> budgets = {
    '2000': {'ja': '〜2,000円', 'en': '~¥2,000', 'ko': '~¥2,000', 'zh': '~¥2,000'},
    '3000': {'ja': '〜3,000円', 'en': '~¥3,000', 'ko': '~¥3,000', 'zh': '~¥3,000'},
    '4000': {'ja': '〜4,000円', 'en': '~¥4,000', 'ko': '~¥4,000', 'zh': '~¥4,000'},
    '5000': {'ja': '〜5,000円', 'en': '~¥5,000', 'ko': '~¥5,000', 'zh': '~¥5,000'},
    '8000': {'ja': '〜8,000円', 'en': '~¥8,000', 'ko': '~¥8,000', 'zh': '~¥8,000'},
    '10000': {'ja': '10,000円〜', 'en': '¥10,000+', 'ko': '¥10,000+', 'zh': '¥10,000+'},
  };

  // Hotel budget tiers
  static const Map<String, Map<String, String>> hotelBudgetsJapan = {
    '10000': {'ja': '〜¥10,000', 'en': '~¥10,000', 'ko': '~¥10,000', 'zh': '~¥10,000'},
    '15000': {'ja': '〜¥15,000', 'en': '~¥15,000', 'ko': '~¥15,000', 'zh': '~¥15,000'},
    '20000': {'ja': '〜¥20,000', 'en': '~¥20,000', 'ko': '~¥20,000', 'zh': '~¥20,000'},
    '30000': {'ja': '〜¥30,000', 'en': '~¥30,000', 'ko': '~¥30,000', 'zh': '~¥30,000'},
    '50000': {'ja': '¥50,000〜', 'en': '¥50,000+', 'ko': '¥50,000+', 'zh': '¥50,000+'},
  };

  static const Map<String, Map<String, String>> hotelBudgetsKorea = {
    '50000': {'ja': '〜₩50,000', 'en': '~₩50,000', 'ko': '~₩50,000', 'zh': '~₩50,000'},
    '80000': {'ja': '〜₩80,000', 'en': '~₩80,000', 'ko': '~₩80,000', 'zh': '~₩80,000'},
    '120000': {'ja': '〜₩120,000', 'en': '~₩120,000', 'ko': '~₩120,000', 'zh': '~₩120,000'},
    '200000': {'ja': '₩200,000〜', 'en': '₩200,000+', 'ko': '₩200,000+', 'zh': '₩200,000+'},
  };

  // Filter options
  static const Map<String, Map<String, String>> filterOptions = {
    'ps': {'ja': '個室', 'en': 'Private room', 'ko': '개인실', 'zh': '包间'},
    'ns': {'ja': '禁煙', 'en': 'No smoking', 'ko': '금연', 'zh': '禁烟'},
    'fd': {'ja': '飲み放題', 'en': 'Free drink', 'ko': '무한리필', 'zh': '畅饮'},
    'wf': {'ja': 'WiFi', 'en': 'WiFi', 'ko': 'WiFi', 'zh': 'WiFi'},
  };
}
