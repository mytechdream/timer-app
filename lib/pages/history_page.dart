import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_page.dart';
import '../widgets/cards.dart';
import '../widgets/segmented_pill.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.history,
  });

  final List<TimerHistoryEntry> history;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.timerPalette.background,
      body: AppPage(
        title: '历史记录',
        leading: RoundIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: '返回',
          onPressed: () => Navigator.of(context).pop(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          children: <Widget>[
            SegmentedPill(
              items: const <String>['全部', '倒计时', '正计时'],
              selectedIndex: _filterIndex,
              onChanged: (int index) => setState(() => _filterIndex = index),
            ),
            const SizedBox(height: 22),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final List<TimerHistoryEntry> entries =
        widget.history.where((TimerHistoryEntry entry) {
      if (_filterIndex == 1) {
        return entry.mode == TimerRunMode.countdown;
      }
      if (_filterIndex == 2) {
        return entry.mode == TimerRunMode.stopwatch;
      }
      return true;
    }).toList();

    if (entries.isEmpty) {
      return const Align(
        alignment: Alignment.topCenter,
        child: EmptyStateCard(
          title: '暂无历史记录',
          subtitle: '完成一次计时后，记录会出现在这里。',
          icon: Icons.history_rounded,
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final TimerHistoryEntry entry = entries[index];
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              Icon(
                entry.mode == TimerRunMode.countdown
                    ? Icons.timer_outlined
                    : Icons.av_timer_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(entry.name,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                formatDigitalTime(entry.durationSeconds),
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
