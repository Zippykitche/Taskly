import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/main.dart';

void main() {
  testWidgets('Taskly user app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TasklyUserApp());
    expect(find.byType(TasklyUserApp), findsOneWidget);
  });
}
