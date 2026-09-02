import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_page.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/duration_picker_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_pill.dart';

class BatchTimerPage extends StatefulWidget {
  const BatchTimerPage({
    super.key,
    required this.timers,
    required this.labels,
    required this.hiddenDefaultTimerIds,
    required this.hiddenDefaultLabels,
    required this.onCreateTimer,
    required this.onDeleteTimer,
    required this.onCreateLabel,
    required this.onEditLabel,
    required this.onDeleteLabel,
  });

  final List<CreatedTimer> timers;
  final List<String> labels;
  final List<String> hiddenDefaultTimerIds;
  final List<String> hiddenDefaultLabels;
  final Future<void> Function(String name, int seconds) onCreateTimer;
  final Future<void> Function(String id) onDeleteTimer;
  final Future<void> Function(String label) onCreateLabel;
  final ValueChanged<String> onEditLabel;
  final Future<void> Function(String label) onDeleteLabel;

  @override
  State<BatchTimerPage> createState() => _BatchTimerPageState();
}

class _BatchTimerPageState extends State<BatchTimerPage> {
  int _modeIndex = 0;
  bool _selecting = false;
  Timer? _ticker;

  final Map<String, _CountdownBatchState> _countdownStates =
      <String, _CountdownBatchState>{};
  final Map<String, _StopwatchBatchState> _stopwatchStates =
      <String, _StopwatchBatchState>{};

  List<CreatedTimer> get _countdownTimers {
    final Set<String> hiddenDefaultIds = widget.hiddenDefaultTimerIds.toSet();
    return <CreatedTimer>[
      for (final TimerPreset timer in TimerDefaults.batchCountdownTimers)
        if (!hiddenDefaultIds.contains(timer.id))
          CreatedTimer(
            id: timer.id,
            name: timer.name,
            seconds: timer.seconds,
            createdAt: DateTime(2026, 9, 2),
          ),
      ...widget.timers,
    ];
  }

  List<String> get _stopwatchLabels {
    final Set<String> hiddenDefaultLabels = widget.hiddenDefaultLabels.toSet();
    return <String>{
      for (final String label in TimerDefaults.batchStopwatchLabels)
        if (!hiddenDefaultLabels.contains(label)) label,
      ...widget.labels,
    }.toList();
  }

  bool get _isCountdownMode => _modeIndex == 0;

  bool get _hasRunningItems {
    return _countdownStates.values.any(
          (_CountdownBatchState state) => state.running,
        ) ||
        _stopwatchStates.values.any(
          (_StopwatchBatchState state) => state.running,
        );
  }

  int get _deletableSelectedCount {
    if (_isCountdownMode) {
      return _countdownTimers
          .where(
            (CreatedTimer timer) =>
                _countdownStates[timer.id]?.selected ?? false,
          )
          .length;
    }
    return _stopwatchLabels
        .where((String label) => _stopwatchStates[label]?.selected ?? false)
        .length;
  }

  bool get _hasRunningVisibleItems {
    if (_isCountdownMode) {
      return _countdownTimers.any(
        (CreatedTimer timer) => _countdownStates[timer.id]?.running ?? false,
      );
    }
    return _stopwatchLabels.any(
      (String label) => _stopwatchStates[label]?.running ?? false,
    );
  }

  @override
  void initState() {
    super.initState();
    _syncBatchStates();
  }

  @override
  void didUpdateWidget(BatchTimerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBatchStates();
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncBatchStates() {
    final Set<String> countdownIds =
        _countdownTimers.map((CreatedTimer timer) => timer.id).toSet();
    _countdownStates.removeWhere(
      (String id, _) => !countdownIds.contains(id),
    );

    for (final CreatedTimer timer in _countdownTimers) {
      final _CountdownBatchState? existing = _countdownStates[timer.id];
      if (existing == null || existing.initialSeconds != timer.seconds) {
        _countdownStates[timer.id] = _CountdownBatchState(
          initialSeconds: timer.seconds,
          remainingSeconds: timer.seconds,
        );
      }
    }

    final Set<String> labels = _stopwatchLabels.toSet();
    _stopwatchStates.removeWhere((String label, _) => !labels.contains(label));
    for (final String label in _stopwatchLabels) {
      _stopwatchStates.putIfAbsent(label, _StopwatchBatchState.new);
    }
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _syncTicker() {
    if (_hasRunningItems) {
      _ensureTicker();
      return;
    }
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    if (!mounted) {
      return;
    }

    setState(() {
      _countdownStates.updateAll(
        (_, _CountdownBatchState state) {
          if (!state.running) {
            return state;
          }
          final int nextRemaining = math.max(0, state.remainingSeconds - 1);
          return state.copyWith(
            remainingSeconds: nextRemaining,
            running: nextRemaining > 0,
          );
        },
      );
      _stopwatchStates.updateAll(
        (_, _StopwatchBatchState state) => state.running
            ? state.copyWith(elapsedSeconds: state.elapsedSeconds + 1)
            : state,
      );
    });
    _syncTicker();
  }

  void _setModeIndex(int index) {
    setState(() {
      _modeIndex = index;
      _selecting = false;
      _clearSelections();
    });
  }

  void _showCreateSheet() {
    final TimerRunMode mode =
        _isCountdownMode ? TimerRunMode.countdown : TimerRunMode.stopwatch;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _BatchCreateSheet(
          mode: mode,
          onCreateTimer: widget.onCreateTimer,
          onCreateLabel: widget.onCreateLabel,
        );
      },
    );
  }

  void _toggleSelecting() {
    setState(() {
      _selecting = !_selecting;
      if (!_selecting) {
        _clearSelections();
      }
    });
  }

  void _clearSelections() {
    _countdownStates.updateAll(
      (_, _CountdownBatchState state) => state.copyWith(selected: false),
    );
    _stopwatchStates.updateAll(
      (_, _StopwatchBatchState state) => state.copyWith(selected: false),
    );
  }

  void _toggleCountdownSelection(String id) {
    setState(() {
      final _CountdownBatchState state = _countdownStates[id]!;
      _countdownStates[id] = state.copyWith(selected: !state.selected);
    });
  }

  void _toggleStopwatchSelection(String label) {
    setState(() {
      final _StopwatchBatchState state = _stopwatchStates[label]!;
      _stopwatchStates[label] = state.copyWith(selected: !state.selected);
    });
  }

  void _toggleCountdownRunning(String id) {
    setState(() {
      final _CountdownBatchState state = _countdownStates[id]!;
      final bool shouldRun = !state.running;
      _countdownStates[id] = state.copyWith(
        remainingSeconds: state.remainingSeconds == 0
            ? state.initialSeconds
            : state.remainingSeconds,
        running: shouldRun,
      );
    });
    _syncTicker();
  }

  void _toggleStopwatchRunning(String label) {
    setState(() {
      final _StopwatchBatchState state = _stopwatchStates[label]!;
      _stopwatchStates[label] = state.copyWith(running: !state.running);
    });
    _syncTicker();
  }

  void _resetCountdown(String id) {
    setState(() {
      final _CountdownBatchState state = _countdownStates[id]!;
      _countdownStates[id] = state.copyWith(
        remainingSeconds: state.initialSeconds,
        running: false,
      );
    });
    _syncTicker();
  }

  void _resetStopwatch(String label) {
    setState(() {
      final _StopwatchBatchState state = _stopwatchStates[label]!;
      _stopwatchStates[label] = state.copyWith(
        elapsedSeconds: 0,
        running: false,
      );
    });
    _syncTicker();
  }

  void _startAllVisible() {
    setState(() {
      if (_isCountdownMode) {
        for (final CreatedTimer timer in _countdownTimers) {
          final _CountdownBatchState state = _countdownStates[timer.id]!;
          _countdownStates[timer.id] = state.copyWith(
            remainingSeconds: state.remainingSeconds == 0
                ? state.initialSeconds
                : state.remainingSeconds,
            running: true,
          );
        }
      } else {
        for (final String label in _stopwatchLabels) {
          _stopwatchStates[label] = _stopwatchStates[label]!.copyWith(
            running: true,
          );
        }
      }
    });
    _syncTicker();
  }

  void _pauseAllVisible() {
    setState(() {
      if (_isCountdownMode) {
        for (final CreatedTimer timer in _countdownTimers) {
          _countdownStates[timer.id] = _countdownStates[timer.id]!.copyWith(
            running: false,
          );
        }
      } else {
        for (final String label in _stopwatchLabels) {
          _stopwatchStates[label] = _stopwatchStates[label]!.copyWith(
            running: false,
          );
        }
      }
    });
    _syncTicker();
  }

  void _resetAllVisible() {
    setState(() {
      if (_isCountdownMode) {
        for (final CreatedTimer timer in _countdownTimers) {
          final _CountdownBatchState state = _countdownStates[timer.id]!;
          _countdownStates[timer.id] = state.copyWith(
            remainingSeconds: state.initialSeconds,
            running: false,
          );
        }
      } else {
        for (final String label in _stopwatchLabels) {
          _stopwatchStates[label] = _stopwatchStates[label]!.copyWith(
            elapsedSeconds: 0,
            running: false,
          );
        }
      }
    });
    _syncTicker();
  }

  Future<void> _deleteSelectedVisible() async {
    if (_deletableSelectedCount == 0) {
      return;
    }

    final bool shouldDelete = await showDeleteDialog(
      context: context,
      title: '删除选中项？',
      message: '选中的已创建项目会从批量计时里删除。',
      actionLabel: '删除',
    );
    if (!shouldDelete) {
      return;
    }

    if (_isCountdownMode) {
      final List<String> ids = _countdownTimers
          .where(
            (CreatedTimer timer) =>
                _countdownStates[timer.id]?.selected ?? false,
          )
          .map((CreatedTimer timer) => timer.id)
          .toList();
      for (final String id in ids) {
        await widget.onDeleteTimer(id);
      }
    } else {
      final List<String> labels = _stopwatchLabels
          .where((String label) => _stopwatchStates[label]?.selected ?? false)
          .toList();
      for (final String label in labels) {
        await widget.onDeleteLabel(label);
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _selecting = false;
      _clearSelections();
    });
    _syncTicker();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '批量计时',
      centerTitle: false,
      actions: <Widget>[
        _SelectActionButton(
          selecting: _selecting,
          onPressed: _toggleSelecting,
        ),
        RoundIconButton(
          icon: Icons.add_rounded,
          tooltip: _isCountdownMode ? '创建倒计时' : '添加标签',
          filled: true,
          onPressed: _showCreateSheet,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SegmentedPill(
            items: const <String>['倒计时', '正计时'],
            selectedIndex: _modeIndex,
            onChanged: _setModeIndex,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isCountdownMode ? _buildCountdowns() : _buildStopwatches(),
          ),
          const SizedBox(height: 22),
          _BatchActionPanel(
            selectedCount: _deletableSelectedCount,
            hasRunningItems: _hasRunningVisibleItems,
            onStartAll: _startAllVisible,
            onPauseAll: _pauseAllVisible,
            onResetAll: _resetAllVisible,
            onDeleteSelected:
                _deletableSelectedCount > 0 ? _deleteSelectedVisible : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCountdowns() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _countdownTimers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final CreatedTimer timer = _countdownTimers[index];
        final _CountdownBatchState state = _countdownStates[timer.id]!;
        return _BatchCountdownCard(
          timer: timer,
          state: state,
          selecting: _selecting,
          editable: true,
          onToggleSelection: () => _toggleCountdownSelection(timer.id),
          onToggleRunning: () => _toggleCountdownRunning(timer.id),
          onReset: () => _resetCountdown(timer.id),
          onDelete: () => _confirmDeleteCountdown(timer),
        );
      },
    );
  }

  Widget _buildStopwatches() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _stopwatchLabels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final String label = _stopwatchLabels[index];
        final _StopwatchBatchState state = _stopwatchStates[label]!;
        return _BatchStopwatchCard(
          label: label,
          state: state,
          selecting: _selecting,
          editable: true,
          onToggleSelection: () => _toggleStopwatchSelection(label),
          onToggleRunning: () => _toggleStopwatchRunning(label),
          onReset: () => _resetStopwatch(label),
          onEdit: () => widget.onEditLabel(label),
        );
      },
    );
  }

  Future<void> _confirmDeleteCountdown(CreatedTimer timer) async {
    final bool shouldDelete = await showDeleteDialog(
      context: context,
      title: '删除倒计时？',
      message: '删除“${timer.name}”后，它不会再出现在批量计时里。',
      actionLabel: '删除',
    );
    if (!shouldDelete) {
      return;
    }
    await widget.onDeleteTimer(timer.id);
  }
}

class _CountdownBatchState {
  const _CountdownBatchState({
    required this.initialSeconds,
    required this.remainingSeconds,
    this.running = false,
    this.selected = false,
  });

  final int initialSeconds;
  final int remainingSeconds;
  final bool running;
  final bool selected;

  double get progress {
    if (initialSeconds == 0) {
      return 0;
    }
    return 1 - remainingSeconds / initialSeconds;
  }

  _CountdownBatchState copyWith({
    int? initialSeconds,
    int? remainingSeconds,
    bool? running,
    bool? selected,
  }) {
    return _CountdownBatchState(
      initialSeconds: initialSeconds ?? this.initialSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      running: running ?? this.running,
      selected: selected ?? this.selected,
    );
  }
}

class _StopwatchBatchState {
  const _StopwatchBatchState({
    this.elapsedSeconds = 0,
    this.running = false,
    this.selected = false,
  });

  final int elapsedSeconds;
  final bool running;
  final bool selected;

  double get progress => (elapsedSeconds % 60) / 60;

  _StopwatchBatchState copyWith({
    int? elapsedSeconds,
    bool? running,
    bool? selected,
  }) {
    return _StopwatchBatchState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      running: running ?? this.running,
      selected: selected ?? this.selected,
    );
  }
}

class _SelectActionButton extends StatelessWidget {
  const _SelectActionButton({
    required this.selecting,
    required this.onPressed,
  });

  final bool selecting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        fixedSize: const Size(44, 44),
        foregroundColor: primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      child: Text(selecting ? '完成' : '选择'),
    );
  }
}

class _BatchCountdownCard extends StatelessWidget {
  const _BatchCountdownCard({
    required this.timer,
    required this.state,
    required this.selecting,
    required this.editable,
    required this.onToggleSelection,
    required this.onToggleRunning,
    required this.onReset,
    required this.onDelete,
  });

  final CreatedTimer timer;
  final _CountdownBatchState state;
  final bool selecting;
  final bool editable;
  final VoidCallback onToggleSelection;
  final VoidCallback onToggleRunning;
  final VoidCallback onReset;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _BatchCardFrame(
      selected: state.selected,
      onTap: selecting ? onToggleSelection : null,
      onLongPress: !selecting && editable ? onDelete : null,
      child: _BatchCardContent(
        title: timer.name,
        time: formatDigitalTime(state.remainingSeconds),
        progress: state.progress.clamp(0.0, 1.0).toDouble(),
        selected: state.selected,
        selecting: selecting,
        running: state.running,
        resetTooltip: '重置${timer.name}',
        toggleTooltip: state.running ? '暂停${timer.name}' : '开始${timer.name}',
        onReset: onReset,
        onToggleRunning: onToggleRunning,
      ),
    );
  }
}

class _BatchStopwatchCard extends StatelessWidget {
  const _BatchStopwatchCard({
    required this.label,
    required this.state,
    required this.selecting,
    required this.editable,
    required this.onToggleSelection,
    required this.onToggleRunning,
    required this.onReset,
    required this.onEdit,
  });

  final String label;
  final _StopwatchBatchState state;
  final bool selecting;
  final bool editable;
  final VoidCallback onToggleSelection;
  final VoidCallback onToggleRunning;
  final VoidCallback onReset;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _BatchCardFrame(
      selected: state.selected,
      onTap: selecting ? onToggleSelection : null,
      onLongPress: !selecting && editable ? onEdit : null,
      child: _BatchCardContent(
        title: label,
        time: formatDigitalTime(state.elapsedSeconds),
        progress: state.progress,
        selected: state.selected,
        selecting: selecting,
        running: state.running,
        resetTooltip: '重置$label',
        toggleTooltip: state.running ? '暂停$label' : '开始$label',
        onReset: onReset,
        onToggleRunning: onToggleRunning,
      ),
    );
  }
}

class _BatchCardFrame extends StatelessWidget {
  const _BatchCardFrame({
    required this.selected,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final BorderRadius radius = BorderRadius.circular(24);
    final Widget card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: radius,
        border: Border.all(
          color: selected ? primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null && onLongPress == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      ),
    );
  }
}

class _BatchCardContent extends StatelessWidget {
  const _BatchCardContent({
    required this.title,
    required this.time,
    required this.progress,
    required this.selected,
    required this.selecting,
    required this.running,
    required this.resetTooltip,
    required this.toggleTooltip,
    required this.onReset,
    required this.onToggleRunning,
  });

  final String title;
  final String time;
  final double progress;
  final bool selected;
  final bool selecting;
  final bool running;
  final String resetTooltip;
  final String toggleTooltip;
  final VoidCallback onReset;
  final VoidCallback onToggleRunning;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final TimerPalette palette = context.timerPalette;

    return Row(
      children: <Widget>[
        if (selecting) ...<Widget>[
          _SelectionMark(selected: selected),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                time,
                style: const TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  backgroundColor: palette.soft,
                  value: progress.clamp(0.0, 1.0).toDouble(),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _CardIconButton(
          icon: Icons.refresh_rounded,
          tooltip: resetTooltip,
          backgroundColor: palette.soft,
          foregroundColor: AppTheme.mutedInk,
          onPressed: onReset,
        ),
        const SizedBox(width: 8),
        _CardIconButton(
          icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          tooltip: toggleTooltip,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          size: 58,
          iconSize: running ? 28 : 34,
          onPressed: onToggleRunning,
        ),
      ],
    );
  }
}

class _BatchCreateSheet extends StatefulWidget {
  const _BatchCreateSheet({
    required this.mode,
    required this.onCreateTimer,
    required this.onCreateLabel,
  });

  final TimerRunMode mode;
  final Future<void> Function(String name, int seconds) onCreateTimer;
  final Future<void> Function(String label) onCreateLabel;

  @override
  State<_BatchCreateSheet> createState() => _BatchCreateSheetState();
}

class _BatchCreateSheetState extends State<_BatchCreateSheet> {
  final TextEditingController _controller = TextEditingController();
  int _seconds = 15 * 60;
  bool _saving = false;

  bool get _isCountdown => widget.mode == TimerRunMode.countdown;

  bool get _canSave {
    if (_saving) {
      return false;
    }
    return _isCountdown || _controller.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }

    setState(() => _saving = true);
    if (_isCountdown) {
      final String name =
          _controller.text.trim().isEmpty ? '新倒计时' : _controller.text.trim();
      await widget.onCreateTimer(name, _seconds);
    } else {
      await widget.onCreateLabel(_controller.text.trim());
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final TimerPalette palette = context.timerPalette;
    final String title = _isCountdown ? '添加倒计时' : '添加正计时';
    final String fieldTitle = _isCountdown ? '倒计时名称' : '标签名称';
    final String hint = _isCountdown ? '例如：新倒计时' : '例如：阅读';

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.mutedInk.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    const SizedBox(width: 44, height: 44),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isCountdown) ...<Widget>[
                  Text('倒计时时长', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  DurationPickerCard(
                    seconds: _seconds,
                    onChanged: (int value) => setState(() => _seconds = value),
                  ),
                  const SizedBox(height: 22),
                ],
                Text(fieldTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                _SheetInput(
                  controller: _controller,
                  hint: hint,
                  autofocus: !_isCountdown,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _saving ? '添加中...' : title,
                  compact: true,
                  onPressed: _canSave ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetInput extends StatelessWidget {
  const _SheetInput({
    required this.controller,
    required this.hint,
    required this.autofocus,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.divider.withOpacity(0.72)),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        minLines: 1,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: AppTheme.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFD7C9D3),
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? primary : Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: primary.withOpacity(selected ? 1 : 0.48)),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
          : null,
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.size = 50,
    this.iconSize = 24,
  });

  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: Size(size, size),
          fixedSize: Size(size, size),
        ),
      ),
    );
  }
}

class _BatchActionPanel extends StatelessWidget {
  const _BatchActionPanel({
    required this.selectedCount,
    required this.hasRunningItems,
    required this.onStartAll,
    required this.onPauseAll,
    required this.onResetAll,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final bool hasRunningItems;
  final VoidCallback onStartAll;
  final VoidCallback onPauseAll;
  final VoidCallback onResetAll;
  final VoidCallback? onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _BatchActionButton(
              icon: Icons.play_arrow_rounded,
              label: '全部开始',
              color: const Color(0xFF0AA276),
              backgroundColor: const Color(0xFFE2F6EE),
              onPressed: onStartAll,
            ),
          ),
          Expanded(
            child: _BatchActionButton(
              icon: Icons.pause_rounded,
              label: '全部暂停',
              color: AppTheme.mutedInk.withOpacity(0.76),
              backgroundColor: const Color(0xFFF4F6FA),
              onPressed: hasRunningItems ? onPauseAll : null,
            ),
          ),
          Expanded(
            child: _BatchActionButton(
              icon: Icons.refresh_rounded,
              label: '全部重置',
              color: primary,
              backgroundColor: primary.withOpacity(0.10),
              onPressed: onResetAll,
            ),
          ),
          Expanded(
            child: _BatchActionButton(
              icon: Icons.delete_outline_rounded,
              label: '删除选中',
              color: selectedCount > 0
                  ? primary
                  : AppTheme.mutedInk.withOpacity(0.76),
              backgroundColor: selectedCount > 0
                  ? primary.withOpacity(0.10)
                  : const Color(0xFFF4F6FA),
              onPressed: onDeleteSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchActionButton extends StatelessWidget {
  const _BatchActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor =
        onPressed == null ? color.withOpacity(0.62) : color;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        foregroundColor: effectiveColor,
        disabledForegroundColor: effectiveColor,
        minimumSize: const Size(64, 82),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: effectiveColor, size: 30),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
