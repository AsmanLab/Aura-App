# 00 · Project Overview & Build Plan

## What Aura is

Aura is an internal mobile app for **APRD**, an IT company in Bishkek. It does two jobs:

1. **Gamifies the 3‑month intern trial** — interns earn **Aura points** (awarded by mentors &
   full‑timers across five categories) and hold **8 hearts** (margin for mistakes). Running out
   of hearts ends the trial. A progress bar tracks days remaining.
2. **Runs the on‑duty rotation** — a weekly schedule of who is the first responder for
   production, with a per‑shift checklist and an end‑of‑shift handoff note.

Target: **iOS + Android** from one layout. Design width ≈ 390 dp. **Dark mode is primary**;
light is a supported variant.

---

## Roles

Shown as a badge + position on every profile.

| Role | RU | Accent | Can award Aura? | Has trial/hearts? |
|------|----|--------|-----------------|-------------------|
| **Intern** | Стажёр | cyan `#22D3EE` | no | **yes** |
| **Full‑time** | Сотрудник | indigo `#818CF8` | yes | no |
| **Mentor** | Ментор | violet `#C084FC` | yes | no |
| **Admin** | Админ | amber `#FBBF24` | yes | no |

The signed‑in demo user is an **Intern** (Aibek), so Home/Profile show trial state. The Award
flow is a mentor capability; in the prototype it is reachable for demonstration. In production,
gate the Award entry points behind `role != Intern`.

---

## The five Aura categories

| Category | RU | Icon | Color |
|----------|----|------|-------|
| Productivity | Продуктивность | bolt | emerald `#34D399` |
| Initiative | Инициатива | rocket | amber `#FBBF24` |
| Code Quality | Качество кода | shield | violet `#A78BFA` |
| Helping Others | Помощь | hands | cyan `#22D3EE` |
| Reliability | Надёжность | gauge | blue `#60A5FA` |

---

## The 7 screens (MVP)

1. **Home** — "On duty now" card → my status (Aura total w/ glow, hearts row, trial progress
   bar) → quick actions → recent Aura feed.
2. **Leaderboard** — interns ranked by Aura; top‑3 podium; All‑time / Month / Week filter;
   sticky "your rank" row pinned above the tab bar.
3. **Profile** — identity + role badge → big Aura number → hearts (interns) → trial progress
   (interns) → scrollable Aura history feed (category tag, ± points, reason, optional Linear link).
4. **Award Aura** (mentor flow) — pick intern → category chip → points → comment + attach
   Linear → confirm. 4 steps, animated success.
5. **Duty** — "who's on duty" indicator → week view → my‑shift card (checklist + handoff note).
6. **Info / Knowledge** — list of docs (On‑Duty Guide, How Aura Works, Hearts & the Trial,
   Incident Runbook, Team Handbook) + an article reading view.
7. **Notifications / Settings** — per‑category toggles (Duty, Aura, Hearts, Milestones,
   Announcements) + quiet hours + theme + language.

Navigation: **5‑item bottom tab bar** (Home · Leaderboard · Duty · Knowledge · Profile). Award
Aura is a **FAB on Home** (and a button on other interns' profiles). Settings & Article open as
**pushed routes**.

---

## Stage‑by‑stage build plan

Each stage is shippable/reviewable on its own. Don't skip ahead — later stages assume the
earlier scaffolding exists.

### Stage 0 — Project & tooling (½ day)
- `flutter create`, set org/bundle id, add dependencies, wire fonts.
- Strip the counter template. App boots to a blank `Scaffold` with the dark background color.
- **Exit check:** app runs on iOS sim + Android emulator showing `#08080B`.
- Docs: `01_setup_and_commands.md`, `02_architecture.md`.

### Stage 1 — Design system (1 day)
- Implement `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`.
- Build a throwaway **"Style Gallery" screen** that renders every token (color swatches, type
  scale, radii, the gradient) so you can eyeball it against the prototype.
- **Exit check:** dark & light `ThemeData` switch cleanly; gradient + glow match the prototype.
- Docs: `03_design_system.md`.

### Stage 2 — Core widgets (2 days)
- Build, in this order: `AppCard`, `AuraValue` (+ `AuraPoints`), `Avatar`, `RoleBadge`,
  `HeartsRow` (static first), `CategoryChip`/`CategoryTag`, `AuraProgressBar`, `AppSwitch`,
  `SegmentedControl`, `LinearLinkChip`.
- Render them all in the Style Gallery.
- **Exit check:** every widget matches the prototype in dark + light; no Material defaults leak.
- Docs: `04_widgets.md`.

### Stage 3 — Data layer (½ day)
- Models + enums + the in‑memory seed repository (`05_data_models.md`).
- Riverpod providers expose people, leaderboard, history, duty week, docs, notif settings.
- **Exit check:** providers return the seed data; a debug screen prints it.

### Stage 4 — Navigation shell (½ day)
- `go_router` with a `ShellRoute` for the 5 tabs + a custom bottom `TabBar` (not Material's).
- Pushed routes for Award, Settings, Article.
- FAB on Home.
- **Exit check:** all 5 tabs reachable, FAB opens an empty Award page, back works.
- Docs: `02_architecture.md` (navigation section).

### Stage 5 — Read‑only screens (2–3 days)
- Build **Home → Profile → Leaderboard → Duty → Info → Article** using Stage‑2 widgets and
  Stage‑3 data. No mutations yet (checklist not tickable, filters can still switch).
- **Exit check:** every screen pixel‑close to the prototype, scrolls cleanly, RU + EN both fit.
- Docs: `06_screens.md`.

### Stage 6 — Interactions & flows (2–3 days)
- **Award Aura** 4‑step flow with validation + animated success.
- **Heart‑loss animation** (tap hearts to demo): scale punch, shard burst, red screen pulse.
- Duty checklist toggling + handoff note field; Leaderboard filter re‑ranking with the pill
  animation; Settings toggles + quiet hours; light/dark toggle.
- **Exit check:** every interaction from the prototype works and is animated.
- Docs: `06_screens.md` (animation sections).

### Stage 7 — Localization & polish (1–2 days)
- Wire `flutter_localizations` + ARB files; move all strings out of widgets.
- Audit every screen in Russian for overflow.
- Reduced‑motion handling, haptics on heart loss / award, empty states.
- **Exit check:** full RU pass with zero overflow warnings.

> **Estimate:** ~10–13 working days for one engineer to reach feature parity with the prototype.
