import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The signature Aura gradient + glow. One source, used everywhere
/// (Aura values, progress fills, FAB). See commands/03_design_system.md §3.2.
class AppGradients {
  const AppGradients._();

  /// violet -> pink, 135deg in CSS ≈ topLeft -> bottomRight.
  static LinearGradient aura(AppColors c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [c.accent1, c.accent2],
  );

  /// Outer glow behind Aura numbers, progress fills, the FAB.
  /// [intensity] 0..1 mirrors the prototype's --glow (default 0.5).
  static List<BoxShadow> glow(
    AppColors c, {
    double intensity = 0.5,
    double blur = 18,
  }) => [
    BoxShadow(
      color: c.accentSolid.withValues(alpha: 0.9 * intensity),
      blurRadius: blur,
    ),
  ];
}
