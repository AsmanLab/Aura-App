# Firebase Seeding & Data Model Overview

How to put data into Firestore for development/demo, and how the models are shaped so the schema
stays **flexible and scalable**. Pairs with [`07_firebase_setup.md`](07_firebase_setup.md) (auth +
rules) and [`styles.md`](styles.md).

---

## 1. Collections at a glance

```
users/{uid}                         # one doc per signed-in user (the leaderboard source)
aura_transactions/{auto}            # every +/- award (append-only feed)
roulette_history/{uid}/spins/{auto} # optional: per-user spin log (subcollection)
```

- **`users`** is the hot collection — read by Home (current user), Profile, and the Board
  (ordered by `totalAura` / `currentWeekAura`).
- **`aura_transactions`** is append-only history; never updated in place. Query by `toUserId`.
- Unbounded per-user lists go in **subcollections**, not arrays on the user doc (keeps docs small,
  reads cheap).

---

## 2. Models (current) + how they stay flexible

### `users/{uid}` — [`UserModel`](../lib/core/models/user_model.dart)
| field | type | default | notes |
|-------|------|---------|-------|
| `id` | string | — | == uid |
| `displayName` | string | `''` | from Google |
| `email` | string | `''` | |
| `photoURL` | string? | null | account picture |
| `currentWeekAura` | int | `0` | weekly score (Board "Week") |
| `totalAura` | int | `0` | lifetime (Board "All-time") |
| `lastRouletteDate` | Timestamp? | null | |
| `createdAt` | Timestamp | — | server time |

**Flexibility rules (already followed — keep doing this):**
- `fromMap` is **null-safe with defaults** (`map['x'] ?? 0`). Adding a new field never breaks old
  docs, and missing fields read as a sane default. **Never** assume a field exists.
- New optional fields (e.g. `role`, `position`, `hearts`, `trialStart/End`, `teamId`) can be added
  to the model + `fromMap`/`toMap` without a migration — old docs just default.
- Keep a **`schemaVersion` int** on each doc so future migrations can branch on it.
- Consider a forward-compat `metadata: Map<String, dynamic>` bucket for experimental fields you
  don't want to promote to typed fields yet.

```dart
// Pattern: tolerant fromMap, typed copyWith, version + metadata for scale.
factory UserModel.fromMap(Map<String, dynamic> m, String id) => UserModel(
  id: id,
  displayName: m['displayName'] ?? '',
  totalAura: m['totalAura'] ?? 0,
  role: Role.values.asNameMap()[m['role']] ?? Role.member, // enum by name, safe default
  schemaVersion: m['schemaVersion'] ?? 1,
  metadata: Map<String, dynamic>.from(m['metadata'] ?? const {}),
  // ...
);
```

### `aura_transactions/{auto}` — [`AuraTransaction`](../lib/core/models/aura_transaction.dart)
`fromUserId`, `toUserId`, `points`, `comment`, `timestamp`, `weekId`.

**Scale tip — denormalize for reads:** also store `fromName` / `fromPhotoURL` (and `toName`) on the
transaction so the history feed renders without N extra `users` reads. Write-time cost, read-time
win. Accept that denormalized copies can go stale (fine for a feed).

---

## 3. Scalability guidelines

- **Small docs, subcollections for lists.** Don't grow arrays unbounded on a doc (1 MB doc cap;
  whole doc re-read on every change).
- **Denormalize** what you read together (giver name on a transaction; rank counters on user).
- **Paginate** big lists: `orderBy(field).limit(n).startAfterDocument(last)`. The Board already
  `limit(50)`.
- **Indexes:** single-field `orderBy` is auto-indexed (Board needs none). Composite queries
  (`where` + `orderBy` on different fields, e.g. history) need a composite index — see
  [`07_firebase_setup.md`](07_firebase_setup.md) §8.
- **Atomic counters:** update `currentWeekAura`/`totalAura` with `FieldValue.increment(n)` inside a
  batch with the transaction write — never read-modify-write.
- **Timestamps:** `FieldValue.serverTimestamp()` on create; never trust client clocks for ordering.
- **Weekly reset** (`currentWeekAura` → 0): a scheduled Cloud Function, keyed off `weekId`.
- **Rules first.** Enforce shape/permissions server-side ([`07`](07_firebase_setup.md) §9); seeding
  with the Admin SDK bypasses rules, so validate seed data yourself.

---

## 4. Seeding methods

### A. Admin SDK script (recommended for bulk / repeatable)
Bypasses security rules. Needs a service-account key (Project Settings → Service accounts →
Generate key → `serviceAccountKey.json`, **git-ignored**).

```bash
mkdir -p tools/seed && cd tools/seed
npm init -y && npm i firebase-admin
# put serviceAccountKey.json here (DO NOT COMMIT)
node seed.js
```

```js
// tools/seed/seed.js
const admin = require('firebase-admin');
admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) });
const db = admin.firestore();
const now = admin.firestore.FieldValue.serverTimestamp();

const users = [
  { id: 'u_aibek',  displayName: 'Aibek Toktosunov', email: 'aibek@aprd.dev',  totalAura: 1840, currentWeekAura: 120, role: 'member',  photoURL: null },
  { id: 'u_aida',   displayName: 'Aida Nurlanova',   email: 'aida@aprd.dev',   totalAura: 5120, currentWeekAura: 300, role: 'mentor',  photoURL: null },
  { id: 'u_damir',  displayName: 'Damir Sultanov',   email: 'damir@aprd.dev',  totalAura: 6010, currentWeekAura: 90,  role: 'admin',   photoURL: null },
];

async function main() {
  const batch = db.batch();
  for (const u of users) {
    const { id, ...data } = u;
    batch.set(db.collection('users').doc(id), {
      ...data,
      lastRouletteDate: null,
      schemaVersion: 1,
      createdAt: now,
    }, { merge: true }); // merge: safe to re-run
  }
  await batch.commit();
  console.log(`Seeded ${users.length} users.`);
}
main();
```

> `merge: true` makes the script **idempotent** for profile fields. Note: it would also overwrite
> `totalAura` — for production seeds, seed counters only when the doc is new (read-then-write, like
> the app's `_createUserIfNotExists`).

### B. Firebase console (one-off, manual)
Firestore → Start collection `users` → add a doc with id = uid → add fields. Fine for 1–2 test
docs; tedious at scale.

### C. In-app dev seeder (no Node, uses the app's SDK — obeys rules)
A debug-only button that writes via `cloud_firestore`. Keep it behind a debug route and strip
before release.

```dart
Future<void> seedUsers() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  for (final u in _seedUsers) {
    batch.set(db.collection('users').doc(u.id), {
      ...u.toMap(), 'schemaVersion': 1, 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  await batch.commit();
}
```

---

## 5. Sample seed JSON (shape reference)

```json
// users/u_aibek
{
  "displayName": "Aibek Toktosunov",
  "email": "aibek@aprd.dev",
  "photoURL": null,
  "totalAura": 1840,
  "currentWeekAura": 120,
  "role": "member",
  "lastRouletteDate": null,
  "schemaVersion": 1,
  "createdAt": "<serverTimestamp>"
}

// aura_transactions/<auto>
{
  "fromUserId": "u_aida",
  "fromName": "Aida Nurlanova",
  "toUserId": "u_aibek",
  "points": 40,
  "comment": "Clean, well-tested PR.",
  "weekId": "week_2026-06-01",
  "timestamp": "<serverTimestamp>"
}
```

---

## 6. Checklist before seeding

- [ ] Decide test uids (match real Firebase Auth uids if you want them to log in).
- [ ] Service-account key git-ignored; not committed.
- [ ] Seed `createdAt` with server timestamp, counters only on new docs.
- [ ] Add `schemaVersion` to every doc.
- [ ] Rules deployed ([`07`](07_firebase_setup.md) §9) — confirm a normal user can't fake aura.
- [ ] Verify Board orders correctly (`totalAura` desc) and your own row highlights.
