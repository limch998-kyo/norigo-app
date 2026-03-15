class AppConstants {
  static const String apiBaseUrl = 'https://norigo.app';
  static const String appName = 'Norigo';

  // API endpoints (reuse existing Next.js API)
  static const String searchLandmarkEndpoint = '/api/search/landmark';
  static const String stayRecommendEndpoint = '/api/stay/recommend';
  static const String stayHotelsEndpoint = '/api/stay/hotels';
  static const String eventLogEndpoint = '/api/log';
  static const String stationSearchEndpoint = '/api/stations/search';

  // Regions
  static const List<String> japanRegions = ['kanto', 'kansai'];
  static const List<String> koreaRegions = ['seoul', 'busan'];
  static const List<String> allRegions = ['kanto', 'kansai', 'seoul', 'busan'];
}
