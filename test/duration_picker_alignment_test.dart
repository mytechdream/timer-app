import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/theme/app_theme.dart';
import 'package:timer_app/widgets/duration_picker_card.dart';

Offset _numberCenter(WidgetTester tester, Finder richText, int digits) {
  final RenderParagraph paragraph =
      tester.renderObject<RenderParagraph>(richText);
  final List<TextBox> boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: digits),
  );
  final Rect bounds = boxes
      .map((TextBox box) => box.toRect())
      .reduce((Rect a, Rect b) => a.expandToInclude(b));
  return paragraph.localToGlobal(bounds.center);
}

Finder _selectedText(int value, String unit) =>
    find.byWidgetPredicate((Widget widget) =>
        widget is Text && widget.semanticsLabel == '$value $unit');

void _expectColumnAligned(
  WidgetTester tester, {
  required String unit,
  required int value,
  required int max,
}) {
  final Finder selected = find.descendant(
    of: _selectedText(value, unit),
    matching: find.byType(RichText),
  );
  expect(selected, findsOneWidget);
  final Offset selectedCenter =
      _numberCenter(tester, selected, '$value'.length);
  for (final int offset in <int>[-2, -1, 1, 2]) {
    final int candidateValue = value + offset;
    if (candidateValue < 0 || candidateValue > max) {
      continue;
    }
    final Finder candidates = find.descendant(
      of: find.byType(DurationPickerCard),
      matching: find.byWidgetPredicate((Widget widget) =>
          widget is RichText && widget.text.toPlainText() == '$candidateValue'),
    );
    expect(candidates, findsWidgets);
    int nearest = 0;
    double distance = double.infinity;
    for (int i = 0; i < candidates.evaluate().length; i++) {
      final double candidateDistance =
          (tester.getCenter(candidates.at(i)).dx - selectedCenter.dx).abs();
      if (candidateDistance < distance) {
        nearest = i;
        distance = candidateDistance;
      }
    }
    final Offset candidateCenter =
        _numberCenter(tester, candidates.at(nearest), '$candidateValue'.length);
    expect(selectedCenter.dx, closeTo(candidateCenter.dx, 0.5),
        reason: '$value $unit must align with row $candidateValue');
    expect(candidateCenter.dy - selectedCenter.dy,
        offset < 0 ? isNegative : isPositive);
  }
}

void _expectAllColumnsAligned(WidgetTester tester, int seconds) {
  _expectColumnAligned(tester, unit: '小时', value: seconds ~/ 3600, max: 99);
  _expectColumnAligned(tester,
      unit: '分钟', value: (seconds % 3600) ~/ 60, max: 59);
  _expectColumnAligned(tester, unit: '秒', value: seconds % 60, max: 59);
  expect(tester.takeException(), isNull);
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  int seconds = 600,
  double textScale = 1,
  bool disableAnimations = false,
  ValueChanged<int>? onChanged,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
          child: DurationPickerCard(
            seconds: seconds,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  final List<({String unit, int value, int max})> cases = [
    (unit: '小时', value: 0, max: 99),
    (unit: '分钟', value: 10, max: 59),
    (unit: '秒', value: 0, max: 59),
  ];
  for (final entry in cases) {
    testWidgets('${entry.unit} digits align with the next wheel row',
        (WidgetTester tester) async {
      await _pumpPicker(tester);
      _expectColumnAligned(tester,
          unit: entry.unit, value: entry.value, max: entry.max);
      expect(tester.takeException(), isNull);
    });
  }

  for (final Size size in <Size>[
    const Size(320, 640),
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    for (final double textScale in <double>[1, 2]) {
      testWidgets('alignment at $size with text scale $textScale',
          (WidgetTester tester) async {
        for (final int seconds in <int>[
          1,
          9 * 3600 + 9 * 60 + 9,
          10 * 3600 + 10 * 60 + 10,
          99 * 3600 + 59 * 60 + 59,
        ]) {
          await _pumpPicker(tester,
              size: size, seconds: seconds, textScale: textScale);
          _expectAllColumnsAligned(tester, seconds);
          final Finder units = find.descendant(
              of: find.byType(DurationPickerCard),
              matching: find.byWidgetPredicate((Widget widget) =>
                  widget is Text &&
                  <String>['小时', '分钟', '秒'].contains(widget.data)));
          expect(units, findsNWidgets(3));
          for (final Text unit in tester.widgetList<Text>(units)) {
            expect(unit.style!.fontSize, 16);
          }
          final Text number =
              tester.widget<Text>(_selectedText(seconds ~/ 3600, '小时'));
          expect(number.style!.fontSize, 28);
          expect(number.style!.fontFeatures,
              contains(const FontFeature.tabularFigures()));
        }
      });
    }
  }

  testWidgets('external changes sync wheels without emitting a new value',
      (WidgetTester tester) async {
    final List<int> changes = <int>[];
    await _pumpPicker(tester, onChanged: changes.add);
    await _pumpPicker(tester,
        seconds: 99 * 3600 + 59 * 60 + 59, onChanged: changes.add);
    _expectAllColumnsAligned(tester, 99 * 3600 + 59 * 60 + 59);
    await _pumpPicker(tester, seconds: 0, onChanged: changes.add);
    _expectAllColumnsAligned(tester, 1);
    expect(changes, isEmpty);
  });

  testWidgets('all three wheels still respond to touch scrolling',
      (WidgetTester tester) async {
    final List<int> changes = <int>[];
    await _pumpPicker(tester, onChanged: changes.add);
    int previous = 600;
    for (int i = 0; i < 3; i++) {
      final int previousChanges = changes.length;
      await tester.drag(
          find.byType(CupertinoPicker).at(i), const Offset(0, -56));
      await tester.pumpAndSettle();
      expect(changes.length, greaterThan(previousChanges));
      expect(changes.last, greaterThan(previous));
      _expectAllColumnsAligned(tester, changes.last);
      previous = changes.last;
    }
  });

  testWidgets('alignment is retained with reduced motion enabled',
      (WidgetTester tester) async {
    await _pumpPicker(tester, disableAnimations: true);
    _expectAllColumnsAligned(tester, 600);
  });

  testWidgets('native picker exposes selected values with their units',
      (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await _pumpPicker(tester);
      expect(find.bySemanticsLabel('0 小时'), findsOneWidget);
      expect(find.bySemanticsLabel('10 分钟'), findsOneWidget);
      expect(find.bySemanticsLabel('0 秒'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
