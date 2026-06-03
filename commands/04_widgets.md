# 04 · Widgets

The reusable building blocks, in build order (Stage 2). Each lists **props**, **prototype
source**, and a **Dart skeleton**. Render every one in the Style Gallery and diff against
`Aura.html` in both themes.

Convention in all skeletons: `final c = Theme.of(context).extension<AppColors>()!;`

---

## 4.1 `AppCard`
The base surface. Prototype: `.card` (radius 22, `surface` bg, hairline border, soft shadow).

```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;          // default EdgeInsets.all(AppSpacing.screenPad)
  final VoidCallback? onTap;
  final Color? color;                // override surface
  final Border? border;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20),
    this.onTap, this.color, this.border});

  @override Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(AppSpacing.rCard),
        border: border ?? Border.all(color: c.border),
        boxShadow: AppShadows.card(c),
      ),
      child: child,
    );
    return onTap == null ? card
      : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}
```
Variants: `AppCard.flush` (padding zero, `clipBehavior: antiAlias` for list rows).

---

## 4.2 `AuraValue` ★ (the glow number)
Prototype: `.aura-val` — gradient‑filled numerals + outer glow, optional "AURA" unit.

- Number in **Space Grotesk**, gradient via `ShaderMask`.
- Glow via a blurred duplicate behind.
- Unit ("AURA") is Manrope, `textDim`, ~0.3× the number size, uppercase, baseline‑aligned.

```dart
class AuraValue extends StatelessWidget {
  final int value;
  final double size;        // number font size (Home/Profile ≈ 56–64)
  final bool showUnit;
  final double glow;        // 0..1, default 0.5
  const AuraValue(this.value, {super.key, this.size = 64, this.showUnit = true, this.glow = .5});

  @override Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final text = NumberFormat.decimalPattern().format(value);   // 1,840
    final numStyle = GoogleFonts.spaceGrotesk(
      fontSize: size, fontWeight: FontWeight.w600, height: .95, letterSpacing: -0.03 * size);

    final gradientNumber = ShaderMask(
      shaderCallback: (r) => AppGradients.aura(c).createShader(r),
      blendMode: BlendMode.srcIn,
      child: Text(text, style: numStyle.copyWith(color: Colors.white)),
    );

    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic, children: [
        Stack(children: [
          // glow underlay
          Positioned.fill(child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 12 * glow, sigmaY: 12 * glow),
            child: Text(text, style: numStyle.copyWith(color: c.accentSolid.withOpacity(.8 * glow))),
          )),
          gradientNumber,
        ]),
        if (showUnit) ...[
          const SizedBox(width: 8),
          Text('AURA', style: GoogleFonts.manrope(
            fontSize: size * .3, fontWeight: FontWeight.w700, color: c.textDim, letterSpacing: 1)),
        ],
      ]);
  }
}
```

### `AuraPoints` (inline ±N)
The `+40` / `−15` in history & award. Gradient for positive; **solid warm red** (`#FF7A88`) for
negative (no gradient, no glow).

```dart
class AuraPoints extends StatelessWidget {  // "+40" / "−15"
  final int pts; final double size;
  // pts >= 0 → gradient ShaderMask on "+$pts"; pts < 0 → Text("$pts", color: Color(0xFFFF7A88))
}
```

---

## 4.3 `Avatar`
Prototype: initials on a deterministic gradient; optional gradient ring.

- No photos in MVP → initials. Gradient chosen by hashing `person.id` into a fixed 12‑entry list.
- `ring: true` draws a 3px gradient ring (Profile, podium #1, "you" rows).

```dart
const _avatarGrads = <List<Color>>[
  [Color(0xFF8B5CF6), Color(0xFF22D3EE)], [Color(0xFFF472B6), Color(0xFFA855F7)],
  [Color(0xFF34D399), Color(0xFF06B6D4)], [Color(0xFFFBBF24), Color(0xFFFB7185)],
  [Color(0xFF60A5FA), Color(0xFF818CF8)], [Color(0xFFF59E0B), Color(0xFFEF4444)],
  [Color(0xFF2DD4BF), Color(0xFF3B82F6)], [Color(0xFFC084FC), Color(0xFFEC4899)],
  [Color(0xFF4ADE80), Color(0xFF22D3EE)], [Color(0xFFFB923C), Color(0xFFF43F5E)],
  [Color(0xFFA78BFA), Color(0xFF38BDF8)], [Color(0xFFF0ABFC), Color(0xFF6366F1)],
];
List<Color> gradFor(String id) {
  var h = 0; for (final r in id.codeUnits) { h = (h * 31 + r) & 0x7fffffff; }
  return _avatarGrads[h % _avatarGrads.length];
}
String initials(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  return ((p.isNotEmpty ? p[0][0] : '') + (p.length > 1 ? p[1][0] : '')).toUpperCase();
}

class Avatar extends StatelessWidget {
  final Person person; final double size; final bool ring;
  // Container(size) with LinearGradient(gradFor(id)), centered initials (Manrope 700, .38*size).
  // if ring: wrap in a gradient-bordered circle (3px) via nested Containers / CustomPaint.
}
```

---

## 4.4 `HeartsRow` ★ (the emotional one)
Prototype: 8 hearts, filled = `heart` red + glow, empty = outlined `textFaint`. **Interactive
variant animates loss** (see `06_screens.md` for the full break sequence).

Static spec:
- 8 heart glyphs in a `Row` with 7px gaps, each ~22–26 dp.
- Filled: solid `c.heart` with a soft red glow shadow. Empty: 1.6px stroke, no fill.
- Build the heart with a `CustomPainter` (path below) or a bundled SVG via `flutter_svg`.

```dart
// Heart path (viewBox 0 0 24 24) — reuse the prototype's:
// M12 21s-7.5-4.7-10-9.3C.4 8.3 2 4.5 5.6 4.5c2 0 3.4 1.1 4.4 2.6 1-1.5 2.4-2.6 4.4-2.6
//   C18 4.5 19.6 8.3 18 11.7 15.5 16.3 12 21 12 21Z
class HeartsRow extends StatefulWidget {
  final int count;            // filled hearts (0..max)
  final int max;              // 8
  final double size;
  final bool interactive;     // tap → animate losing the last filled heart (demo)
  final VoidCallback? onLose;
}
```

Filled glow: `BoxShadow(color: c.heart.withOpacity(.55), blurRadius: 6)`.

---

## 4.5 `RoleBadge`
Prototype: pill with a colored dot + label, tinted by role.

```dart
class RoleBadge extends StatelessWidget {
  final Role role;
  // Pill: padding (3,9,3,7), radius 999, bg role.tint(12%), text role.color w700 11.5,
  // leading 6dp dot in role.color. Label from l10n (role.label / role.labelRu).
}
```
Role colors: Intern `#22D3EE`, Full‑time `#818CF8`, Mentor `#C084FC`, Admin `#FBBF24`.

---

## 4.6 `CategoryChip` & `CategoryTag`
Prototype: `.chip` (selectable, used in Award) and `.cat-tag` (static, used in history).

- **CategoryChip** (selectable): rest = `surface2` bg, `textDim`, category icon in category color.
  Selected = filled with the **category color gradient**, dark text, subtle glow ring.
- **CategoryTag** (static): a 22dp rounded icon tile (category color @ 13%) + category‑color
  label, used in history rows.

```dart
class CategoryChip extends StatelessWidget {
  final AuraCategory cat; final bool selected; final VoidCallback onTap;
}
class CategoryTag extends StatelessWidget {     // non-interactive
  final AuraCategory cat;
}
```
Category → {icon, color} lives on the `AuraCategory` enum (`05_data_models.md`).

---

## 4.7 `AuraProgressBar`
Prototype: `.progress` track + gradient fill with glow. Used for trial progress.

```dart
class AuraProgressBar extends StatelessWidget {
  final double pct;   // 0..100
  // height 10, radius 999, track c.surface3.
  // fill: AnimatedContainer(width = pct%) with AppGradients.aura + AppGradients.glow.
}
```
Animate width on first build (`med` duration, easeOutCubic) so it "fills in".

---

## 4.8 `AppSwitch`
Prototype: custom 48×28 pill toggle — **do not use Material `Switch`**.

```dart
class AppSwitch extends StatelessWidget {
  final bool value; final ValueChanged<bool> onChanged;
  // Track 48×28 radius 999: off = c.surface3 + border; on = AppGradients.aura.
  // Knob 22dp white circle, AnimatedAlign left↔right (spring-ish: easeOutBack), shadow.
}
```

---

## 4.9 `SegmentedControl`
Prototype: animated pill segmented (Leaderboard filter, Settings language).

```dart
class SegmentedControl<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T value; final ValueChanged<T> onChanged;
  // Container(surface2, radius 999, padding 4). Stack:
  //   - AnimatedPositioned gradient "pill" under the active segment (med, easeOutCubic),
  //   - Row of Expanded buttons; active label white, inactive textDim.
}
```
Measure segment width with `LayoutBuilder` (equal widths) → animate `left`.

---

## 4.10 `LinearLinkChip`
Prototype: a small mono pill `APRD‑512` with the Linear glyph. Static in MVP (tap → no‑op or
`url_launcher` later).

```dart
class LinearLinkChip extends StatelessWidget {
  final String id;   // "APRD-512"
  // surface2 pill, radius 7, Space Grotesk 11.5 w700 textDim, leading 11dp Linear mark.
}
```

---

## 4.11 Icons
The prototype uses a custom stroke icon set. Two clean options:

- **`flutter_svg`** + the SVG paths from `aura/icons.jsx` (1:1 fidelity), or
- **Phosphor Icons** (`phosphor_flutter`) — the stroke weight/feel matches closely. Mapping:
  home→`house`, trophy→`trophy`, shield→`shieldCheck`, book→`bookOpen`, user→`user`,
  bell→`bell`, gear→`gear`, spark→`sparkle`, bolt→`lightning`, rocket→`rocketLaunch`,
  hands→`handsClapping`, gauge→`gauge`, fire→`fire`, calendar→`calendarBlank`, flag→`flag`,
  link→`link`, clock→`clock`, check→`check`.

Pick one approach and stay consistent. Default icon size 24, stroke ~2.

---

### Style Gallery checklist (end of Stage 2)
- [ ] All widgets render in **dark and light**.
- [ ] `AuraValue` glow + gradient reads identical to the prototype.
- [ ] Hearts: 8 across, filled glow + empty outline correct.
- [ ] No Material ripple/tint anywhere (switch, chips, cards).
- [ ] Numbers use Space Grotesk; everything else Manrope; Cyrillic renders in Manrope.
