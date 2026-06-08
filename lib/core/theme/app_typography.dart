import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Two families: **Manrope** for all text (Cyrillic-safe), **Space Grotesk**
/// for numerals only (Aura values, ranks, dates, points). See commands/03 §3.3.
class AppType {
  const AppType._();

  static TextStyle _m(
    double size,
    FontWeight w,
    Color c, {
    double ls = -0.01,
  }) => TextStyle(fontFamily: 'Manrope', 
    fontSize: size,
    fontWeight: w,
    color: c,
    letterSpacing: size * ls,
  );

  static TextStyle _g(double size, FontWeight w, Color c) =>
      TextStyle(fontFamily: 'SpaceGrotesk', 
        fontSize: size,
        fontWeight: w,
        color: c,
        letterSpacing: -0.03 * size,
      );

  static TextStyle display(AppColors c) => _g(64, FontWeight.w600, c.text);
  static TextStyle h1(AppColors c) => _m(27, FontWeight.w800, c.text, ls: -0.03);
  static TextStyle h2(AppColors c) => _m(21, FontWeight.w800, c.text);
  static TextStyle h3(AppColors c) => _m(17, FontWeight.w700, c.text);
  static TextStyle body(AppColors c) => _m(15, FontWeight.w500, c.text);
  static TextStyle bodyStrong(AppColors c) => _m(15, FontWeight.w700, c.text);
  static TextStyle bodyDim(AppColors c) => _m(15, FontWeight.w500, c.textDim);
  static TextStyle sm(AppColors c) => _m(13, FontWeight.w600, c.textDim);
  static TextStyle label(AppColors c) => _m(
    11.5,
    FontWeight.w700,
    c.textFaint,
  ).copyWith(letterSpacing: 0.9, height: 1);

  /// Inline numerals (ranks, +points, dates) in Space Grotesk.
  static TextStyle number(double size, AppColors c) =>
      _g(size, FontWeight.w600, c.text);
}
