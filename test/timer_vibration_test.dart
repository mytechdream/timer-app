import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/pages/timer_dashboard_page.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';
import 'package:timer_app/services/timer_vibration.dart';

const MethodChannel _vibrationChannel = MethodChannel('timer_app/vibration');

void main() {
  final TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> vibrationCalls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    vibrationCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_vibrationChannel, (MethodCall call) async {
      vibrationCalls.add(call);
      return true;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_vibrationChannel, null);
    debugDefaultTargetPlatformOverride = null;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  Future<void> completeSession({
    TimerSettings settings = const TimerSettings(),
    Duration elapsed = const Duration(seconds: 1),
    TimerRunMode mode = TimerRunMode.countdown,
    Future<void> Function(TimerHistoryEntry)? onCompleted,
  }) async {
    final DateTime startedAt = DateTime(2026, 10, 3, 10);
    DateTime now = startedAt;
    final TimerSession session = TimerSession(
      mode: mode,
      name: '振动测试',
      initialSeconds: 1,
      settings: settings,
      audio: const SilentTimerAudio(),
      onSettingsChanged: (_) async {},
      onCompleted: onCompleted ?? (_) async {},
      now: () => now,
    );
    addTearDown(session.dispose);

    now = startedAt.add(elapsed);
    session.toggleRunning();
    await Future<void>.delayed(Duration.zero);
  }

  test('an enabled foreground countdown sends an alarm vibration request',
      () async {
    await completeSession();
    expect(vibrationCalls, hasLength(1),
        reason: 'Sound + vibration must reach the vibrator at completion, '
            'even when system notifications are unavailable.');
    expect(vibrationCalls.single.method, 'vibrateCountdownComplete');
    expect(
        vibrationCalls.single.arguments['pattern'], countdownVibrationPattern);
  });

  for (final String reminder in <String>[
    TimerSettings.reminderOff,
    TimerSettings.reminderSoundOnly,
  ]) {
    test('$reminder does not request a vibration', () async {
      await completeSession(
          settings: TimerSettings(completionReminderName: reminder));
      expect(vibrationCalls, isEmpty);
    });
  }

  test('vibration does not depend on the completion sound player', () async {
    await completeSession(
        settings: const TimerSettings(completionSoundEnabled: false));
    expect(vibrationCalls, hasLength(1));
  });

  test('a stopwatch never triggers a countdown vibration', () async {
    await completeSession(mode: TimerRunMode.stopwatch);
    expect(vibrationCalls, isEmpty);
  });

  test('a countdown that has not finished does not vibrate', () async {
    await completeSession(elapsed: const Duration(milliseconds: 500));
    expect(vibrationCalls, isEmpty);
  });

  test('an overdue countdown does not replay an old background alert',
      () async {
    await completeSession(elapsed: const Duration(seconds: 30));
    expect(vibrationCalls, isEmpty);
  });

  for (final AppLifecycleState state in <AppLifecycleState>[
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  ]) {
    test('$state delegates vibration to the scheduled notification', () async {
      binding.handleAppLifecycleStateChanged(state);
      await completeSession();
      expect(vibrationCalls, isEmpty);
    });
  }

  for (final Object failure in <Object>[
    PlatformException(code: 'vibration_denied'),
    MissingPluginException('No vibrator plugin on this platform'),
  ]) {
    test('$failure does not prevent saving the completed countdown', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              _vibrationChannel, (MethodCall call) async => throw failure);
      final List<TimerHistoryEntry> history = <TimerHistoryEntry>[];
      await completeSession(
          onCompleted: (TimerHistoryEntry entry) async => history.add(entry));
      expect(history, hasLength(1));
    });
  }

  test('non-Android platforms do not call the Android vibration channel',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await completeSession();
    expect(vibrationCalls, isEmpty);
  });

  Future<void> pumpApp(WidgetTester tester, TimerRepository repository,
      DateTime Function() now) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(TimerApp(
      repository: repository,
      audio: const SilentTimerAudio(),
      notifications: const DisabledTimerNotificationScheduler(),
      foregroundService: const DisabledTimerForegroundService(),
      now: now,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the actual app vibrates when the selected countdown completes',
      (WidgetTester tester) async {
    final DateTime startedAt = DateTime(2026, 10, 3, 10);
    DateTime now = startedAt;
    final MemoryTimerRepository repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(
        settings: const TimerSettings(defaultCountdownSeconds: 1),
      ),
    );
    try {
      await pumpApp(tester, repository, () => now);
      await tester.tap(find.text('开始 00:01'));
      await tester.pump();
      now = startedAt.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(vibrationCalls, hasLength(1));
      expect((await repository.load()).history, hasLength(1));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('batch countdowns each vibrate once without notifications',
      (WidgetTester tester) async {
    final DateTime startedAt = DateTime(2026, 10, 3, 10);
    DateTime now = startedAt;
    final MemoryTimerRepository repository = MemoryTimerRepository(
      TimerSnapshot.initial().copyWith(
        hiddenDefaultTimerIds: <String>['default-batch-countdown'],
        timers: <CreatedTimer>[
          CreatedTimer(id: 'a', name: '甲', seconds: 1, createdAt: startedAt),
          CreatedTimer(id: 'b', name: '乙', seconds: 2, createdAt: startedAt),
        ],
      ),
    );
    try {
      await pumpApp(tester, repository, () => now);
      await tester.tap(find.byIcon(Icons.layers_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部开始'));
      await tester.pump();
      now = startedAt.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(vibrationCalls, hasLength(1));
      now = startedAt.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(vibrationCalls, hasLength(2));
      await tester.pump(const Duration(seconds: 1));
      expect(vibrationCalls, hasLength(2));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
