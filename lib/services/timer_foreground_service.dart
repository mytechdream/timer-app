import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class TimerForegroundService {
  Future<void> start({required String title, required String body});

  Future<void> stop();
}

class DisabledTimerForegroundService implements TimerForegroundService {
  const DisabledTimerForegroundService();

  @override
  Future<void> start({required String title, required String body}) async {}

  @override
  Future<void> stop() async {}
}

class AndroidTimerForegroundService implements TimerForegroundService {
  const AndroidTimerForegroundService();

  static const MethodChannel _channel =
      MethodChannel('timer_app/background_timer');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> start({required String title, required String body}) async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel
          .invokeMethod<void>('startForegroundTimer', <String, String>{
        'title': title,
        'body': body,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> stop() async {
    if (!_isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('stopForegroundTimer');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}

TimerForegroundService buildDefaultForegroundService() {
  if (kIsWeb) {
    return const DisabledTimerForegroundService();
  }
  return const AndroidTimerForegroundService();
}
