import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'timer_vibration.dart';

abstract class TimerNotificationScheduler {
  Future<void> initialize();

  Future<bool> requestNotificationPermission();

  Future<CountdownNotificationStatus> scheduleCountdownComplete({
    required String notificationKey,
    required String timerName,
    required DateTime endAt,
    required bool vibrate,
    required bool preferExact,
  });

  Future<void> completeCountdown({
    required String notificationKey,
    required String timerName,
    required bool vibrate,
  });

  Future<void> cancelCountdownComplete(String notificationKey);
}

enum CountdownNotificationStatus {
  exact,
  inexact,
  permissionDenied,
  unavailable,
}

class DisabledTimerNotificationScheduler implements TimerNotificationScheduler {
  const DisabledTimerNotificationScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestNotificationPermission() async => false;

  @override
  Future<CountdownNotificationStatus> scheduleCountdownComplete({
    required String notificationKey,
    required String timerName,
    required DateTime endAt,
    required bool vibrate,
    required bool preferExact,
  }) async =>
      CountdownNotificationStatus.unavailable;

  @override
  Future<void> completeCountdown({
    required String notificationKey,
    required String timerName,
    required bool vibrate,
  }) async {}

  @override
  Future<void> cancelCountdownComplete(String notificationKey) async {}
}

class LocalTimerNotificationScheduler implements TimerNotificationScheduler {
  LocalTimerNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _soundChannelId = 'timer_alerts_sound';
  // Android freezes a channel's vibration configuration on first creation.
  // Use a versioned channel so existing installs receive the explicit waveform.
  static const String _vibrationChannelId = 'timer_alerts_vibration_v2';

  final FlutterLocalNotificationsPlugin _plugin;
  final Set<String> _scheduledKeys = <String>{};
  final Map<String, int> _notificationIds = <String, int>{};
  Future<void> _operationTail = Future<void>.value();
  Future<void>? _initializing;
  Future<bool>? _requestingPermission;
  bool _initialized = false;
  bool _timeZonesInitialized = false;
  bool _exactPermissionRequestAttempted = false;

  @override
  Future<void> initialize() {
    if (kIsWeb) {
      return Future<void>.value();
    }
    return _initializing ??= _initializePlugin().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initializePlugin() async {
    if (_initialized) {
      return;
    }
    _ensureTimeZones();
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_stat_timer');
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
      _initialized = await _plugin.initialize(settings) ?? false;
    } on Object {
      _initialized = false;
    }
  }

  @override
  Future<bool> requestNotificationPermission() {
    if (kIsWeb) {
      return Future<bool>.value(false);
    }
    // Startup and a newly started timer can overlap while the system prompt is
    // open. Share that request instead of asking the Android plugin twice.
    return _requestingPermission ??=
        _initializeAndRequestPermission().whenComplete(() {
      _requestingPermission = null;
    });
  }

  Future<bool> _initializeAndRequestPermission() async {
    await initialize();
    return _initialized && await _requestNotificationPermission();
  }

  @override
  Future<CountdownNotificationStatus> scheduleCountdownComplete({
    required String notificationKey,
    required String timerName,
    required DateTime endAt,
    required bool vibrate,
    required bool preferExact,
  }) =>
      _enqueue(() async {
        if (kIsWeb || !endAt.isAfter(DateTime.now())) {
          return CountdownNotificationStatus.unavailable;
        }
        await initialize();
        if (!_initialized) {
          return CountdownNotificationStatus.unavailable;
        }

        final int id = _idForKey(notificationKey);
        try {
          await _plugin.cancel(id);
        } on Object {
          return CountdownNotificationStatus.unavailable;
        }
        _scheduledKeys.remove(notificationKey);

        final bool notificationPermissionGranted =
            await requestNotificationPermission();
        if (!notificationPermissionGranted) {
          return CountdownNotificationStatus.permissionDenied;
        }

        final AndroidScheduleMode androidScheduleMode =
            await _androidScheduleMode(preferExact: preferExact);
        try {
          await _plugin.zonedSchedule(
            id,
            '计时结束',
            '「$timerName」已完成',
            tz.TZDateTime.from(endAt, tz.local),
            _details(vibrate),
            androidScheduleMode: androidScheduleMode,
          );
          _scheduledKeys.add(notificationKey);
          return androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle
              ? CountdownNotificationStatus.exact
              : CountdownNotificationStatus.inexact;
        } on Object {
          if (androidScheduleMode ==
              AndroidScheduleMode.inexactAllowWhileIdle) {
            return CountdownNotificationStatus.unavailable;
          }
          try {
            await _plugin.zonedSchedule(
              id,
              '计时结束',
              '「$timerName」已完成',
              tz.TZDateTime.from(endAt, tz.local),
              _details(vibrate),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
            _scheduledKeys.add(notificationKey);
            return CountdownNotificationStatus.inexact;
          } on Object {
            return CountdownNotificationStatus.unavailable;
          }
        }
      });

  @override
  Future<void> completeCountdown({
    required String notificationKey,
    required String timerName,
    required bool vibrate,
  }) =>
      _enqueue(() async {
        await initialize();
        if (kIsWeb || !_initialized) {
          return;
        }
        if (!_scheduledKeys.contains(notificationKey)) {
          return;
        }
        final int id = _idForKey(notificationKey);
        try {
          final List<PendingNotificationRequest> pending =
              await _plugin.pendingNotificationRequests();
          if (!pending
              .any((PendingNotificationRequest item) => item.id == id)) {
            return;
          }
          await _plugin.cancel(id);
          await _plugin.show(
            id,
            '计时结束',
            '「$timerName」已完成',
            _details(vibrate),
          );
        } on Object {
          return;
        } finally {
          _scheduledKeys.remove(notificationKey);
        }
      });

  @override
  Future<void> cancelCountdownComplete(String notificationKey) =>
      _enqueue(() async {
        if (kIsWeb) {
          return;
        }
        await initialize();
        if (!_initialized) {
          return;
        }
        try {
          await _plugin.cancel(_idForKey(notificationKey));
        } on Object {
          return;
        } finally {
          _scheduledKeys.remove(notificationKey);
        }
      });

  NotificationDetails _details(bool vibrate) => NotificationDetails(
        android: AndroidNotificationDetails(
          vibrate ? _vibrationChannelId : _soundChannelId,
          vibrate ? '计时提醒（声音和振动）' : '计时提醒（声音）',
          channelDescription: '倒计时结束时提醒用户',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: vibrate,
          vibrationPattern:
              vibrate ? Int64List.fromList(countdownVibrationPattern) : null,
          audioAttributesUsage: vibrate
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
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
      );

  int _idForKey(String key) {
    final int? existing = _notificationIds[key];
    if (existing != null) {
      return existing;
    }
    int id = countdownNotificationId(key);
    while (id == 1001 || id == 2001 || _notificationIds.values.contains(id)) {
      id = (id + 1) & 0x7fffffff;
      if (id == 0) {
        id = 1;
      }
    }
    _notificationIds[key] = id;
    return id;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final Future<T> result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
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
      if (_exactPermissionRequestAttempted) {
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
      _exactPermissionRequestAttempted = true;
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

@visibleForTesting
int countdownNotificationId(String key) {
  int hash = 0x811c9dc5;
  for (final int codeUnit in key.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0xffffffff;
  }
  final int id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}

TimerNotificationScheduler buildDefaultNotificationScheduler() {
  if (kIsWeb) {
    return const DisabledTimerNotificationScheduler();
  }
  return LocalTimerNotificationScheduler();
}
