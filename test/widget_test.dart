import 'package:flutter_test/flutter_test.dart';
import 'package:ubermotor/main.dart';

void main() {
  testWidgets('HablaVas monta la app sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const HablaVasApp());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
