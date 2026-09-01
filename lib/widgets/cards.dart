import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.tinted = false,
    this.borderColor,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final bool tinted;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tinted ? AppColors.softPink : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border:
            Border.all(color: borderColor ?? Colors.transparent, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEECEDF).withOpacity(.16),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final AppPalette palette;
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      tinted: true,
      borderColor: palette.softBorder,
      child: SizedBox(
        width: double.infinity,
        height: subtitle == null ? 186 : 170,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: palette.color, size: 52),
            const SizedBox(height: 18),
            Text(title, style: AppText.emptyTitle),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(subtitle!,
                  textAlign: TextAlign.center, style: AppText.bodyMuted),
            ],
          ],
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.palette, required this.icon});

  final AppPalette palette;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
          color: palette.tint, borderRadius: BorderRadius.circular(18)),
      child: Icon(icon, color: palette.color, size: 27),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.section),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
