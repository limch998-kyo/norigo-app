import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norigo_app/app.dart';
import 'package:norigo_app/providers/app_providers.dart';

void main() {
  testWidgets('App should render with ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeProvider.overrideWith((ref) => 'en'),
        ],
        child: const NorigoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify bottom navigation bar is present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Hotel'), findsOneWidget);
    expect(find.text('Trip'), findsOneWidget);
  });
}
