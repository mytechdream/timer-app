import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class TimerAudio {
  TimerAudio()
      : _tickPlayer = AudioPlayer(),
        _completionPlayer = AudioPlayer() {
    unawaited(_tickPlayer.setReleaseMode(ReleaseMode.stop));
    unawaited(_completionPlayer.setReleaseMode(ReleaseMode.stop));
  }

  final AudioPlayer _tickPlayer;
  final AudioPlayer _completionPlayer;

  Future<void> playTick() async {
    await _tickPlayer.stop();
    await _tickPlayer.play(
      AssetSource('audio/clock_tick.wav'),
      volume: 0.35,
    );
  }

  Future<void> playCompletion() async {
    await _completionPlayer.stop();
    await _completionPlayer.play(
      AssetSource('audio/countdown_complete.wav'),
      volume: 0.85,
    );
  }

  Future<void> dispose() async {
    await _tickPlayer.dispose();
    await _completionPlayer.dispose();
  }
}
