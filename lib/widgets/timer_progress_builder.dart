import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef TimerProgressWidgetBuilder = Widget Function(
    BuildContext context, double progress, Widget? child);

/// Repaints the time-driven graphic at display refresh rate without rebuilding
/// the timer's text, controls, or notification logic on every frame.
class TimerProgressBuilder extends StatefulWidget {
  const TimerProgressBuilder({
    super.key,
    required this.progress,
    required this.running,
    required this.builder,
    this.child,
  });

  final double Function() progress;
  final bool running;
  final TimerProgressWidgetBuilder builder;
  final Widget? child;

  @override
  State<TimerProgressBuilder> createState() => _TimerProgressBuilderState();
}

class _TimerProgressBuilderState extends State<TimerProgressBuilder>
    with SingleTickerProviderStateMixin {
  late final ValueNotifier<double> _progress;
  late final Ticker _ticker;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _progress = ValueNotifier<double>(_readProgress());
    _ticker = createTicker((_) => _progress.value = _readProgress());
  }

  double _readProgress() => widget.progress().clamp(0.0, 1.0).toDouble();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _progress.value = _readProgress();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant TimerProgressBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progress.value = _readProgress();
    _syncTicker();
  }

  void _syncTicker() {
    if (widget.running && !_reduceMotion) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: _progress,
        builder: widget.builder,
        child: widget.child,
      );
}
