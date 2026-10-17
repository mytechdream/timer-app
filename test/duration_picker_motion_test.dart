import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';
import 'package:timer_app/theme/app_theme.dart';
import 'package:timer_app/widgets/duration_picker_card.dart';

Finder _number(int value, String unit) => find.byWidgetPredicate(
      (Widget widget) =>
          widget is Text && widget.semanticsLabel == '$value $unit',
    );

Finder _wheel(int index) => find.byType(CupertinoPicker).at(index);

FixedExtentScrollController _controller(WidgetTester tester, int index) =>
    tester.widget<CupertinoPicker>(_wheel(index)).scrollController!;

Finder _digitInWheel(int index, int value) => find.descendant(
      of: _wheel(index),
      matching: find.byWidgetPredicate(
          (Widget widget) => widget is Text && widget.data == '$value'),
    );

const List<String> _units = <String>['小时', '分钟', '秒'];

Future<void> _pumpPicker(
  WidgetTester tester, {
  bool echoChanges = true,
  int initialSeconds = 600,
  Size size = const Size(375, 812),
  double textScale = 1,
  bool disableAnimations = false,
  ValueChanged<int>? onChanged,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  int seconds = initialSeconds;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(AppTheme.palettes[1]),
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                DurationPickerCard(
              seconds: seconds,
              onChanged: (int value) {
                onChanged?.call(value);
                if (echoChanges) {
                  setState(() => seconds = value);
                }
              },
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void _expectSettled(WidgetTester tester, int index) {
  final FixedExtentScrollController controller = _controller(tester, index);
  final double itemExtent =
      tester.widget<CupertinoPicker>(_wheel(index)).itemExtent;
  // FixedExtentScrollPhysics stops within one physical pixel rather than
  // snapping the last spring frame to an exact floating-point offset.
  final double tolerance =
      controller.position.physics.toleranceFor(controller.position).distance;
  expect(controller.offset,
      closeTo(controller.selectedItem * itemExtent, tolerance));
  expect(tester.getCenter(_number(controller.selectedItem, _units[index])).dy,
      closeTo(tester.getCenter(_wheel(index)).dy, tolerance));
  expect(tester.takeException(), isNull);
}

Future<void> _expectDragStep(
  WidgetTester tester,
  TestGesture gesture, {
  required int index,
  required int value,
  required double fingerDelta,
}) async {
  final FixedExtentScrollController controller = _controller(tester, index);
  final double previousOffset = controller.offset;
  final Offset previousCenter = tester.getCenter(_digitInWheel(index, value));
  await gesture.moveBy(Offset(0, fingerDelta));
  await tester.pump(const Duration(milliseconds: 16));
  final double offsetDelta = controller.offset - previousOffset;
  final Offset center = tester.getCenter(_digitInWheel(index, value));
  expect(offsetDelta, closeTo(-fingerDelta, 0.01));
  expect(center.dy - previousCenter.dy, closeTo(-offsetDelta, 1),
      reason:
          'Visible digits must track each drag frame, not just selection changes.');
  expect(center.dx, closeTo(previousCenter.dx, 0.5));
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(TimerApp(
    repository: MemoryTimerRepository(),
    audio: const SilentTimerAudio(),
    notifications: const DisabledTimerNotificationScheduler(),
    foregroundService: const DisabledTimerForegroundService(),
    now: tester.binding.clock.now,
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('native wheel digits retain the app font family',
      (WidgetTester tester) async {
    await _pumpPicker(tester);
    final Text number = tester.widget<Text>(_number(10, '分钟'));
    final String? appFont =
        Theme.of(tester.element(find.byType(DurationPickerCard)))
            .textTheme
            .titleLarge!
            .fontFamily;
    expect(appFont, 'Roboto');
    expect(number.style!.fontFamily, appFont);
  });

  testWidgets('digits follow slow dragging before the selected item changes',
      (WidgetTester tester) async {
    final List<int> changes = <int>[];
    await _pumpPicker(tester, echoChanges: false, onChanged: changes.add);
    final Finder wheel = find.byType(CupertinoPicker).at(1);
    final FixedExtentScrollController controller =
        tester.widget<CupertinoPicker>(wheel).scrollController!;
    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(wheel));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 16));

    final double previousOffset = controller.offset;
    final double previousY = tester.getCenter(_number(10, '分钟')).dy;
    await gesture.moveBy(const Offset(0, -6));
    await tester.pump(const Duration(milliseconds: 16));
    final double offsetDelta = controller.offset - previousOffset;
    final double numberDelta =
        tester.getCenter(_number(10, '分钟')).dy - previousY;
    expect(controller.selectedItem, 10);
    expect(changes, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(offsetDelta, closeTo(6, 0.01));
    expect(numberDelta, closeTo(-offsetDelta, 1),
        reason: 'The wheel scrolled $offsetDelta px but the visible digits '
            'moved $numberDelta px. Sub-item motion must be visible.');
    expect(tester.takeException(), isNull);
  });

  for (int index = 0; index < 3; index++) {
    for (final bool echoChanges in <bool>[false, true]) {
      testWidgets(
          '${_units[index]} tracks small drag steps and reversals '
          '(parent feedback: $echoChanges)', (WidgetTester tester) async {
        final List<int> changes = <int>[];
        await _pumpPicker(tester,
            initialSeconds: 10 * 3600 + 10 * 60 + 10,
            echoChanges: echoChanges,
            onChanged: changes.add);
        final FixedExtentScrollController controller =
            _controller(tester, index);
        final DurationPickerCard originalCard =
            tester.widget<DurationPickerCard>(find.byType(DurationPickerCard));
        final Offset unitCenter = tester.getCenter(find.text(_units[index]));
        final TestGesture gesture =
            await tester.startGesture(tester.getCenter(_wheel(index)));
        await gesture.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 16));
        for (final double delta in <double>[-6, 4, -4, 4, -4]) {
          await _expectDragStep(tester, gesture,
              index: index, value: 10, fingerDelta: delta);
          expect(controller.selectedItem, 10);
          expect(changes, isEmpty);
          // Fractional scrolling paints the viewport without rebuilding its
          // parent or moving the fixed unit label.
          expect(
              tester
                  .widget<DurationPickerCard>(find.byType(DurationPickerCard)),
              same(originalCard));
          expect(tester.getCenter(find.text(_units[index])), unitCenter);
        }
        await gesture.up();
        await tester.pumpAndSettle();
        _expectSettled(tester, index);
      });
    }

    testWidgets('${_units[index]} digits continue moving during a fling',
        (WidgetTester tester) async {
      final List<int> changes = <int>[];
      await _pumpPicker(tester,
          initialSeconds: 10 * 3600 + 10 * 60 + 10, onChanged: changes.add);
      final FixedExtentScrollController controller = _controller(tester, index);
      await tester.fling(_wheel(index), const Offset(0, -112), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final int value = controller.selectedItem;
      final double previousOffset = controller.offset;
      final double previousY = tester.getCenter(_digitInWheel(index, value)).dy;
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.offset - previousOffset, greaterThan(1));
      expect(tester.getCenter(_digitInWheel(index, value)).dy - previousY,
          lessThan(-1));
      await tester.pumpAndSettle();
      _expectSettled(tester, index);
      expect(changes, isNotEmpty);
      expect(
          changes.last,
          _controller(tester, 0).selectedItem * 3600 +
              _controller(tester, 1).selectedItem * 60 +
              _controller(tester, 2).selectedItem);
      for (int sibling = 0; sibling < 3; sibling++) {
        if (sibling != index) {
          expect(_controller(tester, sibling).offset, 10 * 56);
        }
      }
    });

    testWidgets('${_units[index]} unit label does not block dragging',
        (WidgetTester tester) async {
      await _pumpPicker(tester, initialSeconds: 10 * 3600 + 10 * 60 + 10);
      await tester.dragFrom(
          tester.getCenter(find.text(_units[index])), const Offset(0, -56));
      await tester.pumpAndSettle();
      expect(_controller(tester, index).selectedItem, greaterThan(10));
      _expectSettled(tester, index);
    });
  }

  for (final Size size in <Size>[
    const Size(320, 640),
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    for (final double textScale in <double>[1, 2]) {
      testWidgets('motion at $size with text scale $textScale',
          (WidgetTester tester) async {
        await _pumpPicker(tester, size: size, textScale: textScale);
        final TestGesture gesture =
            await tester.startGesture(tester.getCenter(_wheel(1)));
        await gesture.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 16));
        await _expectDragStep(tester, gesture,
            index: 1, value: 10, fingerDelta: -6);
        await gesture.up();
        await tester.pumpAndSettle();
        _expectSettled(tester, 1);
      });
    }
  }

  testWidgets('reduced motion keeps direct gesture feedback',
      (WidgetTester tester) async {
    await _pumpPicker(tester, disableAnimations: true);
    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(_wheel(1)));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump(const Duration(milliseconds: 16));
    await _expectDragStep(tester, gesture,
        index: 1, value: 10, fingerDelta: -6);
    await gesture.up();
    await tester.pumpAndSettle();
    _expectSettled(tester, 1);
  });

  testWidgets('a new drag immediately interrupts an active fling',
      (WidgetTester tester) async {
    await _pumpPicker(tester);
    final FixedExtentScrollController controller = _controller(tester, 1);
    await tester.fling(_wheel(1), const Offset(0, -112), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final TestGesture gesture =
        await tester.startGesture(tester.getCenter(_wheel(1)));
    final double heldOffset = controller.offset;
    await tester.pump(const Duration(milliseconds: 32));
    expect(controller.offset, closeTo(heldOffset, 0.01));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump(const Duration(milliseconds: 16));
    final int value = controller.selectedItem;
    await _expectDragStep(tester, gesture,
        index: 1, value: value, fingerDelta: 6);
    await gesture.up();
    await tester.pumpAndSettle();
    _expectSettled(tester, 1);
  });

  for (final String page in <String>['home', 'create', 'batch']) {
    testWidgets('$page page keeps fractional motion while echoing selections',
        (WidgetTester tester) async {
      await _pumpApp(tester);
      if (page == 'batch') {
        await tester.tap(find.byIcon(Icons.layers_outlined));
        await tester.pumpAndSettle();
      }
      if (page != 'home') {
        tester
            .widget<IconButton>(find.byWidgetPredicate((Widget widget) =>
                widget is IconButton && widget.tooltip == '创建倒计时'))
            .onPressed!();
        await tester.pumpAndSettle();
      }
      final FixedExtentScrollController controller = _controller(tester, 1);
      expect(controller.selectedItem, 10);
      final TestGesture gesture =
          await tester.startGesture(tester.getCenter(_wheel(1)));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
      await _expectDragStep(tester, gesture,
          index: 1, value: 10, fingerDelta: -6);
      final double previousOffset = controller.offset;
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.offset - previousOffset, closeTo(40, 0.01),
          reason: 'Parent feedback must not snap the wheel during a drag.');
      expect(controller.selectedItem, greaterThan(10));
      final DurationPickerCard card =
          tester.widget<DurationPickerCard>(find.byType(DurationPickerCard));
      expect(
          card.seconds,
          _controller(tester, 0).selectedItem * 3600 +
              controller.selectedItem * 60 +
              _controller(tester, 2).selectedItem);
      await gesture.up();
      await tester.pumpAndSettle();
      _expectSettled(tester, 1);
    });
  }
}
