import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.actions,
    this.centerTitle = true,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 104),
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? actions;
  final bool centerTitle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final List<Widget> headerActions = actions ??
        <Widget>[
          if (trailing != null) trailing!,
        ];

    return SafeArea(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  SizedBox(width: 44, height: 44, child: leading),
                  const SizedBox(width: 8),
                ] else if (centerTitle) ...<Widget>[
                  const SizedBox(width: 44, height: 44),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (headerActions.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  for (int index = 0;
                      index < headerActions.length;
                      index++) ...<Widget>[
                    SizedBox(
                        width: 44, height: 44, child: headerActions[index]),
                    if (index != headerActions.length - 1)
                      const SizedBox(width: 8),
                  ],
                ] else if (centerTitle) ...<Widget>[
                  const SizedBox(width: 8),
                  const SizedBox(width: 44, height: 44),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
    this.transparentBackground = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        fixedSize: const Size(44, 44),
        backgroundColor: filled
            ? primary
            : transparentBackground
                ? Colors.transparent
                : AppTheme.panel,
        foregroundColor: filled ? Colors.white : AppTheme.ink,
        disabledBackgroundColor: transparentBackground
            ? Colors.transparent
            : AppTheme.panel.withOpacity(0.64),
        disabledForegroundColor: AppTheme.mutedInk.withOpacity(0.35),
        shadowColor: transparentBackground
            ? Colors.transparent
            : Colors.black.withOpacity(0.08),
        elevation: filled ? 10 : 0,
      ),
    );
  }
}
