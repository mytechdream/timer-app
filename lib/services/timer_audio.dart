import 'package:audioplayers/audioplayers.dart';

abstract class TimerAudio {
  Future<void> playComplete();

  Future<void> dispose();
}

class AudioplayersTimerAudio implements TimerAudio {
  AudioplayersTimerAudio() : _player = AudioPlayer();

  final AudioPlayer _player;

  static final AssetSource _completeSound =
      AssetSource('audio/countdown_complete.wav');

  @override
  Future<void> playComplete() async {
    await _player.stop();
    await _player.play(_completeSound);
  }

  @override
  Future<void> dispose() => _player.dispose();
}

class SilentTimerAudio implements TimerAudio {
  const SilentTimerAudio();

  @override
  Future<void> playComplete() async {}

  @override
  Future<void> dispose() async {}
}
