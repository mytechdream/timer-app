import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SegmentedPill extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.segmentBg,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: selected == i,
                button: true,
                child: GestureDetector(
                  onTap: () => onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected == i ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: selected == i
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      style: AppText.segment.copyWith(
                        color:
                            selected == i ? AppColors.ink : AppColors.mutedText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
