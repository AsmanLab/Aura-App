# 07 · Firebase Setup, Models & Functions

How to wire the app to Firebase, plus every model, service function, role, and the rules that
govern who can do what. Use this when recreating the backend from scratch.

> **Note on scope.** Two app surfaces exist in this repo: the live **Firebase app** (`/`, Google
> sign-in, roulette) and the seed-only **Aura spec app** (`/aura/*`, no backend). This doc is about
> the **Firebase** side. Where the current code and the intended target differ (e.g. the `role`
> field, mentor-only awarding), it is called out as **CURRENT** vs **TARGET**.

Firebase project: **`aura-app-16fc3`** (see [`firebase.json`](../firebase.json),
[`lib/firebase_options.dart`](../lib/firebase_options.dart)).

---

## 1. Services used

| Firebase product | Used for |
|------------------|----------|
| **Authentication** | Google Sign-In (only provider) |
| **Cloud Firestore** | users, aura transactions, roulette history |

No Cloud Functions, Storage, or Realtime DB.

---

## 2. First-time project setup

```bash
# 1. Tooling
dart pub global activate flutterfire_cli
npm i -g firebase-tools
firebase login

# 2. Generate firebase_options.dart + native config (already committed; rerun to refresh)
flutterfire configure --project=aura-app-16fc3
#   -> writes lib/firebase_options.dart
#           android/app/google-services.json
#           ios/Runner/GoogleService-Info.plist

# 3. Pull deps & run
flutter pub get
flutter run
```

`main()` boots Firebase before the app:

```dart
// lib/main.dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
await setupDi();
runApp(const ProviderScope(child: AuraApp()));
```

---

## 3. Google Authorization setup

### 3.1 Firebase console
1. **Build → Authentication → Sign-in method → Google → Enable.** Set support email.
2. Confirm the app entries: Android app `1:594801867619:android:…`, iOS app
   `1:594801867619:ios:…`.

### 3.2 Android
- Add the app's **SHA-1** and **SHA-256** fingerprints (Project Settings → your Android app):
  ```bash
  cd android && ./gradlew signingReport      # copy SHA1 / SHA256 of debug + release
  ```
  Google Sign-In **fails silently without SHA-1.** Re-download `google-services.json` after adding.
- `google-services.json` lives at `android/app/google-services.json`.

### 3.3 iOS
- `ios/Runner/GoogleService-Info.plist` must be in the Xcode project.
- Add the **reversed client ID** as a URL scheme in `ios/Runner/Info.plist`:
  ```xml
  <key>CFBundleURLTypes</key>
  <array><dict><key>CFBundleURLSchemes</key>
    <array><string>com.googleusercontent.apps.594801867619-XXXX</string></array>
  </dict></array>
  ```
  (value = `REVERSED_CLIENT_ID` from the plist.)

### 3.4 Scopes
Only `email` is requested:

```dart
// lib/core/services/auth_service.dart
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
```

---

## 4. Registration / sign-in flow

There is **no separate registration** — first Google sign-in creates the user doc. Flow
([`auth_service.dart`](../lib/core/services/auth_service.dart)):

```
LoginScreen "Sign in with Google" tap
  → AuthService.signInWithGoogle()
      → _googleSignIn.signIn()            // native account picker; null if cancelled
      → googleUser.authentication          // accessToken + idToken
      → GoogleAuthProvider.credential(...)
      → FirebaseAuth.signInWithCredential  // creates / signs in the Firebase user
      → _createUserIfNotExists(user)       // upsert users/{uid}
```

`_createUserIfNotExists` writes (merge, so re-login won't wipe data):

```dart
firestore.collection('users').doc(user.uid).set({
  'id': user.uid,
  'displayName': user.displayName ?? 'Anonymous',
  'email': user.email ?? '',
  'photoURL': user.photoURL,
  'currentWeekAura': 0,
  'totalAura': 0,
  'lastRouletteDate': null,
  'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
```

> **TARGET:** also write `'role': 'intern'` here (default), so role-gating below has data to read.
> The default role of a fresh sign-up is **Intern**; an admin promotes people to Mentor/Full-time.

Routing gate ([`aura_app.dart`](../lib/app/aura_app.dart)): unauthenticated users are redirected to
`/login`; `/aura/*` + debug screens are public. (Login is currently bypassed at boot —
`initialLocation: '/aura/home'`; restore `'/'` to re-enable.)

Sign-out: `AuthService.signOut()` → `_googleSignIn.signOut()` + `_auth.signOut()`.

Auth providers (Riverpod):
- `authStateProvider` → `Stream<bool>` (signed in?)
- `currentUserProvider` → `Stream<UserModel?>` (the Firestore profile)

---

## 5. Roles

| Role | RU | Can give Aura? | Has trial / hearts? |
|------|----|----------------|---------------------|
| **Intern** | Стажёр | **no** | yes |
| **Full-time** | Сотрудник | yes¹ | no |
| **Mentor** | Ментор | **yes** | no |
| **Admin** | Админ | yes¹ | no |

¹ Spec allows full-time/mentor/admin to award. **Per current product decision, only _Mentors_ may
give Aura points.** Pick one and enforce it in both the app and Firestore rules (below).

- **CURRENT:** `UserModel` has **no `role` field**, and `AuraService.giveAuraPoints` does **not**
  check role — any signed-in user can award (except to themselves).
- **TARGET:** add `role` to `UserModel` + the user doc, gate awarding on `role == mentor`.

```dart
enum Role { intern, fullTime, mentor, admin }   // store as string: 'intern' | 'fullTime' | ...
bool canAward(Role r) => r == Role.mentor;       // mentor-only rule
```

---

## 6. Firestore data model

### `users/{uid}` — `UserModel` ([model](../lib/shared/models/user_model.dart))
| field | type | notes |
|-------|------|-------|
| `id` | string | == uid |
| `displayName` | string | from Google |
| `email` | string | |
| `photoURL` | string? | |
| `currentWeekAura` | int | resets per week (TODO job) |
| `totalAura` | int | lifetime |
| `lastRouletteDate` | Timestamp? | gate for daily spin |
| `createdAt` | Timestamp | server time |
| `role` | string | **TARGET** — `'intern'` default |

### `aura_transactions/{uuid}` — `AuraTransaction` ([model](../lib/shared/models/aura_transaction.dart))
| field | type | notes |
|-------|------|-------|
| `fromUserId` | string | giver uid |
| `toUserId` | string | recipient uid |
| `points` | int | **CURRENT: only +1 or −1** |
| `comment` | string | required, non-empty |
| `timestamp` | Timestamp | |
| `weekId` | string | `week_YYYY-MM-DD` (Monday), see `DateUtils.getCurrentWeekId()` |

### `roulette_history/{uid}/spins/{auto}` — `RouletteSpin` ([model](../lib/shared/models/roulette_spin.dart))
| field | type | notes |
|-------|------|-------|
| `userId` | string | |
| `result` | int | `-10` (70%) or `+5` (30%) |
| `timestamp` | Timestamp | |

---

## 7. Services & functions

### AuthService ([file](../lib/core/services/auth_service.dart))
| member | does |
|--------|------|
| `authStateChanges` | `Stream<User?>` |
| `currentUser` | current `User?` |
| `currentUserStream` | `Stream<UserModel?>` (reads Firestore doc) |
| `signInWithGoogle()` | full Google flow + upsert user |
| `signOut()` | Google + Firebase sign-out |
| `_createUserIfNotExists(user)` | upsert `users/{uid}` |

### AuraService ([file](../lib/core/services/aura_service.dart))
| member | does | rules |
|--------|------|-------|
| `giveAuraPoints({toUserId, points, comment})` | batch: write `aura_transactions` doc + `FieldValue.increment` recipient `currentWeekAura` & `totalAura` | not self · `points ∈ {+1,−1}` · comment non-empty · **TARGET: giver.role == mentor** |
| `getLeaderboard()` | `Stream<List<UserModel>>` top 50 by `currentWeekAura` desc | |
| `getAuraHistory(userId)` | `Stream` by `toUserId` + `orderBy(timestamp)` | **needs composite index** |
| `getAuraHistorySimple(userId)` | same, sorts in memory | avoids the index |
| `getAuraHistoryOnce(userId)` | one-shot `Future` | |
| `getAllUsers()` | all users except self, ordered by name | |

Providers: `auraServiceProvider`, `leaderboardProvider`, `auraHistoryProvider(userId)`.

### RouletteService ([file](../lib/core/services/roulette_service.dart))
| member | does | rules |
|--------|------|-------|
| `canSpinToday()` | true if `lastRouletteDate` is not today | |
| `spinRoulette()` | random result, batch: increment aura + set `lastRouletteDate` + record spin | **once per day** |

Providers: `rouletteServiceProvider`, `canSpinRouletteProvider`.

> ⚠️ Roulette inline comment says `+10 / -5`; the code does `_random.nextDouble() < 0.7 ? -10 : 5`
> → **−10 (70%) / +5 (30%)**. Fix one to match intent.

---

## 8. Composite index

`getAuraHistory` (the `orderBy` variant) needs an index on `aura_transactions`:
`toUserId ASC, timestamp DESC`. Create it via the link in the console error, or:

```json
// firestore.indexes.json
{ "indexes": [{
  "collectionGroup": "aura_transactions", "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "toUserId", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}]}
```
`firebase deploy --only firestore:indexes`. (Or just use `getAuraHistorySimple`.)

---

## 9. Security rules (TARGET)

Enforce the rules server-side — the app checks are not enough. `firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function signedIn() { return request.auth != null; }
    function me() { return request.auth.uid; }
    function roleOf(uid) {
      return get(/databases/$(db)/documents/users/$(uid)).data.role;
    }

    match /users/{uid} {
      allow read: if signedIn();
      // user edits own profile; aura fields only via increment (award/roulette).
      allow create: if signedIn() && uid == me();
      allow update: if signedIn() && uid == me();
    }

    match /aura_transactions/{id} {
      allow read: if signedIn();
      allow create: if signedIn()
        && request.resource.data.fromUserId == me()
        && request.resource.data.toUserId != me()            // no self-award
        && roleOf(me()) == 'mentor'                          // mentor-only
        && request.resource.data.points in [1, -1]           // ±1
        && request.resource.data.comment.size() > 0;
      allow update, delete: if false;
    }

    match /roulette_history/{uid}/spins/{spin} {
      allow read: if signedIn() && uid == me();
      allow create: if signedIn() && uid == me();
    }
  }
}
```
`firebase deploy --only firestore:rules`.

> Recipient aura increments come from the same batch as the transaction create. If rules block
> arbitrary `users` writes, scope the allowed `update` to the two aura fields, or move awarding to a
> Cloud Function (recommended once role-gating matters).

---

## 10. Reset checklist (clearing existing data)

1. Firestore console → delete `users`, `aura_transactions`, `roulette_history` collections.
2. Authentication → delete existing users (so first sign-in re-creates clean docs).
3. Deploy rules + indexes (§8, §9).
4. Add `role` to `_createUserIfNotExists` and `UserModel` (§4, §6) before re-testing awarding.
5. Sign in → confirm `users/{uid}` created with `role: 'intern'`.
6. Promote a test account to `mentor` (edit the doc) → verify it can award and an intern cannot.
```
