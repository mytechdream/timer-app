import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../services/timer_foreground_service.dart';
import '../services/timer_notifications.dart';
import '../services/timer_vibration.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_tab_stack.dart';
import '../widgets/app_bottom_nav.dart';
import 'batch_timer_page.dart';
import 'create_timer_page.dart';
import 'history_page.dart';
import 'insights_page.dart';
import 'settings_page.dart';
import 'timer_dashboard_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.snapshot,
    required this.audio,
    required this.notifications,
    required this.foregroundService,
    required this.vibration,
    this.now,
    required this.paletteIndex,
    required this.onPaletteChanged,
    required this.onCreateTimer,
    required this.onDeleteTimer,
    required this.onCreateLabel,
    required this.onRenameLabel,
    required this.onDeleteLabel,
    required this.onSettingsChanged,
    required this.onHistoryEntry,
    required this.onDeleteHistoryEntry,
  });

  final TimerSnapshot snapshot;
  final TimerAudio audio;
  final TimerNotificationScheduler notifications;
  final TimerForegroundService foregroundService;
  final TimerVibration vibration;
  final DateTime Function()? now;
  final int paletteIndex;
  final ValueChanged<int> onPaletteChanged;
  final Future<void> Function(
      TimerCollectionScope scope, String name, int seconds) onCreateTimer;
  final Future<void> Function(TimerCollectionScope scope, String id)
      onDeleteTimer;
  final Future<void> Function(TimerCollectionScope scope, String label)
      onCreateLabel;
  final Future<void> Function(
          TimerCollectionScope scope, String oldLabel, String newLabel)
      onRenameLabel;
  final Future<void> Function(TimerCollectionScope scope, String label)
      onDeleteLabel;
  final Future<void> Function(TimerSettings settings) onSettingsChanged;
  final Future<void> Function(TimerHistoryEntry entry) onHistoryEntry;
  final Future<void> Function(String id) onDeleteHistoryEntry;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: context.timerPalette.background,
      body: Stack(
        children: <Widget>[
          AnimatedTabStack(
            index: _pageIndex,
            children: <Widget>[
              TimerDashboardPage(
                timers: widget.snapshot.timers,
                labels: widget.snapshot.labels,
                hiddenDefaultTimerIds: widget.snapshot.hiddenDefaultTimerIds,
                hiddenDefaultLabels: widget.snapshot.hiddenDefaultLabels,
                settings: widget.snapshot.settings,
                onCreateTimer: () => _openCreateTimer(context),
                onDeleteTimer: (String id) =>
                    widget.onDeleteTimer(TimerCollectionScope.home, id),
                onCreateLabel: () => _openAddLabel(context),
                onEditLabel: (String label) =>
                    _openEditLabel(context, label, TimerCollectionScope.home),
                onOpenHistory: () => _openHistory(context),
                onStartTimer: _openRunningTimer,
              ),
              BatchTimerPage(
                timers: widget.snapshot.batch.timers,
                labels: widget.snapshot.batch.labels,
                hiddenDefaultTimerIds:
                    widget.snapshot.batch.hiddenDefaultTimerIds,
                hiddenDefaultLabels: widget.snapshot.batch.hiddenDefaultLabels,
                defaultCountdownSeconds:
                    widget.snapshot.settings.defaultCountdownSeconds,
                settings: widget.snapshot.settings,
                notifications: widget.notifications,
                vibration: widget.vibration,
                now: widget.now,
                onCreateTimer: (String name, int seconds) => widget
                    .onCreateTimer(TimerCollectionScope.batch, name, seconds),
                onDeleteTimer: (String id) =>
                    widget.onDeleteTimer(TimerCollectionScope.batch, id),
                onCreateLabel: (String label) =>
                    widget.onCreateLabel(TimerCollectionScope.batch, label),
                onEditLabel: (String label) =>
                    _openEditLabel(context, label, TimerCollectionScope.batch),
                onDeleteLabel: (String label) =>
                    widget.onDeleteLabel(TimerCollectionScope.batch, label),
              ),
              InsightsPage(history: widget.snapshot.history),
              SettingsPage(
                settings: widget.snapshot.settings,
                audio: widget.audio,
                selectedPaletteIndex: widget.paletteIndex,
                onPaletteChanged: widget.onPaletteChanged,
                onSettingsChanged: widget.onSettingsChanged,
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomNav(
              index: _pageIndex,
              onChanged: (int index) => setState(() => _pageIndex = index),
            ),
          ),
        ],
      ),
    );
  }

  void _openRunningTimer(TimerRunMode mode, String name, int seconds) {
    final TimerSession session = TimerSession(
      mode: mode,
      name: name,
      initialSeconds: seconds,
      settings: widget.snapshot.settings,
      audio: widget.audio,
      notifications: widget.notifications,
      foregroundService: widget.foregroundService,
      vibration: widget.vibration,
      now: widget.now,
      onSettingsChanged: widget.onSettingsChanged,
      onCompleted: widget.onHistoryEntry,
    );
    Navigator.of(context).push(
      _instantRoute<void>(
        (_) => RunningTimerPage(session: session),
      ),
    );
  }

  void _openCreateTimer(BuildContext context) {
    Navigator.of(context).push(
      _instantRoute<void>(
        (_) => CreateTimerPage(
          initialSeconds: widget.snapshot.settings.defaultCountdownSeconds,
          onSave: (String name, int seconds) =>
              widget.onCreateTimer(TimerCollectionScope.home, name, seconds),
        ),
      ),
    );
  }

  void _openAddLabel(BuildContext context) {
    Navigator.of(context).push(
      _instantRoute<void>(
        (_) => AddLabelPage(
          existingLabels: widget.snapshot
              .collection(TimerCollectionScope.home)
              .visibleLabels,
          onSave: (String label) =>
              widget.onCreateLabel(TimerCollectionScope.home, label),
        ),
      ),
    );
  }

  void _openEditLabel(
      BuildContext context, String label, TimerCollectionScope scope) {
    Navigator.of(context).push(
      _instantRoute<void>(
        (_) => EditLabelPage(
          initialLabel: label,
          existingLabels: widget.snapshot.collection(scope).visibleLabels,
          onSave: (String value) => widget.onRenameLabel(scope, label, value),
          onDelete: () => widget.onDeleteLabel(scope, label),
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      _instantRoute<void>(
        (_) => HistoryPage(
          history: widget.snapshot.history,
          onDelete: widget.onDeleteHistoryEntry,
        ),
      ),
    );
  }

  PageRouteBuilder<T> _instantRoute<T>(WidgetBuilder builder) {
    return PageRouteBuilder<T>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (BuildContext context, _, __) => builder(context),
    );
  }
}
