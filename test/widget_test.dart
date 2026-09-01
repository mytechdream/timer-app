import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/services/timer_audio.dart';

Finder get addTimerButton => find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == '创建倒计时',
    );

Future<void> pumpTimerApp(
    WidgetTester tester, TimerRepository repository) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    TimerApp(repository: repository, audio: const SilentTimerAudio()),
  );
  await tester.pumpAndSettle();
}

Future<void> openCreateTimerPage(WidgetTester tester) async {
  tester.widget<IconButton>(addTimerButton).onPressed?.call();
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

    await openCreateTimerPage(tester);

    expect(find.text('创建倒计时'), findsOneWidget);
    expect(find.text('倒计时名称'), findsOneWidget);
    expect(find.text('例如：煮鸡蛋'), findsOneWidget);
  });

  testWidgets('stopwatch add buttons open add label page',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();

    final Finder headerAddLabelButton = find.byWidgetPredicate(
      (Widget widget) => widget is IconButton && widget.tooltip == '添加标签',
    );
    tester.widget<IconButton>(headerAddLabelButton).onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('添加标签'), findsOneWidget);
    expect(find.text('标签名称'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('添加标签'), findsOneWidget);
    expect(find.text('标签名称'), findsOneWidget);
  });

  testWidgets('opens tomato countdown running page',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.text('番茄时钟'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('番茄时钟'), findsOneWidget);
    expect(find.text('24:59'), findsOneWidget);
    expect(find.textContaining('结束于'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('starts stopwatch mode separately from countdown',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始 口算'));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('口算'), findsOneWidget);
    expect(find.text('00:02'), findsOneWidget);
    expect(find.text('正计时中'), findsOneWidget);
  });

  testWidgets('settings bottom sheets update persisted timer settings',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    await pumpTimerApp(tester, repository);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认倒计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25分钟').last);
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.settings.defaultCountdownSeconds, 25 * 60);
    expect(find.text('25分钟'), findsOneWidget);
  });

  testWidgets('bottom navigation pages respond to taps',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    expect(find.text('批量计时'), findsWidgets);
    expect(find.text('选择'), findsOneWidget);
    expect(find.text('新倒计时'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(find.text('全部开始'), findsOneWidget);
    expect(find.text('全部暂停'), findsOneWidget);
    expect(find.text('全部重置'), findsOneWidget);
    expect(find.text('删除选中'), findsOneWidget);

    tester.widget<IconButton>(addTimerButton).onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('创建倒计时'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('数据洞察'), findsWidgets);
    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsWidgets);
  });

  testWidgets('persists created timer through repository',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    await pumpTimerApp(tester, repository);

    await openCreateTimerPage(tester);
    await tester.enterText(find.byType(TextField), '煮鸡蛋');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.timers.single.name, '煮鸡蛋');
    expect(snapshot.timers.single.seconds, 5 * 60);
  });
}
