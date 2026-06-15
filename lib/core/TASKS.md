# TASKS

Project task board. Each task lists **goal**, **approach** (using this repo's patterns —
feature folder `data/domain/presentation`, BLoC, `get_it`, Firestore; see
[`commands/08_feature_setup.md`](../../commands/08_feature_setup.md) and
[`commands/styles.md`](../../commands/styles.md)), and **status / acceptance**.

Status: 🔴 not started · 🟡 in progress / partial · 🟢 done

---

## 1. QA Testing  🔴
**Goal:** confidence the core flows don't regress.

**Approach**
- **Unit/bloc tests** (`flutter_test` + `bloc_test`): `AwardCubit`, `HeartsCubit`,
  `LeaderboardCubit`, `AuthCubit`, repositories with a fake/`fake_cloud_firestore`.
- **Widget tests:** login, profile, board, award flow, hearts flow.
- **Golden tests** for `core/widgets/` (AppCard, AuraValue, HeartsRow, skeletons) in dark + light.
- **Firestore rules tests:** `@firebase/rules-unit-testing` against [`firestore.rules`](../../firestore.rules)
  (mentor-only hearts, ±1, no self-award, intern-can-award-aura).
- Manual QA pass: real device, both platforms, offline behavior, account switch.

**Acceptance:** `flutter test` green in CI; rules tests cover the deny cases.

---

## 2. Push notification after updating the app  🟡
**Goal:** notifications keep working after an app update, and optionally announce updates.

**Approach**
- **Token freshness:** on launch (`PushService.init`) the token is re-synced for the signed-in
  user — already wired. Verify it still fires after an update (cold start path).
- **"New version available" prompt:** add `firebase_remote_config` or a `config/app_version` doc;
  compare to running `package_info_plus` version → in-app banner / dialog with a store link.
- **Force/soft update gate** if needed (min supported version).

**Acceptance:** updating the app re-registers the FCM token; users on an old build see an update
prompt. (Cloud Function send already exists — [`functions/index.js`](../../functions/index.js).)

---

## 3. On-duty feature (real backend)  🟡
**Goal:** replace the seed Duty screen with a real on-call rotation.

**Current:** [`features/duty`](../../lib/features/duty) renders **seed data** ([`core/data/seed`](data/seed)).

**Approach**
- Firestore: `duty_weeks/{weekId}` (days → userId) + `duty_checklists/{uid_weekId}` (items, done),
  handoff note. Or `duty_roster/{weekId}`.
- New `duty` data layer: `DutyRemoteDataSource` + repo impl (swap the seed impl in
  [`injection.dart`](di/injection.dart)).
- Cubit already exists; point it at the Firebase repo. Checklist toggle → Firestore write.
- "On duty now" derived from today's roster; show on Home.
- Admin/mentor assigns the rotation (a small editor) — or seed via a script.

**Acceptance:** duty week + my-shift checklist persist in Firestore and update live.

---

## 4. Profile edit  🔴
**Goal:** user edits their own profile (displayName, position, photo).

**Approach**
- `features/profile`: an edit page + `ProfileEditCubit`.
- Writes only the owner-allowed fields — rules already permit `displayName`, `photoURL`,
  `position`, `metadata` ([`firestore.rules`](../../firestore.rules)); **role/aura/hearts stay
  locked**.
- Photo: `image_picker` → Firebase Storage → save `photoURL`. (Add `firebase_storage`.)
- Entry point: a pencil on the own-profile header → edit page; realtime profile already reflects
  changes via `watchUser`.

**Acceptance:** user updates name/position/photo; persists; visible everywhere live; can't touch
privileged fields (rule-enforced).

---

## 5. Realtime update in board section  🔴
**Goal:** the leaderboard updates live (new aura → ranks re-sort instantly).

**Current:** [`LeaderboardCubit`](../../lib/features/leaderboard) loads **one-shot**
(`getLeaderboard`); month is computed from `aura_transactions`.

**Approach**
- Add `watchLeaderboard(filter)` to the data source: `users.snapshots()` (+ for Month, also
  stream `aura_transactions` since month start) → map to ranked `LeaderboardEntry`s.
- Cubit subscribes to the stream per filter (cache the stream like the profile views do, to avoid
  re-subscribe churn — see the `_UserProfileView` fix).
- Mind read cost: streaming all users + a monthly txn range can be chatty; throttle/debounce, or
  keep Month one-shot with pull-to-refresh.

**Acceptance:** awarding aura re-ranks the open board without manual refresh.

---

## 6. In-app notifications  🟡
**Goal:** a notifications center + live in-app alerts.

**Current:** foreground push shows a styled **banner** ([`core/widgets/notification_banner.dart`](widgets/notification_banner.dart)).
Missing: a persistent list / unread state.

**Approach**
- Firestore `users/{uid}/notifications/{auto}` (title, body, route, read, createdAt) — write from
  the Cloud Function alongside the FCM send.
- `features/notifications`: stream the subcollection → a notifications page (bell entry on Home),
  unread badge, mark-as-read, tap → deep-link via `data['route']`.
- Reuse the banner for foreground; the list is the history.

**Acceptance:** every aura/heart event creates a notification doc; a bell shows unread count;
tapping routes correctly.

---

## 7. Attendance — office hours, geofenced  🔴
**Goal:** clock-in/out for office hours, allowed only inside the office location.

**Approach**
- Permissions + location: `geolocator` (+ `permission_handler`). Request "while in use".
- Config: office `lat/lng` + `radiusMeters` (+ work hours) in `config/office` (Firestore /
  Remote Config) so it's tunable without a release.
- On clock-in: get current position → `Geolocator.distanceBetween` to office → allow only within
  radius **and** within work-hours window; else reject with a reason.
- Firestore `attendance/{uid}/days/{yyyy-mm-dd}` (checkIn, checkOut, durations) — append-only;
  rules: owner-write, no edits to past days.
- `features/attendance`: Cubit + page (clock in/out, today's status, history). Optional map preview.
- **Anti-spoof note:** client GPS is spoofable. For real enforcement validate server-side (Cloud
  Function) and/or use `mock location` detection; treat client checks as UX, not security.

**Acceptance:** clock-in succeeds only inside the geofence + work hours; records persist; history
viewable; out-of-range attempts are clearly rejected.

---

## Cross-cutting
- New features follow [`08_feature_setup.md`](../../commands/08_feature_setup.md) (layers + BLoC + DI).
- Every Firestore write that changes privileged data needs a matching **rule**
  ([`firestore.rules`](../../firestore.rules)).
- Stream in `build()` is a bug — **cache streams/futures** in `StatefulWidget` fields.
- UI uses tokens only ([`styles.md`](../../commands/styles.md)); skeletons on loading states.
