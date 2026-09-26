import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../services/timer_foreground_service.dart';
import '../services/timer_notifications.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_page.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/duration_picker_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/timer_bubbles.dart';

class TimerDashboardPage extends StatefulWidget {
  const TimerDashboardPage({
    super.key,
    required this.timers,
    required this.labels,
    required this.hiddenDefaultTimerIds,
    required this.hiddenDefaultLabels,
    required this.settings,
    required this.onCreateTimer,
    required this.onDeleteTimer,
    required this.onCreateLabel,
    required this.onEditLabel,
    required this.onOpenHistory,
    required this.onStartTimer,
  });

  final List<CreatedTimer> timers;
  final List<String> labels;
  final List<String> hiddenDefaultTimerIds;
  final List<String> hiddenDefaultLabels;
  final TimerSettings settings;
  final VoidCallback onCreateTimer;
  final Future<void> Function(String id) onDeleteTimer;
  final VoidCallback onCreateLabel;
  final ValueChanged<String> onEditLabel;
  final VoidCallback onOpenHistory;
  final void Function(TimerRunMode mode, String name, int seconds) onStartTimer;

  @override
  State<TimerDashboardPage> createState() => _TimerDashboardPageState();
}

class _TimerDashboardPageState extends State<TimerDashboardPage> {
  int _modeIndex = 0;
  late int _draftSeconds;
  String _selectedLabel = '口算';

  List<TimerBubbleData> get _countdownTimers {
    final Set<String> hiddenDefaultIds = widget.hiddenDefaultTimerIds.toSet();
    return <TimerBubbleData>[
      for (final TimerPreset timer in TimerDefaults.countdownTimers)
        if (!hiddenDefaultIds.contains(timer.id))
          TimerBubbleData(
            id: timer.id,
            label: timer.name,
            seconds: timer.seconds,
          ),
      ...widget.timers.map(
        (CreatedTimer timer) => TimerBubbleData(
          id: timer.id,
          label: timer.name,
          seconds: timer.seconds,
        ),
      ),
    ];
  }

  List<String> get _labels {
    final Set<String> hiddenDefaultLabels = widget.hiddenDefaultLabels.toSet();
    return <String>{
      for (final String label in TimerDefaults.stopwatchLabels)
        if (!hiddenDefaultLabels.contains(label)) label,
      ...widget.labels,
    }.toList();
  }

  @override
  void initState() {
    super.initState();
    _draftSeconds = widget.settings.defaultCountdownSeconds;
  }

  @override
  void didUpdateWidget(covariant TimerDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.defaultCountdownSeconds !=
        widget.settings.defaultCountdownSeconds) {
      _draftSeconds = widget.settings.defaultCountdownSeconds;
    }
    final List<String> labels = _labels;
    if (labels.isEmpty) {
      _selectedLabel = '';
    } else if (!labels.contains(_selectedLabel)) {
      _selectedLabel = labels.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '计时器',
      centerTitle: false,
      actions: <Widget>[
        RoundIconButton(
          icon: Icons.history_toggle_off_rounded,
          tooltip: '历史记录',
          transparentBackground: true,
          onPressed: widget.onOpenHistory,
        ),
        RoundIconButton(
          icon: Icons.add_rounded,
          tooltip: _modeIndex == 0 ? '创建倒计时' : '添加标签',
          filled: true,
          onPressed:
              _modeIndex == 0 ? widget.onCreateTimer : widget.onCreateLabel,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SegmentedPill(
              items: const <String>['倒计时', '正计时'],
              selectedIndex: _modeIndex,
              onChanged: (int index) => setState(() => _modeIndex = index),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _modeIndex == 0 ? _buildCountdown() : _buildStopwatch(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Column(
      key: const ValueKey<String>('countdown'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('选择倒计时时长', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        DurationPickerCard(
          seconds: _draftSeconds,
          onChanged: (int value) => setState(() => _draftSeconds = value),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: '开始 ${formatBubbleTime(_draftSeconds)}',
          onPressed: () => widget.onStartTimer(
            TimerRunMode.countdown,
            '自定义倒计时',
            _draftSeconds,
          ),
        ),
        const SizedBox(height: 26),
        Text('已创建的倒计时', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TimerBubbleGrid(
          timers: _countdownTimers,
          editableTimerIds: _countdownTimers
              .map((TimerBubbleData timer) => timer.id)
              .whereType<String>()
              .toSet(),
          onTap: (TimerBubbleData timer) => widget.onStartTimer(
            TimerRunMode.countdown,
            timer.label,
            timer.seconds,
          ),
          onLongPress: _confirmDeleteTimer,
          onAdd: widget.onCreateTimer,
        ),
      ],
    );
  }

  Widget _buildStopwatch() {
    final List<String> labels = _labels;
    final String selectedLabel = labels.contains(_selectedLabel)
        ? _selectedLabel
        : (labels.isEmpty ? '' : labels.first);

    return Column(
      key: const ValueKey<String>('stopwatch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('选择正计时标签', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        LabelBubbleGrid(
          labels: labels,
          selectedLabel: selectedLabel,
          editableLabels: labels.toSet(),
          onSelect: (String label) => setState(() => _selectedLabel = label),
          onEdit: widget.onEditLabel,
          onAdd: widget.onCreateLabel,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: selectedLabel.isEmpty ? '请先添加标签' : '开始 $selectedLabel',
          onPressed: selectedLabel.isEmpty
              ? null
              : () => widget.onStartTimer(
                    TimerRunMode.stopwatch,
                    selectedLabel,
                    0,
                  ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteTimer(TimerBubbleData timer) async {
    final String? id = timer.id;
    if (id == null) {
      return;
    }

    final bool shouldDelete = await showDeleteDialog(
      context: context,
      title: '删除倒计时？',
      message: '删除“${timer.label}”后，它不会再出现在已创建的倒计时里。',
      actionLabel: '删除',
    );
    if (!shouldDelete) {
      return;
    }
    await widget.onDeleteTimer(id);
  }
}

class RunningTimerPage extends StatefulWidget {
  const RunningTimerPage({super.key, required this.session});

  final TimerSession session;

  @override
  State<RunningTimerPage> createState() => _RunningTimerPageState();
}

class _RunningTimerPageState extends State<RunningTimerPage> {
  TimerSession get _session => widget.session;

  bool get _isCountdown => _session.mode == TimerRunMode.countdown;
  bool _exitDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showRenameSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _RenameTimerSheet(
          initialName: _session.name,
          onSave: _session.rename,
        );
      },
    );
  }

  void _openFullscreenTimer() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (BuildContext context, _, __) {
          return _FullscreenTimerPage(session: _session);
        },
      ),
    );
  }

  Future<void> _requestExit() async {
    if (_exitDialogOpen) {
      return;
    }
    _exitDialogOpen = true;
    final bool shouldExit = await showExitTimerDialog(
      context,
      savesHistory: !_isCountdown && _session.displaySeconds > 0,
    );
    _exitDialogOpen = false;
    if (!shouldExit || !mounted) {
      return;
    }
    await _session.saveStopwatchHistoryOnExit();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final double progress = _isCountdown && _session.initialSeconds > 0
        ? _session.displaySeconds / _session.initialSeconds
        : 0;
    final Widget timeFace = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          formatDigitalTime(_session.displaySeconds),
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 58,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _isCountdown ? Icons.notifications_rounded : Icons.timer_rounded,
              color: AppTheme.mutedInk,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _isCountdown ? _endTimeText() : '正计时中',
              style: const TextStyle(
                color: AppTheme.mutedInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (_session.reminderWarning != null) ...<Widget>[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _session.reminderWarning!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9B5C16),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          unawaited(_requestExit());
        }
      },
      child: Scaffold(
        backgroundColor: context.timerPalette.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RoundIconButton(
                      icon: Icons.close_rounded,
                      tooltip: '关闭',
                      onPressed: () => unawaited(_requestExit()),
                    ),
                    const Spacer(),
                    Text(
                      _session.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    RoundIconButton(
                      icon: Icons.edit_rounded,
                      tooltip: '编辑标签',
                      onPressed: _showRenameSheet,
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Center(
                  child: SizedBox(
                    width: 292,
                    height: 292,
                    child: _isCountdown
                        ? CustomPaint(
                            painter: _TimerRingPainter(
                              color: primary,
                              progress: progress.clamp(0, 1),
                            ),
                            child: timeFace,
                          )
                        : Center(child: timeFace),
                  ),
                ),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _ControlCircle(
                      icon: Icons.replay_rounded,
                      tooltip: '重置',
                      onPressed: _session.reset,
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: IconButton(
                        tooltip: _session.running ? '暂停' : '继续',
                        onPressed: _session.toggleRunning,
                        icon: Icon(
                          _session.running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: _session.running ? 34 : 42,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shadowColor: primary.withOpacity(0.30),
                          elevation: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _ControlCircle(
                      icon: _session.settings.tickSoundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      tooltip: _session.settings.tickSoundEnabled
                          ? '关闭滴答声音'
                          : '开启滴答声音',
                      onPressed: () => unawaited(_session.toggleTickSound()),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _QuickAction(
                      icon: Icons.more_time_rounded,
                      label: '延时 ${_session.settings.extendSeconds}秒',
                      onTap: _isCountdown
                          ? () =>
                              _session.extend(_session.settings.extendSeconds)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    _QuickAction(
                      icon: Icons.north_east_rounded,
                      label: '全屏',
                      onTap: _openFullscreenTimer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _endTimeText() {
    final DateTime endTime = DateTime.now().add(
      Duration(seconds: _session.displaySeconds),
    );
    final String hour = endTime.hour.toString().padLeft(2, '0');
    final String minute = endTime.minute.toString().padLeft(2, '0');
    return '结束于 $hour:$minute';
  }
}

class _RenameTimerSheet extends StatefulWidget {
  const _RenameTimerSheet({
    required this.initialName,
    required this.onSave,
  });

  final String initialName;
  final ValueChanged<String> onSave;

  @override
  State<_RenameTimerSheet> createState() => _RenameTimerSheetState();
}

class _RenameTimerSheetState extends State<_RenameTimerSheet> {
  late final TextEditingController _controller;

  bool get _canSave => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_canSave) {
      return;
    }
    widget.onSave(_controller.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final TimerPalette palette = context.timerPalette;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 28,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SheetHandle(),
                const SizedBox(height: 12),
                _SheetHeader(
                  title: '修改标签',
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 22),
                Text('标签名称', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                _RunningSheetInput(
                  controller: _controller,
                  hint: '例如：番茄时钟',
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: '保存',
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppTheme.mutedInk.withOpacity(0.16),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            tooltip: '关闭',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        const SizedBox(width: 44, height: 44),
      ],
    );
  }
}

class _RunningSheetInput extends StatelessWidget {
  const _RunningSheetInput({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
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
        autofocus: true,
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

class _FullscreenTimerPage extends StatefulWidget {
  const _FullscreenTimerPage({required this.session});

  final TimerSession session;

  @override
  State<_FullscreenTimerPage> createState() => _FullscreenTimerPageState();
}

class _FullscreenTimerPageState extends State<_FullscreenTimerPage> {
  TimerSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
    unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    unawaited(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final bool isCountdown = _session.mode == TimerRunMode.countdown;
    final double progress = isCountdown && _session.initialSeconds > 0
        ? _session.displaySeconds / _session.initialSeconds
        : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _FullscreenTimerPainter(
                color: primary,
                progress: progress.clamp(0.0, 1.0).toDouble(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _session.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isCountdown ? _endTimeText() : '正计时中',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _FullscreenIconButton(
                        icon: Icons.close_rounded,
                        tooltip: '关闭全屏',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatDigitalTime(_session.displaySeconds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 168,
                                  fontWeight: FontWeight.w900,
                                  height: 0.92,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 28),
                        SizedBox(
                          width: 82,
                          height: 82,
                          child: IconButton(
                            tooltip: _session.running ? '暂停' : '继续',
                            onPressed: _session.toggleRunning,
                            icon: Icon(
                              _session.running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: _session.running ? 36 : 44,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCountdown)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        value: progress.clamp(0.0, 1.0).toDouble(),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _endTimeText() {
    final DateTime endTime = DateTime.now().add(
      Duration(seconds: _session.displaySeconds),
    );
    final String hour = endTime.hour.toString().padLeft(2, '0');
    final String minute = endTime.minute.toString().padLeft(2, '0');
    return '结束于 $hour:$minute';
  }
}

class _FullscreenIconButton extends StatelessWidget {
  const _FullscreenIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.14),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _FullscreenTimerPainter extends CustomPainter {
  const _FullscreenTimerPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect screen = Offset.zero & size;
    final Paint wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          color.withOpacity(0.30),
          Colors.black,
          color.withOpacity(0.16),
        ],
        stops: const <double>[0, 0.56, 1],
      ).createShader(screen);
    canvas.drawRect(screen, wash);

    final Paint progressWash = Paint()
      ..color = color.withOpacity(0.16)
      ..style = PaintingStyle.fill;
    final double sweepWidth = size.width * progress;
    canvas.drawRect(Rect.fromLTWH(0, 0, sweepWidth, size.height), progressWash);

    final Paint glow = Paint()
      ..color = color.withOpacity(0.24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.50),
        size.shortestSide * 0.42, glow);
  }

  @override
  bool shouldRepaint(covariant _FullscreenTimerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class TimerSession extends ChangeNotifier {
  TimerSession({
    required this.mode,
    required this.name,
    required this.initialSeconds,
    required this.settings,
    required this.audio,
    required this.onSettingsChanged,
    required this.onCompleted,
    this.notifications = const DisabledTimerNotificationScheduler(),
    this.foregroundService = const DisabledTimerForegroundService(),
    DateTime Function()? now,
    String? notificationKey,
  })  : notificationKey = notificationKey ??
            'session-${DateTime.now().microsecondsSinceEpoch}-${_nextNotificationKey++}',
        displaySeconds = mode == TimerRunMode.countdown ? initialSeconds : 0 {
    _now = now ?? DateTime.now;
    _runStartedAt = _now();
    _secondsAtRunStart = displaySeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    unawaited(_scheduleCountdownNotification());
    unawaited(_updateForegroundService());
  }

  final TimerRunMode mode;
  String name;
  final int initialSeconds;
  TimerSettings settings;
  final TimerAudio audio;
  final Future<void> Function(TimerSettings settings) onSettingsChanged;
  final Future<void> Function(TimerHistoryEntry entry) onCompleted;
  final TimerNotificationScheduler notifications;
  final TimerForegroundService foregroundService;
  final String notificationKey;

  static int _nextNotificationKey = 0;

  int displaySeconds;
  bool running = true;
  bool _completed = false;
  bool _hasCompletedCountdown = false;
  bool _disposed = false;
  int _notificationGeneration = 0;
  CountdownNotificationStatus? notificationStatus;
  Timer? _ticker;
  late final DateTime Function() _now;
  DateTime? _runStartedAt;
  int _secondsAtRunStart = 0;

  bool get _isCountdown => mode == TimerRunMode.countdown;

  String? get reminderWarning {
    if (!_isCountdown ||
        !running ||
        settings.completionReminderName == TimerSettings.reminderOff) {
      return null;
    }
    switch (notificationStatus) {
      case CountdownNotificationStatus.inexact:
        return '精确提醒未获授权，后台通知可能延迟';
      case CountdownNotificationStatus.permissionDenied:
        return '通知权限未开启，计时结束时可能收不到系统提醒';
      case CountdownNotificationStatus.unavailable:
        return '系统提醒暂不可用，请检查通知权限';
      case CountdownNotificationStatus.exact:
      case null:
        return null;
    }
  }

  DateTime? get countdownEndAt {
    if (!_isCountdown || !running || _runStartedAt == null) {
      return null;
    }
    return _runStartedAt!.add(Duration(seconds: _secondsAtRunStart));
  }

  void toggleRunning() {
    if (_completed && _isCountdown) {
      reset();
      return;
    }

    _syncDisplay();
    if (_completed) {
      return;
    }
    running = !running;
    if (running) {
      _hasCompletedCountdown = false;
      _runStartedAt = _now();
      _secondsAtRunStart = displaySeconds;
      _ensureTicker();
      unawaited(_scheduleCountdownNotification());
      unawaited(_updateForegroundService());
    } else {
      _runStartedAt = null;
      _ticker?.cancel();
      _ticker = null;
      _clearNotificationStatus();
      unawaited(notifications.cancelCountdownComplete(notificationKey));
      unawaited(foregroundService.stop());
    }
    notifyListeners();
  }

  void rename(String value) {
    final String nextName = value.trim();
    if (nextName.isEmpty || nextName == name) {
      return;
    }
    name = nextName;
    unawaited(_scheduleCountdownNotification());
    notifyListeners();
  }

  Future<void> updateSettings(TimerSettings value) async {
    final bool reminderChanged =
        value.completionReminderName != settings.completionReminderName;
    final bool backgroundRunChanged =
        value.backgroundRunEnabled != settings.backgroundRunEnabled;
    settings = value;
    notifyListeners();
    await onSettingsChanged(value);
    if (reminderChanged) {
      unawaited(_scheduleCountdownNotification());
    }
    if (backgroundRunChanged) {
      unawaited(_updateForegroundService());
    }
  }

  Future<void> toggleTickSound() async {
    await updateSettings(
      settings.copyWith(tickSoundEnabled: !settings.tickSoundEnabled),
    );
  }

  void reset() {
    _clearNotificationStatus();
    _hasCompletedCountdown = false;
    unawaited(notifications.cancelCountdownComplete(notificationKey));
    unawaited(foregroundService.stop());
    displaySeconds = _isCountdown ? initialSeconds : 0;
    running = true;
    _completed = false;
    _runStartedAt = _now();
    _secondsAtRunStart = displaySeconds;
    _ensureTicker();
    unawaited(_scheduleCountdownNotification());
    unawaited(_updateForegroundService());
    notifyListeners();
  }

  void extend(int seconds) {
    if (!_isCountdown || _completed) {
      return;
    }
    _syncDisplay();
    if (_completed) {
      return;
    }
    displaySeconds += seconds;
    _secondsAtRunStart = displaySeconds;
    if (running) {
      _runStartedAt = _now();
    }
    unawaited(_scheduleCountdownNotification());
    unawaited(_updateForegroundService());
    notifyListeners();
  }

  Future<void> saveStopwatchHistoryOnExit() async {
    _syncDisplay();
    if (_isCountdown || displaySeconds <= 0 || _completed) {
      return;
    }
    _completed = true;
    running = false;
    _runStartedAt = null;
    _ticker?.cancel();
    _ticker = null;
    await notifications.cancelCountdownComplete(notificationKey);
    await foregroundService.stop();
    notifyListeners();
    await onCompleted(
      TimerHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        mode: mode,
        durationSeconds: displaySeconds,
        completedAt: DateTime.now(),
      ),
    );
  }

  void _tick() {
    if (!running || _completed) {
      return;
    }

    final int before = displaySeconds;
    _syncDisplay();
    if (_completed) {
      return;
    }
    if (settings.tickSoundEnabled && (!_isCountdown || displaySeconds > 0)) {
      unawaited(audio.playTick());
    }
    if (before != displaySeconds) {
      notifyListeners();
    }
    unawaited(_updateForegroundService());
  }

  void _syncDisplay() {
    if (!running || _completed || _runStartedAt == null) {
      return;
    }
    final int elapsedSeconds = math.max(
      0,
      _now().difference(_runStartedAt!).inSeconds,
    );
    final int nextDisplaySeconds = _isCountdown
        ? math.max(0, _secondsAtRunStart - elapsedSeconds)
        : _secondsAtRunStart + elapsedSeconds;
    displaySeconds = nextDisplaySeconds;
    if (_isCountdown && nextDisplaySeconds == 0) {
      unawaited(_completeCountdown());
    }
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _scheduleCountdownNotification() async {
    final int generation = ++_notificationGeneration;
    if (_hasCompletedCountdown) {
      return;
    }
    if (!_isCountdown ||
        !running ||
        _completed ||
        settings.completionReminderName == TimerSettings.reminderOff) {
      notificationStatus = null;
      await notifications.cancelCountdownComplete(notificationKey);
      return;
    }
    _syncDisplay();
    if (_completed || displaySeconds <= 0) {
      return;
    }
    final CountdownNotificationStatus status =
        await notifications.scheduleCountdownComplete(
      notificationKey: notificationKey,
      timerName: name,
      endAt: _now().add(Duration(seconds: displaySeconds)),
      vibrate: settings.completionReminderName ==
          TimerSettings.reminderSoundAndVibration,
      preferExact: true,
    );
    if (!_disposed &&
        generation == _notificationGeneration &&
        running &&
        !_completed) {
      notificationStatus = status;
      notifyListeners();
    }
  }

  void _clearNotificationStatus() {
    _notificationGeneration++;
    notificationStatus = null;
  }

  Future<void> _updateForegroundService() async {
    if (!running || _completed || !settings.backgroundRunEnabled) {
      await foregroundService.stop();
      return;
    }
    await foregroundService.start(
      title: name,
      body: _isCountdown
          ? '剩余 ${formatDigitalTime(displaySeconds)}'
          : '已计时 ${formatDigitalTime(displaySeconds)}',
    );
  }

  Future<void> _completeCountdown() async {
    if (_completed) {
      return;
    }
    _completed = true;
    _hasCompletedCountdown = true;
    _clearNotificationStatus();
    _runStartedAt = null;
    _ticker?.cancel();
    _ticker = null;
    if (settings.completionReminderName != TimerSettings.reminderOff) {
      unawaited(notifications.completeCountdown(
        notificationKey: notificationKey,
        timerName: name,
        vibrate: settings.completionReminderName ==
            TimerSettings.reminderSoundAndVibration,
      ));
    } else {
      unawaited(notifications.cancelCountdownComplete(notificationKey));
    }
    await foregroundService.stop();
    if (settings.completionSoundEnabled &&
        settings.completionReminderName != TimerSettings.reminderOff) {
      await audio.playComplete(settings.alertSoundName);
    }
    await onCompleted(
      TimerHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        mode: mode,
        durationSeconds: initialSeconds,
        completedAt: DateTime.now(),
      ),
    );
    displaySeconds = initialSeconds;
    _secondsAtRunStart = displaySeconds;
    running = false;
    _completed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _runStartedAt = null;
    _ticker?.cancel();
    _ticker = null;
    if (_isCountdown && !_hasCompletedCountdown) {
      unawaited(notifications.cancelCountdownComplete(notificationKey));
    }
    unawaited(foregroundService.stop());
    super.dispose();
  }
}

class _TimerRingPainter extends CustomPainter {
  const _TimerRingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 9;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.10);
    final Paint active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}

class _ControlCircle extends StatelessWidget {
  const _ControlCircle({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 30),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.mutedInk,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.08),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(onTap == null ? 0.45 : 0.75),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: AppTheme.mutedInk, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.mutedInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
