import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_page.dart';
import '../widgets/duration_picker_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/timer_bubbles.dart';

class TimerDashboardPage extends StatefulWidget {
  const TimerDashboardPage({
    super.key,
    required this.timers,
    required this.labels,
    required this.settings,
    required this.onCreateTimer,
    required this.onCreateLabel,
    required this.onOpenHistory,
    required this.onStartTimer,
  });

  final List<CreatedTimer> timers;
  final List<String> labels;
  final TimerSettings settings;
  final VoidCallback onCreateTimer;
  final VoidCallback onCreateLabel;
  final VoidCallback onOpenHistory;
  final void Function(TimerRunMode mode, String name, int seconds) onStartTimer;

  @override
  State<TimerDashboardPage> createState() => _TimerDashboardPageState();
}

class _TimerDashboardPageState extends State<TimerDashboardPage> {
  static const List<TimerBubbleData> _defaultCountdowns = <TimerBubbleData>[
    TimerBubbleData(label: '刷牙', seconds: 3 * 60),
    TimerBubbleData(label: '番茄时钟', seconds: 25 * 60),
    TimerBubbleData(label: '练字', seconds: 15 * 60),
  ];

  static const List<String> _defaultLabels = <String>['口算', '阅读', '运动', '学习'];

  int _modeIndex = 0;
  int _draftSeconds = 8 * 60;
  String _selectedLabel = '口算';

  List<TimerBubbleData> get _countdownTimers {
    return <TimerBubbleData>[
      ..._defaultCountdowns,
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
    return <String>{..._defaultLabels, ...widget.labels}.toList();
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
          onTap: (TimerBubbleData timer) => widget.onStartTimer(
            TimerRunMode.countdown,
            timer.label,
            timer.seconds,
          ),
          onAdd: widget.onCreateTimer,
        ),
      ],
    );
  }

  Widget _buildStopwatch() {
    return Column(
      key: const ValueKey<String>('stopwatch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('选择正计时标签', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 18),
        LabelBubbleGrid(
          labels: _labels,
          selectedLabel: _selectedLabel,
          onSelect: (String label) => setState(() => _selectedLabel = label),
          onAdd: widget.onCreateLabel,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: '开始 $_selectedLabel',
          onPressed: () => widget.onStartTimer(
            TimerRunMode.stopwatch,
            _selectedLabel,
            0,
          ),
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final double progress = _isCountdown && _session.initialSeconds > 0
        ? _session.displaySeconds / _session.initialSeconds
        : (_session.displaySeconds % 60) / 60;

    return Scaffold(
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  Text(
                    _session.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  RoundIconButton(
                    icon: Icons.edit_rounded,
                    tooltip: '编辑',
                    onPressed: () {},
                  ),
                ],
              ),
              const Spacer(flex: 2),
              Center(
                child: SizedBox(
                  width: 292,
                  height: 292,
                  child: CustomPaint(
                    painter: _TimerRingPainter(
                      color: primary,
                      progress: progress.clamp(0, 1),
                    ),
                    child: Column(
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
                              _isCountdown
                                  ? Icons.notifications_rounded
                                  : Icons.timer_rounded,
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
                      ],
                    ),
                  ),
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
                      icon: const Icon(Icons.play_arrow_rounded, size: 42),
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
                    icon: Icons.volume_up_rounded,
                    tooltip: '提示音',
                    onPressed: () {},
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
                        ? () => _session.extend(_session.settings.extendSeconds)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  _QuickAction(
                    icon: Icons.north_east_rounded,
                    label: '展开',
                    onTap: () {},
                  ),
                ],
              ),
            ],
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

class TimerSession extends ChangeNotifier {
  TimerSession({
    required this.mode,
    required this.name,
    required this.initialSeconds,
    required this.settings,
    required this.audio,
    required this.onCompleted,
  }) : displaySeconds = mode == TimerRunMode.countdown ? initialSeconds : 0 {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final TimerRunMode mode;
  final String name;
  final int initialSeconds;
  final TimerSettings settings;
  final TimerAudio audio;
  final Future<void> Function(TimerHistoryEntry entry) onCompleted;

  int displaySeconds;
  bool running = true;
  bool _completed = false;
  Timer? _ticker;

  bool get _isCountdown => mode == TimerRunMode.countdown;

  void toggleRunning() {
    running = !running;
    notifyListeners();
  }

  void reset() {
    displaySeconds = _isCountdown ? initialSeconds : 0;
    running = true;
    _completed = false;
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void extend(int seconds) {
    if (!_isCountdown || _completed) {
      return;
    }
    displaySeconds += seconds;
    notifyListeners();
  }

  void _tick() {
    if (!running || _completed) {
      return;
    }

    if (_isCountdown) {
      displaySeconds = math.max(0, displaySeconds - 1);
    } else {
      displaySeconds += 1;
    }
    notifyListeners();

    if (_isCountdown && displaySeconds == 0) {
      _completeCountdown();
    }
  }

  Future<void> _completeCountdown() async {
    if (_completed) {
      return;
    }
    _completed = true;
    _ticker?.cancel();
    _ticker = null;
    if (settings.completionSoundEnabled) {
      await audio.playComplete();
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
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
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
