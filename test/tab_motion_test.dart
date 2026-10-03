import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';
import 'package:timer_app/theme/app_theme.dart';
import 'package:timer_app/widgets/animated_tab_stack.dart';
import 'package:timer_app/widgets/app_bottom_nav.dart';
import 'package:timer_app/widgets/segmented_pill.dart';

class _TabHarness extends StatefulWidget {
  const _TabHarness({required this.mounts});

  final List<int> mounts;

  @override
  State<_TabHarness> createState() => _TabHarnessState();
}

class _TabHarnessState extends State<_TabHarness> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AnimatedTabStack(
          index: _index,
          children: <Widget>[
            for (int i = 0; i < 4; i++)
              _CounterTab(
                key: ValueKey<int>(i),
                index: i,
                onMounted: () => widget.mounts[i]++,
              ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          index: _index,
          onChanged: (int index) => setState(() => _index = index),
        ),
      );
}

class _CounterTab extends StatefulWidget {
  const _CounterTab({
    super.key,
    required this.index,
    required this.onMounted,
  });

  final int index;
  final VoidCallback onMounted;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    widget.onMounted();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Tab ${widget.index}: $_count'),
            FilledButton(
              onPressed: () => setState(() => _count++),
              child: Text('Increase ${widget.index}'),
            ),
          ],
        ),
      );
}

Widget _app(Widget home, {bool reduceMotion = false, double textScale = 1}) =>
    MaterialApp(
      theme: AppTheme.build(AppTheme.palettes[1]),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    );

Finder _indicator(String key) => find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: find.byType(FractionallySizedBox),
    );

void main() {
  testWidgets('tab transitions retarget rapid taps and preserve page state',
      (WidgetTester tester) async {
    final List<int> mounts = List<int>.filled(4, 0);
    await tester.pumpWidget(_app(_TabHarness(mounts: mounts)));
    await tester.tap(find.text('Increase 0'));
    await tester.pumpAndSettle();
    expect(find.text('Tab 0: 1'), findsOneWidget);

    await tester.tap(find.text('批量计时'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final Iterable<Opacity> fades = tester.widgetList<Opacity>(find.descendant(
      of: find.byType(AnimatedTabStack),
      matching: find.byType(Opacity),
    ));
    expect(fades.any((Opacity fade) => fade.opacity > 0 && fade.opacity < 1),
        isTrue);

    await tester.tap(find.text('设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('数据洞察'));
    await tester.pumpAndSettle();
    expect(find.text('Tab 2: 0'), findsOneWidget);
    expect(find.text('Tab 1: 0'), findsNothing);
    expect(find.text('Tab 3: 0'), findsNothing);

    await tester.tap(find.text('计时'));
    await tester.pumpAndSettle();
    expect(find.text('Tab 0: 1'), findsOneWidget);
    expect(mounts, <int>[1, 1, 1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom indicator moves continuously and settles on the last tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app(_TabHarness(mounts: List<int>.filled(4, 0))));
    final Finder indicator = _indicator('bottom-nav-indicator');
    final double start = tester.getCenter(indicator).dx;
    final double end = tester.getCenter(find.text('设置')).dx;

    await tester.tap(find.text('设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getCenter(indicator).dx, greaterThan(start));
    expect(tester.getCenter(indicator).dx, lessThan(end));
    await tester.tap(find.text('批量计时'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.tap(find.text('计时'));
    await tester.pumpAndSettle();
    expect(tester.getCenter(indicator).dx, closeTo(start, 0.01));

    final Finder selected = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.byWidgetPredicate((Widget widget) =>
          widget is Semantics && widget.properties.selected == true),
    );
    expect(selected, findsOneWidget);
    expect(find.descendant(of: selected, matching: find.text('计时')),
        findsOneWidget);
  });

  testWidgets('mode indicator slides rather than replacing its background',
      (WidgetTester tester) async {
    int selected = 0;
    await tester.pumpWidget(_app(Scaffold(
      body: Center(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              SegmentedPill(
            items: const <String>['倒计时', '正计时'],
            selectedIndex: selected,
            onChanged: (int index) => setState(() => selected = index),
          ),
        ),
      ),
    )));
    final Finder indicator = _indicator('segment-indicator');
    final double start = tester.getCenter(indicator).dx;
    await tester.tap(find.text('正计时'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getCenter(indicator).dx, greaterThan(start));
    expect(tester.getCenter(indicator).dx,
        lessThan(tester.getCenter(find.text('正计时')).dx));
    await tester.pumpAndSettle();
    expect(tester.getCenter(indicator).dx,
        closeTo(tester.getCenter(find.text('正计时')).dx, 0.01));
  });

  testWidgets('reduced motion switches tabs immediately without a fade loop',
      (WidgetTester tester) async {
    final List<int> mounts = List<int>.filled(4, 0);
    await tester
        .pumpWidget(_app(_TabHarness(mounts: mounts), reduceMotion: true));
    tester.widget<AppBottomNav>(find.byType(AppBottomNav)).onChanged(3);
    await tester.pump();
    expect(find.text('Tab 3: 0'), findsOneWidget);
    expect(find.text('Tab 0: 0'), findsNothing);
    expect(tester.getCenter(_indicator('bottom-nav-indicator')).dx,
        closeTo(tester.getCenter(find.text('设置')).dx, 0.01));
    // Flush the final paint scheduled by a zero-duration implicit animation.
    // No virtual time is advanced and there must not be a continuing frame loop.
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(mounts, <int>[1, 1, 1, 1]);
  });

  for (final Size size in <Size>[
    const Size(375, 812),
    const Size(812, 375),
  ]) {
    testWidgets('navigation stays usable at $size with large text',
        (WidgetTester tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _app(_TabHarness(mounts: List<int>.filled(4, 0)), textScale: 2),
      );
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 3: 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_indicator('bottom-nav-indicator')).height,
          greaterThanOrEqualTo(48));
    });
  }

  testWidgets('reduced motion also applies to the timer mode content',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(
      TimerApp(
        repository: MemoryTimerRepository(),
        audio: const SilentTimerAudio(),
        notifications: const DisabledTimerNotificationScheduler(),
        foregroundService: const DisabledTimerForegroundService(),
      ),
      reduceMotion: true,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('正计时'));
    await tester.pump();
    await tester.pump();
    expect(find.text('选择正计时标签'), findsOneWidget);
    expect(find.text('选择倒计时时长'), findsNothing);
  });
}
