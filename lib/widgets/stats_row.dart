import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.items,
  });

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int index = 0; index < items.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(width: 12),
          Expanded(child: _StatCard(item: items[index])),
        ],
      ],
    );
  }
}

class StatItem {
  const StatItem(this.label, this.value);

  final String label;
  final String value;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          item.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.mutedInk,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
