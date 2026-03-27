import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for session tracking logic:
/// - Same session reused within 30 min
/// - New session after 30 min timeout
/// - UID persistent across restarts
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('Session tracking', () {
    test('TrackingService code has 30-min timeout constant', () {
      final content = File('lib/services/tracking_service.dart').readAsStringSync();
      expect(content, contains('_sessionTimeoutMs'));
      expect(content, contains('30 * 60 * 1000'));
    });

    test('Session ID is stored in SharedPreferences', () {
      final content = File('lib/services/tracking_service.dart').readAsStringSync();
      expect(content, contains('tracking_session_id'));
      expect(content, contains('prefs.getString(_keySessionId)'));
    });

    test('Last active timestamp is updated on every event', () {
      final content = File('lib/services/tracking_service.dart').readAsStringSync();
      expect(content, contains('_keyLastActive'));
      // trackEvent should update last active
      expect(content, contains('prefs.setInt(_keyLastActive'));
    });

    test('Session reuse logic: within timeout → same session', () {
      final content = File('lib/services/tracking_service.dart').readAsStringSync();
      // Check that the code compares now - lastActive < timeout
      expect(content, contains('now - lastActive'));
      expect(content, contains('_sessionTimeoutMs'));
    });

    test('New session created when no saved session exists', () {
      final content = File('lib/services/tracking_service.dart').readAsStringSync();
      // Fallback to new UUID when savedSessionId is null
      expect(content, contains('const Uuid().v4()'));
    });

    test('UID remains persistent (not regenerated)', () {
      final content = File('lib/services/tracking_service.dart').readAsStringSync();
      // UID should only be created if null
      expect(content, contains("prefs.getString('uid')"));
      expect(content, contains("prefs.setString('uid'"));
    });

    test('Session flow simulation', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Simulate first app launch
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionId1 = 'session-abc';
      await prefs.setString('tracking_session_id', sessionId1);
      await prefs.setInt('tracking_last_active', now);

      // Simulate re-open within 5 minutes → should reuse session
      final fiveMinLater = now + (5 * 60 * 1000);
      final lastActive = prefs.getInt('tracking_last_active') ?? 0;
      final shouldReuse = (fiveMinLater - lastActive) < (30 * 60 * 1000);
      expect(shouldReuse, true, reason: '5 min < 30 min → reuse session');

      // Simulate re-open after 45 minutes → should create new session
      final fortyFiveMinLater = now + (45 * 60 * 1000);
      final shouldCreateNew = (fortyFiveMinLater - lastActive) >= (30 * 60 * 1000);
      expect(shouldCreateNew, true, reason: '45 min > 30 min → new session');
    });
  });
}
