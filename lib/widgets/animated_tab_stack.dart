import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Keeps tab subtrees mounted, including scroll positions and running timers.
/// Each fade retargets from its current value when tabs are tapped rapidly.
class AnimatedTabStack extends StatelessWidget {
  const AnimatedTabStack({
    super.key,
    required this.index,
    required this.children,
  }) : assert(index >= 0 && index < children.length);

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          for (int i = 0; i < children.length; i++)
            TweenAnimationBuilder<double>(
              key: ValueKey<int>(i),
              tween: Tween<double>(
                begin: i == index ? 1.0 : 0.0,
                end: i == index ? 1.0 : 0.0,
              ),
              duration: AppMotion.duration(context,
                  i == index ? AppMotion.pageEnter : AppMotion.pageExit),
              curve: AppMotion.curve,
              child: IgnorePointer(
                ignoring: i != index,
                child: ExcludeSemantics(
                  excluding: i != index,
                  child: ExcludeFocus(
                    excluding: i != index,
                    child: TickerMode(
                      enabled: i == index,
                      child: RepaintBoundary(child: children[i]),
                    ),
                  ),
                ),
              ),
              builder: (BuildContext context, double value, Widget? child) =>
                  Offstage(
                offstage: value == 0,
                child: Opacity(
                  opacity: value,
                  child: FractionalTranslation(
                    translation: Offset(0, 0.018 * (1 - value)),
                    child: child,
                  ),
                ),
              ),
            ),
        ],
      );
}
