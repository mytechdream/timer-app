import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';

class TimerBubbleGrid extends StatelessWidget {
  const TimerBubbleGrid({
    super.key,
    required this.palette,
    required this.timers,
    required this.onTimerPressed,
    required this.onAddPressed,
  });

  final AppPalette palette;
  final List<SavedTimer> timers;
  final ValueChanged<SavedTimer> onTimerPressed;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 28,
      children: [
        for (final timer in timers)
          TimerBubble(
              palette: palette,
              timer: timer,
              onPressed: () => onTimerPressed(timer)),
        AddBubble(palette: palette, onPressed: onAddPressed),
      ],
    );
  }
}

class TimerBubble extends StatelessWidget {
  const TimerBubble(
      {super.key,
      required this.palette,
      required this.timer,
      required this.onPressed});

  final AppPalette palette;
  final SavedTimer timer;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${timer.name} ${formatCompact(timer.seconds)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          width: 112,
          height: 112,
          decoration:
              BoxDecoration(color: palette.tint, shape: BoxShape.circle),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatCompact(timer.seconds),
                    style: AppText.bubbleTime.copyWith(color: palette.color)),
              ),
              const SizedBox(height: 8),
              Text(timer.name, style: AppText.bubbleLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class AddBubble extends StatelessWidget {
  const AddBubble({super.key, required this.palette, required this.onPressed});

  final AppPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.color.withOpacity(.55), width: 2),
        ),
        child: Icon(Icons.add_rounded, color: palette.color, size: 52),
      ),
    );
  }
}
