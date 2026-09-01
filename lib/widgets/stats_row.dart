import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        StatBlock(label: '累计时长', value: '0秒'),
        StatBlock(label: '累计次数', value: '0'),
        StatBlock(label: '日平均', value: '0秒'),
      ],
    );
  }
}

class StatBlock extends StatelessWidget {
  const StatBlock({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppText.statLabel),
        const SizedBox(height: 10),
        Text(value, style: AppText.statValue),
      ],
    );
  }
}
