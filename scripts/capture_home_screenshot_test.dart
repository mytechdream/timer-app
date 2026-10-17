// Run manually: flutter test scripts/capture_home_screenshot_test.dart
// Override SCREENSHOT_FONT / SCREENSHOT_BOLD_FONT with --dart-define on other OSes.
// SCREENSHOT_PAGE=settings captures manual layout checks in build/ by default.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/pages/settings_page.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';
import 'package:timer_app/theme/app_theme.dart';
import 'package:timer_app/widgets/app_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const List<String> fontPaths = <String>[
      String.fromEnvironment(
        'SCREENSHOT_FONT',
        defaultValue: 'C:/Windows/Fonts/msyh.ttc',
      ),
      String.fromEnvironment(
        'SCREENSHOT_BOLD_FONT',
        defaultValue: 'C:/Windows/Fonts/msyhbd.ttc',
      ),
    ];
    // Widget tests otherwise use Ahem, which cannot render the Chinese UI.
    // Load local fonts for this capture only; no font files are redistributed.
    final FontLoader fonts = FontLoader('Roboto');
    for (final String path in fontPaths) {
      final File font = File(path);
      if (!await font.exists()) {
        throw StateError('Screenshot font missing: $path');
      }
      fonts.addFont(font.readAsBytes().then(ByteData.sublistView));
    }
    await fonts.load();
    final FontLoader icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('capture the home or settings page with real Chinese fonts',
      (WidgetTester tester) async {
    final bool previousDisableShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      const bool captureSettings =
          String.fromEnvironment('SCREENSHOT_PAGE') == 'settings';
      const int width =
          int.fromEnvironment('SCREENSHOT_WIDTH', defaultValue: 375);
      const int height =
          int.fromEnvironment('SCREENSHOT_HEIGHT', defaultValue: 812);
      final double textScale = double.parse(const String.fromEnvironment(
        'SCREENSHOT_TEXT_SCALE',
        defaultValue: '1',
      ));
      tester.view.physicalSize = const Size(width * 2, height * 2);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final GlobalKey screenshotKey = GlobalKey();
      // Isolate settings typography from unrelated offstage preset-card layouts.
      final Widget app = captureSettings
          ? MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('zh', 'CN'),
              supportedLocales: const <Locale>[Locale('zh', 'CN')],
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              theme: AppTheme.build(AppTheme.palettes[1]),
              home: Scaffold(
                body: Stack(
                  children: <Widget>[
                    SettingsPage(
                      settings: const TimerSettings(),
                      audio: const SilentTimerAudio(),
                      selectedPaletteIndex: 1,
                      onPaletteChanged: (_) {},
                      onSettingsChanged: (_) async {},
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AppBottomNav(index: 3, onChanged: (_) {}),
                    ),
                  ],
                ),
              ),
            )
          : TimerApp(
              repository: MemoryTimerRepository(),
              audio: const SilentTimerAudio(),
              notifications: const DisabledTimerNotificationScheduler(),
              foregroundService: const DisabledTimerForegroundService(),
            );
      await tester.pumpWidget(RepaintBoundary(
        key: screenshotKey,
        child: app,
      ));
      await tester.pumpAndSettle();
      if (captureSettings) {
        final Finder settingsPage = find.byType(SettingsPage);
        final Finder scrollView = find.descendant(
            of: settingsPage, matching: find.byType(SingleChildScrollView));
        final ScrollableState scrollable = tester.state<ScrollableState>(
            find.descendant(of: scrollView, matching: find.byType(Scrollable)));
        final double scrollOffset = tester.getTopLeft(find.text('提醒')).dy -
            20 -
            tester.getTopLeft(scrollView).dy;
        scrollable.position.jumpTo(
            scrollOffset.clamp(0.0, scrollable.position.maxScrollExtent));
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('番茄红'));
        await tester.tap(find.text('番茄红'));
        await tester.pumpAndSettle();
        expect(find.text('当前配色：番茄红'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.timer_outlined));
        await tester.pumpAndSettle();
        expect(find.text('选择倒计时时长'), findsOneWidget);
        expect(
          Theme.of(tester.element(find.text('计时器'))).colorScheme.primary,
          AppTheme.palettes.last.primary,
        );
      }
      expect(tester.takeException(), isNull);

      final RenderRepaintBoundary boundary = screenshotKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage(pixelRatio: 2);
        try {
          final ByteData? png =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (png == null) {
            throw StateError('Could not encode the screenshot');
          }
          const String outputPath = String.fromEnvironment(
            'SCREENSHOT_OUTPUT',
            defaultValue: captureSettings
                ? 'build/settings-layout.png'
                : 'docs/screenshots/home.png',
          );
          await File(outputPath).writeAsBytes(
            png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
            flush: true,
          );
        } finally {
          image.dispose();
        }
      });
    } finally {
      debugDisableShadows = previousDisableShadows;
    }
  });
}
