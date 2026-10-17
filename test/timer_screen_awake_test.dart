import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/pages/timer_dashboard_page.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_screen_awake.dart';
import 'package:timer_app/theme/app_theme.dart';

const MethodChannel _screenAwakeChannel =
    MethodChannel('timer_app/screen_awake');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_screenAwakeChannel, (MethodCall call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_screenAwakeChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android registers the same screen-awake channel used by Dart', () {
    // Flutter mocks cannot detect a missing native channel registration.
    // Check the shipped Activity as well as exercising the real Dart adapter.
    final String activity = File(
      'android/app/src/main/kotlin/com/example/timer_app/MainActivity.kt',
    ).readAsStringSync();
    final RegExp registration = RegExp(
      r'MethodChannel\(flutterEngine\.dartExecutor\.binaryMessenger,\s*'
      r'"timer_app/screen_awake"\)\s*\.setMethodCallHandler',
    );
    expect(registration.hasMatch(activity), isTrue,
        reason: 'Android must handle timer_app/screen_awake; a handler on '
            'timer_app/background_timer cannot receive these calls.');
    final String handler = activity
        .substring(registration.firstMatch(activity)!.end)
        .split('MethodChannel(')
        .first;
    expect(handler, contains('"setKeepScreenOn" ->'));
    expect(handler, contains('call.argument<Boolean>("enabled")'));
    expect(
        handler,
        contains(
            'window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)'));
    expect(
        handler,
        contains(
            'window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)'));
  });

  test('the Android adapter sends enable and disable on its native channel',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const AndroidTimerScreenAwake screenAwake = AndroidTimerScreenAwake();
    await screenAwake.setEnabled(true);
    await screenAwake.setEnabled(false);
    expect(calls.map((MethodCall call) => call.method),
        <String>['setKeepScreenOn', 'setKeepScreenOn']);
    expect(calls.map((MethodCall call) => call.arguments), <Map<String, bool>>[
      <String, bool>{'enabled': true},
      <String, bool>{'enabled': false},
    ]);
  });

  test('non-Android platforms do not request an Android screen flag', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await const AndroidTimerScreenAwake().setEnabled(true);
    await const AndroidTimerScreenAwake().setEnabled(false);
    expect(calls, isEmpty);
  });

  test('missing plugins and platform failures do not break the timer',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_screenAwakeChannel, null);
    await const AndroidTimerScreenAwake().setEnabled(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_screenAwakeChannel, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    await const AndroidTimerScreenAwake().setEnabled(false);
  });

  Future<TimerSession> pumpTimer(
    WidgetTester tester, {
    TimerRunMode mode = TimerRunMode.countdown,
  }) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final TimerSession session = TimerSession(
      mode: mode,
      name: '常亮测试',
      initialSeconds: 10,
      settings: const TimerSettings(
        tickSoundEnabled: false,
        completionReminderName: TimerSettings.reminderOff,
      ),
      audio: const SilentTimerAudio(),
      onSettingsChanged: (_) async {},
      onCompleted: (_) async {},
      now: tester.binding.clock.now,
    );
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.build(AppTheme.palettes[1]),
      home: RunningTimerPage(session: session),
    ));
    await tester.pump();
    return session;
  }

  Future<void> enterFullscreen(WidgetTester tester) async {
    await tester.tap(find.text('全屏'));
    await tester.pump();
    await tester.pump();
  }

  Future<void> leaveFullscreen(WidgetTester tester) async {
    await tester.tap(find.byTooltip('关闭全屏'));
    await tester.pump();
    await tester.pump();
  }

  List<bool> enabledStates() => calls
      .map((MethodCall call) =>
          (call.arguments as Map<Object?, Object?>)['enabled']! as bool)
      .toList();

  testWidgets('only fullscreen keeps awake, including while paused',
      (WidgetTester tester) async {
    final TimerSession session = await pumpTimer(tester);
    expect(calls, isEmpty, reason: 'The ordinary timer must not keep awake.');
    await enterFullscreen(tester);
    expect(enabledStates(), <bool>[true]);
    session.toggleRunning();
    await tester.pump();
    expect(enabledStates(), <bool>[true],
        reason: 'Pausing is not ending fullscreen.');
    await leaveFullscreen(tester);
    expect(enabledStates(), <bool>[true, false]);
    await enterFullscreen(tester);
    expect(enabledStates(), <bool>[true, false, true]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(enabledStates(), <bool>[true, false, true, false]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('completion releases awake and restarting enables it again',
      (WidgetTester tester) async {
    final TimerSession session = await pumpTimer(tester);
    await enterFullscreen(tester);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(enabledStates(), <bool>[true, false]);
    await leaveFullscreen(tester);
    await enterFullscreen(tester);
    expect(enabledStates(), <bool>[true, false, false],
        reason: 'A completed countdown must not request awake on re-entry.');
    session.toggleRunning();
    await tester.pump();
    expect(enabledStates(), <bool>[true, false, false, true]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(enabledStates(), <bool>[true, false, false, true, false]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a fullscreen stopwatch stays awake until fullscreen is closed',
      (WidgetTester tester) async {
    final TimerSession session =
        await pumpTimer(tester, mode: TimerRunMode.stopwatch);
    await enterFullscreen(tester);
    await tester.pump(const Duration(seconds: 15));
    session.toggleRunning();
    await tester.pump();
    expect(enabledStates(), <bool>[true]);
    await leaveFullscreen(tester);
    expect(enabledStates(), <bool>[true, false]);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
