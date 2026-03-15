import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

class TrackingService {
  final ApiClient _api;
  String? _sessionId;
  String? _userId;
  String _locale = 'en';

  TrackingService(this._api);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Session ID: new per app launch
    _sessionId = const Uuid().v4();

    // User ID: persistent across launches
    _userId = prefs.getString('uid');
    if (_userId == null) {
      _userId = const Uuid().v4();
      await prefs.setString('uid', _userId!);
    }
  }

  void setLocale(String locale) {
    _locale = locale;
  }

  Future<void> trackEvent(
    String eventType, {
    Map<String, dynamic> payload = const {},
    String? path,
  }) async {
    if (_sessionId == null || _userId == null) return;

    await _api.logEvent(
      eventType: eventType,
      sessionId: _sessionId!,
      userId: _userId!,
      payload: payload,
      path: path,
      locale: _locale,
    );
  }
}
