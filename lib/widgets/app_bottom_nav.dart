import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.palette,
    required this.index,
    required this.onChanged,
  });

  final AppPalette palette;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      NavSpec(Icons.timer_outlined, Icons.timer_rounded, '计时'),
      NavSpec(Icons.layers_outlined, Icons.layers_rounded, '批量计时'),
      NavSpec(Icons.bar_chart_outlined, Icons.bar_chart_rounded, '数据洞察'),
      NavSpec(Icons.settings_outlined, Icons.settings_rounded, '设置'),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.phoneMaxWidth),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: Container(
            height: 92,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.96),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFECCADB).withOpacity(.55),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      label: items[i].label,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () => onChanged(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 170),
                          decoration: BoxDecoration(
                            color: i == index
                                ? palette.tint.withOpacity(.55)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                i == index
                                    ? items[i].activeIcon
                                    : items[i].icon,
                                color:
                                    i == index ? palette.color : AppColors.ink,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  items[i].label,
                                  style: AppText.nav.copyWith(
                                    color: i == index
                                        ? palette.color
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
