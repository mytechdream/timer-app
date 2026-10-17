import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/pages/settings_page.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/theme/app_theme.dart';

Future<void> _pumpSettings(
  WidgetTester tester, {
  Size size = const Size(375, 812),
  double textScale = 1,
  GlobalKey? captureKey,
  bool disableAnimations = false,
  EdgeInsets safeInsets = EdgeInsets.zero,
  Future<void> Function(TimerSettings)? onSettingsChanged,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(RepaintBoundary(
    key: captureKey,
    child: MaterialApp(
      theme: AppTheme.build(AppTheme.palettes[1]),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
          padding: safeInsets,
          viewPadding: safeInsets,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SettingsPage(
          settings: const TimerSettings(),
          audio: const SilentTimerAudio(),
          selectedPaletteIndex: 1,
          onPaletteChanged: (_) {},
          onSettingsChanged: onSettingsChanged ?? (_) async {},
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void _expectReadable(WidgetTester tester, String label, {int maxLines = 1}) {
  final Finder text = find.text(label);
  expect(text, findsOneWidget);
  final Finder richText =
      find.descendant(of: text, matching: find.byType(RichText));
  final RenderParagraph paragraph =
      tester.renderObject<RenderParagraph>(richText);
  final List<TextBox> boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: label.length),
    boxHeightStyle: ui.BoxHeightStyle.max,
  );
  expect(boxes, isNotEmpty);
  expect(boxes.map((TextBox box) => box.top).toSet().length,
      lessThanOrEqualTo(maxLines),
      reason: 'The complete settings label "$label" must not be squeezed '
          'into a narrow vertical column.');
  expect(paragraph.didExceedMaxLines, isFalse,
      reason: 'The settings label "$label" must remain fully readable.');
  // Flutter may hang a line-ending space outside the paragraph width. Only
  // visible characters need horizontal bounds; whitespace must not fail this.
  for (int index = 0; index < label.length; index++) {
    if (label[index].trim().isEmpty) {
      continue;
    }
    for (final TextBox box in paragraph.getBoxesForSelection(
      TextSelection(baseOffset: index, extentOffset: index + 1),
    )) {
      expect(box.left, greaterThanOrEqualTo(-0.5));
      expect(box.right, lessThanOrEqualTo(paragraph.size.width + 0.5),
          reason: 'The full text "$label" must fit horizontally.');
    }
  }
}

void main() {
  testWidgets('settings labels stay readable on a 375dp phone',
      (WidgetTester tester) async {
    await _pumpSettings(tester);
    _expectReadable(tester, '结束提醒');
    _expectReadable(tester, '提示音');
    _expectReadable(tester, '默认倒计时');
    _expectReadable(tester, '延时按钮');
    _expectReadable(tester, TimerSettings.reminderSoundAndVibration);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow settings rows preserve the full title and selected value',
      (WidgetTester tester) async {
    await _pumpSettings(tester, size: const Size(320, 640));
    _expectReadable(tester, '结束提醒');
    _expectReadable(tester, '默认倒计时');
    _expectReadable(tester, TimerSettings.reminderSoundAndVibration);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a large font does not squeeze the reminder title into a column',
      (WidgetTester tester) async {
    await _pumpSettings(tester, textScale: 2);
    _expectReadable(tester, '结束提醒');
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolling settings does not paint over the fixed page heading',
      (WidgetTester tester) async {
    final GlobalKey captureKey = GlobalKey();
    await _pumpSettings(tester, captureKey: captureKey);
    final List<int> before = await _captureHeading(tester, captureKey);
    final ScrollableState scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(240);
    await tester.pump();
    final List<int> after = await _captureHeading(tester, captureKey);
    expect(after, before,
        reason: 'Cards must stay inside their scroll viewport instead of '
            'covering the fixed settings heading.');
    expect(tester.takeException(), isNull);
  });

  for (final Size size in <Size>[
    const Size(320, 640),
    const Size(360, 800),
    const Size(375, 812),
    const Size(430, 932),
    const Size(812, 375),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    for (final double scale in <double>[1, 1.3, 2]) {
      testWidgets('settings reflow at $size with text scale $scale',
          (WidgetTester tester) async {
        await _pumpSettings(tester, size: size, textScale: scale);
        for (final String title in <String>[
          '结束提醒',
          '提示音',
          '后台运行',
          '默认倒计时',
          '延时按钮',
        ]) {
          _expectReadable(tester, title, maxLines: scale > 1 ? 2 : 1);
          final Text text = tester.widget<Text>(find.text(title));
          expect(text.style!.fontSize, 18);
          final RichText richText = tester.widget<RichText>(find.descendant(
              of: find.text(title), matching: find.byType(RichText)));
          expect(richText.textScaler.scale(18), closeTo(18 * scale, 0.01),
              reason: 'Responsive layout must preserve the system text size.');
        }
        for (final String value in <String>[
          TimerSettings.reminderSoundAndVibration,
          '清脆铃声',
          '10分钟',
          '3秒',
        ]) {
          _expectReadable(tester, value, maxLines: scale > 1 ? 2 : 1);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('safe areas and reduced motion keep the last setting reachable',
      (WidgetTester tester) async {
    await _pumpSettings(tester,
        size: const Size(320, 640),
        textScale: 2,
        disableAnimations: true,
        safeInsets: const EdgeInsets.only(top: 32, bottom: 24));
    expect(tester.getRect(find.text('设置')).top, greaterThanOrEqualTo(32));
    await tester.ensureVisible(find.text('延时按钮'));
    await tester.pumpAndSettle();
    final Rect lastSetting = tester.getRect(find.text('延时按钮'));
    expect(
        lastSetting.top, greaterThan(tester.getRect(find.text('设置')).bottom));
    expect(lastSetting.bottom, lessThan(640 - 24));
    expect(tester.takeException(), isNull);
  });

  for (final Size size in <Size>[
    const Size(320, 640),
    const Size(812, 375),
  ]) {
    testWidgets('setting choices remain usable at $size with large fonts',
        (WidgetTester tester) async {
      final List<TimerSettings> changes = <TimerSettings>[];
      await _pumpSettings(tester,
          size: size,
          textScale: 2,
          onSettingsChanged: (TimerSettings settings) async =>
              changes.add(settings));
      for (final ({String title, String option}) choice in [
        (title: '结束提醒', option: TimerSettings.reminderSoundOnly),
        (title: '提示音', option: '电子提示'),
        (title: '默认倒计时', option: '25分钟'),
        (title: '延时按钮', option: '30秒'),
      ]) {
        await tester.ensureVisible(find.text(choice.title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice.title));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason:
                'The ${choice.title} sheet must not overflow its viewport.');
        await tester.ensureVisible(find.text(choice.option));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice.option));
        await tester.pumpAndSettle();
      }
      expect(changes, hasLength(4));
      expect(
          changes[0].completionReminderName, TimerSettings.reminderSoundOnly);
      expect(changes[1].alertSoundName, '电子提示');
      expect(changes[2].defaultCountdownSeconds, 25 * 60);
      expect(changes[3].extendSeconds, 30);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<List<int>> _captureHeading(
    WidgetTester tester, GlobalKey captureKey) async {
  final RenderRepaintBoundary boundary =
      captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final Rect heading = tester
      .getRect(find.text('设置'))
      .shift(-boundary.localToGlobal(Offset.zero));
  return (await tester.runAsync(() async {
    final ui.Image frame = await boundary.toImage();
    try {
      final bytes = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = bytes!.buffer.asUint8List();
      final List<int> area = <int>[];
      for (int y = heading.top.floor(); y < heading.bottom.ceil(); y++) {
        area.addAll(pixels.sublist(
          (y * frame.width + heading.left.floor()) * 4,
          (y * frame.width + heading.right.ceil()) * 4,
        ));
      }
      return area;
    } finally {
      frame.dispose();
    }
  }))!;
}
