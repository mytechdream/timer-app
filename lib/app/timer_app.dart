import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/timer_repository.dart';
import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../services/timer_foreground_service.dart';
import '../services/timer_notifications.dart';
import '../services/timer_vibration.dart';
import '../theme/app_theme.dart';
import '../pages/home_shell.dart';

class TimerApp extends StatefulWidget {
  const TimerApp({
    super.key,
    required this.repository,
    this.audio,
    this.notifications,
    this.foregroundService,
    this.vibration,
    this.now,
  });

  final TimerRepository repository;
  final TimerAudio? audio;
  final TimerNotificationScheduler? notifications;
  final TimerForegroundService? foregroundService;
  final TimerVibration? vibration;
  final DateTime Function()? now;

  @override
  State<TimerApp> createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  TimerSnapshot? _snapshot;
  late final TimerAudio _audio;
  late final TimerNotificationScheduler _notifications;
  late final TimerForegroundService _foregroundService;
  late final TimerVibration _vibration;
  int _paletteIndex = 1;

  @override
  void initState() {
    super.initState();
    _audio = widget.audio ?? AudioplayersTimerAudio();
    _notifications =
        widget.notifications ?? buildDefaultNotificationScheduler();
    _foregroundService =
        widget.foregroundService ?? buildDefaultForegroundService();
    _vibration = widget.vibration ?? const AndroidTimerVibration();
    unawaited(_notifications.initialize());
    _load();
  }

  @override
  void dispose() {
    unawaited(_foregroundService.stop());
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final TimerSnapshot snapshot = await widget.repository.load();
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = snapshot);
    // Wait until the loaded home screen is visible before the OS permission UI.
    // Exact-alarm access remains a separate request when a countdown is started.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          snapshot.settings.completionSoundEnabled &&
          snapshot.settings.completionReminderName !=
              TimerSettings.reminderOff) {
        unawaited(_notifications.requestNotificationPermission());
      }
    });
  }

  Future<void> _saveSnapshot(TimerSnapshot snapshot) async {
    setState(() => _snapshot = snapshot);
    await widget.repository.save(snapshot);
  }

  Future<void> _updateCollection(
    TimerCollectionScope scope,
    TimerCollection Function(TimerCollection collection) update,
  ) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    final TimerCollection collection = snapshot.collection(scope);
    final TimerCollection updated = update(collection);
    if (identical(updated, collection)) {
      return;
    }
    await _saveSnapshot(snapshot.withCollection(updated));
  }

  Future<void> _createTimer(
      TimerCollectionScope scope, String name, int seconds) async {
    final CreatedTimer timer = CreatedTimer(
      id: '${scope.name}-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      seconds: seconds,
      createdAt: DateTime.now(),
    );
    await _updateCollection(
        scope, (TimerCollection collection) => collection.addTimer(timer));
  }

  Future<void> _deleteTimer(TimerCollectionScope scope, String id) =>
      _updateCollection(
          scope, (TimerCollection collection) => collection.deleteTimer(id));

  Future<void> _createLabel(TimerCollectionScope scope, String label) =>
      _updateCollection(
          scope, (TimerCollection collection) => collection.addLabel(label));

  Future<void> _renameLabel(
          TimerCollectionScope scope, String oldLabel, String newLabel) =>
      _updateCollection(
          scope,
          (TimerCollection collection) =>
              collection.renameLabel(oldLabel, newLabel));

  Future<void> _deleteLabel(TimerCollectionScope scope, String label) =>
      _updateCollection(
          scope, (TimerCollection collection) => collection.deleteLabel(label));

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

  Future<void> _deleteHistoryEntry(String id) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    await _saveSnapshot(
      snapshot.copyWith(
        history: snapshot.history
            .where((TimerHistoryEntry entry) => entry.id != id)
            .toList(),
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
              notifications: _notifications,
              foregroundService: _foregroundService,
              vibration: _vibration,
              now: widget.now,
              paletteIndex: _paletteIndex,
              onPaletteChanged: (int index) =>
                  setState(() => _paletteIndex = index),
              onCreateTimer: _createTimer,
              onDeleteTimer: _deleteTimer,
              onCreateLabel: _createLabel,
              onRenameLabel: _renameLabel,
              onDeleteLabel: _deleteLabel,
              onSettingsChanged: _updateSettings,
              onHistoryEntry: _addHistoryEntry,
              onDeleteHistoryEntry: _deleteHistoryEntry,
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
