import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';

class TrackingService {
  final ApiClient _api;
  String? _sessionId;
  String? _userId;
  String _locale = 'en';

  /// Session timeout: 30 minutes (matching GA4 default)
  static const _sessionTimeoutMs = 30 * 60 * 1000;
  static const _keySessionId = 'tracking_session_id';
  static const _keyLastActive = 'tracking_last_active';

  TrackingService(this._api);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // User ID: persistent across launches
    _userId = prefs.getString('uid');
    if (_userId == null) {
      _userId = const Uuid().v4();
      await prefs.setString('uid', _userId!);
    }

    // Session ID: reuse if last activity was within 30 minutes
    final lastActive = prefs.getInt(_keyLastActive) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final savedSessionId = prefs.getString(_keySessionId);

    if (savedSessionId != null && (now - lastActive) < _sessionTimeoutMs) {
      _sessionId = savedSessionId;
    } else {
      _sessionId = const Uuid().v4();
      await prefs.setString(_keySessionId, _sessionId!);
    }

    // Update last active
    await prefs.setInt(_keyLastActive, now);
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

    // Update last active on every event
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(_keyLastActive, DateTime.now().millisecondsSinceEpoch);
    });

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
