import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_app/main.dart';

void main() {
  testWidgets('Weather app renders main search UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Search city...'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('No data available'), findsNothing);
  });
}
