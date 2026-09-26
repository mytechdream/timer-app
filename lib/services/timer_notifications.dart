import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract class TimerNotificationScheduler {
  Future<void> initialize();

  Future<void> scheduleCountdownComplete({
    required String timerName,
    required DateTime endAt,
    required bool vibrate,
    required bool preferExact,
  });

  Future<void> cancelCountdownComplete();
}

class DisabledTimerNotificationScheduler implements TimerNotificationScheduler {
  const DisabledTimerNotificationScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleCountdownComplete({
    required String timerName,
    required DateTime endAt,
    required bool vibrate,
    required bool preferExact,
  }) async {}

  @override
  Future<void> cancelCountdownComplete() async {}
}

class LocalTimerNotificationScheduler implements TimerNotificationScheduler {
  LocalTimerNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _countdownNotificationId = 1001;
  static const String _channelId = 'timer_alerts';
  static const String _channelName = '计时提醒';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initializing;
  bool _initialized = false;
  bool _timeZonesInitialized = false;

  @override
  Future<void> initialize() {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return _initializing ??= _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    if (_initialized) {
      return;
    }
    _ensureTimeZones();
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_launcher');
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } on Object {
      _initialized = false;
    }
  }

  @override
  Future<void> scheduleCountdownComplete({
    required String timerName,
    required DateTime endAt,
    required bool vibrate,
    required bool preferExact,
  }) async {
    if (kIsWeb || !endAt.isAfter(DateTime.now())) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }

    final bool notificationPermissionGranted =
        await _requestNotificationPermission();
    if (!notificationPermissionGranted) {
      return;
    }

    final AndroidScheduleMode androidScheduleMode =
        await _androidScheduleMode(preferExact: preferExact);
    try {
      await _plugin.zonedSchedule(
        _countdownNotificationId,
        '计时结束',
        '「$timerName」已完成',
        tz.TZDateTime.from(endAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: '倒计时结束时提醒用户',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: vibrate,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: androidScheduleMode,
      );
    } on Object {
      if (androidScheduleMode == AndroidScheduleMode.inexactAllowWhileIdle) {
        return;
      }
      await _plugin.zonedSchedule(
        _countdownNotificationId,
        '计时结束',
        '「$timerName」已完成',
        tz.TZDateTime.from(endAt, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: '倒计时结束时提醒用户',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: vibrate,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelCountdownComplete() async {
    if (kIsWeb) {
      return;
    }
    await initialize();
    if (!_initialized) {
      return;
    }
    try {
      await _plugin.cancel(_countdownNotificationId);
    } on Object {
      return;
    }
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? androidGranted =
          await androidPlugin?.requestNotificationsPermission();
      if (androidGranted == false) {
        return false;
      }

      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final bool? iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        sound: true,
      );
      if (iosGranted == false) {
        return false;
      }

      final MacOSFlutterLocalNotificationsPlugin? macOSPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>();
      final bool? macOSGranted = await macOSPlugin?.requestPermissions(
        alert: true,
        sound: true,
      );
      return macOSGranted != false;
    } on Object {
      return false;
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode({
    required bool preferExact,
  }) async {
    if (!preferExact) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
      final bool? canScheduleExact =
          await androidPlugin.canScheduleExactNotifications();
      if (canScheduleExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
      final bool? exactGranted =
          await androidPlugin.requestExactAlarmsPermission();
      return exactGranted == true
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } on Object {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  void _ensureTimeZones() {
    if (_timeZonesInitialized) {
      return;
    }
    tz_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
}

TimerNotificationScheduler buildDefaultNotificationScheduler() {
  if (kIsWeb) {
    return const DisabledTimerNotificationScheduler();
  }
  return LocalTimerNotificationScheduler();
}
