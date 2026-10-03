// Run manually: flutter test scripts/capture_home_screenshot_test.dart
// Override SCREENSHOT_FONT / SCREENSHOT_BOLD_FONT with --dart-define on other OSes.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';
import 'package:timer_app/theme/app_theme.dart';

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

  testWidgets('capture the current tomato-red home for the README',
      (WidgetTester tester) async {
    final bool previousDisableShadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final GlobalKey screenshotKey = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: screenshotKey,
        child: TimerApp(
          repository: MemoryTimerRepository(),
          audio: const SilentTimerAudio(),
          notifications: const DisabledTimerNotificationScheduler(),
          foregroundService: const DisabledTimerForegroundService(),
        ),
      ));
      await tester.pumpAndSettle();
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
      expect(tester.takeException(), isNull);

      final RenderRepaintBoundary boundary = screenshotKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final ui.Image image = await boundary.toImage(pixelRatio: 2);
        try {
          final ByteData? png =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (png == null) {
            throw StateError('Could not encode the README screenshot');
          }
          await File('docs/screenshots/home.png').writeAsBytes(
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
