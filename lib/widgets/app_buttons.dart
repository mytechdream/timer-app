import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 36),
      color: foreground,
      style: IconButton.styleFrom(
        backgroundColor: background,
        minimumSize: const Size(58, 58),
        shape: const CircleBorder(),
      ),
    );
  }
}

class CapsuleButton extends StatelessWidget {
  const CapsuleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: disabled ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: disabled ? AppColors.disabledText : AppColors.ink,
        minimumSize: const Size(92, 58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: AppText.capsule,
      ),
      child: Text(label),
    );
  }
}
