import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../data/timer_repository.dart';
import '../pages/home_shell.dart';
import '../theme/app_theme.dart';

class TimerApp extends StatelessWidget {
  const TimerApp({super.key, this.repository});

  final TimerRepository? repository;

  @override
  Widget build(BuildContext context) {
    final timerRepository = repository ??
        (kIsWeb ? MemoryTimerRepository() : SqliteTimerRepository());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '计时器',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.palettes[1].color,
          surface: AppColors.bg,
        ),
        fontFamily: 'sans',
        scaffoldBackgroundColor: AppColors.bg,
      ),
      home: HomeShell(repository: timerRepository),
    );
  }
}
