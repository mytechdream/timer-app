import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/stats_row.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final numbers = List<int>.generate(30, (index) => index + 1);

    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('数据洞察', style: AppText.title),
          const SizedBox(height: 70),
          SegmentedPill(
              labels: const ['周', '月', '年'], selected: 0, onSelected: (_) {}),
          const SizedBox(height: 52),
          Row(
            children: [
              const Expanded(
                  child: Text('2026年8月30日 - 5日', style: AppText.large)),
              Icon(Icons.expand_less_rounded, color: palette.color, size: 34),
              const SizedBox(width: 20),
              Icon(Icons.chevron_left_rounded, color: palette.color, size: 34),
              const SizedBox(width: 20),
              Icon(Icons.chevron_right_rounded, color: palette.color, size: 34),
            ],
          ),
          const SizedBox(height: 54),
          Row(
            children: [
              const Text('2026年9月', style: AppText.large),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: palette.color, size: 42),
              const Spacer(),
              Icon(Icons.chevron_left_rounded, color: palette.color, size: 32),
              const SizedBox(width: 24),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.mutedText, size: 32),
            ],
          ),
          const SizedBox(height: 38),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days
                .map((day) => Text(day, style: AppText.calendarHead))
                .toList(),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.08,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              if (index == 0) return const SizedBox.shrink();
              final day = numbers[index - 1];
              final selected = day == 2;
              return Center(
                child: Container(
                  width: selected ? 58 : null,
                  height: selected ? 58 : null,
                  alignment: Alignment.center,
                  decoration: selected
                      ? BoxDecoration(
                          color: palette.color, shape: BoxShape.circle)
                      : null,
                  child: Text(
                    '$day',
                    style: selected
                        ? AppText.calendarSelected
                        : AppText.calendar.copyWith(
                            color: day == 1
                                ? AppColors.ink
                                : AppColors.disabledText,
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 26),
          const Divider(color: AppColors.divider, thickness: 1.5),
          const SizedBox(height: 26),
          const StatsRow(),
          const SizedBox(height: 150),
        ],
      ),
    );
  }
}
