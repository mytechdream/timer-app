import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';

Finder get addTimerButton => find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == '创建倒计时',
    );

Future<void> pumpTimerApp(WidgetTester tester, TimerRepository repository) async {
  await tester.pumpWidget(TimerApp(repository: repository));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows timer home and bottom navigation',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    expect(find.text('计时器'), findsOneWidget);
    expect(find.text('选择倒计时时长'), findsOneWidget);
    expect(find.text('已创建的倒计时'), findsOneWidget);
    expect(find.text('03:00'), findsOneWidget);
    expect(find.text('番茄时钟'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('opens create timer page from add button',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(addTimerButton);
    await tester.pumpAndSettle();

    expect(find.text('创建倒计时'), findsOneWidget);
    expect(find.text('倒计时名称'), findsOneWidget);
    expect(find.text('例如：煮鸡蛋'), findsOneWidget);
  });

  testWidgets('persists created timer through repository',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    await pumpTimerApp(tester, repository);

    await tester.tap(addTimerButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '煮鸡蛋');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.timers.single.name, '煮鸡蛋');
    expect(snapshot.timers.single.seconds, 5 * 60);
  });
}
