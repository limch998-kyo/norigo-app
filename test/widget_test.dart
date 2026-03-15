import 'package:flutter_test/flutter_test.dart';
import 'package:norigo_app/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const NorigoApp());
    await tester.pumpAndSettle();
  });
}
