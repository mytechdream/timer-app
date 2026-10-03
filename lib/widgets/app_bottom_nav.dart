import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_motion.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const List<_NavItem> _items = <_NavItem>[
    _NavItem('计时', Icons.timer_outlined, Icons.timer_rounded),
    _NavItem('批量计时', Icons.layers_outlined, Icons.layers_rounded),
    _NavItem('数据洞察', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
    _NavItem('设置', Icons.settings_outlined, Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final double barHeight =
        (64 + MediaQuery.textScalerOf(context).scale(13) * 1.5)
            .clamp(84.0, double.infinity)
            .toDouble();
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(32),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedAlign(
                key: const ValueKey<String>('bottom-nav-indicator'),
                alignment: AlignmentDirectional(
                    -1 + 2 * index / (_items.length - 1), 0),
                duration: AppMotion.duration(context, AppMotion.selection),
                curve: AppMotion.curve,
                child: FractionallySizedBox(
                  widthFactor: 1 / _items.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      active: i == index,
                      activeColor: primary,
                      onTap: () {
                        if (i != index) {
                          onChanged(i);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Tooltip(
        message: item.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: active ? 1 : 0, end: active ? 1 : 0),
              duration: AppMotion.duration(context, AppMotion.feedback),
              curve: AppMotion.curve,
              builder: (BuildContext context, double value, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Transform.scale(
                      scale: 1 + 0.06 * value,
                      child: Icon(
                        active ? item.activeIcon : item.icon,
                        size: 28,
                        color: Color.lerp(AppTheme.ink, activeColor, value),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: Color.lerp(AppTheme.ink, activeColor, value),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
