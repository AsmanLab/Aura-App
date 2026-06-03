# 03 · Design System → Flutter

Every value here is lifted directly from the prototype's `aura/styles.css`. Build these four
files in Stage 1, then never write a raw hex/number in a widget again.

---

## 3.1 Colors — `core/theme/app_colors.dart`

Aura ships **two palettes** (dark = primary, light = variant). Model them as an
`AppColors` object resolved from `Theme.of(context)` so widgets stay theme‑agnostic.

```dart
import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  // Neutrals
  final Color bg;          // app background
  final Color bg2;         // recessed background
  final Color surface;     // card
  final Color surface2;    // elevated / input
  final Color surface3;    // track / chip rest
  final Color border;      // hairline
  final Color borderStrong;
  final Color text;        // primary
  final Color textDim;     // secondary
  final Color textFaint;   // tertiary / disabled

  // Brand
  final Color accent1;     // gradient start (violet)
  final Color accent2;     // gradient end (pink)
  final Color accentSolid; // single-color accent (gradient midpoint)
  final Color accentSoft;  // 16% tint for fills

  // Semantic
  final Color heart;       // #FF4D5E
  final Color success;     // #34D399  (on-duty "live", done states)
  final Color warning;     // #FBBF24

  const AppColors({ ...all fields... });

  // ---- DARK (primary) ----
  static const dark = AppColors(
    bg:           Color(0xFF08080B),
    bg2:          Color(0xFF0C0C11),
    surface:      Color(0xFF121218),
    surface2:     Color(0xFF1A1A22),
    surface3:     Color(0xFF22222C),
    border:       Color(0x12FFFFFF),   // white @ ~7%
    borderStrong: Color(0x1FFFFFFF),   // white @ ~12%
    text:         Color(0xFFF5F5F8),
    textDim:      Color(0xFF9C9CAA),
    textFaint:    Color(0xFF62626F),
    accent1:      Color(0xFFA855F7),
    accent2:      Color(0xFFEC4899),
    accentSolid:  Color(0xFFC45CEE),
    accentSoft:   Color(0x29C45CEE),   // ~16%
    heart:        Color(0xFFFF4D5E),
    success:      Color(0xFF34D399),
    warning:      Color(0xFFFBBF24),
  );

  // ---- LIGHT (variant) ----
  static const light = AppColors(
    bg:           Color(0xFFEEEEF2),
    bg2:          Color(0xFFE7E7EE),
    surface:      Color(0xFFFFFFFF),
    surface2:     Color(0xFFF4F4F7),
    surface3:     Color(0xFFECECF1),
    border:       Color(0x140A0A14),   // near-black @ ~8%
    borderStrong: Color(0x240A0A14),   // ~14%
    text:         Color(0xFF14141A),
    textDim:      Color(0xFF5C5C6A),
    textFaint:    Color(0xFF9595A4),
    accent1:      Color(0xFFA855F7),
    accent2:      Color(0xFFEC4899),
    accentSolid:  Color(0xFFC45CEE),
    accentSoft:   Color(0x29C45CEE),
    heart:        Color(0xFFFF4D5E),
    success:      Color(0xFF1F9D6B),   // slightly darker for contrast on white
    warning:      Color(0xFFD9920A),
  );

  @override AppColors copyWith({ ... }) => ...;
  @override AppColors lerp(ThemeExtension<AppColors>? o, double t) => ...; // lerp every Color
}
```

Access in widgets:

```dart
final c = Theme.of(context).extension<AppColors>()!;
Container(color: c.surface, ...);
```

> **Role & category colors** are constants (they don't change per theme). Put them on the
> `Role` / `AuraCategory` enums (see `05_data_models.md`) — e.g. `Role.intern.color`.

---

## 3.2 The Aura gradient & glow — `core/theme/app_gradients.dart`

The signature element. One source, used everywhere.

```dart
class AppGradients {
  static LinearGradient aura(AppColors c) => LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [c.accent1, c.accent2],     // 135deg in CSS ≈ topLeft→bottomRight
  );

  /// Outer glow used behind Aura numbers, progress fills, the FAB.
  /// `intensity` 0..1 mirrors the prototype's --glow (default 0.5).
  static List<BoxShadow> glow(AppColors c, {double intensity = 0.5, double blur = 18}) => [
    BoxShadow(
      color: c.accentSolid.withOpacity(0.9 * intensity),
      blurRadius: blur,
      spreadRadius: 0,
    ),
  ];
}
```

- **Gradient text** (the big Aura number): paint the gradient through the glyphs with a
  `ShaderMask` — see `AuraValue` in `04_widgets.md`.
- **Glow on text:** Flutter can't drop‑shadow a `ShaderMask` cleanly; emulate with a blurred
  duplicate behind it, or a `Stack` with a `BackdropFilter`‑free blurred `Text` underlay. The
  `AuraValue` widget encapsulates this.
- **Glow orbs** (the soft blurred blobs behind status cards): a positioned `Container` with the
  gradient + `ImageFiltered(blur 46)`, low opacity, `IgnorePointer`.

---

## 3.3 Typography — `core/theme/app_typography.dart`

Two families. **Manrope** for everything textual (Cyrillic‑safe). **Space Grotesk** for numerals
only (Aura values, ranks, dates, points).

| Token | Family | Size (dp) | Weight | Used for |
|-------|--------|-----------|--------|----------|
| `display` | SpaceGrotesk | 64 | 600 | Big Aura number (Profile/Home), award points |
| `h1` | Manrope | 27 | 800 | Screen titles ("Hi, Aibek", "Leaderboard") |
| `h2` | Manrope | 21 | 800 | Card/section headlines, article H1 |
| `h3` | Manrope | 17 | 700 | Names, row titles |
| `body` | Manrope | 15 | 500 | Body copy, list text |
| `bodyStrong` | Manrope | 15 | 700 | Emphasised body |
| `sm` | Manrope | 13 | 500/600 | Meta, positions, secondary |
| `xs` | Manrope | 11.5 | 700 | Section labels (UPPERCASE, +0.08em tracking), badges |
| `num` | SpaceGrotesk | varies | 600 | Inline numerals: ranks, +points, dates |

```dart
class AppType {
  static TextStyle _m(double size, FontWeight w, Color c, {double ls = -0.01}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: w, color: c, letterSpacing: size * ls);
  static TextStyle _g(double size, FontWeight w, Color c) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: w, color: c, letterSpacing: -0.03 * size);

  static TextStyle h1(AppColors c)        => _m(27, FontWeight.w800, c.text, ls: -0.03);
  static TextStyle h2(AppColors c)        => _m(21, FontWeight.w800, c.text);
  static TextStyle h3(AppColors c)        => _m(17, FontWeight.w700, c.text);
  static TextStyle body(AppColors c)      => _m(15, FontWeight.w500, c.text);
  static TextStyle bodyDim(AppColors c)   => _m(15, FontWeight.w500, c.textDim);
  static TextStyle sm(AppColors c)        => _m(13, FontWeight.w600, c.textDim);
  static TextStyle label(AppColors c)     => _m(11.5, FontWeight.w700, c.textFaint)
                                                .copyWith(letterSpacing: 0.9, height: 1);
  static TextStyle number(double size, AppColors c) => _g(size, FontWeight.w600, c.text);
}
```

> Section labels in the prototype are uppercase with wide tracking — uppercase the **string**
> (or use `text.toUpperCase()`), don't rely on a CSS transform.

---

## 3.4 Spacing, radii, durations — `core/theme/app_spacing.dart`

```dart
class AppSpacing {
  // 4-based rhythm
  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0,
               s5 = 20.0, s6 = 24.0, s7 = 32.0, s8 = 40.0;

  // Screen horizontal padding (the prototype's --pad). Density-aware:
  static const padCompact = 16.0, padRegular = 18.0, padComfy = 20.0;
  static const screenPad = padComfy;          // default

  // Radii  (prototype --r-base = 22)
  static const rCard = 22.0;
  static const rLg   = 30.0;                   // big surfaces
  static const rSm   = 14.0;                   // buttons, inputs
  static const rChip = 999.0;                  // pills, segmented, avatars
}

class AppDurations {
  static const fast   = Duration(milliseconds: 150);
  static const med    = Duration(milliseconds: 280);   // segmented pill, push routes
  static const slow   = Duration(milliseconds: 500);   // card entrance
  static const heart  = Duration(milliseconds: 600);   // heart break
}

class AppShadows {
  static List<BoxShadow> card(AppColors c) => [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 18,
              offset: const Offset(0, 4), spreadRadius: -8),
  ];
}
```

---

## 3.5 `ThemeData` — `core/theme/app_theme.dart`

Wire the tokens into a `ThemeData` whose **only** real job is to host the `AppColors` extension,
set the scaffold background, the default font, and **kill Material chrome** (ripples, tints).

```dart
class AppTheme {
  static ThemeData _base(AppColors c, Brightness b) {
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: c.bg,
      splashFactory: NoSplash.splashFactory,           // no Material ripple
      highlightColor: Colors.transparent,
      textTheme: GoogleFonts.manropeTextTheme().apply(
        bodyColor: c.text, displayColor: c.text,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accentSolid, brightness: b,
        surface: c.surface, background: c.bg,
      ),
      extensions: [c],
    );
  }
  static ThemeData get dark  => _base(AppColors.dark,  Brightness.dark);
  static ThemeData get light => _base(AppColors.light, Brightness.light);
}
```

> Keep the **density / glow / roundness / accent** knobs from the prototype's Tweaks panel out of
> production unless product wants them. If they do, promote them to a `settings_provider` that
> overrides `AppColors.copyWith` / `AppSpacing` at runtime — the architecture already supports it.
