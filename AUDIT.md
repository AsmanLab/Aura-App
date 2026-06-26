# Aura App — Performance & Code Quality Audit

**Date:** 2026-06-27  
**Auditor:** Claude Sonnet 4.6  
**Scope:** Full `lib/` static analysis — memory leaks, performance, correctness, dead code

---

## Legend

| Symbol | Severity |
|--------|----------|
| 🔴 P0 | **Critical bug** — wrong behavior today |
| 🟠 P1 | **Memory leak** — resource not released |
| 🟡 P2 | **Performance** — waste, but app works |
| ⚪ P3 | **Dead code** — compile bloat, ship risk |
| 🔵 P4 | **Code quality** — tech debt, not urgent |

---

## 🔴 P0 — Critical Bugs

### 1. Attendance time window logic wrong
**File:** [lib/core/services/attendance_service.dart:85-91](lib/core/services/attendance_service.dart#L85-L91)

```dart
bool isWithinTimeWindow() {
  final now = _now; // _now is DateTime.now().toUtc()
  ...
  return timeInMinutes >= 7 * 60 && timeInMinutes <= 9 * 60; // 07:00–09:00 UTC
}
```

Three conflicting values:
- **Code** gates on `07:00–09:00 UTC`
- **Error message** on line 24 says `"13:00-15:00"`
- **Notification** fires at `11:00 AM local time`

None of these agree. Users who open the app after the notification fires at 11 AM local will almost certainly be outside the 7–9 UTC window (only overlaps for UTC+7 to UTC+9 timezones). **Pick one window, make it consistent across all three.**

**Action required:** Decide the real time window, fix the gate, fix the error string, fix the notification time.

---

### 2. `watchTodayAllStatuses` selects oldest record per user, not latest
**File:** [lib/core/services/attendance_service.dart:107-111](lib/core/services/attendance_service.dart#L107-L111)

```dart
if (prev == null || record.timestamp.isBefore(prev.timestamp)) {
  byUser[record.userId] = record; // keeps older record, not newer
}
```

Condition replaces `prev` only when current record is **older**. Result: `byUser` accumulates the earliest attendance record per user, not the most recent. If a user has multiple records today (e.g., re-check-in after error), the UI shows stale data.

**Fix:** Flip condition to `record.timestamp.isAfter(prev.timestamp)`.

---

## 🟠 P1 — Memory Leaks

### 3. `PushService` leaks FCM stream subscriptions
**File:** [lib/core/services/push_service.dart:43-57](lib/core/services/push_service.dart#L43-L57)

```dart
FirebaseMessaging.onMessage.listen(_onForeground);        // subscription not stored
FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);   // subscription not stored
_fcm.onTokenRefresh.listen((t) { ... });                  // subscription not stored
```

All three subscriptions are fire-and-forget — no `StreamSubscription` variable, no `cancel()` path. `PushService` has no `dispose()` method. Because `PushService` is a long-lived singleton (via `sl<PushService>()`), these never get cleaned up, but the lambdas capture `_auth`, `_db`, and the context of `rootNavigatorKey` — preventing GC on logout flows.

**Fix:** Store subscriptions in fields; add `Future<void> dispose()` that cancels them; call on sign-out.

---

### 4. `leaderboardProvider` never auto-disposed
**File:** [lib/core/services/aura_service.dart:13-16](lib/core/services/aura_service.dart#L13-L16)

```dart
final leaderboardProvider = StreamProvider<List<UserModel>>((ref) {
  ...
});
```

No `.autoDispose`. The Firestore stream stays open and holds a listener even when no widget is watching the leaderboard tab. Same applies to `auraHistoryProvider` — keeps one stream open **per unique userId** ever loaded, forever.

**Fix:** Change to `StreamProvider.autoDispose` and `StreamProvider.autoDispose.family`.

---

### 5. `leaderboard_repository_impl` monthly StreamController not closed on disposal
**File:** [lib/features/leaderboard/data/repositories/leaderboard_repository_impl.dart:48-65](lib/features/leaderboard/data/repositories/leaderboard_repository_impl.dart#L48-L65)

When the monthly leaderboard filter is active, a `StreamController` is created. The `onCancel` callback cancels inner subscriptions — this is correct. However, the `StreamController` itself is never `close()`d after cancel. If no subscriber ever calls `cancel()` (e.g., widget tree is torn down abruptly), the controller and its two inner subscriptions leak.

**Fix:** Add `await controller.close()` inside `onCancel` after cancelling subscriptions.

---

## 🟡 P2 — Performance

### 6. `Image.network()` — no disk cache on user avatars
**File:** [lib/core/widgets/avatar.dart:83-89](lib/core/widgets/avatar.dart#L83-L89)

```dart
Image.network(
  photoUrl!,
  fit: BoxFit.cover,
  ...
)
```

Flutter's built-in `Image.network` uses only an in-memory image cache (cleared on app restart). Google profile photo URLs are the same per-user, so they re-download from CDN on every cold start. Avatars appear in lists (leaderboard, attendance page) — that's N network requests on first load.

**Fix:** Add `cached_network_image` package; replace with `CachedNetworkImage(imageUrl: photoUrl!)`.

---

### 7. In-memory sort on every Firestore snapshot
**File:** [lib/core/services/aura_service.dart:132-136](lib/core/services/aura_service.dart#L132-L136)

```dart
transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
```

Runs on every Firestore snapshot emission — O(n log n) per write to `aura_transactions`. Acceptable up to ~100 docs (the `limit(100)` cap). Workaround is deliberate (avoids needing a composite index). Fine for now, but note: once you create the composite index (`toUserId` ASC + `timestamp` DESC), switch to `getAuraHistory()` which uses `orderBy` and drops this cost.

**Action:** Create the Firestore composite index when user counts grow; switch to `getAuraHistory()`.

---

### 8. `watchAttendance` sorts all-time records in memory per snapshot
**File:** [lib/core/services/attendance_service.dart:76-83](lib/core/services/attendance_service.dart#L76-L83)

```dart
records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
```

No `limit()` on the Firestore query — fetches ALL attendance records for a user. Long-tenured users accumulate hundreds of records; every new check-in re-sorts the entire history.

**Fix:** Add `.limit(90)` (3 months of weekdays) and `orderBy('timestamp', descending: true)` with the appropriate Firestore index.

---

### 9. `watchAllUsers()` fetches entire `users` collection with no limit
**File:** [lib/core/services/attendance_service.dart:139-144](lib/core/services/attendance_service.dart#L139-L144)

```dart
_firestore.collection('users').snapshots()
```

No `limit()`. As team grows this downloads and deserializes every user document on every status change. Also triggers `watchTodayAllStatuses` to re-emit on ANY user field change (not just attendance).

**Action:** Add `.limit(200)` short-term; long-term consider a dedicated team membership collection.

---

## ⚪ P3 — Dead Code

### 10. Seed data layer from spec app is completely unused
**Files:**
- [lib/core/data/repositories/seed_duty_repository.dart](lib/core/data/repositories/seed_duty_repository.dart)
- [lib/core/data/repositories/seed_knowledge_repository.dart](lib/core/data/repositories/seed_knowledge_repository.dart)
- [lib/core/data/repositories/seed_people_repository.dart](lib/core/data/repositories/seed_people_repository.dart)
- [lib/core/data/repositories/seed_settings_repository.dart](lib/core/data/repositories/seed_settings_repository.dart)
- [lib/core/data/seed/seed_data.dart](lib/core/data/seed/seed_data.dart)

These correspond to the `commands/` spec (in-memory hearts/duty/knowledge app), not the Firebase-backed Aura app. They reference entities that don't map to Firestore. Zero live call sites in the production feature code.

**Action:** Delete the entire `lib/core/data/` subtree after confirming nothing in DI wires them.

---

### 11. Domain entities for unimplemented features
**Files:**
- [lib/core/domain/entities/duty_day.dart](lib/core/domain/entities/duty_day.dart)
- [lib/core/domain/entities/knowledge_doc.dart](lib/core/domain/entities/knowledge_doc.dart)
- [lib/core/domain/entities/notif_pref.dart](lib/core/domain/entities/notif_pref.dart)
- [lib/core/domain/entities/person.dart](lib/core/domain/entities/person.dart)

Spec-app artifacts. No Firestore collection backs them.

**Action:** Delete after confirming no live use.

---

### 12. `getAuraHistory()` dead method with index dependency
**File:** [lib/core/services/aura_service.dart:90-111](lib/core/services/aura_service.dart#L90-L111)

Method exists but is never called — `getAuraHistorySimple()` is used everywhere. Has a `// Alternative method` comment indicating it's a leftover from debugging.

**Action:** Delete `getAuraHistory()` and `getAuraHistoryOnce()` (debug method at line 141 also unused in production flows).

---

## 🔵 P4 — Code Quality

### 13. No `mounted` check after `await` in profile edit
**File:** [lib/features/profile/presentation/pages/profile_edit_page.dart](lib/features/profile/presentation/pages/profile_edit_page.dart)

After `await x.readAsBytes()` the code calls a cubit method using captured `ref`. In Riverpod this is safer than using `BuildContext` directly, but if the widget is disposed before the await completes the cubit may already be closed. Guard with `if (context.mounted)` before calling.

---

### 14. `AuraService` bypasses DI — uses `FirebaseFirestore.instance`
**File:** [lib/core/services/aura_service.dart:25-27](lib/core/services/aura_service.dart#L25-L27)

```dart
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
```

Other services (e.g., `AttendanceService`, `PushService`) are DI-injected via `get_it`. `AuraService` uses singletons directly — inconsistent pattern that makes unit testing impossible without Firebase emulator.

---

### 15. `AttendanceNotificationService` instantiated in `main.dart` with no handle
**File:** [lib/main.dart:37](lib/main.dart#L37)

```dart
final service = AttendanceNotificationService();
await service.init();
```

Instance is created, `init()` called, then dropped. No way to call `cancelAll()` on sign-out, locale change, or when notifications should be disabled per user preference. The `init()` always re-schedules notifications for all 5 weekdays, even if already scheduled.

**Fix:** Register `AttendanceNotificationService` in `get_it`; expose a `cancelAll()` call path from settings or sign-out flow.

---

## Summary Table

| # | Severity | File | Issue | Action |
|---|----------|------|-------|--------|
| 1 | 🔴 P0 | `attendance_service.dart:90` | Time window 7-9 UTC vs 13-15 error msg vs 11 AM notif | Pick one window, fix all three |
| 2 | 🔴 P0 | `attendance_service.dart:108` | `byUser` keeps oldest record per user, not latest | Flip `isBefore` → `isAfter` |
| 3 | 🟠 P1 | `push_service.dart:43-57` | FCM subscriptions never cancelled | Store + cancel in `dispose()` |
| 4 | 🟠 P1 | `aura_service.dart:13` | `leaderboardProvider` not auto-disposed | Add `.autoDispose` |
| 5 | 🟠 P1 | `leaderboard_repository_impl.dart:59` | Monthly `StreamController` not closed | `await controller.close()` in `onCancel` |
| 6 | 🟡 P2 | `avatar.dart:83` | `Image.network()` no disk cache | Add `cached_network_image` |
| 7 | 🟡 P2 | `aura_service.dart:132` | In-memory sort per snapshot | Add Firestore index; use `orderBy` |
| 8 | 🟡 P2 | `attendance_service.dart:76` | No `limit()` on attendance history | `.limit(90)` + `orderBy` |
| 9 | 🟡 P2 | `attendance_service.dart:139` | No `limit()` on `watchAllUsers()` | `.limit(200)` |
| 10 | ⚪ P3 | `lib/core/data/` | Entire seed repo layer unused | Delete subtree |
| 11 | ⚪ P3 | `lib/core/domain/entities/` | Dead spec entities | Delete |
| 12 | ⚪ P3 | `aura_service.dart:90,141` | Dead `getAuraHistory` + `getAuraHistoryOnce` | Delete |
| 13 | 🔵 P4 | `profile_edit_page.dart` | No `mounted` check post-await | Add `if (context.mounted)` |
| 14 | 🔵 P4 | `aura_service.dart:25` | `AuraService` uses singletons, not DI | Inject via constructor |
| 15 | 🔵 P4 | `main.dart:37` | `AttendanceNotificationService` leaked | Register in `get_it` |

---

## Recommended Fix Order

1. **Fix now (P0):** Items 1 + 2 — users cannot check in correctly
2. **Fix this sprint (P1):** Items 3–5 — prevent memory growth in prod
3. **Fix next sprint (P2):** Item 6 (image cache) — visible perf win; items 8+9 as team grows
4. **Cleanup pass (P3/P4):** Items 10–15 — reduce compile size and tech debt
