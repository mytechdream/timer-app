import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/pages/settings_page.dart';
import 'package:timer_app/pages/timer_dashboard_page.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';
import 'package:timer_app/theme/app_theme.dart';
import 'package:timer_app/widgets/app_bottom_nav.dart';

TimerPalette get _tomato =>
    AppTheme.palettes.singleWhere((TimerPalette p) => p.name == '番茄红');

double _contrast(Color foreground, Color background) {
  final double a = foreground.computeLuminance();
  final double b = background.computeLuminance();
  return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
}

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
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

Future<void> _pumpSettings(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  int selectedPalette = 1;
  await tester.pumpWidget(MaterialApp(
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
      child: child!,
    ),
    home: StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => Theme(
        data: AppTheme.build(AppTheme.palettes[selectedPalette]),
        child: Scaffold(
          body: SettingsPage(
            settings: const TimerSettings(),
            audio: const SilentTimerAudio(),
            selectedPaletteIndex: selectedPalette,
            onPaletteChanged: (int index) =>
                setState(() => selectedPalette = index),
            onSettingsChanged: (_) async {},
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _selectTomato(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('番茄红'));
  await tester.tap(find.text('番茄红'));
  await tester.pumpAndSettle();
}

void main() {
  test('tomato palette is appended without reordering existing choices', () {
    expect(
      AppTheme.palettes.map((TimerPalette palette) => palette.name),
      <String>['天空蓝', '樱花粉', '薄荷绿', '葡萄紫', '暖橙色', '番茄红'],
    );
    expect(AppTheme.palettes[1].primary, const Color(0xFFF04286));
    expect(_tomato.primary, const Color(0xFFC4312C));
  });

  test('tomato accent stays readable on buttons and selected tab backgrounds',
      () {
    final TimerPalette palette = _tomato;
    final Color navSurface =
        Color.alphaBlend(Colors.white.withOpacity(0.96), palette.background);
    final Color selectedSurface =
        Color.alphaBlend(palette.primary.withOpacity(0.12), navSurface);
    expect(_contrast(Colors.white, palette.primary), greaterThanOrEqualTo(4.5));
    expect(
        _contrast(palette.primary, selectedSurface), greaterThanOrEqualTo(4.5));
    expect(_contrast(palette.primary, palette.soft), greaterThanOrEqualTo(4.5));
    expect(_contrast(palette.primary, palette.background),
        greaterThanOrEqualTo(4.5));
    expect(
        _contrast(AppTheme.ink, palette.background), greaterThanOrEqualTo(7));
  });

  testWidgets('tomato selection updates the app theme and survives tab changes',
      (WidgetTester tester) async {
    await _pumpApp(tester);
    expect(
      Theme.of(tester.element(find.byType(TimerDashboardPage)))
          .colorScheme
          .primary,
      AppTheme.palettes[1].primary,
    );
    await _selectTomato(tester);
    expect(find.text('当前配色：番茄红'), findsOneWidget);
    final BuildContext settingsContext =
        tester.element(find.byType(SettingsPage));
    expect(Theme.of(settingsContext).colorScheme.primary, _tomato.primary);
    expect(
        Theme.of(settingsContext).scaffoldBackgroundColor, _tomato.background);
    expect(settingsContext.timerPalette, same(_tomato));
    final Finder selected = find.ancestor(
      of: find.text('番茄红'),
      matching: find.byWidgetPredicate((Widget widget) =>
          widget is Semantics && widget.properties.selected == true),
    );
    expect(selected, findsOneWidget);

    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();
    final BuildContext timerContext =
        tester.element(find.byType(TimerDashboardPage));
    expect(Theme.of(timerContext).colorScheme.primary, _tomato.primary);
    expect(timerContext.timerPalette, same(_tomato));
    final Finder navLabel = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.text('计时'),
    );
    expect(tester.widget<Text>(navLabel).style!.color, _tomato.primary);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('当前配色：番茄红'), findsOneWidget);
    await tester.ensureVisible(find.text('天空蓝'));
    await tester.tap(find.text('天空蓝'));
    await tester.pumpAndSettle();
    expect(find.text('当前配色：天空蓝'), findsOneWidget);
    expect(
        Theme.of(tester.element(find.byType(SettingsPage))).colorScheme.primary,
        AppTheme.palettes.first.primary);
    expect(tester.takeException(), isNull);
  });

  for (final Size size in <Size>[
    const Size(375, 812),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    testWidgets('tomato picker remains usable at $size with large text',
        (WidgetTester tester) async {
      await _pumpSettings(tester, size);
      await tester.ensureVisible(find.text('番茄红'));
      await tester.tap(find.text('番茄红'));
      await tester.pumpAndSettle();
      final BuildContext context = tester.element(find.byType(SettingsPage));
      expect(MediaQuery.textScalerOf(context).scale(16), 32);
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
      expect(find.text('当前配色：番茄红'), findsOneWidget);
      expect(Theme.of(context).colorScheme.primary, _tomato.primary);
      await tester.ensureVisible(find.text('番茄红'));
      final Finder chip = find
          .ancestor(
            of: find.text('番茄红'),
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }
}
