import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DurationPickerCard extends StatefulWidget {
  const DurationPickerCard({
    super.key,
    required this.seconds,
    required this.onChanged,
  });

  final int seconds;
  final ValueChanged<int> onChanged;

  @override
  State<DurationPickerCard> createState() => _DurationPickerCardState();
}

class _DurationPickerCardState extends State<DurationPickerCard> {
  static const int _maxHours = 99;
  static const int _maxTotalSeconds = _maxHours * 3600 + 59 * 60 + 59;

  late final FixedExtentScrollController _hoursController;
  late final FixedExtentScrollController _minutesController;
  late final FixedExtentScrollController _secondsController;

  late int _hours;
  late int _minutes;
  late int _seconds;
  bool _syncingSelection = false;

  @override
  void initState() {
    super.initState();
    _setPartsFromSeconds(widget.seconds);
    _hoursController = FixedExtentScrollController(initialItem: _hours);
    _minutesController = FixedExtentScrollController(initialItem: _minutes);
    _secondsController = FixedExtentScrollController(initialItem: _seconds);
  }

  @override
  void didUpdateWidget(DurationPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int nextSeconds = _normalizeSeconds(widget.seconds);
    if (nextSeconds == _totalSeconds) {
      return;
    }

    setState(() {
      _setPartsFromSeconds(nextSeconds);
    });
    _jumpControllersToSelection();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  int get _totalSeconds => _hours * 3600 + _minutes * 60 + _seconds;

  int _normalizeSeconds(int seconds) {
    return seconds.clamp(1, _maxTotalSeconds).toInt();
  }

  void _setPartsFromSeconds(int seconds) {
    final int safeSeconds = _normalizeSeconds(seconds);
    _hours = safeSeconds ~/ 3600;
    _minutes = (safeSeconds % 3600) ~/ 60;
    _seconds = safeSeconds % 60;
  }

  void _jumpControllersToSelection() {
    _syncingSelection = true;
    try {
      if (_hoursController.hasClients) {
        _hoursController.jumpToItem(_hours);
      }
      if (_minutesController.hasClients) {
        _minutesController.jumpToItem(_minutes);
      }
      if (_secondsController.hasClients) {
        _secondsController.jumpToItem(_seconds);
      }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncingSelection = false;
        }
      });
    }
  }

  void _emitChange() {
    if (_syncingSelection) {
      return;
    }
    final int nextSeconds = _totalSeconds;
    widget.onChanged(nextSeconds == 0 ? 1 : nextSeconds);
  }

  void _handleWheelChanged(VoidCallback updatePart) {
    if (_syncingSelection) {
      return;
    }
    setState(updatePart);
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    final TimerPalette palette = context.timerPalette;

    return Container(
      width: double.infinity,
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: palette.soft.withOpacity(0.58),
        borderRadius: BorderRadius.circular(30),
        border:
            Border.all(color: palette.primary.withOpacity(0.14), width: 1.2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            height: 62,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: palette.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _DurationWheel(
                  value: _hours,
                  max: _maxHours,
                  unit: '小时',
                  controller: _hoursController,
                  onChanged: (int value) {
                    _handleWheelChanged(() => _hours = value);
                  },
                ),
              ),
              Expanded(
                child: _DurationWheel(
                  value: _minutes,
                  max: 59,
                  unit: '分钟',
                  controller: _minutesController,
                  onChanged: (int value) {
                    _handleWheelChanged(() => _minutes = value);
                  },
                ),
              ),
              Expanded(
                child: _DurationWheel(
                  value: _seconds,
                  max: 59,
                  unit: '秒',
                  controller: _secondsController,
                  onChanged: (int value) {
                    _handleWheelChanged(() => _seconds = value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationWheel extends StatelessWidget {
  const _DurationWheel({
    required this.value,
    required this.max,
    required this.unit,
    required this.controller,
    required this.onChanged,
  });

  final int value;
  final int max;
  final String unit;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
          child: CupertinoPicker.builder(
            scrollController: controller,
            itemExtent: 56,
            diameterRatio: 1.8,
            squeeze: 0.98,
            useMagnifier: false,
            backgroundColor: Colors.transparent,
            selectionOverlay: const SizedBox.shrink(),
            onSelectedItemChanged: onChanged,
            childCount: max + 1,
            itemBuilder: (BuildContext context, int index) {
              return const SizedBox.expand();
            },
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _WheelReadout(value: value, max: max, unit: unit),
          ),
        ),
      ],
    );
  }
}

class _WheelReadout extends StatelessWidget {
  const _WheelReadout({
    required this.value,
    required this.max,
    required this.unit,
  });

  final int value;
  final int max;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        _WheelCandidate(
          number: value - 2,
          max: max,
          offsetY: -86,
          opacity: 0.30,
        ),
        _WheelCandidate(
          number: value - 1,
          max: max,
          offsetY: -48,
          opacity: 0.44,
        ),
        _WheelText(number: value, unit: unit, selected: true),
        _WheelCandidate(
          number: value + 1,
          max: max,
          offsetY: 58,
          opacity: 0.44,
        ),
        _WheelCandidate(
          number: value + 2,
          max: max,
          offsetY: 96,
          opacity: 0.30,
        ),
      ],
    );
  }
}

class _WheelCandidate extends StatelessWidget {
  const _WheelCandidate({
    required this.number,
    required this.max,
    required this.offsetY,
    required this.opacity,
  });

  final int number;
  final int max;
  final double offsetY;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (number < 0 || number > max) {
      return const SizedBox.shrink();
    }

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: _WheelText(number: number, opacity: opacity),
    );
  }
}

class _WheelText extends StatelessWidget {
  const _WheelText({
    required this.number,
    this.unit,
    this.selected = false,
    this.opacity = 1,
  });

  final int number;
  final String? unit;
  final bool selected;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          selected ? '$number $unit' : '$number',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.ink.withOpacity(opacity),
            fontFamilyFallback: const <String>[
              'Microsoft YaHei',
              'PingFang SC',
              'Noto Sans CJK SC',
              'Noto Sans SC',
              'Arial Unicode MS',
              'sans-serif',
            ],
            fontSize: 28,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
