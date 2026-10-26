import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/main.dart';

void main() {
  testWidgets('To-Do List app displays its main screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TodoListApp());

    // Allow asynchronous task loading to finish without waiting
    // for every repeating animation to settle.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Tasks'), findsOneWidget);
    expect(find.text('Stay on track ✨'), findsOneWidget);
    expect(find.text('Add new task'), findsOneWidget);
  });
}

