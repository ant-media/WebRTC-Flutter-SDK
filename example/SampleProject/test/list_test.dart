import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('List items are displayed correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Assuming that you initialized some items in _initItems()
    // Check that the first list item is present
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('P2P'), findsOneWidget);
    expect(find.text('Conference'), findsOneWidget);
  });
}
