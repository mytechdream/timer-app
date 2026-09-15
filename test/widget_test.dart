import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/services/timer_audio.dart';

Finder get addTimerButton => find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == '创建倒计时',
    );

Finder iconButtonWithTooltip(String tooltip) => find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == tooltip,
    );

Future<void> pumpTimerApp(
  WidgetTester tester,
  TimerRepository repository, {
  TimerAudio audio = const SilentTimerAudio(),
  Size viewSize = const Size(430, 932),
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    TimerApp(repository: repository, audio: audio),
  );
  await tester.pumpAndSettle();
}

class RecordingTimerAudio implements TimerAudio {
  int tickCount = 0;
  int completeCount = 0;
  String? completedSoundName;

  @override
  Future<void> playTick() async {
    tickCount += 1;
  }

  @override
  Future<void> playComplete(String soundName) async {
    completeCount += 1;
    completedSoundName = soundName;
  }

  @override
  Future<void> dispose() async {}
}

Future<void> openCreateTimerPage(WidgetTester tester) async {
  tester.widget<IconButton>(addTimerButton).onPressed?.call();
  await tester.pumpAndSettle();
}

Future<void> openBatchPage(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.layers_outlined));
  await tester.pumpAndSettle();
}

Future<void> openHistoryPage(WidgetTester tester) async {
  tester.widget<IconButton>(iconButtonWithTooltip('历史记录')).onPressed?.call();
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

  testWidgets('long pressing a created label opens edit page and can delete it',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(labels: <String>['cc']),
    );
    await pumpTimerApp(tester, repository);

    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('cc'));
    await tester.pumpAndSettle();
    expect(find.text('修改标签'), findsOneWidget);
    expect(find.text('删除标签'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '专注');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    var snapshot = await repository.load();
    expect(snapshot.labels, contains('专注'));
    expect(snapshot.labels, isNot(contains('cc')));
    expect(find.text('专注'), findsOneWidget);

    await tester.longPress(find.text('专注'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除标签'));
    await tester.pumpAndSettle();

    snapshot = await repository.load();
    expect(snapshot.labels, isNot(contains('专注')));
    expect(find.text('专注'), findsNothing);
  });

  testWidgets('long pressing a created countdown can delete it',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(
        timers: <CreatedTimer>[
          CreatedTimer(
            id: 'egg',
            name: '煮鸡蛋',
            seconds: 5 * 60,
            createdAt: DateTime(2026, 9, 2),
          ),
        ],
      ),
    );
    await pumpTimerApp(tester, repository);

    await tester.longPress(find.text('煮鸡蛋'));
    await tester.pumpAndSettle();
    expect(find.text('删除倒计时？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.timers, isEmpty);
    expect(find.text('煮鸡蛋'), findsNothing);
  });

  testWidgets('long pressing a default countdown hides it',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    await pumpTimerApp(tester, repository);

    await tester.longPress(find.text('番茄时钟'));
    await tester.pumpAndSettle();
    expect(find.text('删除倒计时？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(
        snapshot.hiddenDefaultTimerIds, contains('default-countdown-pomodoro'));
    expect(find.text('番茄时钟'), findsNothing);
  });

  testWidgets('default stopwatch labels can be deleted from edit page',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    await pumpTimerApp(tester, repository);

    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('口算'));
    await tester.pumpAndSettle();
    expect(find.text('修改标签'), findsOneWidget);

    await tester.tap(find.text('删除标签'));
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.hiddenDefaultLabels, contains('口算'));
    expect(find.text('口算'), findsNothing);
  });

  testWidgets('history supports left swipe delete',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(
        history: <TimerHistoryEntry>[
          TimerHistoryEntry(
            id: 'history-1',
            name: '番茄时钟',
            mode: TimerRunMode.countdown,
            durationSeconds: 25 * 60,
            completedAt: DateTime(2026, 9, 2),
          ),
        ],
      ),
    );
    await pumpTimerApp(tester, repository);

    await openHistoryPage(tester);
    expect(find.text('番茄时钟'), findsOneWidget);

    await tester.drag(find.text('番茄时钟'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.history, isEmpty);
    expect(find.text('暂无历史记录'), findsOneWidget);
  });

  testWidgets('opens tomato countdown running page',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.text('番茄时钟'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('番茄时钟'), findsOneWidget);
    expect(find.text('24:59'), findsOneWidget);
    expect(find.textContaining('结束于'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('exiting a running timer asks for confirmation',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.text('番茄时钟'));
    await tester.pump(const Duration(seconds: 1));

    tester.widget<IconButton>(iconButtonWithTooltip('关闭')).onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('退出计时？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('24:59'), findsOneWidget);

    tester.widget<IconButton>(iconButtonWithTooltip('关闭')).onPressed?.call();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '退出'));
    await tester.pumpAndSettle();
    expect(find.text('选择倒计时时长'), findsOneWidget);
  });

  testWidgets(
      'running timer controls pause, edit label, tick sound, and fullscreen',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    final audio = RecordingTimerAudio();
    await pumpTimerApp(tester, repository, audio: audio);

    await tester.tap(find.text('番茄时钟'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('24:59'), findsOneWidget);
    expect(audio.tickCount, greaterThan(0));
    expect(iconButtonWithTooltip('暂停'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(iconButtonWithTooltip('关闭滴答声音'), findsOneWidget);

    tester.widget<IconButton>(iconButtonWithTooltip('暂停')).onPressed?.call();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('24:59'), findsOneWidget);
    expect(iconButtonWithTooltip('继续'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    tester.widget<IconButton>(iconButtonWithTooltip('继续')).onPressed?.call();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('24:58'), findsOneWidget);

    tester.widget<IconButton>(iconButtonWithTooltip('编辑标签')).onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('修改标签'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '专注');
    await tester.pump();
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '保存'))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    expect(find.text('专注'), findsOneWidget);

    final int ticksBeforeMute = audio.tickCount;
    tester
        .widget<IconButton>(iconButtonWithTooltip('关闭滴答声音'))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();
    expect((await repository.load()).settings.tickSoundEnabled, isFalse);
    expect(iconButtonWithTooltip('开启滴答声音'), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(audio.tickCount, ticksBeforeMute);

    await tester.tap(find.text('全屏'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭全屏'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Scaffold && widget.backgroundColor == Colors.black,
      ),
      findsOneWidget,
    );
    tester.widget<IconButton>(iconButtonWithTooltip('关闭全屏')).onPressed?.call();
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('默认倒计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('默认倒计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25分钟').last);
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.settings.defaultCountdownSeconds, 25 * 60);
    expect(find.text('25分钟'), findsOneWidget);
  });

  testWidgets('settings reminder and sound rows use bottom sheets',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    final audio = RecordingTimerAudio();
    await pumpTimerApp(tester, repository, audio: audio);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('结束提醒'));
    await tester.pumpAndSettle();
    expect(find.text('关闭'), findsOneWidget);
    expect(find.text('仅提示音'), findsOneWidget);
    expect(find.text('提示音 + 振动'), findsWidgets);
    await tester.tap(find.text('仅提示音').last);
    await tester.pumpAndSettle();
    expect(
      (await repository.load()).settings.completionReminderName,
      '仅提示音',
    );
    expect((await repository.load()).settings.completionSoundEnabled, isTrue);

    await tester.tap(find.text('提示音'));
    await tester.pumpAndSettle();
    expect(find.text('提示音'), findsWidgets);
    expect(find.text('清脆铃声'), findsWidgets);
    expect(find.text('柔和提示'), findsOneWidget);
    expect(find.text('电子提示'), findsOneWidget);
    await tester.tap(find.text('柔和提示').last);
    await tester.pumpAndSettle();
    final snapshot = await repository.load();
    expect(snapshot.settings.alertSoundName, '柔和提示');
    expect(snapshot.settings.completionSoundEnabled, isTrue);
    expect(audio.completeCount, 1);
    expect(audio.completedSoundName, '柔和提示');
  });

  testWidgets('countdown completion plays the selected ending sound',
      (WidgetTester tester) async {
    final audio = RecordingTimerAudio();
    final repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(
        timers: <CreatedTimer>[
          CreatedTimer(
            id: 'short-countdown',
            name: '短倒计时',
            seconds: 1,
            createdAt: DateTime(2026, 9, 2),
          ),
        ],
        settings: const TimerSettings(
          completionReminderName: TimerSettings.reminderSoundOnly,
          alertSoundName: '电子提示',
        ),
      ),
    );

    await pumpTimerApp(tester, repository, audio: audio);
    await tester.tap(find.text('短倒计时'));
    await tester.pump(const Duration(seconds: 2));

    expect(audio.completeCount, 1);
    expect(audio.completedSoundName, '电子提示');
  });

  testWidgets('bottom navigation pages respond to taps',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await openBatchPage(tester);
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
    expect(find.text('添加倒计时'), findsWidgets);
    expect(find.text('倒计时时长'), findsOneWidget);
    expect(find.text('倒计时名称'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
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

  testWidgets('insights calendar navigates, filters, and collapses',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(
        history: <TimerHistoryEntry>[
          TimerHistoryEntry(
            id: 'history-0',
            name: '运动',
            mode: TimerRunMode.stopwatch,
            durationSeconds: 3 * 60,
            completedAt: DateTime(2026, 8, 31),
          ),
          TimerHistoryEntry(
            id: 'history-1',
            name: '阅读',
            mode: TimerRunMode.stopwatch,
            durationSeconds: 2 * 60,
            completedAt: DateTime(2026, 9, 2),
          ),
          TimerHistoryEntry(
            id: 'history-2',
            name: '口算',
            mode: TimerRunMode.stopwatch,
            durationSeconds: 60,
            completedAt: DateTime(2026, 9, 2),
          ),
        ],
      ),
    );
    await pumpTimerApp(tester, repository);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('2026年8月30日 - 2026年9月5日'), findsOneWidget);
    expect(find.text('2026年9月'), findsOneWidget);
    expect(find.text('不同标签计时'), findsOneWidget);
    expect(find.text('运动'), findsOneWidget);
    expect(find.text('阅读'), findsOneWidget);
    expect(find.text('口算'), findsOneWidget);
    expect(find.text('03:00 · 1次'), findsOneWidget);
    expect(find.text('02:00 · 1次'), findsOneWidget);
    expect(find.text('01:00 · 1次'), findsOneWidget);
    expect(find.text('周日'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('insights-date-2026-9-10')));
    await tester.pumpAndSettle();

    expect(find.text('2026年9月6日 - 2026年9月12日'), findsOneWidget);
    expect(find.text('不同标签计时'), findsNothing);
    expect(find.text('当前范围暂无计时记录'), findsNothing);
    expect(find.text('阅读'), findsNothing);

    await tester.tap(find.byTooltip('上个月'));
    await tester.pumpAndSettle();

    expect(find.text('2026年8月'), findsOneWidget);

    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    expect(find.text('不同标签计时'), findsOneWidget);
    expect(find.text('运动'), findsOneWidget);
    expect(find.text('03:00 · 1次'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pumpAndSettle();

    expect(find.text('周日'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('settings page matches target sections',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('配色'), findsOneWidget);
    expect(find.text('提醒'), findsOneWidget);
    expect(find.text('计时'), findsWidgets);
    expect(find.text('功能反馈'), findsNothing);
  });

  testWidgets('settings row values align to the right edge',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final double reminderRight = tester.getTopRight(find.text('提示音 + 振动')).dx;
    final double soundRight = tester.getTopRight(find.text('清脆铃声')).dx;

    expect((reminderRight - soundRight).abs(), lessThan(1));
  });

  testWidgets('settings layout stays usable on small phones',
      (WidgetTester tester) async {
    await pumpTimerApp(
      tester,
      MemoryTimerRepository(),
      viewSize: const Size(375, 812),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('默认倒计时'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('默认倒计时'));
    await tester.pumpAndSettle();

    expect(find.text('默认倒计时'), findsWidgets);
    expect(find.text('25分钟'), findsOneWidget);
  });

  testWidgets('batch countdown starts in place instead of opening session',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());
    await openBatchPage(tester);

    tester
        .widget<IconButton>(iconButtonWithTooltip('开始新倒计时'))
        .onPressed
        ?.call();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('批量计时'), findsWidgets);
    expect(find.text('14:58'), findsOneWidget);
    expect(find.textContaining('结束于'), findsNothing);
    expect(iconButtonWithTooltip('暂停新倒计时'), findsOneWidget);

    tester
        .widget<IconButton>(iconButtonWithTooltip('暂停新倒计时'))
        .onPressed
        ?.call();
    await tester.pump();
  });

  testWidgets('batch stopwatch uses label sheet and runs in place',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    await pumpTimerApp(tester, repository);
    await openBatchPage(tester);
    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();

    tester.widget<IconButton>(iconButtonWithTooltip('添加标签')).onPressed?.call();
    await tester.pumpAndSettle();
    expect(find.text('添加正计时'), findsWidgets);
    expect(find.text('标签名称'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'cc');
    await tester.pump();
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '添加正计时'))
        .onPressed
        ?.call();
    await tester.pumpAndSettle();

    final snapshot = await repository.load();
    expect(snapshot.labels, contains('cc'));
    expect(find.text('批量计时'), findsWidgets);
    expect(find.text('cc'), findsOneWidget);

    await tester.longPress(find.text('cc'));
    await tester.pumpAndSettle();
    expect(find.text('修改标签'), findsOneWidget);
    expect(find.text('删除标签'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    tester.widget<IconButton>(iconButtonWithTooltip('开始cc')).onPressed?.call();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('00:02'), findsOneWidget);
    expect(find.textContaining('正计时中'), findsNothing);
    expect(iconButtonWithTooltip('暂停cc'), findsOneWidget);

    tester.widget<IconButton>(iconButtonWithTooltip('暂停cc')).onPressed?.call();
    await tester.pump();
  });

  testWidgets('batch selection marks selected card',
      (WidgetTester tester) async {
    await pumpTimerApp(tester, MemoryTimerRepository());
    await openBatchPage(tester);

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    expect(find.text('完成'), findsOneWidget);

    await tester.tap(find.text('新倒计时'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('batch delete selected removes created timers and labels',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(
        timers: <CreatedTimer>[
          CreatedTimer(
            id: 'egg',
            name: '煮鸡蛋',
            seconds: 5 * 60,
            createdAt: DateTime(2026, 9, 2),
          ),
        ],
        labels: <String>['cc'],
      ),
    );
    await pumpTimerApp(tester, repository);
    await openBatchPage(tester);

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('煮鸡蛋'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    var snapshot = await repository.load();
    expect(snapshot.timers, isEmpty);

    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('cc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    snapshot = await repository.load();
    expect(snapshot.labels, isNot(contains('cc')));
  });

  testWidgets('batch delete selected also removes default timers and labels',
      (WidgetTester tester) async {
    final repository = MemoryTimerRepository();
    await pumpTimerApp(tester, repository);
    await openBatchPage(tester);

    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新倒计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    var snapshot = await repository.load();
    expect(snapshot.hiddenDefaultTimerIds, contains('default-batch-countdown'));
    expect(find.text('新倒计时'), findsNothing);

    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新正计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    snapshot = await repository.load();
    expect(snapshot.hiddenDefaultLabels, contains('新正计时'));
    expect(find.text('新正计时'), findsNothing);
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
    expect(snapshot.timers.single.seconds,
        const TimerSettings().defaultCountdownSeconds);
  });
}
