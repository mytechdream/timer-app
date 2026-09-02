import 'dart:async';

import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../services/timer_audio.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import '../widgets/app_page.dart';
import '../widgets/cards.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.audio,
    required this.selectedPaletteIndex,
    required this.onPaletteChanged,
    required this.onSettingsChanged,
  });

  final TimerSettings settings;
  final TimerAudio audio;
  final int selectedPaletteIndex;
  final ValueChanged<int> onPaletteChanged;
  final Future<void> Function(TimerSettings settings) onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: '设置',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SectionCard(
              title: '配色',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '当前配色：${AppTheme.palettes[selectedPaletteIndex].name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (int i = 0; i < AppTheme.palettes.length; i++)
                        _PaletteChip(
                          palette: AppTheme.palettes[i],
                          selected: i == selectedPaletteIndex,
                          onTap: () => onPaletteChanged(i),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: '提醒',
              child: Column(
                children: <Widget>[
                  _SettingsRow(
                    icon: Icons.notifications_active_outlined,
                    title: '结束提醒',
                    value: settings.completionReminderName,
                    onTap: () => _showCompletionReminderSheet(context),
                  ),
                  _SettingsRow(
                    icon: Icons.volume_up_outlined,
                    title: '提示音',
                    value: settings.alertSoundName,
                    onTap: () => _showSoundSheet(context),
                  ),
                  _SettingsRow(
                    icon: Icons.phone_android_rounded,
                    title: '后台运行',
                    trailing: Switch(
                      value: settings.backgroundRunEnabled,
                      onChanged: (bool value) => onSettingsChanged(
                        settings.copyWith(backgroundRunEnabled: value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionCard(
              title: '计时',
              child: Column(
                children: <Widget>[
                  _SettingsRow(
                    icon: Icons.lock_clock_outlined,
                    title: '默认倒计时',
                    value: formatMinuteLabel(settings.defaultCountdownSeconds),
                    onTap: () => _showDefaultCountdownSheet(context),
                  ),
                  _SettingsRow(
                    icon: Icons.more_time_rounded,
                    title: '延时按钮',
                    value: '${settings.extendSeconds}秒',
                    onTap: () => _showExtendSheet(context),
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDefaultCountdownSheet(BuildContext context) {
    _showOptionSheet<int>(
      context: context,
      title: '默认倒计时',
      options: const <int>[3 * 60, 5 * 60, 10 * 60, 15 * 60, 25 * 60],
      labelBuilder: formatMinuteLabel,
      selected: settings.defaultCountdownSeconds,
      onSelected: (int seconds) => onSettingsChanged(
        settings.copyWith(defaultCountdownSeconds: seconds),
      ),
    );
  }

  void _showCompletionReminderSheet(BuildContext context) {
    _showOptionSheet<String>(
      context: context,
      title: '结束提醒',
      options: TimerSettings.completionReminderOptions,
      labelBuilder: (String reminder) => reminder,
      selected: settings.completionReminderName,
      onSelected: (String reminder) => onSettingsChanged(
        settings.copyWith(
          completionReminderName: reminder,
          completionSoundEnabled: reminder != TimerSettings.reminderOff,
        ),
      ),
    );
  }

  void _showSoundSheet(BuildContext context) {
    _showOptionSheet<String>(
      context: context,
      title: '提示音',
      options: TimerSettings.alertSoundOptions,
      labelBuilder: (String sound) => sound,
      selected: settings.alertSoundName,
      onSelected: (String sound) async {
        unawaited(_previewSound(sound));
        await onSettingsChanged(
          settings.copyWith(
            alertSoundName: sound,
            completionSoundEnabled: true,
          ),
        );
      },
    );
  }

  Future<void> _previewSound(String sound) async {
    try {
      await audio.playComplete(sound);
    } catch (_) {
      // Sound preview should never block saving the user's selection.
    }
  }

  void _showExtendSheet(BuildContext context) {
    _showOptionSheet<int>(
      context: context,
      title: '延时按钮',
      options: const <int>[3, 5, 10, 30],
      labelBuilder: (int seconds) => '$seconds秒',
      selected: settings.extendSeconds,
      onSelected: (int seconds) => onSettingsChanged(
        settings.copyWith(extendSeconds: seconds),
      ),
    );
  }

  void _showOptionSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required String Function(T option) labelBuilder,
    required T selected,
    required Future<void> Function(T option) onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                for (final T option in options)
                  ListTile(
                    minVerticalPadding: 10,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      labelBuilder(option),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: option == selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      await onSelected(option);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PaletteChip extends StatelessWidget {
  const _PaletteChip({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final TimerPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.primary : AppTheme.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                palette.name,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded,
                    color: palette.primary, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                color: AppTheme.mutedInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (trailing != null) trailing!,
          if (onTap != null) ...<Widget>[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedInk),
          ],
        ],
      ),
    );

    final Widget content = Column(
      children: <Widget>[
        row,
        if (showDivider)
          const Divider(height: 1, indent: 52, color: AppTheme.divider),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return InkWell(onTap: onTap, child: content);
  }
}
