import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';
import 'package:timer_app/widgets/app_bottom_nav.dart';

Future<void> _pumpApp(WidgetTester tester, TimerRepository repository) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(TimerApp(
    repository: repository,
    audio: const SilentTimerAudio(),
    notifications: const DisabledTimerNotificationScheduler(),
    foregroundService: const DisabledTimerForegroundService(),
    now: tester.binding.clock.now,
  ));
  await tester.pumpAndSettle();
}

Finder _button(String tooltip) => find.byWidgetPredicate(
    (Widget widget) => widget is IconButton && widget.tooltip == tooltip);

// Use the same encoded snapshot as SQLite, so a restart cannot pass by
// retaining an in-memory object with unsaved state.
class _JsonRepository implements TimerRepository {
  _JsonRepository([TimerSnapshot? initial])
      : encoded = jsonEncode((initial ?? TimerSnapshot.initial()).toJson());

  String encoded;

  @override
  Future<TimerSnapshot> load() async =>
      TimerSnapshot.fromJson(jsonDecode(encoded) as Map<String, Object?>);

  @override
  Future<void> save(TimerSnapshot snapshot) async {
    encoded = jsonEncode(snapshot.toJson());
  }
}

Future<void> _openPage(WidgetTester tester, TimerCollectionScope scope) async {
  await tester.tap(find.descendant(
    of: find.byType(AppBottomNav),
    matching: find.text(scope == TimerCollectionScope.home ? '计时' : '批量计时'),
  ));
  await tester.pumpAndSettle();
}

Future<void> _restart(WidgetTester tester, TimerRepository repository) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
  await _pumpApp(tester, repository);
}

Future<void> _createCountdown(
    WidgetTester tester, TimerCollectionScope scope, String name) async {
  await _openPage(tester, scope);
  tester.widget<IconButton>(_button('创建倒计时')).onPressed!();
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, name);
  if (scope == TimerCollectionScope.home) {
    await tester.tap(find.text('保存'));
  } else {
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '添加倒计时'))
        .onPressed!();
  }
  await tester.pumpAndSettle();
}

Future<void> _createLabel(
    WidgetTester tester, TimerCollectionScope scope, String label) async {
  await _openPage(tester, scope);
  await tester.tap(find.text('正计时'));
  await tester.pumpAndSettle();
  tester.widget<IconButton>(_button('添加标签')).onPressed!();
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, label);
  await tester.pump();
  expect(find.text('标签已存在'), findsNothing);
  if (scope == TimerCollectionScope.home) {
    await tester.tap(find.text('保存'));
  } else {
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '添加正计时'))
        .onPressed!();
  }
  await tester.pumpAndSettle();
}

CreatedTimer _timer({String id = 'shared', String name = '同名计时'}) =>
    CreatedTimer(
      id: id,
      name: name,
      seconds: 600,
      createdAt: DateTime(2026, 10, 12),
    );

TimerSnapshot _sharedCopies() => TimerSnapshot.initial().copyWith(
      timers: <CreatedTimer>[_timer()],
      labels: <String>['同名标签'],
      batch: TimerCollection(
        scope: TimerCollectionScope.batch,
        timers: <CreatedTimer>[_timer()],
        labels: <String>['同名标签'],
      ),
    );

Future<void> _deleteCountdown(WidgetTester tester, String name) async {
  await tester.ensureVisible(find.text(name));
  await tester.longPress(find.text(name));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, '删除'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a countdown created on home does not appear in batch timers',
      (WidgetTester tester) async {
    final MemoryTimerRepository repository = MemoryTimerRepository();
    await _pumpApp(tester, repository);
    tester.widget<IconButton>(_button('创建倒计时')).onPressed!();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '仅首页计时');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('仅首页计时'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();
    expect(find.text('仅首页计时'), findsNothing,
        reason: 'Home and batch countdown collections must be independent.');
  });

  testWidgets('a batch countdown stays out of home after an app restart',
      (WidgetTester tester) async {
    final _JsonRepository repository = _JsonRepository();
    await _pumpApp(tester, repository);
    await _createCountdown(tester, TimerCollectionScope.batch, '仅批量计时');
    final TimerSnapshot stored = await repository.load();
    expect(stored.timers, isEmpty);
    expect(stored.batch.timers.single.name, '仅批量计时');
    await _restart(tester, repository);
    expect(find.text('仅批量计时'), findsNothing);
    await _openPage(tester, TimerCollectionScope.batch);
    expect(find.text('仅批量计时'), findsOneWidget);
  });

  for (final TimerCollectionScope scope in TimerCollectionScope.values) {
    final TimerCollectionScope other = scope == TimerCollectionScope.home
        ? TimerCollectionScope.batch
        : TimerCollectionScope.home;

    testWidgets('$scope countdown creation persists only in its own page',
        (WidgetTester tester) async {
      final _JsonRepository repository = _JsonRepository();
      await _pumpApp(tester, repository);
      await _createCountdown(tester, scope, '独立计时');
      await _restart(tester, repository);
      await _openPage(tester, other);
      expect(find.text('独立计时'), findsNothing);
      await _openPage(tester, scope);
      expect(find.text('独立计时'), findsOneWidget);
    });

    testWidgets('$scope countdown deletion does not delete the other copy',
        (WidgetTester tester) async {
      final _JsonRepository repository = _JsonRepository(_sharedCopies());
      await _pumpApp(tester, repository);
      await _openPage(tester, scope);
      await _deleteCountdown(tester, '同名计时');
      final TimerSnapshot snapshot = await repository.load();
      expect(snapshot.collection(scope).timers, isEmpty);
      expect(snapshot.collection(other).timers.single.id, 'shared');
      await _restart(tester, repository);
      await _openPage(tester, scope);
      expect(find.text('同名计时'), findsNothing);
      await _openPage(tester, other);
      expect(find.text('同名计时'), findsOneWidget);
    });

    testWidgets('$scope can add the same custom label as the other page',
        (WidgetTester tester) async {
      final TimerSnapshot initial = TimerSnapshot.initial().withCollection(
          TimerCollection(scope: other, labels: const <String>['独立标签']));
      final _JsonRepository repository = _JsonRepository(initial);
      await _pumpApp(tester, repository);
      await _createLabel(tester, scope, '独立标签');
      final TimerSnapshot snapshot = await repository.load();
      expect(snapshot.collection(scope).labels, <String>['独立标签']);
      expect(snapshot.collection(other).labels, <String>['独立标签']);
      await _restart(tester, repository);
      await _openPage(tester, scope);
      await tester.tap(find.text('正计时'));
      await tester.pumpAndSettle();
      expect(find.text('独立标签'), findsOneWidget);
    });

    testWidgets('$scope can add and remove a label reserved by the other page',
        (WidgetTester tester) async {
      final _JsonRepository repository = _JsonRepository();
      final String label = TimerDefaults.stopwatchLabelsFor(other).first;
      await _pumpApp(tester, repository);
      await _createLabel(tester, scope, label);
      expect(
          (await repository.load()).collection(scope).labels, <String>[label]);
      await tester.longPress(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除标签'));
      await tester.pumpAndSettle();
      final TimerSnapshot snapshot = await repository.load();
      expect(snapshot.collection(scope).labels, isEmpty);
      expect(snapshot.collection(other).hiddenDefaultLabels, isEmpty);
      await _restart(tester, repository);
      await _openPage(tester, other);
      await tester.tap(find.text('正计时'));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
    });

    testWidgets('$scope label rename uses only its own duplicate check',
        (WidgetTester tester) async {
      final TimerSnapshot initial = _sharedCopies()
          .withCollection(_sharedCopies().collection(other).addLabel('目标标签'));
      final _JsonRepository repository = _JsonRepository(initial);
      await _pumpApp(tester, repository);
      await _openPage(tester, scope);
      await tester.tap(find.text('正计时'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('同名标签'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '目标标签');
      await tester.pump();
      expect(find.text('标签已存在'), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, '保存'));
      await tester.pumpAndSettle();
      final TimerSnapshot snapshot = await repository.load();
      expect(snapshot.collection(scope).labels, <String>['目标标签']);
      expect(snapshot.collection(other).labels, <String>['同名标签', '目标标签']);
      await _restart(tester, repository);
      await _openPage(tester, other);
      await tester.tap(find.text('正计时'));
      await tester.pumpAndSettle();
      expect(find.text('同名标签'), findsOneWidget);
      expect(find.text('目标标签'), findsOneWidget);
    });

    testWidgets('$scope label deletion does not delete the other copy',
        (WidgetTester tester) async {
      final _JsonRepository repository = _JsonRepository(_sharedCopies());
      await _pumpApp(tester, repository);
      await _openPage(tester, scope);
      await tester.tap(find.text('正计时'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('同名标签'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除标签'));
      await tester.pumpAndSettle();
      final TimerSnapshot snapshot = await repository.load();
      expect(snapshot.collection(scope).labels, isEmpty);
      expect(snapshot.collection(other).labels, <String>['同名标签']);
      await _restart(tester, repository);
      await _openPage(tester, other);
      await tester.tap(find.text('正计时'));
      await tester.pumpAndSettle();
      expect(find.text('同名标签'), findsOneWidget);
    });
  }

  testWidgets('batch multi-delete keeps home countdowns and labels',
      (WidgetTester tester) async {
    final TimerSnapshot initial = _sharedCopies().withCollection(_sharedCopies()
        .batch
        .addTimer(_timer(id: 'second', name: '第二个计时'))
        .addLabel('第二个标签'));
    final _JsonRepository repository = _JsonRepository(initial);
    await _pumpApp(tester, repository);
    await _openPage(tester, TimerCollectionScope.batch);
    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同名计时'));
    await tester.tap(find.text('第二个计时'));
    await tester.pump();
    await tester.tap(find.text('删除选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('正计时'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同名标签'));
    await tester.tap(find.text('第二个标签'));
    await tester.pump();
    await tester.tap(find.text('删除选中'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    final TimerSnapshot snapshot = await repository.load();
    expect(snapshot.batch.timers, isEmpty);
    expect(snapshot.batch.labels, isEmpty);
    expect(snapshot.timers.single.name, '同名计时');
    expect(snapshot.labels, <String>['同名标签']);
  });

  testWidgets(
      'home deletion does not stop a running batch timer with the same ID',
      (WidgetTester tester) async {
    final _JsonRepository repository = _JsonRepository(_sharedCopies());
    await _pumpApp(tester, repository);
    await _openPage(tester, TimerCollectionScope.batch);
    tester.widget<IconButton>(_button('开始同名计时')).onPressed!();
    await tester.pump();
    await _openPage(tester, TimerCollectionScope.home);
    await _deleteCountdown(tester, '同名计时');
    await _openPage(tester, TimerCollectionScope.batch);
    expect(_button('暂停同名计时'), findsOneWidget);
    final TimerSnapshot snapshot = await repository.load();
    expect(snapshot.timers, isEmpty);
    expect(snapshot.batch.timers.single.id, 'shared');
    tester.widget<IconButton>(_button('暂停同名计时')).onPressed!();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
