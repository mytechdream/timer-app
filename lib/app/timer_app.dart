import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/timer_repository.dart';
import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../theme/app_theme.dart';
import '../pages/home_shell.dart';

class TimerApp extends StatefulWidget {
  const TimerApp({
    super.key,
    required this.repository,
    this.audio,
  });

  final TimerRepository repository;
  final TimerAudio? audio;

  @override
  State<TimerApp> createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  TimerSnapshot? _snapshot;
  late final TimerAudio _audio;
  int _paletteIndex = 1;

  @override
  void initState() {
    super.initState();
    _audio = widget.audio ?? AudioplayersTimerAudio();
    _load();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final TimerSnapshot snapshot = await widget.repository.load();
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = snapshot);
  }

  Future<void> _saveSnapshot(TimerSnapshot snapshot) async {
    setState(() => _snapshot = snapshot);
    await widget.repository.save(snapshot);
  }

  Future<void> _createTimer(String name, int seconds) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    final CreatedTimer timer = CreatedTimer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      seconds: seconds,
      createdAt: DateTime.now(),
    );
    await _saveSnapshot(
      snapshot.copyWith(timers: <CreatedTimer>[...snapshot.timers, timer]),
    );
  }

  Future<void> _createLabel(String label) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    if (snapshot.labels.contains(label)) {
      return;
    }
    await _saveSnapshot(
      snapshot.copyWith(labels: <String>[...snapshot.labels, label]),
    );
  }

  Future<void> _updateSettings(TimerSettings settings) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    await _saveSnapshot(snapshot.copyWith(settings: settings));
  }

  Future<void> _addHistoryEntry(TimerHistoryEntry entry) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    await _saveSnapshot(
      snapshot.copyWith(
        history:
            <TimerHistoryEntry>[entry, ...snapshot.history].take(100).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TimerPalette palette = AppTheme.palettes[_paletteIndex];
    return MaterialApp(
      title: '番茄时钟',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const <Locale>[
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.build(palette),
      home: _snapshot == null
          ? const _LoadingPage()
          : HomeShell(
              snapshot: _snapshot!,
              audio: _audio,
              paletteIndex: _paletteIndex,
              onPaletteChanged: (int index) =>
                  setState(() => _paletteIndex = index),
              onCreateTimer: _createTimer,
              onCreateLabel: _createLabel,
              onSettingsChanged: _updateSettings,
              onHistoryEntry: _addHistoryEntry,
            ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

TimerRepository buildDefaultRepository() {
  if (kIsWeb) {
    return MemoryTimerRepository();
  }
  return SqliteTimerRepository();
}
