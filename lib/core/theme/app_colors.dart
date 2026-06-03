import 'package:flutter/material.dart';

/// Color tokens, resolved from `Theme.of(context).extension<AppColors>()!`.
///
/// Dark is the primary palette; light is a token swap. Values lifted from the
/// prototype's `styles.css` (see commands/03_design_system.md).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Neutrals
  final Color bg; // app background
  final Color bg2; // recessed background
  final Color surface; // card
  final Color surface2; // elevated / input
  final Color surface3; // track / chip rest
  final Color border; // hairline
  final Color borderStrong;
  final Color text; // primary
  final Color textDim; // secondary
  final Color textFaint; // tertiary / disabled

  // Brand
  final Color accent1; // gradient start (violet)
  final Color accent2; // gradient end (pink)
  final Color accentSolid; // single-color accent (gradient midpoint)
  final Color accentSoft; // ~16% tint for fills

  // Semantic
  final Color heart;
  final Color success;
  final Color warning;

  const AppColors({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textDim,
    required this.textFaint,
    required this.accent1,
    required this.accent2,
    required this.accentSolid,
    required this.accentSoft,
    required this.heart,
    required this.success,
    required this.warning,
  });

  // ---- DARK (primary) ----
  static const dark = AppColors(
    bg: Color(0xFF08080B),
    bg2: Color(0xFF0C0C11),
    surface: Color(0xFF121218),
    surface2: Color(0xFF1A1A22),
    surface3: Color(0xFF22222C),
    border: Color(0x12FFFFFF), // white @ ~7%
    borderStrong: Color(0x1FFFFFFF), // white @ ~12%
    text: Color(0xFFF5F5F8),
    textDim: Color(0xFF9C9CAA),
    textFaint: Color(0xFF62626F),
    accent1: Color(0xFFA855F7),
    accent2: Color(0xFFEC4899),
    accentSolid: Color(0xFFC45CEE),
    accentSoft: Color(0x29C45CEE), // ~16%
    heart: Color(0xFFFF4D5E),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
  );

  // ---- LIGHT (variant) ----
  static const light = AppColors(
    bg: Color(0xFFEEEEF2),
    bg2: Color(0xFFE7E7EE),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF4F4F7),
    surface3: Color(0xFFECECF1),
    border: Color(0x140A0A14), // near-black @ ~8%
    borderStrong: Color(0x240A0A14), // ~14%
    text: Color(0xFF14141A),
    textDim: Color(0xFF5C5C6A),
    textFaint: Color(0xFF9595A4),
    accent1: Color(0xFFA855F7),
    accent2: Color(0xFFEC4899),
    accentSolid: Color(0xFFC45CEE),
    accentSoft: Color(0x29C45CEE),
    heart: Color(0xFFFF4D5E),
    success: Color(0xFF1F9D6B), // darker for contrast on white
    warning: Color(0xFFD9920A),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? bg2,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? textDim,
    Color? textFaint,
    Color? accent1,
    Color? accent2,
    Color? accentSolid,
    Color? accentSoft,
    Color? heart,
    Color? success,
    Color? warning,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      bg2: bg2 ?? this.bg2,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text: text ?? this.text,
      textDim: textDim ?? this.textDim,
      textFaint: textFaint ?? this.textFaint,
      accent1: accent1 ?? this.accent1,
      accent2: accent2 ?? this.accent2,
      accentSolid: accentSolid ?? this.accentSolid,
      accentSoft: accentSoft ?? this.accentSoft,
      heart: heart ?? this.heart,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accent1: Color.lerp(accent1, other.accent1, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      accentSolid: Color.lerp(accentSolid, other.accentSolid, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      heart: Color.lerp(heart, other.heart, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
