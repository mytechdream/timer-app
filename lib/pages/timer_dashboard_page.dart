import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_page.dart';
import '../widgets/duration_picker_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/timer_bubbles.dart';

class TimerDashboardPage extends StatelessWidget {
  const TimerDashboardPage({
    super.key,
    required this.palette,
    required this.countdownMode,
    required this.running,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.timers,
    required this.onDurationChanged,
    required this.onModeChanged,
    required this.onStartPressed,
    required this.onHistoryPressed,
    required this.onAddPressed,
    required this.onTimerPressed,
  });

  final AppPalette palette;
  final bool countdownMode;
  final bool running;
  final int durationSeconds;
  final int remainingSeconds;
  final List<SavedTimer> timers;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onHistoryPressed;
  final VoidCallback onAddPressed;
  final ValueChanged<SavedTimer> onTimerPressed;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('计时器', style: AppText.title)),
              IconCircleButton(
                tooltip: '历史记录',
                icon: Icons.history_rounded,
                foreground: AppColors.mutedText,
                background: Colors.transparent,
                onPressed: onHistoryPressed,
              ),
              const SizedBox(width: 14),
              IconCircleButton(
                tooltip: '创建倒计时',
                icon: Icons.add_rounded,
                foreground: Colors.white,
                background: palette.color,
                onPressed: onAddPressed,
              ),
            ],
          ),
          const SizedBox(height: 34),
          SegmentedPill(
            labels: const ['倒计时', '正计时'],
            selected: countdownMode ? 0 : 1,
            onSelected: (index) => onModeChanged(index == 0),
          ),
          const SizedBox(height: 30),
          Text(countdownMode ? '选择倒计时时长' : '开始正计时', style: AppText.section),
          const SizedBox(height: 22),
          DurationPickerCard(
            palette: palette,
            seconds: countdownMode ? durationSeconds : remainingSeconds,
            interactive: countdownMode && !running,
            onChanged: onDurationChanged,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              palette: palette,
              label: running
                  ? '暂停 ${formatCompact(remainingSeconds)}'
                  : '开始 ${formatCompact(countdownMode ? durationSeconds : remainingSeconds)}',
              onPressed: onStartPressed,
            ),
          ),
          const SizedBox(height: 36),
          const Text('已创建的倒计时', style: AppText.section),
          const SizedBox(height: 20),
          TimerBubbleGrid(
            palette: palette,
            timers: timers,
            onTimerPressed: onTimerPressed,
            onAddPressed: onAddPressed,
          ),
          const SizedBox(height: 130),
        ],
      ),
    );
  }
}
