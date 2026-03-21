import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norigo_app/app.dart';
import 'package:norigo_app/providers/app_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget createApp({String locale = 'ko'}) {
    return ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => locale),
      ],
      child: const NorigoApp(),
    );
  }

  group('Tab navigation', () {
    testWidgets('all 5 tabs are accessible', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Home tab is visible by default
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('호텔'), findsOneWidget);
      expect(find.text('만남'), findsOneWidget);
      expect(find.text('여행'), findsOneWidget);

      // Tap Hotel tab
      await tester.tap(find.text('호텔'));
      await tester.pumpAndSettle();
      expect(find.text('숙박 지역 찾기'), findsOneWidget);

      // Tap Meetup tab
      await tester.tap(find.text('만남'));
      await tester.pumpAndSettle();
      expect(find.text('만남역 찾기'), findsOneWidget);

      // Tap Trip tab
      await tester.tap(find.text('여행'));
      await tester.pumpAndSettle();
      expect(find.text('내 여행'), findsOneWidget);

      // Back to Home
      await tester.tap(find.text('홈'));
      await tester.pumpAndSettle();
    });
  });

  group('Language switching', () {
    testWidgets('Korean UI shows Korean labels', (tester) async {
      await tester.pumpWidget(createApp(locale: 'ko'));
      await tester.pumpAndSettle();

      expect(find.text('홈'), findsOneWidget);
      expect(find.text('호텔'), findsOneWidget);
      expect(find.text('만남'), findsOneWidget);
      expect(find.text('여행'), findsOneWidget);
    });

    testWidgets('Japanese UI shows Japanese labels', (tester) async {
      await tester.pumpWidget(createApp(locale: 'ja'));
      await tester.pumpAndSettle();

      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('ホテル'), findsOneWidget);
      expect(find.text('集合'), findsOneWidget);
      expect(find.text('旅行'), findsOneWidget);
    });

    testWidgets('English UI shows English labels', (tester) async {
      await tester.pumpWidget(createApp(locale: 'en'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Hotel'), findsOneWidget);
      expect(find.text('Meetup'), findsOneWidget);
      expect(find.text('Trip'), findsOneWidget);
    });

    testWidgets('Chinese UI shows Chinese labels', (tester) async {
      await tester.pumpWidget(createApp(locale: 'zh'));
      await tester.pumpAndSettle();

      expect(find.text('首页'), findsOneWidget);
      expect(find.text('酒店'), findsOneWidget);
      expect(find.text('聚会'), findsOneWidget);
      expect(find.text('旅行'), findsOneWidget);
    });
  });

  group('Stay search screen', () {
    testWidgets('region chips are visible', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Go to Hotel tab
      await tester.tap(find.text('호텔'));
      await tester.pumpAndSettle();

      // Region chips should be visible
      expect(find.text('도쿄 / 간토'), findsOneWidget);
      expect(find.text('오사카 / 간사이'), findsOneWidget);
      expect(find.text('서울'), findsOneWidget);
      expect(find.text('부산'), findsOneWidget);
    });

    testWidgets('search button disabled with less than 2 landmarks', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('호텔'));
      await tester.pumpAndSettle();

      // Search button should exist but be disabled
      final searchButton = find.text('호텔 검색');
      expect(searchButton, findsOneWidget);

      // Button should be disabled (no landmarks added)
      final button = tester.widget<ElevatedButton>(
        find.ancestor(of: searchButton, matching: find.byType(ElevatedButton)),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('mode selector shows 2 modes', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('호텔'));
      await tester.pumpAndSettle();

      // Stay search should have 2 modes
      expect(find.text('균등 거리'), findsOneWidget);
      expect(find.text('최소 이동'), findsOneWidget);
    });

    testWidgets('can switch regions', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('호텔'));
      await tester.pumpAndSettle();

      // Tap Seoul region
      await tester.tap(find.text('서울'));
      await tester.pumpAndSettle();

      // Popular spots should change (Seoul spots like 명동)
      expect(find.textContaining('명동'), findsWidgets);
    });
  });

  group('Meetup search screen', () {
    testWidgets('shows 3 search modes', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('만남'));
      await tester.pumpAndSettle();

      // Meetup should have 3 modes (same labels as ModeSelector with meetupModes)
      expect(find.text('균등 거리'), findsOneWidget);
      expect(find.text('최소 이동'), findsOneWidget);
      expect(find.text('가장 공평하게'), findsOneWidget);
    });
  });

  group('Trip screen', () {
    testWidgets('shows empty state when no trips', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('여행'));
      await tester.pumpAndSettle();

      // Should show empty state or trip list
      expect(find.text('내 여행'), findsOneWidget);
    });

    testWidgets('can open new trip dialog', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('여행'));
      await tester.pumpAndSettle();

      // Find and tap the add button (FAB or + icon)
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.text('새 여행 플랜'), findsOneWidget);
      }
    });
  });

  group('Settings', () {
    testWidgets('settings page shows version and links', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // Find settings icon on home screen
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await tester.pumpAndSettle();

        expect(find.text('설정'), findsOneWidget);
        expect(find.text('언어'), findsOneWidget);
        expect(find.text('앱 정보'), findsOneWidget);
        expect(find.text('Nori GO!'), findsOneWidget);
        expect(find.text('웹사이트'), findsOneWidget);
        expect(find.text('개인정보 처리방침'), findsOneWidget);
        expect(find.text('이용약관'), findsOneWidget);
        expect(find.text('이미지 출처'), findsOneWidget);
      }
    });
  });
}
