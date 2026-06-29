import 'package:cinemava/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cinemava starts on splash screen', (tester) async {
    await tester.pumpWidget(const CinemavaApp());

    expect(find.text('Cinemava'), findsOneWidget);
    expect(find.text('Your personal cinema companion'), findsOneWidget);
  });
}
