// Basic widget test for EcoMarket
//
// This is a placeholder test that verifies the app can be instantiated.
// More comprehensive tests should be added as features are developed.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco_market/app.dart';

void main() {
  testWidgets('EcoMarket app smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EcoMarketApp(),
      ),
    );

    // Verify that the EcoMarket branding is displayed
    expect(find.text('EcoMarket'), findsOneWidget);
  });
}
