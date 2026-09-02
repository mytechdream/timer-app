import 'package:audioplayers/audioplayers.dart';

abstract class TimerAudio {
  Future<void> playTick();

  Future<void> playComplete(String soundName);

  Future<void> dispose();
}

class AudioplayersTimerAudio implements TimerAudio {
  AudioplayersTimerAudio()
      : _tickPlayer = AudioPlayer(),
        _completePlayer = AudioPlayer();

  final AudioPlayer _tickPlayer;
  final AudioPlayer _completePlayer;

  static final AssetSource _tickSound = AssetSource('audio/clock_tick.wav');
  static final AssetSource _completeSound =
      AssetSource('audio/countdown_complete.wav');
  static final AssetSource _softCompleteSound =
      AssetSource('audio/countdown_soft.wav');
  static final AssetSource _electronicCompleteSound =
      AssetSource('audio/countdown_electronic.wav');

  @override
  Future<void> playTick() async {
    await _tickPlayer.stop();
    await _tickPlayer.play(_tickSound);
  }

  @override
  Future<void> playComplete(String soundName) async {
    await _completePlayer.stop();
    await _completePlayer.play(_completeSourceFor(soundName));
  }

  AssetSource _completeSourceFor(String soundName) {
    return switch (soundName) {
      '柔和提示' => _softCompleteSound,
      '电子提示' => _electronicCompleteSound,
      _ => _completeSound,
    };
  }

  @override
  Future<void> dispose() async {
    await _tickPlayer.dispose();
    await _completePlayer.dispose();
  }
}

class SilentTimerAudio implements TimerAudio {
  const SilentTimerAudio();

  @override
  Future<void> playTick() async {}

  @override
  Future<void> playComplete(String soundName) async {}

  @override
  Future<void> dispose() async {}
}
