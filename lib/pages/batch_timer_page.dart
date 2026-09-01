import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_page.dart';
import '../widgets/cards.dart';
import '../widgets/segmented_pill.dart';

class BatchTimerPage extends StatefulWidget {
  const BatchTimerPage({
    super.key,
    required this.timers,
    required this.onCreateTimer,
    required this.onStartTimer,
  });

  final List<CreatedTimer> timers;
  final VoidCallback onCreateTimer;
  final void Function(CreatedTimer timer) onStartTimer;

  @override
  State<BatchTimerPage> createState() => _BatchTimerPageState();
}

class _BatchTimerPageState extends State<BatchTimerPage> {
  int _modeIndex = 0;

  CreatedTimer get _designFallbackTimer {
    return CreatedTimer(
      id: 'design-fallback-countdown',
      name: '新倒计时',
      seconds: 15 * 60,
      createdAt: DateTime(2026, 9, 2),
    );
  }

  List<CreatedTimer> get _countdownTimers {
    return widget.timers.isEmpty
        ? <CreatedTimer>[_designFallbackTimer]
        : widget.timers;
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '批量计时',
      centerTitle: false,
      actions: <Widget>[
        _SelectActionButton(onPressed: () {}),
        RoundIconButton(
          icon: Icons.add_rounded,
          tooltip: '创建倒计时',
          filled: true,
          onPressed: widget.onCreateTimer,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SegmentedPill(
            items: const <String>['倒计时', '正计时'],
            selectedIndex: _modeIndex,
            onChanged: (int index) => setState(() => _modeIndex = index),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: _modeIndex == 0 ? _buildCountdowns() : _buildStopwatch(),
          ),
          const SizedBox(height: 16),
          _BatchActionPanel(
            enabled: _modeIndex == 0,
            onStartAll: () => widget.onStartTimer(_countdownTimers.first),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdowns() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _countdownTimers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (BuildContext context, int index) {
        final CreatedTimer timer = _countdownTimers[index];
        return _BatchCountdownCard(
          timer: timer,
          onStart: () => widget.onStartTimer(timer),
        );
      },
    );
  }

  Widget _buildStopwatch() {
    return ListView(
      padding: EdgeInsets.zero,
      children: const <Widget>[
        _BatchStopwatchCard(label: '新正计时'),
      ],
    );
  }
}

class _SelectActionButton extends StatelessWidget {
  const _SelectActionButton({required this.onPressed});

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
      child: const Text('选择'),
    );
  }
}

class _BatchCountdownCard extends StatelessWidget {
  const _BatchCountdownCard({required this.timer, required this.onStart});

  final CreatedTimer timer;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final TimerPalette palette = context.timerPalette;

    return AppCard(
      color: Colors.white.withOpacity(0.82),
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(timer.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                  formatBubbleTime(timer.seconds),
                  style: const TextStyle(
                    color: AppTheme.mutedInk,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: 0,
                    minHeight: 5,
                    backgroundColor: palette.soft,
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _CardIconButton(
            icon: Icons.refresh_rounded,
            tooltip: '重置${timer.name}',
            backgroundColor: palette.soft,
            foregroundColor: AppTheme.mutedInk,
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          _CardIconButton(
            icon: Icons.play_arrow_rounded,
            tooltip: '开始${timer.name}',
            backgroundColor: primary,
            foregroundColor: Colors.white,
            size: 70,
            iconSize: 38,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _BatchStopwatchCard extends StatelessWidget {
  const _BatchStopwatchCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final TimerPalette palette = context.timerPalette;
    return AppCard(
      color: Colors.white.withOpacity(0.82),
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text(
                  '00:00',
                  style: TextStyle(
                    color: AppTheme.mutedInk,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.soft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _CardIconButton(
            icon: Icons.refresh_rounded,
            tooltip: '重置$label',
            backgroundColor: palette.soft,
            foregroundColor: AppTheme.mutedInk,
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          _CardIconButton(
            icon: Icons.play_arrow_rounded,
            tooltip: '开始$label',
            backgroundColor: primary,
            foregroundColor: Colors.white,
            size: 70,
            iconSize: 38,
            onPressed: () {},
          ),
        ],
      ),
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
    this.size = 62,
    this.iconSize = 30,
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
  const _BatchActionPanel({required this.enabled, required this.onStartAll});

  final bool enabled;
  final VoidCallback onStartAll;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              onPressed: enabled ? onStartAll : null,
            ),
          ),
          Expanded(
            child: _BatchActionButton(
              icon: Icons.pause_rounded,
              label: '全部暂停',
              color: AppTheme.mutedInk.withOpacity(0.62),
              backgroundColor: const Color(0xFFF4F6FA),
              onPressed: null,
            ),
          ),
          Expanded(
            child: _BatchActionButton(
              icon: Icons.refresh_rounded,
              label: '全部重置',
              color: primary,
              backgroundColor: primary.withOpacity(0.10),
              onPressed: enabled ? () {} : null,
            ),
          ),
          Expanded(
            child: _BatchActionButton(
              icon: Icons.delete_outline_rounded,
              label: '删除选中',
              color: AppTheme.mutedInk.withOpacity(0.62),
              backgroundColor: const Color(0xFFF4F6FA),
              onPressed: null,
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
        minimumSize: const Size(64, 72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: effectiveColor, size: 28),
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
