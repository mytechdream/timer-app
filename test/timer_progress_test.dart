import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/pages/timer_dashboard_page.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/theme/app_theme.dart';
import 'package:timer_app/widgets/timer_progress_builder.dart';

TimerSession _session(DateTime Function() now) => TimerSession(
      mode: TimerRunMode.countdown,
      name: '平滑进度',
      initialSeconds: 10,
      settings: const TimerSettings(tickSoundEnabled: false),
      audio: const SilentTimerAudio(),
      onSettingsChanged: (_) async {},
      onCompleted: (_) async {},
      now: now,
    );

double _paintedProgress(WidgetTester tester, {int index = 0}) {
  final Finder builder = find.descendant(
    of: find.byType(TimerProgressBuilder).at(index),
    matching: find.byType(ValueListenableBuilder<double>),
  );
  return tester
      .widget<ValueListenableBuilder<double>>(builder)
      .valueListenable
      .value;
}

void main() {
  test('countdown progress decreases between whole-second ticks', () {
    final DateTime start = DateTime(2026, 10, 3, 10);
    DateTime now = start;
    final TimerSession session = _session(() => now);
    addTearDown(session.dispose);

    now = start.add(const Duration(milliseconds: 250));
    expect(session.countdownProgress, closeTo(0.975, 0.000001));
    expect(session.displaySeconds, 10);
    now = start.add(const Duration(milliseconds: 750));
    expect(session.countdownProgress, closeTo(0.925, 0.000001));
    expect(session.displaySeconds, 10);
  });

  test('pause and resume preserve fractional remaining time and deadline', () {
    final DateTime start = DateTime(2026, 10, 3, 10);
    DateTime now = start;
    final TimerSession session = _session(() => now);
    addTearDown(session.dispose);

    now = start.add(const Duration(milliseconds: 1250));
    session.toggleRunning();
    expect(session.countdownProgress, closeTo(0.875, 0.000001));
    expect(session.displaySeconds, 9);
    expect(session.countdownEndAt, isNull);

    now = start.add(const Duration(seconds: 5));
    expect(session.countdownProgress, closeTo(0.875, 0.000001));
    session.toggleRunning();
    expect(session.countdownProgress, closeTo(0.875, 0.000001));
    expect(
        session.countdownEndAt, start.add(const Duration(milliseconds: 13750)));
    now = start.add(const Duration(milliseconds: 5500));
    expect(session.countdownProgress, closeTo(0.825, 0.000001));
  });

  test('extend and rename do not round the real countdown deadline', () {
    final DateTime start = DateTime(2026, 10, 3, 10);
    DateTime now = start;
    final TimerSession session = _session(() => now);
    addTearDown(session.dispose);

    now = start.add(const Duration(milliseconds: 2250));
    session.rename('新名称');
    expect(session.countdownEndAt, start.add(const Duration(seconds: 10)));
    session.extend(1);
    expect(session.countdownProgress, closeTo(0.875, 0.000001));
    expect(session.countdownEndAt, start.add(const Duration(seconds: 11)));
    session.reset();
    expect(session.countdownProgress, 1);
    expect(
        session.countdownEndAt, start.add(const Duration(milliseconds: 12250)));
  });

  test('progress catches up immediately after missing foreground frames', () {
    final DateTime start = DateTime(2026, 10, 3, 10);
    DateTime now = start;
    final TimerSession session = _session(() => now);
    addTearDown(session.dispose);

    now = start.add(const Duration(milliseconds: 8500));
    expect(session.countdownProgress, closeTo(0.15, 0.000001));
    now = start.add(const Duration(seconds: 20));
    expect(session.countdownProgress, 0);
  });

  testWidgets('ring paints subsecond progress while its text stays unchanged',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final TimerSession session = _session(tester.binding.clock.now);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.build(AppTheme.palettes[1]),
      home: RunningTimerPage(session: session),
    ));
    await tester.pump();
    final double before = _paintedProgress(tester);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_paintedProgress(tester), closeTo(before - 0.025, 0.000001));
    expect(find.text('00:10'), findsOneWidget);

    session.toggleRunning();
    await tester.pump();
    final double paused = _paintedProgress(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_paintedProgress(tester), paused);
    expect(tester.binding.hasScheduledFrame, isFalse);

    session.toggleRunning();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(_paintedProgress(tester), closeTo(paused - 0.025, 0.000001));

    await tester.tap(find.text('全屏'));
    await tester.pump();
    await tester.pump();
    final double fullscreenBefore = _paintedProgress(tester);
    await tester.pump(const Duration(milliseconds: 250));
    expect(
        _paintedProgress(tester), closeTo(fullscreenBefore - 0.025, 0.000001));
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        closeTo(session.countdownProgress, 0.000001));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion and hidden progress do not schedule frame loops',
      (WidgetTester tester) async {
    double progress = 1;
    Widget frame({required bool reduceMotion, required bool visible}) =>
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: TickerMode(
              enabled: visible,
              child: TimerProgressBuilder(
                progress: () => progress,
                running: true,
                builder: (_, double value, __) => Text('$value'),
              ),
            ),
          ),
        );

    await tester.pumpWidget(frame(reduceMotion: true, visible: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    progress = 0.6;
    await tester.pumpWidget(frame(reduceMotion: true, visible: true));
    expect(find.text('0.6'), findsOneWidget);

    await tester.pumpWidget(frame(reduceMotion: false, visible: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(frame(reduceMotion: false, visible: false));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    progress = 0.2;
    await tester.pumpWidget(frame(reduceMotion: false, visible: true));
    await tester.pump();
    expect(find.text('0.2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
