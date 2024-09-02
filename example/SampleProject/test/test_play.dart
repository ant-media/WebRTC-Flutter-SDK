import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('Play item navigates to Play screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final playItem = find.text('Play');
    expect(playItem, findsOneWidget);

    await tester.tap(playItem);
    await tester.pumpAndSettle();

    // Assuming that the Play screen has some unique identifier
    expect(find.text('Enter stream id'), findsOneWidget);
  });
}
