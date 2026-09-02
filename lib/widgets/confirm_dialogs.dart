import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<bool> showDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  String actionLabel = '删除',
}) {
  return showAppConfirmDialog(
    context: context,
    title: title,
    message: message,
    actionLabel: actionLabel,
    actionColor: const Color(0xFFE5486D),
  );
}

Future<bool> showExitTimerDialog(BuildContext context) {
  return showAppConfirmDialog(
    context: context,
    title: '退出计时？',
    message: '退出后当前计时会停止，本次进度不会继续保留。',
    actionLabel: '退出',
  );
}

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
  Color? actionColor,
}) async {
  final Color primary = Theme.of(context).colorScheme.primary;
  final Color confirmColor = actionColor ?? primary;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppTheme.mutedInk,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(72, 44),
              foregroundColor: AppTheme.mutedInk,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, 44),
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: Text(actionLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
