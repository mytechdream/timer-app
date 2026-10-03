import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  }) : assert(items.length > 0 &&
            selectedIndex >= 0 &&
            selectedIndex < items.length);

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedAlign(
              key: const ValueKey<String>('segment-indicator'),
              alignment: AlignmentDirectional(
                  items.length == 1
                      ? 0
                      : -1 + 2 * selectedIndex / (items.length - 1),
                  0),
              duration: AppMotion.duration(context, AppMotion.selection),
              curve: AppMotion.curve,
              child: FractionallySizedBox(
                widthFactor: 1 / items.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              for (int index = 0; index < items.length; index++)
                Expanded(
                  child: _SegmentButton(
                    label: items[index],
                    selected: index == selectedIndex,
                    onTap: () {
                      if (index != selectedIndex) {
                        onChanged(index);
                      }
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

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.duration(context, AppMotion.feedback),
              curve: AppMotion.curve,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: selected ? AppTheme.ink : AppTheme.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
