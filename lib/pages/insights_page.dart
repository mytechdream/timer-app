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
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _latestHistoryDateOrToday();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  void didUpdateWidget(covariant InsightsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history.isEmpty && widget.history.isNotEmpty) {
      _selectedDate = _latestHistoryDateOrToday();
      _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    }
  }

  _DateRange get _currentRange {
    switch (_periodIndex) {
      case 0:
        final DateTime start = _weekStart(_selectedDate);
        return _DateRange(start, start.add(const Duration(days: 6)));
      case 1:
        final DateTime start =
            DateTime(_focusedMonth.year, _focusedMonth.month);
        return _DateRange(
          start,
          DateTime(_focusedMonth.year, _focusedMonth.month + 1)
              .subtract(const Duration(days: 1)),
        );
      default:
        return _DateRange(
          DateTime(_focusedMonth.year),
          DateTime(_focusedMonth.year + 1).subtract(const Duration(days: 1)),
        );
    }
  }

  List<TimerHistoryEntry> get _filteredHistory {
    final _DateRange range = _currentRange;
    return widget.history
        .where((TimerHistoryEntry entry) => range.contains(entry.completedAt))
        .toList();
  }

  int get _totalSeconds => _filteredHistory.fold<int>(
        0,
        (int total, TimerHistoryEntry entry) => total + entry.durationSeconds,
      );

  int get _averageDays {
    switch (_periodIndex) {
      case 0:
        return 7;
      case 1:
        return _daysInMonth(_focusedMonth.year, _focusedMonth.month);
      default:
        return DateTime(_focusedMonth.year + 1)
            .difference(DateTime(_focusedMonth.year))
            .inDays;
    }
  }

  String get _periodTitle {
    final _DateRange range = _currentRange;
    switch (_periodIndex) {
      case 0:
        return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
      case 1:
        return _formatMonth(_focusedMonth);
      default:
        return '${_focusedMonth.year}年';
    }
  }

  Map<DateTime, int> get _dailySeconds {
    final Map<DateTime, int> totals = <DateTime, int>{};
    for (final TimerHistoryEntry entry in widget.history) {
      final DateTime date = _dateOnly(entry.completedAt);
      totals[date] = (totals[date] ?? 0) + entry.durationSeconds;
    }
    return totals;
  }

  List<_LabelTimeSummary> get _labelSummaries {
    final Map<String, _LabelTimeSummary> summaries =
        <String, _LabelTimeSummary>{};
    for (final TimerHistoryEntry entry in _filteredHistory) {
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
    final List<TimerHistoryEntry> filteredHistory = _filteredHistory;
    final List<_LabelTimeSummary> labelSummaries = _labelSummaries;
    final int totalSeconds = _totalSeconds;
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
              onChanged: _setPeriodIndex,
            ),
            const SizedBox(height: 24),
            Text(
              _periodTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            _CalendarCard(
              focusedMonth: _focusedMonth,
              selectedDate: _selectedDate,
              highlightedRange: _periodIndex == 0 ? _currentRange : null,
              dailySeconds: _dailySeconds,
              expanded: _calendarExpanded,
              onToggleExpanded: () => setState(
                () => _calendarExpanded = !_calendarExpanded,
              ),
              onPreviousMonth: () => _moveMonth(-1),
              onNextMonth: () => _moveMonth(1),
              onDateSelected: _selectDate,
            ),
            const SizedBox(height: 24),
            StatsRow(
              items: <StatItem>[
                StatItem('累计时长', _summaryDuration(totalSeconds)),
                StatItem('累计次数', '${filteredHistory.length}'),
                StatItem('日平均', _summaryDuration(totalSeconds ~/ _averageDays)),
              ],
            ),
            if (labelSummaries.isNotEmpty) ...<Widget>[
              const SizedBox(height: 24),
              _LabelTimeSection(
                summaries: labelSummaries,
                totalSeconds: totalSeconds,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setPeriodIndex(int index) {
    setState(() => _periodIndex = index);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _focusedMonth = DateTime(date.year, date.month);
    });
  }

  void _moveMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      _selectedDate = _clampDateToMonth(_selectedDate, _focusedMonth);
    });
  }

  DateTime _latestHistoryDateOrToday() {
    if (widget.history.isEmpty) {
      return _dateOnly(DateTime.now());
    }
    DateTime latest = widget.history.first.completedAt;
    for (final TimerHistoryEntry entry in widget.history.skip(1)) {
      if (entry.completedAt.isAfter(latest)) {
        latest = entry.completedAt;
      }
    }
    return _dateOnly(latest);
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
    required this.focusedMonth,
    required this.selectedDate,
    required this.highlightedRange,
    required this.dailySeconds,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final _DateRange? highlightedRange;
  final Map<DateTime, int> dailySeconds;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

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
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: '上个月',
                onPressed: onPreviousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: primary,
              ),
              Expanded(
                child: Text(
                  _formatMonth(focusedMonth),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: '下个月',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                color: primary,
              ),
              IconButton(
                tooltip: expanded ? '折叠日历' : '展开日历',
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                color: primary,
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: <Widget>[
                      const SizedBox(height: 12),
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
                      _MonthGrid(
                        focusedMonth: focusedMonth,
                        selectedDate: selectedDate,
                        highlightedRange: highlightedRange,
                        dailySeconds: dailySeconds,
                        onDateSelected: onDateSelected,
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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.highlightedRange,
    required this.dailySeconds,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final _DateRange? highlightedRange;
  final Map<DateTime, int> dailySeconds;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = _daysInMonth(focusedMonth.year, focusedMonth.month);
    final int leadingBlanks =
        DateTime(focusedMonth.year, focusedMonth.month).weekday % 7;
    final int itemCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (BuildContext context, int index) {
        final int day = index - leadingBlanks + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final DateTime date = DateTime(
          focusedMonth.year,
          focusedMonth.month,
          day,
        );
        return _CalendarDayButton(
          date: date,
          selected: _isSameDay(date, selectedDate),
          highlighted: highlightedRange?.contains(date) ?? false,
          hasActivity: (dailySeconds[_dateOnly(date)] ?? 0) > 0,
          onTap: () => onDateSelected(date),
        );
      },
    );
  }
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.date,
    required this.selected,
    required this.highlighted,
    required this.hasActivity,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool highlighted;
  final bool hasActivity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color textColor = selected
        ? Colors.white
        : highlighted
            ? AppTheme.ink
            : AppTheme.ink.withOpacity(0.54);

    return Semantics(
      button: true,
      selected: selected,
      label: '选择${date.month}月${date.day}日',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          key: ValueKey<String>(
            'insights-date-${date.year}-${date.month}-${date.day}',
          ),
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? primary
                    : highlighted
                        ? primary.withOpacity(0.08)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (hasActivity)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
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
          Text('不同标签计时', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
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

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final DateTime value = _dateOnly(date);
    return !value.isBefore(start) && !value.isAfter(end);
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _weekStart(DateTime value) {
  final DateTime date = _dateOnly(value);
  return date.subtract(Duration(days: date.weekday % 7));
}

DateTime _clampDateToMonth(DateTime value, DateTime month) {
  final int day = value.day
      .clamp(
        1,
        _daysInMonth(month.year, month.month),
      )
      .toInt();
  return DateTime(month.year, month.month, day);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

String _formatDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}

String _formatMonth(DateTime date) {
  return '${date.year}年${date.month}月';
}
