import 'dart:async';

import 'package:flutter/material.dart';

import '../data/timer_repository.dart';
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
  const HomeShell({super.key, required this.repository});

  final TimerRepository repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _defaultTimers = [
    SavedTimer(name: '刷牙', seconds: 3 * 60),
    SavedTimer(name: '番茄时钟', seconds: 25 * 60),
    SavedTimer(name: '练字', seconds: 15 * 60),
    SavedTimer(name: '拉伸', seconds: 15 * 60),
  ];

  int _tab = 0;
  bool _countdownMode = true;
  int _durationSeconds = 8 * 60;
  int _remainingSeconds = 8 * 60;
  bool _running = false;
  int _selectedPalette = 1;
  Timer? _ticker;
  final TimerAudio _audio = TimerAudio();

  List<SavedTimer> _timers = List.of(_defaultTimers);
  final List<HistoryRecord> _history = [];

  AppPalette get _palette => AppColors.palettes[_selectedPalette];

  @override
  void initState() {
    super.initState();
    unawaited(_loadPersistedState());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  Future<void> _loadPersistedState() async {
    try {
      final snapshot = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _selectedPalette = _validPalette(snapshot.selectedPalette);
        _timers = [..._defaultTimers, ...snapshot.timers];
        _history
          ..clear()
          ..addAll(snapshot.history);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _timers = List.of(_defaultTimers));
    }
  }

  int _validPalette(int index) {
    if (index < 0 || index >= AppColors.palettes.length) return 1;
    return index;
  }

  void _toggleTimer() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }

    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      HistoryRecord? completedRecord;
      var shouldPlayTick = false;
      var shouldPlayCompletion = false;
      setState(() {
        if (_countdownMode) {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _running = false;
            _ticker?.cancel();
            shouldPlayCompletion = true;
            completedRecord = HistoryRecord(
              type: '倒计时',
              label: '自定义倒计时',
              seconds: _durationSeconds,
              date: DateTime.now(),
            );
            _history.insert(0, completedRecord!);
          } else {
            shouldPlayTick = true;
          }
        } else {
          _remainingSeconds++;
          shouldPlayTick = true;
        }
      });
      final record = completedRecord;
      if (record != null) {
        unawaited(_persistHistory(record));
      }
      if (shouldPlayCompletion) {
        unawaited(_audio.playCompletion());
      } else if (shouldPlayTick) {
        unawaited(_audio.playTick());
      }
    });
  }

  void _setMode(bool countdown) {
    setState(() {
      _countdownMode = countdown;
      _running = false;
      _ticker?.cancel();
      _remainingSeconds = countdown ? _durationSeconds : 0;
    });
  }

  Future<void> _openCreateTimer() async {
    final result = await Navigator.of(context).push<SavedTimer>(
      MaterialPageRoute(
        builder: (_) => CreateTimerPage(
          palette: _palette,
          initialSeconds: const Duration(minutes: 5).inSeconds,
        ),
      ),
    );

    if (result == null) return;
    final savedTimer = await _saveTimer(result);
    if (!mounted) return;
    setState(() {
      _timers.add(savedTimer);
      _durationSeconds = savedTimer.seconds;
      _remainingSeconds = savedTimer.seconds;
      _countdownMode = true;
      _tab = 0;
    });
  }

  void _changeDuration(int seconds) {
    if (_running || seconds <= 0) return;
    setState(() {
      _durationSeconds = seconds;
      if (_countdownMode) {
        _remainingSeconds = seconds;
      }
    });
  }

  Future<SavedTimer> _saveTimer(SavedTimer timer) async {
    try {
      return await widget.repository.insertTimer(timer);
    } catch (_) {
      return timer;
    }
  }

  void _changePalette(int value) {
    setState(() => _selectedPalette = value);
    unawaited(_persistPalette(value));
  }

  Future<void> _persistHistory(HistoryRecord record) async {
    try {
      await widget.repository.insertHistory(record);
    } catch (_) {}
  }

  Future<void> _persistPalette(int value) async {
    try {
      await widget.repository.saveSelectedPalette(value);
    } catch (_) {}
  }

  void _startSavedTimer(SavedTimer timer) {
    setState(() {
      _durationSeconds = timer.seconds;
      _remainingSeconds = timer.seconds;
      _countdownMode = true;
      _tab = 0;
      _running = false;
      _ticker?.cancel();
    });
  }

  void _showHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryPage(palette: _palette, records: _history),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TimerDashboardPage(
        palette: _palette,
        countdownMode: _countdownMode,
        running: _running,
        durationSeconds: _durationSeconds,
        remainingSeconds: _remainingSeconds,
        timers: _timers,
        onDurationChanged: _changeDuration,
        onModeChanged: _setMode,
        onStartPressed: _toggleTimer,
        onHistoryPressed: _showHistory,
        onAddPressed: _openCreateTimer,
        onTimerPressed: _startSavedTimer,
      ),
      BatchTimerPage(
        palette: _palette,
        countdownMode: _countdownMode,
        onModeChanged: _setMode,
        onAddPressed: _openCreateTimer,
      ),
      InsightsPage(palette: _palette),
      SettingsPage(
        palette: _palette,
        selectedPalette: _selectedPalette,
        onPaletteChanged: _changePalette,
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      extendBody: true,
      bottomNavigationBar: AppBottomNav(
        palette: _palette,
        index: _tab,
        onChanged: (value) => setState(() => _tab = value),
      ),
    );
  }
}
