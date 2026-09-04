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
  bool _calendarExpanded = true;

  int get _totalSeconds => widget.history.fold<int>(
        0,
        (int total, TimerHistoryEntry entry) => total + entry.durationSeconds,
      );

  List<_LabelTimeSummary> get _labelSummaries {
    final Map<String, _LabelTimeSummary> summaries =
        <String, _LabelTimeSummary>{};
    for (final TimerHistoryEntry entry in widget.history) {
      final _LabelTimeSummary previous =
          summaries[entry.name] ?? _LabelTimeSummary(entry.name, 0, 0);
      summaries[entry.name] = previous.copyWith(
        seconds: previous.seconds + entry.durationSeconds,
        count: previous.count + 1,
      );
    }
    final List<_LabelTimeSummary> sorted = summaries.values.toList()
      ..sort(
        (_LabelTimeSummary a, _LabelTimeSummary b) =>
            b.seconds.compareTo(a.seconds),
      );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '数据洞察',
      centerTitle: false,
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
            _CalendarCard(
              selectedPeriod: _periodIndex,
              expanded: _calendarExpanded,
              onToggleExpanded: () => setState(
                () => _calendarExpanded = !_calendarExpanded,
              ),
            ),
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
            const SizedBox(height: 24),
            _LabelTimeSection(
              summaries: _labelSummaries,
              totalSeconds: _totalSeconds,
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
  const _CalendarCard({
    required this.selectedPeriod,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final int selectedPeriod;
  final bool expanded;
  final VoidCallback onToggleExpanded;

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
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggleExpanded,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: <Widget>[
                  Text('2026年9月',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: primary),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: primary,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: expanded
                ? Column(
                    children: <Widget>[
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _LabelTimeSection extends StatelessWidget {
  const _LabelTimeSection({
    required this.summaries,
    required this.totalSeconds,
  });

  final List<_LabelTimeSummary> summaries;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('标签计时', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (summaries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '暂无标签计时记录',
                style: TextStyle(
                  color: AppTheme.mutedInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (int index = 0; index < summaries.length; index++) ...<Widget>[
              _LabelTimeRow(
                summary: summaries[index],
                totalSeconds: totalSeconds,
              ),
              if (index != summaries.length - 1)
                const Divider(height: 20, color: AppTheme.divider),
            ],
        ],
      ),
    );
  }
}

class _LabelTimeRow extends StatelessWidget {
  const _LabelTimeRow({
    required this.summary,
    required this.totalSeconds,
  });

  final _LabelTimeSummary summary;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final double ratio = totalSeconds == 0 ? 0 : summary.seconds / totalSeconds;

    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _avatarText(summary.name),
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      summary.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _formatPercent(ratio),
                    style: const TextStyle(
                      color: AppTheme.mutedInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: ratio.clamp(0.0, 1.0).toDouble(),
                  backgroundColor: AppTheme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatDigitalTime(summary.seconds)} · ${summary.count}次',
                style: const TextStyle(
                  color: AppTheme.mutedInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPercent(double ratio) {
    return '${(ratio * 100).round()}%';
  }

  String _avatarText(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1);
  }
}

class _LabelTimeSummary {
  const _LabelTimeSummary(this.name, this.seconds, this.count);

  final String name;
  final int seconds;
  final int count;

  _LabelTimeSummary copyWith({int? seconds, int? count}) {
    return _LabelTimeSummary(
      name,
      seconds ?? this.seconds,
      count ?? this.count,
    );
  }
}
