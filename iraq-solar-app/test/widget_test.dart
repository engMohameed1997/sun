import 'package:flutter_test/flutter_test.dart';
import 'package:iraq_solar_app/main.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const IraqSolarApp());
    expect(find.byType(IraqSolarApp), findsOneWidget);
  });
}
