# 10 — In-App Update Notifications

Prompt testers to update when a new build is available on **TestFlight** (iOS) or
**Firebase App Distribution** (Android), without requiring an App Store / Play Store release.

---

## 1. Goal

On every cold start (after auth), the app silently checks whether a newer build exists.
If one does, a bottom sheet slides up:

```
╭──────────────────────────────────────╮
│  🚀  New version available           │
│  Version 1.2 (build 42) is ready.   │
│  Update now to get the latest fixes. │
│                                       │
│  [    Update    ]  [ Later ]          │
╰──────────────────────────────────────╯
```

Two update levels:

| Level | Condition | Dismissible? | Behaviour |
|-------|-----------|--------------|-----------|
| **Soft** | `current_build < latest_build` | Yes — "Later" snoozes 24 h | Prompt once per session / once per day |
| **Force** | `current_build < min_build` | No | User must tap "Update"; app is blocked |

---

## 2. Version source — Firebase Remote Config

No separate backend needed. Store three keys in **Firebase Remote Config**:

| Key | Type | Example | Purpose |
|-----|------|---------|---------|
| `latest_build_number` | Number | `42` | Soft-update threshold |
| `min_build_number` | Number | `38` | Force-update threshold |
| `update_url_ios` | String | `https://testflight.apple.com/join/XXXXXXXX` | TestFlight invite link |
| `update_url_android` | String | `https://appdistribution.firebase.google.com/...` | Distribution link |
| `update_message` | String | `Bug fixes and attendance improvements.` | Custom changelog blurb |

Remote Config fetch uses a 1-hour cache by default; set to 0 in debug builds.

---

## 3. New packages required

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_remote_config: ^5.x.x   # already transitive via firebase_core
  package_info_plus: ^8.x.x        # read current build number
  url_launcher: ^6.x.x             # open TestFlight / App Distribution URL
```

---

## 4. Architecture

```
lib/
└── core/
    ├── services/
    │   └── app_update_service.dart        # fetch Remote Config, compare builds
    ├── utils/
    │   └── dialogs/
    │       └── update_bottom_sheet.dart   # bottom sheet UI
    └── di/
        └── injection.dart                 # register AppUpdateService
```

Trigger point: `lib/app/aura_app.dart` — after auth state = authenticated, call
`AppUpdateService.checkAndPrompt(context)` once per cold start.

---

## 5. AppUpdateService

```dart
class AppUpdateService {
  final FirebaseRemoteConfig _remoteConfig;
  final SharedPreferences _prefs;

  static const _snoozeKey = 'update_snoozed_until';

  Future<void> checkAndPrompt(BuildContext context) async {
    // 1. Fetch remote config (cached 1h in prod, 0 in debug).
    await _remoteConfig.fetchAndActivate();

    final latestBuild = _remoteConfig.getInt('latest_build_number');
    final minBuild    = _remoteConfig.getInt('min_build_number');
    final message     = _remoteConfig.getString('update_message');
    final url = Platform.isIOS
        ? _remoteConfig.getString('update_url_ios')
        : _remoteConfig.getString('update_url_android');

    // 2. Get current build number.
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;

    if (currentBuild >= latestBuild) return; // already up to date

    final isForced = currentBuild < minBuild;

    // 3. Snooze check (soft updates only).
    if (!isForced) {
      final snoozedUntil = _prefs.getInt(_snoozeKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < snoozedUntil) return;
    }

    // 4. Show bottom sheet.
    if (!context.mounted) return;
    await showUpdateBottomSheet(
      context,
      message: message,
      updateUrl: url,
      isForced: isForced,
      onSnooze: () {
        final until = DateTime.now()
            .add(const Duration(hours: 24))
            .millisecondsSinceEpoch;
        _prefs.setInt(_snoozeKey, until);
      },
    );
  }
}
```

---

## 6. Bottom sheet UI — `update_bottom_sheet.dart`

Design tokens: `AppColors`, `AppType`, `AppSpacing`, `AppGradients`.

```
╭─────────────────────────────────────╮
│  ▬▬  (drag handle)                  │
│                                      │
│  🚀  New version available           │  ← h2
│  <update_message from Remote Config> │  ← bodyDim
│                                      │
│  [  Update  ] (gradient, full-width) │
│  [ Continue ] (text button, dimmed)  │  ← hidden if isForced
╰─────────────────────────────────────╯
```

- `isDismissible: !isForced` on the `showModalBottomSheet` call
- `enableDrag: !isForced`
- "Update" taps → `launchUrl(Uri.parse(updateUrl))`
- "Continue" (soft only) → pops sheet, calls `onSnooze()`

---

## 7. Trigger point in `aura_app.dart`

```dart
// Inside _AuraAppState.build, after router redirect settles to an authed route:
ref.listen(authStateProvider, (_, next) {
  _auth.value = next;
  next.whenData((isAuthed) {
    if (isAuthed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sl<AppUpdateService>().checkAndPrompt(context);
      });
    }
  });
});
```

Only fires on cold-start auth transitions, not on every rebuild.

---

## 8. Remote Config defaults (local fallback)

Set defaults so the service works even if Remote Config is unreachable:

```dart
await _remoteConfig.setDefaults({
  'latest_build_number': 0,
  'min_build_number':    0,
  'update_url_ios':      'https://testflight.apple.com/join/REPLACE_ME',
  'update_url_android':  'https://appdistribution.firebase.google.com/REPLACE_ME',
  'update_message':      'A new version is available.',
});
```

---

## 9. Firebase Remote Config setup (one-time)

1. Open [Firebase Console → Remote Config](https://console.firebase.google.com)
2. Add the 5 keys from §2.
3. Set `latest_build_number` and `min_build_number` to `0` initially (no prompt shown).
4. After publishing a new TestFlight/AppDistribution build, bump `latest_build_number`
   to the new build number. Set `min_build_number` only when you want to force.
5. Publish the config.

---

## 10. Implementation checklist

- [ ] Add `firebase_remote_config`, `package_info_plus`, `url_launcher` to `pubspec.yaml`
- [ ] Create `lib/core/services/app_update_service.dart`
- [ ] Create `lib/core/utils/dialogs/update_bottom_sheet.dart`
- [ ] Register `AppUpdateService` as lazy singleton in `injection.dart`
- [ ] Wire `checkAndPrompt` call in `aura_app.dart` post-auth
- [ ] Add Remote Config keys in Firebase console with defaults
- [ ] Add `LSApplicationQueriesSchemes` for `itms-apps` in iOS `Info.plist` (if using App Store link)
- [ ] Test: set `latest_build_number` to `current + 1` → verify soft prompt appears
- [ ] Test: set `min_build_number` to `current + 1` → verify force prompt blocks navigation
