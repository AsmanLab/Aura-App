# 02 · Architecture

## State management

**BLoC** (`flutter_bloc`). Each feature owns one or more `Bloc`/`Cubit`s in its
`presentation/bloc/` folder. Use `Cubit` for simple state (theme, locale, filters, toggles) and
`Bloc` (events → states) for multi-step or event-driven flows (the Award flow, auth).

Dependencies:

```bash
flutter pub add flutter_bloc bloc
flutter pub add equatable          # value equality for states/events
flutter pub add get_it             # service locator for DI (repos → blocs)
```

Hard requirements:
- Theme mode + locale are **app-global and persisted** (`shared_preferences`), exposed via
  `ThemeCubit` / `LocaleCubit` provided above the router with `MultiBlocProvider`.
- The Award flow holds a **draft** in its `AwardBloc` state across the 4 steps.
- Duty checklist, leaderboard filter, and notification toggles are **local Cubit state**.

> Each `Bloc`/`Cubit` depends only on **domain** (use cases / repository interfaces), never on
> `data` implementations directly. Wire concretions in DI (`get_it`).

---

## Layered architecture (data · domain · presentation)

Every feature is split into three layers. Dependencies point **inward**: `presentation → domain ←
data`. Domain knows nothing about Flutter, Firebase, or BLoC.

| Layer | Holds | Depends on |
|-------|-------|------------|
| **domain** | entities, repository **interfaces**, use cases | nothing (pure Dart) |
| **data** | DTO/models, data sources (remote/local), repository **implementations** | domain |
| **presentation** | blocs/cubits, pages, feature widgets | domain |

- **domain/entities** — plain immutable objects the UI speaks (`Person`, `AuraEntry`, …).
- **domain/repositories** — abstract contracts (`abstract class LeaderboardRepository`).
- **domain/usecases** — one callable per action (`GetLeaderboard`, `AwardAura`). Thin; orchestrate
  repositories. A bloc calls use cases, not repositories, when there's logic worth a name.
- **data/models** — extend/serialize entities (`fromMap`/`toMap`); convert at the data boundary.
- **data/datasources** — raw IO (`*RemoteDataSource` over Firestore, `*LocalDataSource` over
  `shared_preferences` or the in-memory seed).
- **data/repositories** — implement the domain interface, map models ↔ entities, pick sources.
- **presentation/bloc** — `Bloc`/`Cubit` + `*_event.dart` / `*_state.dart`.
- **presentation/pages** — the screen widgets.
- **presentation/widgets** — widgets specific to this feature.

---

## Folder structure

```
lib/
├── main.dart                       # setupDi(); runApp(AuraApp())
├── app.dart                        # AuraApp: MultiBlocProvider + MaterialApp.router
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
│   ├── di/
│   │   └── injection.dart          # get_it registrations (data sources, repos, blocs)
│   ├── usecase/
│   │   └── usecase.dart            # UseCase<Out, In> base + NoParams
│   ├── error/
│   │   └── failures.dart           # Failure types returned across the repo boundary
│   └── l10n/                       # generated localizations land here
│
├── shared/
│   ├── widgets/                    # screen-agnostic widgets (see 04_widgets.md)
│   │   ├── app_card.dart
│   │   ├── aura_value.dart
│   │   ├── avatar.dart
│   │   ├── role_badge.dart
│   │   ├── hearts_row.dart
│   │   ├── category_chip.dart
│   │   ├── aura_progress_bar.dart
│   │   ├── app_switch.dart
│   │   ├── segmented_control.dart
│   │   └── linear_link_chip.dart
│   └── models/                     # cross-feature enums (Role, AuraCategory)
│
└── features/                       # one folder per screen/flow, each layered
    ├── shell/
    │   └── presentation/
    │       └── pages/app_shell.dart        # bottom-tab scaffold + FAB
    │
    ├── home/
    │   ├── data/
    │   │   ├── datasources/home_remote_data_source.dart
    │   │   ├── models/...
    │   │   └── repositories/home_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/...
    │   │   ├── repositories/home_repository.dart
    │   │   └── usecases/get_home_summary.dart
    │   └── presentation/
    │       ├── bloc/home_cubit.dart (+ home_state.dart)
    │       ├── pages/home_page.dart
    │       └── widgets/status_card.dart
    │
    ├── leaderboard/
    │   ├── data/        { datasources/, models/, repositories/leaderboard_repository_impl.dart }
    │   ├── domain/      { entities/, repositories/leaderboard_repository.dart,
    │   │                  usecases/get_leaderboard.dart }
    │   └── presentation/{ bloc/leaderboard_bloc.dart (+ event/state),
    │                      pages/leaderboard_page.dart, widgets/podium.dart }
    │
    ├── profile/
    │   ├── data/        { datasources/, models/, repositories/ }
    │   ├── domain/      { entities/, repositories/, usecases/get_profile.dart,
    │   │                  usecases/get_aura_history.dart }
    │   └── presentation/{ bloc/profile_cubit.dart, pages/profile_page.dart,
    │                      widgets/history_row.dart }
    │
    ├── award/
    │   ├── data/        { datasources/, models/, repositories/award_repository_impl.dart }
    │   ├── domain/      { entities/award_draft.dart, repositories/award_repository.dart,
    │   │                  usecases/award_aura.dart, usecases/get_interns.dart }
    │   └── presentation/{ bloc/award_bloc.dart (+ award_event.dart / award_state.dart),
    │                      pages/award_page.dart, widgets/steps/... }
    │
    ├── duty/
    │   ├── data/        { datasources/, models/, repositories/ }
    │   ├── domain/      { entities/duty_day.dart, entities/checklist_item.dart,
    │   │                  repositories/, usecases/get_duty_week.dart,
    │   │                  usecases/toggle_checklist_item.dart }
    │   └── presentation/{ bloc/duty_cubit.dart, pages/duty_page.dart,
    │                      widgets/week_strip.dart }
    │
    ├── knowledge/
    │   ├── data/        { datasources/, models/, repositories/ }
    │   ├── domain/      { entities/knowledge_doc.dart, repositories/, usecases/get_docs.dart }
    │   └── presentation/{ bloc/knowledge_cubit.dart, pages/knowledge_page.dart,
    │                      pages/article_page.dart }
    │
    └── settings/
        ├── data/        { datasources/settings_local_data_source.dart, models/,
        │                  repositories/settings_repository_impl.dart }
        ├── domain/      { entities/notif_pref.dart, repositories/settings_repository.dart,
        │                  usecases/set_theme_mode.dart, usecases/set_locale.dart,
        │                  usecases/toggle_notif.dart }
        └── presentation/{ bloc/theme_cubit.dart, bloc/locale_cubit.dart,
                           bloc/settings_cubit.dart, pages/settings_page.dart }
```

**Rules of thumb:**
- Anything used by ≥2 features lives in `shared/widgets/`. Feature-specific widgets live under that
  feature's `presentation/widgets/`.
- A bloc never imports another feature's bloc. Cross-feature reads go through a domain use case.
- `domain` is pure Dart — no `package:flutter`, no `cloud_firestore`, no `flutter_bloc`.

---

## Navigation

`go_router` with a `StatefulShellRoute` so each tab keeps its own navigation stack and scroll
position. Feature blocs are provided either globally (`app.dart`) or per-route via
`BlocProvider(create: (_) => sl<XBloc>())` in the route `builder`.

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
  could also be a bottom sheet — match the prototype's right-slide for parity).
- **Article** is nested under Knowledge so back returns to the doc list.
- **Tapping a leaderboard row / podium / duty day** pushes `/profile/:id`.

### Custom bottom bar
Do **not** use `BottomNavigationBar` / `NavigationBar` defaults — they bring Material tint and
ripple. Build a `Row` of 5 `_TabButton`s inside a `Container` with:
- height ~84, top hairline border (`AppColors.border`),
- a translucent blurred background (`BackdropFilter` + `bg @ 80% opacity`),
- active tab: icon tinted with `AppColors.accentSolid` + glow, label `text`; inactive: `textFaint`.

The **FAB** (Award Aura) is a 60×60 rounded-20 gradient square, only on Home, bottom-right above
the tab bar. Tapping it pushes `/award`.

---

## Theming & persistence

`ThemeCubit` and `LocaleCubit` live in `settings/presentation/bloc/`, persist through the
settings repository (`shared_preferences`), and are provided above the router.

```dart
// app.dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => sl<ThemeCubit>()),
    BlocProvider(create: (_) => sl<LocaleCubit>()),
  ],
  child: Builder(builder: (context) {
    final themeMode = context.watch<ThemeCubit>().state;   // default ThemeMode.dark
    final locale    = context.watch<LocaleCubit>().state;
    return MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }),
);
```

Default `themeMode` is **dark**. The Settings screen flips it via `context.read<ThemeCubit>()`.

---

## Dependency injection

`get_it` wires the layers in `core/di/injection.dart`, called once from `main()` before `runApp`:

```dart
final sl = GetIt.instance;

Future<void> setupDi() async {
  // external
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerSingletonAsync(() => SharedPreferences.getInstance());

  // data sources → repositories → use cases → blocs (outer registered last)
  sl.registerLazySingleton<LeaderboardRemoteDataSource>(() => LeaderboardRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<LeaderboardRepository>(() => LeaderboardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetLeaderboard(sl()));
  sl.registerFactory(() => LeaderboardBloc(sl()));    // factory: fresh bloc per route
}
```

Blocs are `registerFactory` (new instance per screen); repositories/use cases are
`registerLazySingleton`.

---

## Conventions

- **No magic numbers.** Colors → `AppColors`, gaps/radii → `AppSpacing`, durations → `AppDurations`.
- **States/events are immutable** and extend `Equatable`; emit new instances, never mutate.
- **One bloc per feature concern.** Don't reach across features — call a domain use case.
- **`domain` stays pure Dart.** No Flutter/Firebase/BLoC imports there.
- **Const everything** that can be const; it's a list-heavy app.
- **One widget = one file** for anything non-trivial.
- Use `intl` `NumberFormat.decimalPattern()` for Aura values (`1,840`) and `DateFormat` for dates.
- Prefer composition over deep widget trees; pull repeated row layouts into small private widgets.
