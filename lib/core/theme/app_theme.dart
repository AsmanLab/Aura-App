import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Wires the tokens into a [ThemeData] whose only real job is to host the
/// [AppColors] extension, set the background + default font, and kill Material
/// chrome (ripples, tints). See commands/03 §3.5.
class AppTheme {
  const AppTheme._();

  static ThemeData _base(AppColors c, Brightness b) {
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: c.bg,
      splashFactory: NoSplash.splashFactory, // no Material ripple
      highlightColor: Colors.transparent,
      textTheme: GoogleFonts.manropeTextTheme(
        ThemeData(brightness: b).textTheme,
      ).apply(bodyColor: c.text, displayColor: c.text),
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accentSolid,
        brightness: b,
        surface: c.surface,
      ),
      extensions: [c],
    );
  }

  static ThemeData get dark => _base(AppColors.dark, Brightness.dark);
  static ThemeData get light => _base(AppColors.light, Brightness.light);
}
