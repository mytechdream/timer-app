import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.palette,
    required this.label,
    required this.onPressed,
  });

  final AppPalette palette;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: palette.color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(66),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
        textStyle: AppText.button,
      ),
      child: Text(label),
    );
  }
}
