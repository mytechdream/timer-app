import 'package:flutter/material.dart';

import '../models/timer_models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page.dart';
import '../widgets/cards.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.palette,
    required this.selectedPalette,
    required this.onPaletteChanged,
  });

  final AppPalette palette;
  final int selectedPalette;
  final ValueChanged<int> onPaletteChanged;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('设置', style: AppText.title),
          const SizedBox(height: 46),
          SettingsCard(
            title: '配色',
            children: [
              Text('当前配色： ${palette.name}', style: AppText.subtleBold),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < AppColors.palettes.length; i++)
                    ColorChoice(
                      palette: palette,
                      item: AppColors.palettes[i],
                      selected: selectedPalette == i,
                      onPressed: () => onPaletteChanged(i),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsCard(
            title: '提醒',
            children: [
              SettingsTile(
                palette: palette,
                icon: Icons.notifications_active_outlined,
                title: '结束提醒',
                value: '铃声 + 振动',
              ),
              SettingsTile(
                palette: palette,
                icon: Icons.volume_up_outlined,
                title: '提示音',
                value: '滴答 + 合成铃声',
              ),
              SettingsTile(
                palette: palette,
                icon: Icons.phone_android_rounded,
                title: '后台运行',
                value: '',
                trailing: Switch(
                    value: false,
                    onChanged: (_) {},
                    activeColor: palette.color),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsCard(
            title: '计时',
            children: [
              SettingsTile(
                palette: palette,
                icon: Icons.business_center_outlined,
                title: '默认倒计时',
                value: '10分钟',
              ),
              SettingsTile(
                palette: palette,
                icon: Icons.add_circle_outline_rounded,
                title: '延时按钮',
                value: '3秒',
              ),
            ],
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  final AppPalette palette;
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconBadge(palette: palette, icon: icon),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppText.tileTitle)),
          if (trailing != null)
            trailing!
          else ...[
            Text(value, style: AppText.tileValue),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.mutedText, size: 32),
          ],
        ],
      ),
    );
  }
}

class ColorChoice extends StatelessWidget {
  const ColorChoice({
    super.key,
    required this.palette,
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final AppPalette palette;
  final AppPalette item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
        child: selected
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : null,
      ),
      label: Text(item.name),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: AppText.choice,
        minimumSize: const Size(104, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(
            color: selected ? palette.color : AppColors.divider,
            width: selected ? 2 : 1.5),
        backgroundColor: selected ? palette.tint : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
