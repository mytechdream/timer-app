import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class TimerScreenAwake {
  Future<void> setEnabled(bool enabled);
}

class DisabledTimerScreenAwake implements TimerScreenAwake {
  const DisabledTimerScreenAwake();

  @override
  Future<void> setEnabled(bool enabled) async {}
}

class AndroidTimerScreenAwake implements TimerScreenAwake {
  const AndroidTimerScreenAwake();

  static const MethodChannel _channel = MethodChannel('timer_app/screen_awake');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>(
        'setKeepScreenOn',
        <String, bool>{'enabled': enabled},
      );
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}
