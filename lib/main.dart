import 'package:flutter/material.dart';

import 'app/timer_app.dart';
import 'services/timer_audio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    TimerApp(
      repository: buildDefaultRepository(),
      audio: AudioplayersTimerAudio(),
    ),
  );
}
