import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Off/on durations in milliseconds, shared by in-app and OS notification alerts.
const List<int> countdownVibrationPattern = <int>[0, 400, 180, 400];

abstract class TimerVibration {
  Future<void> vibrateCountdownComplete({
    required DateTime endAt,
    required DateTime now,
  });
}

class DisabledTimerVibration implements TimerVibration {
  const DisabledTimerVibration();

  @override
  Future<void> vibrateCountdownComplete({
    required DateTime endAt,
    required DateTime now,
  }) async {}
}

class AndroidTimerVibration implements TimerVibration {
  const AndroidTimerVibration();

  static const MethodChannel _channel = MethodChannel('timer_app/vibration');

  @override
  Future<void> vibrateCountdownComplete({
    required DateTime endAt,
    required DateTime now,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    // Background/locked-screen alerts belong to the scheduled notification.
    // Do not replay an old alert when the app resumes after its deadline.
    final Duration overdueBy = now.difference(endAt);
    if ((lifecycle != null && lifecycle != AppLifecycleState.resumed) ||
        overdueBy.isNegative ||
        overdueBy > const Duration(seconds: 2)) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>(
        'vibrateCountdownComplete',
        <String, Object>{'pattern': countdownVibrationPattern},
      );
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
