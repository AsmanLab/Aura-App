# CLAUDE.md

Guidance for working in this repo.

## What this app is

**Aura** — a Flutter team-building app for giving each other "aura" points. Firebase-backed
(Auth + Firestore), Google Sign-In, weekly leaderboard, peer point-giving, and a once-a-day
roulette spin. Targets iOS + Android.

## ⚠️ `commands/` is a spec for a DIFFERENT app — do not trust it as ground truth

The `commands/` folder is a detailed engineering handoff ("Aura — Flutter Implementation Spec")
describing an internal APRD intern-trial app with **hearts, duty rotation, knowledge docs, an
award flow, a design-token system, and an in-memory seed repo (no backend)**.

The **actual code does none of that.** It's a different product:
- No hearts, no duty, no knowledge docs, no seed data, no `AppColors`/`AppTheme` token system.
- It IS backed by Firebase (Auth + Firestore), not in-memory seed data.
- It HAS a roulette feature the spec never mentions.

Treat `commands/` as aspirational design reference only. **The code in `lib/` is the source of
truth.** Don't implement spec features unless explicitly asked.

## Stack

- Flutter (Dart SDK `^3.8.1`), Material 3, `useMaterial3: true`, purple seed color.
- State: `flutter_riverpod` (providers live next to services).
- Routing: `go_router` — `ShellRoute` + auth redirect in [aura_app.dart](lib/app/aura_app.dart).
- Backend: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`.
- `uuid` for transaction IDs, `intl` for formatting.

## Architecture

```
lib/
├── main.dart                       # Firebase.initializeApp + ProviderScope(AuraApp)
├── app/aura_app.dart               # MaterialApp.router + GoRouter + auth redirect
├── firebase_options.dart
├── core/
│   ├── services/                   # service class + its Riverpod providers, same file
│   │   ├── auth_service.dart        # Google Sign-In, authStateProvider, currentUserProvider
│   │   ├── aura_service.dart        # giveAuraPoints, leaderboard, history
│   │   └── roulette_service.dart    # daily spin
│   └── utils/date_utils.dart        # getCurrentWeekId() etc.
├── features/screens/               # one file per screen (flat, no per-feature folders)
│   ├── login_screen.dart
│   ├── main_shell_screen.dart       # bottom nav shell
│   ├── home_screen.dart
│   ├── leaderboard_screen.dart
│   ├── profile_screen.dart
│   ├── give_aura_screen.dart
│   └── roulette_screen.dart
└── shared/
    ├── models/                     # UserModel, AuraTransaction, RouletteSpin (Firestore (de)serialize)
    └── widgets/                    # aura_card, aura_history_tile, quick_action_button,
                                    #   roulette_wheel, user_rank_tile
```

Routes: `/login`, `/` (home), `/leaderboard`, `/roulette`, `/profile`, `/give-aura`. Unauthed
users redirect to `/login`; authed users on `/login` redirect to `/`.

## Domain rules (from the real code)

- **Giving aura** ([aura_service.dart](lib/core/services/aura_service.dart)): points must be
  **exactly +1 or -1**, comment required, can't give to yourself. Writes an `aura_transactions`
  doc + atomically increments recipient's `currentWeekAura` and `totalAura` via a batch.
- **Leaderboard**: top 50 users ordered by `currentWeekAura` desc.
- **Aura history**: `getAuraHistorySimple` avoids a Firestore composite index by sorting in
  memory (the `orderBy` variant needs an index). Prefer the simple one unless the index exists.
- **Roulette** ([roulette_service.dart](lib/core/services/roulette_service.dart)): once per day
  (gated on `lastRouletteDate`). Result is `-10` (70%) or `+5` (30%) — note the inline comment
  says the opposite of what the code does; the **code** is `_random.nextDouble() < 0.7 ? -10 : 5`.

## Firestore collections

- `users/{uid}` — UserModel: displayName, email, photoURL, currentWeekAura, totalAura,
  lastRouletteDate, createdAt. Created on first Google sign-in.
- `aura_transactions/{uuid}` — fromUserId, toUserId, points, comment, timestamp, weekId.
- `roulette_history/{uid}/spins/{auto}` — userId, result, timestamp.

## Commands

```bash
flutter pub get
flutter run                 # connected device/sim
flutter analyze             # keep clean
dart format lib/
flutter test
flutter build apk --release
flutter build appbundle --release
```

Firebase config is committed (`firebase_options.dart`, `firebase.json`,
`google-services.json`). App won't run without Firebase reachable.
