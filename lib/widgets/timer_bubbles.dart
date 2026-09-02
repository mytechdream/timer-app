import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/time_format.dart';

class TimerBubbleData {
  const TimerBubbleData({
    required this.label,
    required this.seconds,
    this.id,
  });

  final String? id;
  final String label;
  final int seconds;
}

class TimerBubbleGrid extends StatelessWidget {
  const TimerBubbleGrid({
    super.key,
    required this.timers,
    required this.editableTimerIds,
    required this.onTap,
    required this.onLongPress,
    required this.onAdd,
  });

  final List<TimerBubbleData> timers;
  final Set<String> editableTimerIds;
  final ValueChanged<TimerBubbleData> onTap;
  final ValueChanged<TimerBubbleData> onLongPress;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1,
      children: <Widget>[
        for (final TimerBubbleData timer in timers)
          _TimerBubble(
            timer: timer,
            onTap: () => onTap(timer),
            onLongPress: timer.id != null && editableTimerIds.contains(timer.id)
                ? () => onLongPress(timer)
                : null,
          ),
        _AddBubble(onTap: onAdd),
      ],
    );
  }
}

class LabelBubbleGrid extends StatelessWidget {
  const LabelBubbleGrid({
    super.key,
    required this.labels,
    required this.selectedLabel,
    required this.editableLabels,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
  });

  final List<String> labels;
  final String selectedLabel;
  final Set<String> editableLabels;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1,
      children: <Widget>[
        for (final String label in labels)
          _LabelBubble(
            label: label,
            selected: label == selectedLabel,
            onTap: () => onSelect(label),
            onLongPress:
                editableLabels.contains(label) ? () => onEdit(label) : null,
          ),
        _AddBubble(onTap: onAdd),
      ],
    );
  }
}

class _TimerBubble extends StatelessWidget {
  const _TimerBubble({
    required this.timer,
    required this.onTap,
    this.onLongPress,
  });

  final TimerBubbleData timer;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      hint: onLongPress == null ? '点按开始倒计时' : '点按开始倒计时，长按删除',
      child: AspectRatio(
        aspectRatio: 1,
        child: TextButton(
          onPressed: onTap,
          onLongPress: onLongPress,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(92, 92),
            shape: const CircleBorder(),
            backgroundColor: primary.withOpacity(0.12),
            foregroundColor: primary,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                formatBubbleTime(timer.seconds),
                style: TextStyle(
                  color: primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timer.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelBubble extends StatelessWidget {
  const _LabelBubble({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      hint: onLongPress == null ? '点按选择标签' : '点按选择标签，长按修改标签',
      child: AspectRatio(
        aspectRatio: 1,
        child: TextButton(
          onPressed: onTap,
          onLongPress: onLongPress,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(92, 92),
            shape: const CircleBorder(),
            backgroundColor: selected ? primary : primary.withOpacity(0.12),
            foregroundColor: selected ? Colors.white : primary,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddBubble extends StatelessWidget {
  const _AddBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return AspectRatio(
      aspectRatio: 1,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(92, 92),
          shape: const CircleBorder(),
          side: BorderSide(color: primary.withOpacity(0.42), width: 1.5),
          foregroundColor: primary,
        ),
        child: Icon(Icons.add_rounded, color: primary, size: 34),
      ),
    );
  }
}
