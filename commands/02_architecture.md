# 02 · Architecture

## State management

**Riverpod** (`flutter_riverpod`). It's the lowest‑ceremony option that scales: providers for the
seed repository, `StateNotifier`/`Notifier` for mutable UI (award flow draft, duty checklist,
notification settings, theme/locale).

If the team prefers another approach, the only hard requirements are:
- Theme mode + locale are **app‑global and persisted** (`shared_preferences`).
- The Award flow holds a **draft object** across its 4 steps.
- Duty checklist, leaderboard filter, and notification toggles are **local mutable state**.

---

## Folder structure

```
lib/
├── main.dart                       # runApp(ProviderScope(child: AuraApp()))
├── app.dart                        # AuraApp: MaterialApp.router + theme + locale wiring
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart         # Color tokens (dark + light)
│   │   ├── app_typography.dart     # TextTheme + Aura/numeric styles
│   │   ├── app_spacing.dart        # spacing, radii, durations
│   │   ├── app_gradients.dart      # the Aura gradient + glow helpers
│   │   └── app_theme.dart          # ThemeData dark/light from the tokens
│   ├── router/
│   │   └── app_router.dart         # GoRouter: ShellRoute (tabs) + pushed routes
│   └── l10n/                       # generated localizations land here
│
├── data/
│   ├── models/
│   │   ├── person.dart
│   │   ├── aura_entry.dart
│   │   ├── duty_day.dart
│   │   ├── knowledge_doc.dart
│   │   └── enums.dart              # Role, AuraCategory
│   ├── seed/
│   │   └── seed_data.dart          # the mock people / history / duty / docs
│   └── providers/
│       ├── people_providers.dart
│       ├── leaderboard_provider.dart
│       ├── duty_provider.dart
│       ├── award_draft_provider.dart
│       └── settings_providers.dart # themeMode, locale, notif prefs (persisted)
│
├── widgets/                        # shared, screen-agnostic (see 04_widgets.md)
│   ├── app_card.dart
│   ├── aura_value.dart
│   ├── avatar.dart
│   ├── role_badge.dart
│   ├── hearts_row.dart
│   ├── category_chip.dart
│   ├── aura_progress_bar.dart
│   ├── app_switch.dart
│   ├── segmented_control.dart
│   └── linear_link_chip.dart
│
└── features/                       # one folder per screen/flow
    ├── shell/                      # the bottom-tab scaffold + FAB
    │   └── app_shell.dart
    ├── home/
    │   └── home_screen.dart
    ├── leaderboard/
    │   ├── leaderboard_screen.dart
    │   └── widgets/podium.dart
    ├── profile/
    │   ├── profile_screen.dart
    │   └── widgets/history_row.dart
    ├── award/
    │   ├── award_screen.dart       # the 4-step flow host
    │   └── steps/...               # pick_intern, pick_category, set_points, confirm
    ├── duty/
    │   ├── duty_screen.dart
    │   └── widgets/week_strip.dart
    ├── knowledge/
    │   ├── knowledge_screen.dart
    │   └── article_screen.dart
    └── settings/
        └── settings_screen.dart
```

**Rule of thumb:** anything used by ≥2 features lives in `widgets/`. Anything specific to one
screen lives under that feature's `widgets/`.

---

## Navigation

`go_router` with a `StatefulShellRoute` so each tab keeps its own navigation stack and scroll
position.

```dart
// core/router/app_router.dart (shape, not final)
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (ctx, state, shell) => AppShell(shell: shell),   // custom bottom bar + FAB
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/home',        builder: ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/leaderboard', builder: ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/duty',        builder: ...)]),
        StatefulShellBranch(routes: [GoRoute(path: '/knowledge',   builder: ...,
          routes: [GoRoute(path: 'article/:id', builder: ...)])]),  // article nested
        StatefulShellBranch(routes: [GoRoute(path: '/profile',     builder: ...,
          routes: [GoRoute(path: ':id', builder: ...)])]),          // other-user profile
      ],
    ),
    // Full-screen pushed routes (cover the tab bar):
    GoRoute(path: '/award',    pageBuilder: _slideUp,    builder: ...),  // optional ?internId=
    GoRoute(path: '/settings', pageBuilder: _slideRight, builder: ...),
  ],
);
```

- **Award & Settings** push over everything (the prototype slides them in from the right; Award
  could also be a bottom sheet — match the prototype's right‑slide for parity).
- **Article** is nested under Knowledge so back returns to the doc list.
- **Tapping a leaderboard row / podium / duty day** pushes `/profile/:id`.

### Custom bottom bar
Do **not** use `BottomNavigationBar` / `NavigationBar` defaults — they bring Material tint and
ripple. Build a `Row` of 5 `_TabButton`s inside a `Container` with:
- height ~84, top hairline border (`AppColors.border`),
- a translucent blurred background (`BackdropFilter` + `bg @ 80% opacity`),
- active tab: icon tinted with `AppColors.accentSolid` + glow, label `text`; inactive: `textFaint`.

The **FAB** (Award Aura) is a 60×60 rounded‑20 gradient square, only on Home, bottom‑right above
the tab bar. Tapping it pushes `/award`.

---

## Theming & persistence

```dart
// settings_providers.dart
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(...); // persisted
final localeProvider    = NotifierProvider<LocaleNotifier, Locale>(...);       // persisted

// app.dart
MaterialApp.router(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ref.watch(themeModeProvider),   // default ThemeMode.dark
  locale: ref.watch(localeProvider),
  supportedLocales: const [Locale('en'), Locale('ru')],
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  routerConfig: router,
);
```

Default `themeMode` is **dark**. The Settings screen and (optionally) a debug menu flip it.

---

## Conventions

- **No magic numbers.** Colors → `AppColors`, gaps/radii → `AppSpacing`, durations → `AppDurations`.
- **Const everything** that can be const; it's a list‑heavy app.
- **One widget = one file** for anything non‑trivial.
- Use `intl` `NumberFormat.decimalPattern()` for Aura values (`1,840`) and `DateFormat` for dates.
- Prefer composition over deep widget trees; pull repeated row layouts into small private widgets.
