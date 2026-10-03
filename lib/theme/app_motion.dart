import 'package:flutter/material.dart';

class AppMotion {
  static const Duration pageEnter = Duration(milliseconds: 260);
  static const Duration pageExit = Duration(milliseconds: 180);
  static const Duration selection = Duration(milliseconds: 240);
  static const Duration feedback = Duration(milliseconds: 160);
  static const Curve curve = Curves.easeOutCubic;

  static Duration duration(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}
