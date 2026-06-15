#!/usr/bin/env bash
# Create rich GitHub issues for the Aura roadmap (lib/core/TASKS.md) and
# (optionally) add them to a Project board.
#
#   gh auth login
#   gh auth refresh -s project,read:project
#   REPO=AsmanLab/Aura-App OWNER=AsmanLab PROJECT=3 bash tools/gh/create_issues.sh
#   # omit PROJECT to skip adding to a board
#
# NOTE: gh issue create is NOT idempotent — running twice makes duplicates.
set -euo pipefail

REPO="${REPO:-AsmanLab/Aura-App}"
OWNER="${OWNER:-AsmanLab}"
PROJECT="${PROJECT:-}"

# --- labels (idempotent) ---------------------------------------------------
mk_label() { gh label create "$1" -R "$REPO" --color "$2" --description "$3" 2>/dev/null || true; }
mk_label "priority: P0" "B60205" "Critical"
mk_label "priority: P1" "D93F0B" "High"
mk_label "priority: P2" "FBCA04" "Medium"
mk_label "status: todo" "EDEDED" "Not started"
mk_label "status: in progress" "0E8A16" "Partially done"
mk_label "type: task" "1D76DB" "Engineering task"

# helper: create_issue "<title>" "<labels csv>" "<body>"
create_issue() {
  local title="$1" labels="$2" body="$3"
  echo "Creating: $title"
  gh issue create -R "$REPO" --title "$title" --label "$labels" --body "$body"
}

# --- issues ----------------------------------------------------------------

create_issue "QA Testing" "type: task,priority: P1,status: todo" "$(cat <<'MD'
**Status:** 🔴 Not started
**Priority:** P1 (High)

## Description
Establish automated + manual test coverage so core flows don't regress.

## Approach
- Unit/bloc tests (`flutter_test` + `bloc_test`): AwardCubit, HeartsCubit, LeaderboardCubit, AuthCubit; repos with `fake_cloud_firestore`.
- Widget tests: login, profile, board, award flow, hearts flow.
- Golden tests for `core/widgets/` (AppCard, AuraValue, HeartsRow, skeletons) — dark + light.
- Firestore rules tests (`@firebase/rules-unit-testing`) against `firestore.rules`.
- Manual pass: real device, both platforms, offline, account switch.

## Acceptance Criteria
- [ ] `flutter test` green in CI
- [ ] bloc tests for the 4 cubits
- [ ] rules tests cover deny cases (mentor-only hearts, ±1, no self-award)
- [ ] golden tests for core widgets in both themes
MD
)"

create_issue "Push notification after updating the app" "type: task,priority: P2,status: in progress" "$(cat <<'MD'
**Status:** 🟡 Partial (token re-sync works)
**Priority:** P2 (Medium)

## Description
Notifications keep working after an app update; optionally announce new versions.

## Approach
- Verify FCM token re-syncs on cold start after update (`PushService.init`).
- "New version available": `firebase_remote_config` or `config/app_version` doc vs `package_info_plus` → in-app prompt with store link.
- Optional soft/force update gate (min supported version).

## Acceptance Criteria
- [ ] Token re-registers after an app update
- [ ] Update prompt shown when a newer version exists
- [ ] (Optional) force-update gate below min version
MD
)"

create_issue "On-duty feature (real backend)" "type: task,priority: P1,status: in progress" "$(cat <<'MD'
**Status:** 🟡 Partial (currently seed data)
**Priority:** P1 (High)

## Description
Replace the seed Duty screen with a real Firestore-backed on-call rotation.

## Approach
- Firestore: `duty_weeks/{weekId}` (days→userId), `duty_checklists/{uid_weekId}` (items, done, handoff note).
- New `duty` data layer: `DutyRemoteDataSource` + repo impl; swap the seed impl in `core/di/injection.dart`.
- Point existing `DutyCubit` at the Firebase repo; checklist toggle → Firestore write.
- "On duty now" derived from today's roster; surface on Home.
- Mentor/admin assigns the rotation (editor) or seed script.

## Acceptance Criteria
- [ ] Duty week + my-shift checklist persist in Firestore
- [ ] Updates reflect live
- [ ] "On duty now" shown on Home from real data
MD
)"

create_issue "Profile edit" "type: task,priority: P1,status: todo" "$(cat <<'MD'
**Status:** 🔴 Not started
**Priority:** P1 (High)

## Description
Let a user edit their own profile (displayName, position, photo).

## Approach
- `features/profile`: edit page + `ProfileEditCubit`.
- Writes only owner-allowed fields (`displayName`, `photoURL`, `position`, `metadata`) — role/aura/hearts stay locked (firestore.rules).
- Photo: `image_picker` → Firebase Storage → save `photoURL` (add `firebase_storage`).
- Pencil entry on own-profile header; realtime `watchUser` reflects changes.

## Acceptance Criteria
- [ ] Edit name / position / photo
- [ ] Persists + visible everywhere live
- [ ] Privileged fields cannot be changed (rule-enforced)
MD
)"

create_issue "Realtime update in board section" "type: task,priority: P2,status: todo" "$(cat <<'MD'
**Status:** 🔴 Not started (board is one-shot)
**Priority:** P2 (Medium)

## Description
Leaderboard updates live — awarding aura re-ranks instantly.

## Approach
- Add `watchLeaderboard(filter)` to the data source: `users.snapshots()` (+ monthly `aura_transactions` range for Month) → ranked `LeaderboardEntry`s.
- Cubit subscribes per filter; cache the stream (avoid re-subscribe churn — see `_UserProfileView` fix).
- Watch read cost; debounce or keep Month one-shot + pull-to-refresh.

## Acceptance Criteria
- [ ] Awarding aura re-ranks the open board without manual refresh
- [ ] Streams cached (no re-subscribe on rebuild)
MD
)"

create_issue "In-app notifications" "type: task,priority: P1,status: in progress" "$(cat <<'MD'
**Status:** 🟡 Partial (foreground banner done)
**Priority:** P1 (High)

## Description
Notifications center + live in-app alerts (foreground banner already exists).

## Approach
- Firestore `users/{uid}/notifications/{auto}` (title, body, route, read, createdAt) — written by the Cloud Function alongside the FCM send.
- `features/notifications`: stream subcollection → page (bell on Home), unread badge, mark-as-read, tap → deep-link via `data['route']`.
- Reuse `notification_banner` for foreground; list is the history.

## Acceptance Criteria
- [ ] Aura/heart events create a notification doc
- [ ] Bell shows unread count
- [ ] Tapping a notification routes correctly + marks read
MD
)"

create_issue "Attendance — office hours, geofenced" "type: task,priority: P1,status: todo" "$(cat <<'MD'
**Status:** 🔴 Not started
**Priority:** P1 (High)

## Description
Clock-in/out for office hours, allowed only inside the office geofence.

## Approach
- `geolocator` (+ `permission_handler`), "while in use" location.
- Office `lat/lng` + `radiusMeters` + work-hours in `config/office` (Firestore / Remote Config) — tunable without release.
- Clock-in: current position → `Geolocator.distanceBetween` → allow only within radius AND work-hours window.
- Firestore `attendance/{uid}/days/{yyyy-mm-dd}` (checkIn/out) — append-only; owner-write, no past edits.
- `features/attendance`: Cubit + page (clock in/out, today, history).
- Anti-spoof: client GPS is spoofable → validate server-side (Cloud Function) + mock-location detection; client check is UX only.

## Acceptance Criteria
- [ ] Clock-in succeeds only inside geofence + work hours
- [ ] Out-of-range clearly rejected with reason
- [ ] Records persist; history viewable
- [ ] Server-side validation (not client-trusted)
MD
)"

# --- add to project board (optional) ---------------------------------------
if [[ -n "$PROJECT" ]]; then
  echo "Adding open issues to project #$PROJECT ($OWNER)…"
  for url in $(gh issue list -R "$REPO" --state open --json url -q '.[].url'); do
    gh project item-add "$PROJECT" --owner "$OWNER" --url "$url" || true
  done
fi

echo "Done."
