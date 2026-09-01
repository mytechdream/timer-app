import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../theme/app_theme.dart';
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
    required this.paletteIndex,
    required this.onPaletteChanged,
    required this.onCreateTimer,
    required this.onCreateLabel,
    required this.onSettingsChanged,
    required this.onHistoryEntry,
  });

  final TimerSnapshot snapshot;
  final TimerAudio audio;
  final int paletteIndex;
  final ValueChanged<int> onPaletteChanged;
  final Future<void> Function(String name, int seconds) onCreateTimer;
  final Future<void> Function(String label) onCreateLabel;
  final Future<void> Function(TimerSettings settings) onSettingsChanged;
  final Future<void> Function(TimerHistoryEntry entry) onHistoryEntry;

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
          IndexedStack(
            index: _pageIndex,
            children: <Widget>[
              TimerDashboardPage(
                timers: widget.snapshot.timers,
                labels: widget.snapshot.labels,
                settings: widget.snapshot.settings,
                onCreateTimer: () => _openCreateTimer(context),
                onCreateLabel: () => _openAddLabel(context),
                onOpenHistory: () => _openHistory(context),
                onStartTimer: _openRunningTimer,
              ),
              BatchTimerPage(
                timers: widget.snapshot.timers,
                onCreateTimer: () => _openCreateTimer(context),
                onStartTimer: (CreatedTimer timer) => _openRunningTimer(
                  TimerRunMode.countdown,
                  timer.name,
                  timer.seconds,
                ),
              ),
              InsightsPage(history: widget.snapshot.history),
              SettingsPage(
                settings: widget.snapshot.settings,
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
        (_) => CreateTimerPage(onSave: widget.onCreateTimer),
      ),
    );
  }

  void _openAddLabel(BuildContext context) {
    Navigator.of(context).push(
      _instantRoute<void>(
        (_) => AddLabelPage(onSave: widget.onCreateLabel),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      _instantRoute<void>(
        (_) => HistoryPage(history: widget.snapshot.history),
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
