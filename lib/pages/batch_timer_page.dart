import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_page.dart';
import '../widgets/cards.dart';
import '../widgets/segmented_pill.dart';

class BatchTimerPage extends StatelessWidget {
  const BatchTimerPage({
    super.key,
    required this.palette,
    required this.countdownMode,
    required this.onModeChanged,
    required this.onAddPressed,
  });

  final AppPalette palette;
  final bool countdownMode;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('批量计时', style: AppText.title)),
              IconCircleButton(
                tooltip: '添加批量倒计时',
                icon: Icons.add_rounded,
                foreground: Colors.white,
                background: palette.color,
                onPressed: onAddPressed,
              ),
            ],
          ),
          const SizedBox(height: 58),
          SegmentedPill(
            labels: const ['倒计时', '正计时'],
            selected: countdownMode ? 0 : 1,
            onSelected: (index) => onModeChanged(index == 0),
          ),
          const SizedBox(height: 34),
          EmptyPanel(
            palette: palette,
            icon: Icons.layers_clear_rounded,
            title: '还没有批量倒计时',
            subtitle: '添加时间后，可以单独开始，也可以全部一起开始。',
          ),
        ],
      ),
    );
  }
}
