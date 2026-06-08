# styles.md — Coding & Design Style Guide

The canonical style rules for this repo. **Follow these by default in every change.** Visual
detail lives in [`03_design_system.md`](03_design_system.md); architecture in
[`02_architecture.md`](02_architecture.md); per-feature setup in [`08_feature_setup.md`](08_feature_setup.md).

---

## 1. Golden rules

- **No magic numbers.** Colors → `AppColors`, gaps/radii → `AppSpacing`, durations →
  `AppDurations`, gradients/glow → `AppGradients`, text → `AppType`.
- **No Material chrome.** No default `Switch`, `NavigationBar`, ripple, or elevation tint. Theme
  kills splash (`NoSplash`); use the custom widgets in `core/widgets/`.
- **Reuse core widgets** before building new ones (see §5). Anything used by ≥2 features lives in
  `core/widgets/`, not a feature folder.
- **`const` everything** that can be const — it's a list-heavy app.
- **One widget = one file** for anything non-trivial. Pull repeated row layouts into small private
  widgets.
- **`package:` imports** for cross-layer/cross-feature; relative only for same-folder siblings.
- **`.withValues(alpha:)`**, never deprecated `.withOpacity`. Prefer `surfaceContainerHighest`
  over deprecated `surfaceVariant`.
- **Guard `context` across async gaps** — check `mounted` (State) / `context.mounted` after every
  `await` before using `context`, `Theme.of`, `Navigator.of`, `ScaffoldMessenger.of`, etc.
- Run `flutter analyze` — keep it clean.

---

## 2. Theme tokens — how to access

```dart
final c = Theme.of(context).extension<AppColors>()!;   // colors
Container(color: c.surface, ...);
Text('Hi', style: AppType.h1(c));                       // typography
SizedBox(height: AppSpacing.s4);                        // spacing
```

Tokens live in `core/theme/`. **Dark + light both supported; light is the default** (`ThemeCubit`).
Never hard-code a hex or a raw double in a widget.

### Colors — `AppColors` (`core/theme/app_colors.dart`)
Neutrals: `bg`, `bg2`, `surface`, `surface2`, `surface3`, `border`, `borderStrong`, `text`,
`textDim`, `textFaint`. Brand: `accent1` (violet), `accent2` (pink), `accentSolid`, `accentSoft`.
Semantic: `heart`, `success`, `warning`. Role/category colors live on the `Role`/`AuraCategory`
enums, not here.

### Typography — `AppType` (`core/theme/app_typography.dart`)
`display` (Space Grotesk 64) · `h1` 27 · `h2` 21 · `h3` 17 · `body` 15 · `bodyStrong` · `bodyDim`
· `sm` 13 · `label` (uppercase, tracked) · `number(size, c)` (Space Grotesk numerals).
**Manrope** for all text (Cyrillic-safe); **Space Grotesk** for numerals only (Aura values, ranks,
dates, points).

### Spacing / radii / durations — `AppSpacing` (`core/theme/app_spacing.dart`)
4-based: `s1`=4 … `s8`=40. Screen pad `screenPad`=20. Radii: `rSm`=14, `rCard`=22, `rLg`=30,
`rChip`=999. `AppDurations`: `fast` 150 · `med` 280 · `slow` 500 · `heart` 600. `AppShadows.card(c)`.

### Gradient & glow — `AppGradients` (`core/theme/app_gradients.dart`)
`AppGradients.aura(c)` = violet→pink (topLeft→bottomRight). `AppGradients.glow(c)` = outer glow.
One signature gradient, used everywhere (Aura numbers, progress fills, FAB).

> ⚠️ Blur is expensive. `BackdropFilter` / `ImageFiltered` / glow shadows force a per-frame
> `saveLayer`. Use sparingly; don't stack many on one screen.

---

## 3. Naming

| Thing | Pattern | Example |
|-------|---------|---------|
| Entity | noun | `Person` |
| Model | `<Entity>Model` | `UserModel` |
| Repo interface / impl | `<X>Repository` / `<X>RepositoryImpl` / `Seed<X>Repository` | `PeopleRepository` |
| Data source | `<X>RemoteDataSource` / `...LocalDataSource` | `AuthRemoteDataSource` |
| Use case | verb phrase | `GetStreak` |
| Cubit / Bloc | `<X>Cubit` / `<X>Bloc` (+ `<X>State`/`<X>Event`) | `LeaderboardCubit` |
| Page (spec) / Screen (legacy) | `<X>Page` / `<X>Screen` | `HomePage`, `HomeScreen` |

---

## 4. Architecture & state (BLoC)

- Layers per feature: `data` · `domain` · `presentation`. Dependencies point inward
  (`presentation → domain ← data`). `domain` is pure Dart (no Flutter/Firebase/BLoC).
- **BLoC** for state: `Cubit` for simple (loads, toggles, filters), `Bloc` for event-driven flows.
  States immutable + `Equatable`; emit new instances via `copyWith`.
- **DI** via `get_it` (`core/di/injection.dart`): repos/use cases `lazySingleton`, blocs `factory`.
  Provide blocs at the route with `BlocProvider(create: (_) => sl<X>())`; app-global cubits
  (`ThemeCubit`, `LocaleCubit` in `core/settings/`) via `BlocProvider.value` above `MaterialApp`.
- Common/shared code → `core/` (`core/widgets`, `core/domain`, `core/models`, `core/data`,
  `core/theme`, `core/router`, `core/di`, `core/settings`, `core/shell`). Feature-specific →
  `features/<x>/`.

---

## 5. Reusable widgets — `core/widgets/`

Prefer these over raw Material:

| Widget | Use |
|--------|-----|
| `AppCard` / `AppCard.flush` | base surface (radius 22, hairline, shadow); flush = list rows |
| `AuraValue` / `AuraPoints` | gradient glow number / inline ±N |
| `Avatar` | initials on deterministic gradient, optional ring (`id` + `name`) |
| `RoleBadge` | role pill (dot + tinted label) |
| `HeartsRow` | 8 hearts; `interactive` plays heart-loss (punch + pulse + haptic) |
| `CategoryChip` / `CategoryTag` | selectable chip / static tag |
| `AuraProgressBar` | animated gradient fill |
| `AppSwitch` | custom 48×28 pill (not Material `Switch`) |
| `SegmentedControl<T>` | animated pill segmented |
| `LinearLinkChip` | mono `APRD-512` pill |
| `SectionLabel` | uppercase section header |
| `HistoryRow` | Aura history entry |

---

## 6. Localization

EN + RU. Entities carry `*Ru` fields (roles, categories, notif prefs). `LocaleCubit` toggles;
`GlobalMaterialLocalizations.delegates` wired. Never hard-pack text into fixed widths — RU strings
run ~1.4× longer; use `TextOverflow.ellipsis` / flexible layouts.
