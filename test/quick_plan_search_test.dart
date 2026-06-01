import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norigo_app/app.dart';
import 'package:norigo_app/models/landmark.dart';
import 'package:norigo_app/models/stay_area.dart';
import 'package:norigo_app/providers/app_providers.dart';
import 'package:norigo_app/providers/stay_provider.dart';
import 'package:norigo_app/services/api_client.dart';

/// Runnable (non-integration) verification of the core review fix: tapping a
/// starter plan must actually start the stay search (notifier.search()), not
/// merely switch tabs. The integration_test version needs a device; this widget
/// test runs under `flutter test`.
class _StubApiClient extends ApiClient {
  /// Never completes, so the provider stays in the loading state and the test
  /// can assert the search started without any network access.
  @override
  Future<StayRecommendResult> getStayRecommendation({
    required List<Landmark> landmarks,
    required String region,
    String mode = 'centroid',
    String stayStyle = 'auto',
    String? maxBudget,
    String? checkIn,
    String? checkOut,
    String? locale,
  }) {
    return Completer<StayRecommendResult>().future;
  }
}

void main() {
  testWidgets('tapping a starter plan starts the stay search', (tester) async {
    final container = ProviderContainer(
      overrides: [
        localeProvider.overrideWith((ref) => 'ko'),
        apiClientProvider.overrideWithValue(_StubApiClient()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NorigoApp()),
    );
    await tester.pumpAndSettle();

    // The quick plans sit below the fold — scroll until the intent-titled card
    // ("도쿄 처음 3박") is visible, then tap it.
    final planTitle = find.text('도쿄 처음 3박');
    await tester.scrollUntilVisible(
      planTitle,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    await tester.tap(planTitle.first, warnIfMissed: false);
    await tester.pump();

    // search() flips isLoading synchronously and fills the inputs — proof the
    // tap ran the search, not just a tab switch.
    final stay = container.read(staySearchProvider);
    expect(stay.isLoading, isTrue, reason: 'onPlanSelected must call search()');
    expect(stay.region, 'kanto');
    expect(stay.landmarks.length, 5);
  });
}
