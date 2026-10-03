import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/pages/timer_dashboard_page.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';

class _ScheduledReminder {
  const _ScheduledReminder(this.key, this.endAt, this.preferExact);

  final String key;
  final DateTime endAt;
  final bool preferExact;
}

class _RecordingNotifications implements TimerNotificationScheduler {
  _RecordingNotifications({this.status = CountdownNotificationStatus.exact});

  final CountdownNotificationStatus status;
  final List<_ScheduledReminder> scheduled = <_ScheduledReminder>[];
  final List<String> completed = <String>[];
  final List<String> cancelled = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestNotificationPermission() async =>
      status != CountdownNotificationStatus.permissionDenied;

  @override
  Future<CountdownNotificationStatus> scheduleCountdownComplete({
    required String notificationKey,
    required String timerName,
    required DateTime endAt,
    required bool vibrate,
    required bool preferExact,
  }) async {
    scheduled.add(_ScheduledReminder(notificationKey, endAt, preferExact));
    return status;
  }

  @override
  Future<void> completeCountdown({
    required String notificationKey,
    required String timerName,
    required bool vibrate,
  }) async {
    completed.add(notificationKey);
  }

  @override
  Future<void> cancelCountdownComplete(String notificationKey) async {
    cancelled.add(notificationKey);
  }
}

void main() {
  test('a completed single countdown keeps its own notification', () async {
    final DateTime startedAt = DateTime(2026, 9, 26, 10);
    DateTime now = startedAt;
    final _RecordingNotifications notifications = _RecordingNotifications();
    final List<TimerHistoryEntry> history = <TimerHistoryEntry>[];
    final TimerSession session = TimerSession(
      mode: TimerRunMode.countdown,
      name: '番茄时钟',
      initialSeconds: 10,
      settings: const TimerSettings(),
      audio: const SilentTimerAudio(),
      notifications: notifications,
      foregroundService: const DisabledTimerForegroundService(),
      onSettingsChanged: (_) async {},
      onCompleted: (TimerHistoryEntry entry) async => history.add(entry),
      now: () => now,
      notificationKey: 'single-test',
    );

    try {
      expect(notifications.scheduled.single.key, 'single-test');
      expect(notifications.scheduled.single.endAt,
          startedAt.add(const Duration(seconds: 10)));
      expect(notifications.scheduled.single.preferExact, isTrue);

      now = startedAt.add(const Duration(seconds: 10));
      session.toggleRunning();
      await Future<void>.delayed(Duration.zero);

      expect(notifications.completed, <String>['single-test']);
      expect(notifications.cancelled, isEmpty);
      expect(history, hasLength(1));
      session.rename('新名称');
      expect(notifications.cancelled, isEmpty);
    } finally {
      session.dispose();
    }
    expect(notifications.cancelled, isEmpty);
  });

  test('notification permission failure is visible to the running session',
      () async {
    final _RecordingNotifications notifications = _RecordingNotifications(
      status: CountdownNotificationStatus.permissionDenied,
    );
    final TimerSession session = TimerSession(
      mode: TimerRunMode.countdown,
      name: '专注',
      initialSeconds: 60,
      settings: const TimerSettings(),
      audio: const SilentTimerAudio(),
      notifications: notifications,
      foregroundService: const DisabledTimerForegroundService(),
      onSettingsChanged: (_) async {},
      onCompleted: (_) async {},
    );

    try {
      await Future<void>.delayed(Duration.zero);
      expect(session.reminderWarning, contains('通知权限未开启'));
    } finally {
      session.dispose();
    }
  });

  test(
      'notification deadlines retain subsecond progress after rename and pause',
      () async {
    final DateTime startedAt = DateTime(2026, 10, 3, 10);
    DateTime now = startedAt;
    final _RecordingNotifications notifications = _RecordingNotifications();
    final TimerSession session = TimerSession(
      mode: TimerRunMode.countdown,
      name: '专注',
      initialSeconds: 10,
      settings: const TimerSettings(),
      audio: const SilentTimerAudio(),
      notifications: notifications,
      onSettingsChanged: (_) async {},
      onCompleted: (_) async {},
      now: () => now,
    );
    addTearDown(session.dispose);

    now = startedAt.add(const Duration(milliseconds: 1250));
    session.rename('新名称');
    expect(notifications.scheduled.last.endAt,
        startedAt.add(const Duration(seconds: 10)));
    session.toggleRunning();
    now = startedAt.add(const Duration(seconds: 5));
    session.toggleRunning();
    expect(notifications.scheduled.last.endAt,
        startedAt.add(const Duration(milliseconds: 13750)));
  });

  testWidgets('batch countdowns have independent reminders and catch up',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final DateTime startedAt = DateTime(2026, 9, 26, 10);
    DateTime now = startedAt;
    final _RecordingNotifications notifications = _RecordingNotifications();
    final TimerSnapshot snapshot = TimerSnapshot.initial().copyWith(
      hiddenDefaultTimerIds: <String>['default-batch-countdown'],
      timers: <CreatedTimer>[
        CreatedTimer(
          id: 'a',
          name: '甲',
          seconds: 10,
          createdAt: startedAt,
        ),
        CreatedTimer(
          id: 'b',
          name: '乙',
          seconds: 20,
          createdAt: startedAt,
        ),
        CreatedTimer(
          id: 'c',
          name: '丙',
          seconds: 25,
          createdAt: startedAt,
        ),
      ],
    );
    await tester.pumpWidget(TimerApp(
      repository: MemoryTimerRepository(snapshot),
      audio: const SilentTimerAudio(),
      notifications: notifications,
      foregroundService: const DisabledTimerForegroundService(),
      now: () => now,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部开始'));
    await tester.pump();
    expect(notifications.scheduled.map((entry) => entry.key).toSet(),
        <String>{'batch:a', 'batch:b', 'batch:c'});
    expect(notifications.scheduled.every((entry) => entry.preferExact), isTrue);

    now = startedAt.add(const Duration(seconds: 3));
    await tester.tap(find.byTooltip('暂停甲'));
    await tester.pump();
    expect(notifications.cancelled, contains('batch:a'));
    expect(notifications.cancelled, isNot(contains('batch:b')));

    now = startedAt.add(const Duration(seconds: 22));
    await tester.tap(find.byTooltip('暂停乙'));
    await tester.pump();
    expect(notifications.completed, <String>['batch:b']);
    expect(notifications.cancelled, isNot(contains('batch:b')));

    now = startedAt.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(notifications.completed, <String>['batch:b', 'batch:c']);
    expect(notifications.cancelled, isNot(contains('batch:c')));
  });

  test('notification keys generate distinct stable Android IDs', () {
    expect(countdownNotificationId('batch:a'),
        isNot(countdownNotificationId('batch:b')));
    expect(
        countdownNotificationId('batch:a'), countdownNotificationId('batch:a'));
  });
}
