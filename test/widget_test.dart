// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:kanakku/main.dart';
import 'package:kanakku/storage.dart';

void main() {
  testWidgets('App renders home title', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final repository = await LedgerRepository.bootstrap();
    await repository.ensureMonthlySubscriptionCharges(DateTime.now());
    final controller = LedgerController(repository);

    await tester.pumpWidget(UniShareApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Kanakku'), findsOneWidget);
  });
}
