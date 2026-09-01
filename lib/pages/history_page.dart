import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_buttons.dart';
import '../widgets/cards.dart';
import '../widgets/segmented_pill.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.palette, required this.records});

  final AppPalette palette;
  final List<HistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconCircleButton(
                    tooltip: '返回',
                    icon: Icons.arrow_back_rounded,
                    foreground: AppColors.ink,
                    background: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 26),
                  const Text('历史记录', style: AppText.title),
                ],
              ),
              const SizedBox(height: 54),
              SegmentedPill(
                  labels: const ['全部', '倒计时', '正计时'],
                  selected: 0,
                  onSelected: (_) {}),
              const SizedBox(height: 34),
              Expanded(
                child: records.isEmpty
                    ? EmptyPanel(
                        palette: palette,
                        icon: Icons.history_rounded,
                        title: '暂无历史记录',
                      )
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return SurfaceCard(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: IconBadge(
                                  palette: palette, icon: Icons.timer_outlined),
                              title:
                                  Text(record.label, style: AppText.tileTitle),
                              subtitle:
                                  Text(record.type, style: AppText.bodyMuted),
                              trailing: Text(formatCompact(record.seconds),
                                  style: AppText.tileValue),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemCount: records.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
