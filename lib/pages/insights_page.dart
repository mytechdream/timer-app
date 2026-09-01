import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_page.dart';
import '../widgets/cards.dart';
import '../widgets/segmented_pill.dart';
import '../widgets/stats_row.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({
    super.key,
    required this.history,
  });

  final List<TimerHistoryEntry> history;

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int _periodIndex = 0;

  int get _totalSeconds => widget.history.fold<int>(
        0,
        (int total, TimerHistoryEntry entry) => total + entry.durationSeconds,
      );

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '数据洞察',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SegmentedPill(
              items: const <String>['周', '月', '年'],
              selectedIndex: _periodIndex,
              onChanged: (int index) => setState(() => _periodIndex = index),
            ),
            const SizedBox(height: 24),
            Text(
              _periodIndex == 0 ? '2026年8月30日 - 5日' : '2026年9月',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            _CalendarCard(selectedPeriod: _periodIndex),
            const SizedBox(height: 24),
            StatsRow(
              items: <StatItem>[
                StatItem('累计时长', _summaryDuration(_totalSeconds)),
                StatItem('累计次数', '${widget.history.length}'),
                StatItem(
                  '日平均',
                  _summaryDuration(
                      widget.history.isEmpty ? 0 : _totalSeconds ~/ 7),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _summaryDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds秒';
    }
    return formatDigitalTime(seconds);
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.selectedPeriod});

  final int selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    const List<String> weekdays = <String>[
      '周日',
      '周一',
      '周二',
      '周三',
      '周四',
      '周五',
      '周六'
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('2026年9月', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: primary),
              const Spacer(),
              Icon(Icons.chevron_left_rounded, color: primary, size: 20),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: primary, size: 20),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              for (final String weekday in weekdays)
                Expanded(
                  child: Text(
                    weekday,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.mutedInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: 35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (BuildContext context, int index) {
              final int day = index - 1;
              final bool visible = day >= 1 && day <= 30;
              final bool selected = day == 2;
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? primary : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    visible ? '$day' : '',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : visible
                              ? AppTheme.ink.withOpacity(0.42)
                              : Colors.transparent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
