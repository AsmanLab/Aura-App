# 06 · Screens

Each screen as a widget tree, built in Stage 5 (read‑only) then wired for interaction in Stage 6.
Reference `Aura.html` constantly. Horizontal padding = `AppSpacing.screenPad` (20). Every scroll
view ends with ~120 bottom padding so the tab bar / FAB never covers content.

All user‑facing strings go through `AppLocalizations.of(context)` — keys suggested per screen.

---

## 6.0 App shell — `features/shell/app_shell.dart`

`Scaffold` with:
- `body`: the active tab branch (`StatefulShellRoute`'s `indexedStack`).
- **Custom bottom bar** (§02 navigation): 5 `_TabButton`s, blurred translucent bg, top hairline.
  Tabs: Home · Leaderboard · Duty · Knowledge · Profile (labels localized; keep them short for RU
  — "Рейтинг", "Дежур.", "База", "Профиль").
- **FAB** on Home only: 60×60, `BorderRadius.circular(20)`, `AppGradients.aura` + glow, `sparkle`
  icon, `onTap → context.push('/award')`. Press = scale‑down + slight rotate.

Status bar: use `SafeArea` + `AnnotatedRegion<SystemUiOverlayStyle>` (light icons in dark theme).
The prototype's fake status bar / home indicator are **device chrome — do not rebuild them.**

---

## 6.1 Home — `features/home/home_screen.dart`

`ListView` (or `CustomScrollView`):

1. **Greeting header** — date label (`sm`, `textDim`) + "Hi, Aibek" (`h1`); trailing `bell`
   icon button → `/settings`.
2. **`SectionLabel('ON DUTY NOW')`** + **OnDutyCard** (`AppCard`, tappable → `/duty`):
   `Avatar(onDuty, 52)` with a green presence dot, name (`h3`), position (`sm`), and a right
   column: green "Live" dot+label + "until 6 PM". Subtle green radial glow top‑right.
3. **`SectionLabel('MY STATUS')`** + **StatusCard** (`AppCard`, with an Aura glow‑orb behind):
   - "Total Aura" label + `AuraValue(me.aura, 56)` + a green "+120 this wk" pill.
   - "Hearts" row label + `m/8` + `HeartsRow(me.hearts, interactive: true)`.
   - "Trial" label + "{daysLeft} days left" + `AuraProgressBar(pct)` + start/end date row.
4. **`SectionLabel('QUICK ACTIONS')`** — 2×2 grid of `QuickActionCard`s (icon tile + label):
   Award Aura → `/award`, Leaderboard → tab, My duty → tab, Knowledge → tab.
5. **`SectionLabel('RECENT AURA')`** (+ "See all" → Profile) + `AppCard.flush` with 2
   `HistoryRow`s.

l10n keys: `home_greeting`, `home_onDutyNow`, `home_myStatus`, `home_totalAura`, `home_hearts`,
`home_trial`, `home_daysLeft`, `home_quickActions`, `home_recentAura`, `home_seeAll`, `home_live`.

---

## 6.2 Leaderboard — `features/leaderboard/leaderboard_screen.dart`

`Column`:
1. Header: "Leaderboard" (`h1`) + search icon (no‑op MVP).
2. **`SegmentedControl`** (All‑time / Month / Week) → drives `leaderboardProvider(filter)`.
3. Scroll body:
   - **Podium** (`widgets/podium.dart`): top‑3 in visual order **[2nd, 1st, 3rd]**. Each column:
     `Avatar` (1st bigger + ring) with a medal badge (gold/silver/bronze) overlapping the bottom,
     first name, gradient score, and a rising plinth (`surface`, radii top‑only, heights 1st>2nd>3rd).
   - **Rest list** (`AppCard.flush`): rows rank 4+ → rank number (`num`, `textFaint`),
     `Avatar(40)`, name + position, gradient score. Row tap → `/profile/:id`.
4. **Sticky "your rank" row** pinned above the tab bar (`Positioned`/`bottomNavigationBar`‑adjacent):
   `AppCard` (surface2, accent‑soft ring shadow) with your rank, `Avatar(ring)`, "You · Aibek",
   "Up 2 places this week", gradient score.

Filter behaviour: switching re‑sorts with an animated reorder if cheap (`AnimatedList`), otherwise
a simple cross‑fade is fine for MVP. The segmented pill animates (`med`).

l10n: `lb_title`, `lb_allTime`, `lb_month`, `lb_week`, `lb_you`, `lb_upPlaces`.

---

## 6.3 Profile — `features/profile/profile_screen.dart`

Works for **me** (tab) and **others** (`/profile/:id`, with a back button instead of the title).

1. **Identity** (centered): `Avatar(88, ring)`, name (`h2`), position (`sm`), `RoleBadge`.
2. **Big Aura** `AppCard` (centered, glow‑orb): "Total Aura" + `AuraValue(p.aura, 64)`.
3. **Hearts card** — *interns only*: label + `m/8` + `HeartsRow(interactive: isYou)`. If it's you
   and hearts ≤ 6, show a soft info note about hearts recovering.
4. **Trial card** — *interns only*: label + "{daysLeft} days left" + `AuraProgressBar` + start/end.
5. **Award button** — only when viewing **another intern** and viewer `role.canAward`: primary
   gradient button → `/award?internId=:id`.
6. **`SectionLabel('AURA HISTORY')`** + `AppCard.flush` of `HistoryRow`s.

`HistoryRow` (`widgets/history_row.dart`): top line = `CategoryTag` + `AuraPoints`; reason (`body`);
footer = tiny giver avatar + first name + when, and `LinearLinkChip` if present.

l10n: `profile_title`, `profile_totalAura`, `profile_hearts`, `profile_trialProgress`,
`profile_start`, `profile_end`, `profile_daysLeft`, `profile_awardAura`, `profile_auraHistory`,
`profile_heartsHint`.

---

## 6.4 Award Aura — `features/award/award_screen.dart` ★ flow

Full‑screen pushed route. Host = `Column`: header (close X · "Award Aura" · spacer) → **4‑segment
step bar** (filled segments = gradient) → step body (`AnimatedSwitcher`, horizontal slide) →
footer (Back + primary Continue/Award). Backed by `awardDraftProvider`.

- **Step 0 — Pick intern:** list of intern cards (`Avatar`, name, position, a compact ❤ m/8).
  Tap selects + advances. Names get `TextOverflow.ellipsis` (RU‑safe).
- **Step 1 — Category:** wrap of `CategoryChip`s. When one is selected, show a hint card
  (`CategoryTag` + `category.hint`).
- **Step 2 — Points:** big `AuraValue('+$pts')` in a glow card → a `Slider` (5–100, step 5,
  `accentSolid`) → quick‑pick chips (+10/+25/+50/+75).
- **Step 3 — Confirm:** summary card (intern + `CategoryTag` + `+pts`), a comment `TextField`
  (`surface`, radius 14), and an "Attach Linear issue" row with `AppSwitch`.
- **Submit:** `AwardSuccess` — a gradient sparkle disc that pops (scale/elastic), `AuraValue(+pts)`,
  "Aura awarded!" + recipient line. Auto‑close after ~1.6s (and clear the draft).

`canContinue`: step0 → intern set; step1 → category set; step2+ → always.
Add **light haptics** on award submit.

l10n: `award_title`, `award_stepOf`, `award_whoFor`, `award_whatFor`, `award_howMuch`,
`award_review`, `award_comment`, `award_attachLinear`, `award_continue`, `award_awardN`,
`award_success`, `award_received`.

---

## 6.5 Duty — `features/duty/duty_screen.dart`

`ListView`:
1. **Who's on duty** `AppCard` (green radial wash): `Avatar` + presence dot, "ON DUTY NOW" (green
   caps), name.
2. **`SectionLabel('THIS WEEK')`** + **WeekStrip** (`widgets/week_strip.dart`): 7 equal cells
   (`GridView`/`Row` of `Expanded`), each = day abbr, date (`num`), `Avatar(26)`. **Today** =
   gradient fill + white text; **my other days** = accent border. Cell tap → `/profile/:id`.
3. **`SectionLabel('MY SHIFT')`** + **MyShiftCard** `AppCard`:
   - Header: "Wednesday, Jun 3" (`h3`, nowrap) + "10:00 — 18:00 · Bishkek" (`sm`) + an "Active" pill.
   - **Checklist**: header "Checklist · {done}/{total}". Each item = a `GestureDetector` row with a
     24dp check box (done = gradient + white check; todo = bordered) + text (done = strikethrough,
     `textFaint`). Toggling writes to `checklistProvider`.
   - **Handoff note**: label + multiline `TextField` (`surface2`, radius 14).
   - Primary "Hand off shift" button (flag icon).

l10n: `duty_title`, `duty_onDutyNow`, `duty_thisWeek`, `duty_myShift`, `duty_active`,
`duty_checklist`, `duty_handoffNote`, `duty_handoffPlaceholder`, `duty_handOff`, weekday abbrevs.

---

## 6.6 Knowledge + Article — `features/knowledge/`

**KnowledgeScreen** (`ListView`):
1. Header "Knowledge" + search (no‑op).
2. **Featured card**: full gradient `AppCard` for the On‑Duty Guide — "START HERE" eyebrow, title,
   "Read guide ›", a large faint `shield` watermark. Tap → article.
3. **`SectionLabel('ALL DOCUMENTS')`** + doc cards (rounded icon tile in `accentSoft`, title,
   description, `tag · readTime`, trailing chevron). Tap → `article/:id`.

**ArticleScreen** (`article/:id`, pushed/nested):
- Header: back · tag label · share/link icon.
- Body: icon tile, title (`h2`), `readTime · Updated recently`, then render `doc.body` blocks:
  `heading`→`h3`, `paragraph`→`body`/`textDim`, `bullet`→dot + text, `callout`→red‑tinted card
  with a heart‑adjacent icon. End with a "Mark as read" row.

l10n: `kb_title`, `kb_startHere`, `kb_readGuide`, `kb_allDocuments`, `kb_markRead`,
`kb_updatedRecently`, `kb_read`. (Doc titles/bodies live in seed data with `*Ru` variants;
full RU body translation is a fast‑follow — EN bodies are acceptable for MVP.)

---

## 6.7 Settings / Notifications — `features/settings/settings_screen.dart`

Pushed route. `ListView`:
1. **Profile mini** card: `Avatar(ring)`, name, `RoleBadge`, edit affordance.
2. **`SectionLabel('APPEARANCE')`** card: "Dark mode" + `AppSwitch` (→ `themeModeProvider`);
   "Language" + a 130‑wide `SegmentedControl` EN/RU (→ `localeProvider`).
3. **`SectionLabel('NOTIFICATIONS')`** card: one row per `NotifPref` (icon tile, label,
   description, `AppSwitch`). Active icon tinted accent, inactive `textFaint`.
4. **`SectionLabel('QUIET HOURS')`** card: "Enable quiet hours" + `AppSwitch`; when on, a row
   "From 10 PM to 9 AM" + chevron (time‑range picker is a fast‑follow).

All toggles persist via `shared_preferences`. l10n: `set_title`, `set_appearance`, `set_darkMode`,
`set_language`, `set_notifications`, `set_quietHours`, `set_enableQuiet`, per‑category labels.

---

## 6.8 ★ Heart‑loss animation (Stage 6)

The emotional centrepiece. Triggered by tapping the hearts row (demo) or, in production, when the
backend reports a heart lost. Sequence (~700ms), gated on reduced‑motion (skip → just decrement):

1. **Punch**: the last filled heart scales `1 → 1.35 → 0.9 (slight rotate) → settles`, then its
   fill switches to the empty/outlined state. Use a `TweenSequence` on an `AnimationController`
   (`AppDurations.heart`, `Curves.elasticOut`‑ish).
2. **Shard burst**: ~7 small red squares spawn at the heart's centre and fly outward
   (`Stack` + `AnimatedPositioned`/`Transform` + fade out). A short‑lived overlay layer.
3. **Screen pulse**: a full‑screen red inner‑glow flashes once (`inset 0 0 80 rgba(255,77,94,.28)`
   → 0) via an `IgnorePointer` overlay with an animated `BoxShadow`/gradient. ~700ms.
4. **Haptic**: `HapticFeedback.mediumImpact()` at the punch peak.

Encapsulate in `HeartsRow`'s interactive state + a small `HeartBurstOverlay`. Decrement the model
**after** the punch completes so the count and animation stay in sync.

---

## 6.9 Card entrance (optional polish)

The prototype fades+rises cards on screen activation (staggered ~60ms). Reproduce with
`flutter_animate` (`.fadeIn().slideY(begin:.05)`) staggered by index, **only on first appear**, and
disabled under reduced‑motion / for PDF‑like contexts. Keep it subtle; never loop.

---

### Stage 5/6 exit checklist
- [ ] All 7 screens match the prototype in **dark + light**, EN + RU, no overflow.
- [ ] Award flow validates and animates success; draft clears on close.
- [ ] Heart‑loss plays the full punch + shards + pulse + haptic; respects reduced‑motion.
- [ ] Duty checklist toggles; leaderboard filter re‑ranks; settings toggles persist across restart.
- [ ] `flutter analyze` clean; tab/scroll positions preserved when switching tabs.
