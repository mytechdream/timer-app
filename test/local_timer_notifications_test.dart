import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timer_app/app/timer_app.dart';
import 'package:timer_app/data/timer_repository.dart';
import 'package:timer_app/models/timer_models.dart';
import 'package:timer_app/services/timer_audio.dart';
import 'package:timer_app/services/timer_foreground_service.dart';
import 'package:timer_app/services/timer_notifications.dart';

const MethodChannel _notificationChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

// The Android plugin resolves bare icon names as drawable resources, not mipmaps.
// Use the app's actual resources so an invalid default icon cannot be hidden by
// a scheduler fake returning a successful initialization result.
bool _androidIconExists(String icon) {
  final RegExpMatch? qualified = RegExp(r'^@([^/]+)/(.+)$').firstMatch(icon);
  final String type = qualified?.group(1) ?? 'drawable';
  final String name = qualified?.group(2) ?? icon;
  final Directory resources = Directory('android/app/src/main/res');
  return resources.listSync().whereType<Directory>().any((Directory directory) {
    final String directoryName = directory.uri.pathSegments
        .where((String segment) => segment.isNotEmpty)
        .last;
    if (directoryName != type && !directoryName.startsWith('$type-')) {
      return false;
    }
    return directory.listSync().whereType<File>().any(
        (File file) => file.uri.pathSegments.last.split('.').first == name);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  late List<String> initializationErrors;
  late bool notificationPermissionGranted;
  Completer<bool>? permissionResponse;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = <MethodCall>[];
    initializationErrors = <String>[];
    notificationPermissionGranted = true;
    permissionResponse = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationChannel,
            (MethodCall call) async {
      calls.add(call);
      switch (call.method) {
        case 'initialize':
          final String icon = call.arguments['defaultIcon'] as String;
          if (!_androidIconExists(icon)) {
            initializationErrors.add('Drawable resource "$icon" was not found');
            throw PlatformException(code: 'invalid_icon', message: icon);
          }
          return true;
        case 'requestNotificationsPermission':
          return permissionResponse?.future ?? notificationPermissionGranted;
        case 'canScheduleExactNotifications':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('a countdown reaches Android notification permission and scheduling',
      () async {
    final LocalTimerNotificationScheduler scheduler =
        LocalTimerNotificationScheduler();
    final CountdownNotificationStatus status =
        await scheduler.scheduleCountdownComplete(
      notificationKey: 'android-permission-regression',
      timerName: '专注',
      endAt: DateTime.utc(2100, 1, 1),
      vibrate: true,
      preferExact: true,
    );

    expect(
      calls.map((MethodCall call) => call.method),
      contains('requestNotificationsPermission'),
      reason: 'The permission dialog is never reached: $initializationErrors',
    );
    expect(status, CountdownNotificationStatus.exact);
    expect(
        calls.map((MethodCall call) => call.method), contains('zonedSchedule'));
  });

  testWidgets('opening the app reaches notification permission without a timer',
      (WidgetTester tester) async {
    try {
      await tester.pumpWidget(TimerApp(
        repository: MemoryTimerRepository(),
        audio: const SilentTimerAudio(),
        notifications: LocalTimerNotificationScheduler(),
        foregroundService: const DisabledTimerForegroundService(),
      ));
      await tester.pumpAndSettle();

      final Iterable<String> methods =
          calls.map((MethodCall call) => call.method);
      expect(methods, contains('requestNotificationsPermission'));
      expect(methods, isNot(contains('requestExactAlarmsPermission')));
      expect(methods, isNot(contains('zonedSchedule')));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('opening the app does not request permission with reminders off',
      (WidgetTester tester) async {
    try {
      await tester.pumpWidget(TimerApp(
        repository: MemoryTimerRepository(TimerSnapshot.initial().copyWith(
          settings: const TimerSettings(
            completionSoundEnabled: false,
            completionReminderName: TimerSettings.reminderOff,
          ),
        )),
        audio: const SilentTimerAudio(),
        notifications: LocalTimerNotificationScheduler(),
        foregroundService: const DisabledTimerForegroundService(),
      ));
      await tester.pumpAndSettle();

      expect(calls.map((MethodCall call) => call.method),
          isNot(contains('requestNotificationsPermission')));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('startup and a countdown share an outstanding permission request',
      () async {
    permissionResponse = Completer<bool>();
    final LocalTimerNotificationScheduler scheduler =
        LocalTimerNotificationScheduler();
    final Future<bool> startup = scheduler.requestNotificationPermission();
    final Future<CountdownNotificationStatus> countdown =
        scheduler.scheduleCountdownComplete(
      notificationKey: 'android-overlapping-permission',
      timerName: '专注',
      endAt: DateTime.utc(2100, 1, 1),
      vibrate: true,
      preferExact: true,
    );
    await Future<void>.delayed(Duration.zero);

    expect(
        calls.where((MethodCall call) =>
            call.method == 'requestNotificationsPermission'),
        hasLength(1));
    permissionResponse!.complete(true);
    expect(await startup, isTrue);
    expect(await countdown, CountdownNotificationStatus.exact);
    expect(
        calls.where((MethodCall call) =>
            call.method == 'requestNotificationsPermission'),
        hasLength(1));
  });

  test('denied Android permission is reported and does not schedule an alert',
      () async {
    notificationPermissionGranted = false;
    final CountdownNotificationStatus status =
        await LocalTimerNotificationScheduler().scheduleCountdownComplete(
      notificationKey: 'android-denied',
      timerName: '专注',
      endAt: DateTime.utc(2100, 1, 1),
      vibrate: true,
      preferExact: true,
    );

    expect(status, CountdownNotificationStatus.permissionDenied);
    final Iterable<String> methods =
        calls.map((MethodCall call) => call.method);
    expect(methods, isNot(contains('canScheduleExactNotifications')));
    expect(methods, isNot(contains('zonedSchedule')));
  });
}
