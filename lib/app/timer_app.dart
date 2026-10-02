import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/timer_repository.dart';
import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../services/timer_foreground_service.dart';
import '../services/timer_notifications.dart';
import '../theme/app_theme.dart';
import '../pages/home_shell.dart';

class TimerApp extends StatefulWidget {
  const TimerApp({
    super.key,
    required this.repository,
    this.audio,
    this.notifications,
    this.foregroundService,
    this.now,
  });

  final TimerRepository repository;
  final TimerAudio? audio;
  final TimerNotificationScheduler? notifications;
  final TimerForegroundService? foregroundService;
  final DateTime Function()? now;

  @override
  State<TimerApp> createState() => _TimerAppState();
}

class _TimerAppState extends State<TimerApp> {
  TimerSnapshot? _snapshot;
  late final TimerAudio _audio;
  late final TimerNotificationScheduler _notifications;
  late final TimerForegroundService _foregroundService;
  int _paletteIndex = 1;

  @override
  void initState() {
    super.initState();
    _audio = widget.audio ?? AudioplayersTimerAudio();
    _notifications =
        widget.notifications ?? buildDefaultNotificationScheduler();
    _foregroundService =
        widget.foregroundService ?? buildDefaultForegroundService();
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

  Future<void> _deleteTimer(String id) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    if (TimerDefaults.isDefaultTimerId(id)) {
      await _saveSnapshot(
        snapshot.copyWith(
          hiddenDefaultTimerIds: <String>{
            ...snapshot.hiddenDefaultTimerIds,
            id,
          }.toList(),
        ),
      );
      return;
    }

    await _saveSnapshot(
      snapshot.copyWith(
        timers: snapshot.timers
            .where((CreatedTimer timer) => timer.id != id)
            .toList(),
      ),
    );
  }

  Future<void> _createLabel(String label) async {
    final String normalized = label.trim();
    if (normalized.isEmpty) {
      return;
    }

    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    if (snapshot.labels.contains(normalized)) {
      return;
    }

    if (TimerDefaults.isDefaultLabel(normalized)) {
      if (!snapshot.hiddenDefaultLabels.contains(normalized)) {
        return;
      }
      await _saveSnapshot(
        snapshot.copyWith(
          hiddenDefaultLabels: snapshot.hiddenDefaultLabels
              .where((String label) => label != normalized)
              .toList(),
        ),
      );
      return;
    }

    await _saveSnapshot(
      snapshot.copyWith(labels: <String>[...snapshot.labels, normalized]),
    );
  }

  Future<void> _renameLabel(String oldLabel, String newLabel) async {
    final String normalized = newLabel.trim();
    if (normalized.isEmpty) {
      return;
    }

    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    final List<String> labels = List<String>.of(snapshot.labels);
    final List<String> hiddenDefaultLabels =
        List<String>.of(snapshot.hiddenDefaultLabels);
    final bool isStoredLabel = labels.contains(oldLabel);
    final bool isDefaultLabel = TimerDefaults.isDefaultLabel(oldLabel);
    final bool isVisibleDefaultLabel =
        isDefaultLabel && !hiddenDefaultLabels.contains(oldLabel);
    if (!isStoredLabel && !isVisibleDefaultLabel) {
      return;
    }
    if (labels
        .any((String label) => label == normalized && label != oldLabel)) {
      return;
    }
    if (normalized != oldLabel &&
        TimerDefaults.isDefaultLabel(normalized) &&
        !hiddenDefaultLabels.contains(normalized)) {
      return;
    }

    labels.removeWhere((String label) => label == oldLabel);
    if (isDefaultLabel) {
      hiddenDefaultLabels.add(oldLabel);
    }
    if (TimerDefaults.isDefaultLabel(normalized)) {
      hiddenDefaultLabels.removeWhere((String label) => label == normalized);
    } else {
      labels.add(normalized);
    }

    await _saveSnapshot(
      snapshot.copyWith(
        labels: labels.toSet().toList(),
        hiddenDefaultLabels: hiddenDefaultLabels.toSet().toList(),
      ),
    );
  }

  Future<void> _deleteLabel(String label) async {
    final TimerSnapshot snapshot = _snapshot ?? TimerSnapshot.initial();
    final bool isStoredLabel = snapshot.labels.contains(label);
    final bool isDefaultLabel = TimerDefaults.isDefaultLabel(label);
    if (!isStoredLabel && !isDefaultLabel) {
      return;
    }

    await _saveSnapshot(
      snapshot.copyWith(
        labels: snapshot.labels
            .where((String existingLabel) => existingLabel != label)
            .toList(),
        hiddenDefaultLabels: isDefaultLabel
            ? <String>{...snapshot.hiddenDefaultLabels, label}.toList()
            : snapshot.hiddenDefaultLabels,
      ),
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
