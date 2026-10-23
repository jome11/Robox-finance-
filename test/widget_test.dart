import 'package:flutter_test/flutter_test.dart';

import 'package:robox_finance/main.dart';

void main() {
  testWidgets('Robox Finance app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RoboxFinanceApp());

    // Verify that title is present.
    expect(find.text('Robox Finance'), findsOneWidget);
  });
}
