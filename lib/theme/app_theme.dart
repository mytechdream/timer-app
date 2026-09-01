import 'package:flutter/material.dart';

class TimerPalette {
  const TimerPalette({
    required this.name,
    required this.primary,
    required this.soft,
    required this.background,
    required this.surface,
  });

  final String name;
  final Color primary;
  final Color soft;
  final Color background;
  final Color surface;
}

class AppTheme {
  static const Color ink = Color(0xFF08111F);
  static const Color mutedInk = Color(0xFF7B8492);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEAECEF);

  static const List<TimerPalette> palettes = <TimerPalette>[
    TimerPalette(
      name: '天空蓝',
      primary: Color(0xFF2F9BF4),
      soft: Color(0xFFEAF4FF),
      background: Color(0xFFF5F9FF),
      surface: Color(0xFFFFFFFF),
    ),
    TimerPalette(
      name: '樱花粉',
      primary: Color(0xFFF04286),
      soft: Color(0xFFFFECF5),
      background: Color(0xFFFFF6FA),
      surface: Color(0xFFFFFFFF),
    ),
    TimerPalette(
      name: '薄荷绿',
      primary: Color(0xFF12A884),
      soft: Color(0xFFE7FAF4),
      background: Color(0xFFF3FCF8),
      surface: Color(0xFFFFFFFF),
    ),
    TimerPalette(
      name: '葡萄紫',
      primary: Color(0xFF7657E8),
      soft: Color(0xFFF0ECFF),
      background: Color(0xFFF8F6FF),
      surface: Color(0xFFFFFFFF),
    ),
    TimerPalette(
      name: '暖橙色',
      primary: Color(0xFFF4A100),
      soft: Color(0xFFFFF4DA),
      background: Color(0xFFFFFAEF),
      surface: Color(0xFFFFFFFF),
    ),
  ];

  static ThemeData build(TimerPalette palette) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      primary: palette.primary,
      surface: palette.surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Roboto',
      fontFamilyFallback: const <String>[
        'Microsoft YaHei',
        'PingFang SC',
        'Noto Sans CJK SC',
        'Noto Sans SC',
        'Arial Unicode MS',
        'sans-serif',
      ],
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: ink,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          height: 1.12,
        ),
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: mutedInk,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(color: ink),
      splashFactory: InkRipple.splashFactory,
    );
  }
}

extension TimerTheme on BuildContext {
  TimerPalette get timerPalette {
    final Color primary = Theme.of(this).colorScheme.primary;
    return AppTheme.palettes.firstWhere(
      (TimerPalette palette) => palette.primary.value == primary.value,
      orElse: () => AppTheme.palettes[1],
    );
  }
}
