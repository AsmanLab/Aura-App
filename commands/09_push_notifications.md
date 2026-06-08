# 09 · Push Notifications (Firebase Cloud Messaging)

Guideline to wire **FCM** into the app and fire a notification on an **event** (someone awards you
aura). Pairs with [`07_firebase_setup.md`](07_firebase_setup.md) and [`08_feature_setup.md`](08_feature_setup.md).

Project: **`aura-app-16fc3`**.

---

## 0. The shape of it

```
Award flow → Firestore write (aura_transactions/{id})
                 │
                 ▼
   Cloud Function (onDocumentCreated)  ──►  FCM send to recipient's device tokens
                 │
                 ▼
        Recipient's app receives:
          • foreground → show via flutter_local_notifications
          • background/terminated → system tray (FCM handles)
```

**Why a Cloud Function (not client-to-client):** the sender must never hold the recipient's tokens
or the FCM server key. The server (Function) reacts to the Firestore write and sends. This is the
secure, scalable path.

---

## 1. Dependencies

```bash
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications   # show notifications while app is foregrounded
```

`firebase_core` is already wired ([main.dart](../lib/main.dart)).

---

## 2. Data model — store device tokens

A user has multiple devices → store an array (or subcollection) of FCM tokens. Per the flexibility
rules ([`firebase_seeding.md`](firebase_seeding.md)), add to `users/{uid}`:

| field | type | notes |
|-------|------|-------|
| `fcmTokens` | array<string> | this user's device tokens |
| `notifPrefs` | map | optional per-category on/off (Aura, Duty, …) |

> Tokens rotate. Save on login + on refresh; remove on sign-out. For heavy scale use a
> `users/{uid}/tokens/{token}` subcollection instead of an array (avoids the 1 MB doc cap).

---

## 3. iOS setup (required — APNs)

FCM on iOS rides on **APNs**. Without it, iOS push silently does nothing.

1. **APNs key:** Apple Developer → Certificates, IDs & Profiles → **Keys** → `+` → enable **Apple
   Push Notifications service (APNs)** → download the `.p8` (once only) + note **Key ID** + **Team ID**.
2. **Upload to Firebase:** Console → Project Settings → **Cloud Messaging** → Apple app → **APNs
   Authentication Key** → upload the `.p8` + Key ID + Team ID.
3. **Xcode** (`ios/Runner.xcworkspace`):
   - Signing & Capabilities → **+ Capability** → **Push Notifications**.
   - **+ Capability** → **Background Modes** → check **Remote notifications**.
   - This adds `aps-environment` to `Runner.entitlements`.
4. Real device or a recent simulator (iOS 16.4+ supports push on simulator with a signed build).
5. Bundle id must match the Firebase iOS app (`com.aprd.aura` or your reverse domain).

## 4. Android setup

Mostly automatic via `google-services.json` (already present).

- **Android 13+ runtime permission:** add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  ```
  and request it at runtime (FCM `requestPermission()` covers it).
- Optional: a default notification channel + icon/color via `<meta-data>` in the manifest.

---

## 5. Flutter integration

Keep it in a small service (e.g. `core/services/push_service.dart` or a `notifications` feature's
`data/`), registered in `get_it`.

### 5.1 Background handler (must be top-level)
```dart
// top of main.dart (or push_service.dart)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Keep light. Firebase is already initialized for isolates via the plugin.
}
```

### 5.2 Init + permission + token
```dart
class PushService {
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _fcm.requestPermission(); // iOS prompt; Android 13+ POST_NOTIFICATIONS
    await _local.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));

    // Foreground messages → show locally (FCM doesn't auto-display in foreground).
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n != null) {
        _local.show(n.hashCode, n.title, n.body, const NotificationDetails(
          android: AndroidNotificationDetails('aura', 'Aura',
              importance: Importance.high),
          iOS: DarwinNotificationDetails(),
        ));
      }
    });

    // Tapped notification (background → opened).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
  }

  /// Call after sign-in. Saves the token + listens for refresh.
  Future<void> syncToken(String uid, FirebaseFirestore db) async {
    final token = await _fcm.getToken();
    if (token != null) await _save(uid, token, db);
    _fcm.onTokenRefresh.listen((t) => _save(uid, t, db));
  }

  Future<void> _save(String uid, String token, FirebaseFirestore db) =>
      db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

  /// Call on sign-out.
  Future<void> removeToken(String uid, FirebaseFirestore db) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    }
    await _fcm.deleteToken();
  }

  void _handleTap(RemoteMessage m) {
    // e.g. route to /aura/profile using m.data['route'].
  }
}
```

### 5.3 Wiring
- `main.dart`: `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);` after
  `Firebase.initializeApp`, then `await sl<PushService>().init();`.
- After a successful sign-in (`AuthCubit` / `_createUserIfNotExists`): `syncToken(uid, db)`.
- On sign-out (`AuthRepository.signOut`): `removeToken(uid, db)` **before** `_auth.signOut()`.
- Register `PushService` as a `lazySingleton` in [`injection.dart`](../lib/core/di/injection.dart).

---

## 6. The event — notify on award (Cloud Function)

Trigger on `aura_transactions` create → send to the recipient's tokens. Uses the denormalized
`fromName`/`points`/`toUserId` already on the doc.

```bash
# one-time
npm i -g firebase-tools
firebase login
firebase init functions   # TypeScript or JS; pick the aura-app-16fc3 project
```

```js
// functions/index.js  (Firebase Functions v2)
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
initializeApp();

exports.onAuraAwarded = onDocumentCreated('aura_transactions/{id}', async (event) => {
  const t = event.data.data();
  if (!t || !t.toUserId) return;

  const userSnap = await getFirestore().collection('users').doc(t.toUserId).get();
  const tokens = (userSnap.data() || {}).fcmTokens || [];
  if (tokens.length === 0) return;

  const sign = t.points >= 0 ? '+' : '';
  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: `${sign}${t.points} Aura`,
      body: `${t.fromName || 'Someone'} gave you aura${t.comment ? ': ' + t.comment : ''}`,
    },
    data: { route: `/aura/profile`, txnId: event.params.id },
    apns: { payload: { aps: { sound: 'default' } } },
    android: { notification: { channelId: 'aura' } },
  });

  // Prune tokens FCM reports as invalid (optional, recommended).
});
```

```bash
firebase deploy --only functions:onAuraAwarded
```

> Extend the same pattern for other events: role promotion (`users` update), roulette result,
> duty reminders (a scheduled function), etc.

---

## 7. Token hygiene & scale

- **Save on login + `onTokenRefresh`; remove on logout.** Stale tokens → wasted sends + errors.
- **Prune invalid tokens:** inspect `sendEachForMulticast` responses; `arrayRemove` the failures.
- **Respect prefs:** check `notifPrefs` in the Function before sending (e.g. user disabled "Aura").
- **Don't notify the sender** of their own action (here recipient ≠ sender already).
- Subcollection of tokens beats an array once users have many devices.

---

## 8. Testing

1. Run on a **real device** (push is unreliable on simulators/emulators).
2. Grab the token: `print(await FirebaseMessaging.instance.getToken());`.
3. Console → Cloud Messaging → **Send test message** → paste token → send. Confirm foreground +
   background delivery.
4. Then award aura from another account → confirm the Function fires and the recipient is notified.

---

## 9. Checklist

- [ ] `firebase_messaging` + `flutter_local_notifications` added.
- [ ] iOS: APNs key uploaded; Push + Background-Remote-notifications capabilities on.
- [ ] Android: `POST_NOTIFICATIONS` declared.
- [ ] `PushService.init()` + background handler wired in `main.dart`.
- [ ] Token saved on login / refresh, removed on logout.
- [ ] `onAuraAwarded` Function deployed; sends to recipient tokens.
- [ ] Tested on a physical device (foreground + background).
- [ ] Security rules: users can only edit **their own** `fcmTokens` ([`07`](07_firebase_setup.md) §9).
