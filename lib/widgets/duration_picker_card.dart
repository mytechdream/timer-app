import 'package:flutter/cupertino.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';

class DurationPickerCard extends StatelessWidget {
  const DurationPickerCard({
    super.key,
    required this.palette,
    required this.seconds,
    this.interactive = false,
    this.onChanged,
  });

  final AppPalette palette;
  final int seconds;
  final bool interactive;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    return PickerFrame(
      palette: palette,
      height: 224,
      child: interactive
          ? Row(
              children: [
                Expanded(
                  child: WheelColumn(
                    max: 23,
                    value: hours,
                    unit: '小时',
                    onChanged: (value) =>
                        _emit(value, minutes, remainingSeconds),
                  ),
                ),
                Expanded(
                  child: WheelColumn(
                    max: 59,
                    value: minutes,
                    unit: '分钟',
                    onChanged: (value) => _emit(hours, value, remainingSeconds),
                  ),
                ),
                Expanded(
                  child: WheelColumn(
                    max: 59,
                    value: remainingSeconds,
                    unit: '秒',
                    onChanged: (value) => _emit(hours, minutes, value),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                PickerReadout(value: hours, unit: '小时'),
                PickerReadout(value: minutes, unit: '分钟'),
                PickerReadout(value: remainingSeconds, unit: '秒'),
              ],
            ),
    );
  }

  void _emit(int hours, int minutes, int seconds) {
    onChanged?.call(hours * 3600 + minutes * 60 + seconds);
  }
}

class WheelPickerPanel extends StatelessWidget {
  const WheelPickerPanel({
    super.key,
    required this.palette,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.onHoursChanged,
    required this.onMinutesChanged,
    required this.onSecondsChanged,
  });

  final AppPalette palette;
  final int hours;
  final int minutes;
  final int seconds;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onSecondsChanged;

  @override
  Widget build(BuildContext context) {
    return PickerFrame(
      palette: palette,
      height: 286,
      child: Row(
        children: [
          Expanded(
            child: WheelColumn(
                max: 23, value: hours, unit: '小时', onChanged: onHoursChanged),
          ),
          Expanded(
            child: WheelColumn(
                max: 59,
                value: minutes,
                unit: '分钟',
                onChanged: onMinutesChanged),
          ),
          Expanded(
            child: WheelColumn(
                max: 59,
                value: seconds,
                unit: '秒',
                onChanged: onSecondsChanged),
          ),
        ],
      ),
    );
  }
}

class PickerFrame extends StatelessWidget {
  const PickerFrame({
    super.key,
    required this.palette,
    required this.height,
    required this.child,
  });

  final AppPalette palette;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.tint.withOpacity(.22),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.softBorder, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 26),
            decoration: BoxDecoration(
              color: palette.tint.withOpacity(.58),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class WheelColumn extends StatefulWidget {
  const WheelColumn({
    super.key,
    required this.max,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  final int max;
  final int value;
  final String unit;
  final ValueChanged<int> onChanged;

  @override
  State<WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<WheelColumn> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: _controller,
      itemExtent: 64,
      diameterRatio: 1.5,
      magnification: 1.05,
      useMagnifier: true,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: widget.onChanged,
      children: [
        for (var i = 0; i <= widget.max; i++)
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$i ${widget.unit}', style: AppText.picker),
            ),
          ),
      ],
    );
  }
}

class PickerReadout extends StatelessWidget {
  const PickerReadout({super.key, required this.value, required this.unit});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Text('$value $unit', style: AppText.picker);
  }
}
