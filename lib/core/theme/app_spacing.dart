import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 4-based spacing rhythm, radii, screen padding. See commands/03 §3.4.
class AppSpacing {
  const AppSpacing._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 32;
  static const double s8 = 40;

  // Screen horizontal padding (prototype --pad). Density-aware.
  static const double padCompact = 16;
  static const double padRegular = 18;
  static const double padComfy = 20;
  static const double screenPad = padComfy; // default

  // Radii (prototype --r-base = 22)
  static const double rCard = 22;
  static const double rLg = 30; // big surfaces
  static const double rSm = 14; // buttons, inputs
  static const double rChip = 999; // pills, segmented, avatars
}

class AppDurations {
  const AppDurations._();

  static const fast = Duration(milliseconds: 150);
  static const med = Duration(milliseconds: 280); // segmented pill, push routes
  static const slow = Duration(milliseconds: 500); // card entrance
  static const heart = Duration(milliseconds: 600); // heart break
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card(AppColors c) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 18,
      offset: const Offset(0, 4),
      spreadRadius: -8,
    ),
  ];
}
