import 'package:flutter/material.dart';

class PlainTextButton extends StatelessWidget {
  const PlainTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 44),
        foregroundColor: Colors.black,
        disabledForegroundColor: Colors.black.withOpacity(0.18),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        backgroundColor: Colors.white.withOpacity(0.72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(label),
    );
  }
}
