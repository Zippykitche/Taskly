import 'package:flutter_test/flutter_test.dart';
import 'package:tasker_app/main.dart';

void main() {
  testWidgets('Taskly tasker app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TasklyTaskerApp());
    expect(find.byType(TasklyTaskerApp), findsOneWidget);
  });
}
