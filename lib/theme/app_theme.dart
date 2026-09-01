import 'package:flutter/material.dart';

import '../models/timer_models.dart';

class AppColors {
  static const ink = Color(0xFF071523);
  static const mutedText = Color(0xFF728094);
  static const disabledText = Color(0xFFD6DCE6);
  static const bg = Color(0xFFF7F8FE);
  static const pinkBg = Color(0xFFFFF4F9);
  static const softPink = Color(0xFFFFF7FB);
  static const segmentBg = Color(0xFFE9EDF5);
  static const divider = Color(0xFFE5EAF3);

  static const palettes = [
    AppPalette(
      name: '天空蓝',
      color: Color(0xFF37A9F2),
      tint: Color(0xFFE5F5FF),
      softBorder: Color(0xFFCFEAFE),
    ),
    AppPalette(
      name: '樱花粉',
      color: Color(0xFFF2438B),
      tint: Color(0xFFFFE4F0),
      softBorder: Color(0xFFFFD4E6),
    ),
    AppPalette(
      name: '薄荷绿',
      color: Color(0xFF20B486),
      tint: Color(0xFFE1F8F0),
      softBorder: Color(0xFFC9EFE3),
    ),
    AppPalette(
      name: '葡萄紫',
      color: Color(0xFF7657F2),
      tint: Color(0xFFEEE9FF),
      softBorder: Color(0xFFDCD2FF),
    ),
    AppPalette(
      name: '暖橙色',
      color: Color(0xFFFFA20C),
      tint: Color(0xFFFFF0D7),
      softBorder: Color(0xFFFFDE9F),
    ),
  ];
}

class AppLayout {
  static const phoneMaxWidth = 430.0;
  static const pageHorizontalPadding = 22.0;
}

class AppText {
  static const title = TextStyle(
    fontSize: 36,
    height: 1.05,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const navTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const large = TextStyle(
    fontSize: 29,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const section = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const segment = TextStyle(fontSize: 20, fontWeight: FontWeight.w900);
  static const picker = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const fadedNumber = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.disabledText,
  );
  static const fadedNumberSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.disabledText,
  );
  static const button = TextStyle(fontSize: 25, fontWeight: FontWeight.w900);
  static const bubbleTime = TextStyle(
    fontSize: 33,
    height: 1,
    fontWeight: FontWeight.w900,
  );
  static const bubbleLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.mutedText,
  );
  static const emptyTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const bodyMuted = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.mutedText,
  );
  static const subtleBold = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: AppColors.mutedText,
  );
  static const tileTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const tileValue = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.mutedText,
  );
  static const choice = TextStyle(fontSize: 16, fontWeight: FontWeight.w900);
  static const nav = TextStyle(fontSize: 15, fontWeight: FontWeight.w900);
  static const capsule = TextStyle(fontSize: 22, fontWeight: FontWeight.w900);
  static const calendarHead = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    color: AppColors.mutedText,
  );
  static const calendar = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: AppColors.disabledText,
  );
  static const calendarSelected = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );
  static const statLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.mutedText,
  );
  static const statValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const input = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );
  static const inputHint = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.disabledText,
  );
}
