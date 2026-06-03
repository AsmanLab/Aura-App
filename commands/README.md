# Aura — Flutter Implementation Spec

> Internal tool for **APRD** (Bishkek). Gamifies the 3‑month intern trial and runs the team's
> on‑duty rotation. Dark‑mode‑first, iOS + Android from a single layout (~390px design width).

This folder is the **engineering handoff** for rebuilding the Aura prototype as a production
Flutter app. It is written to be read top‑to‑bottom and implemented stage by stage.

The visual source of truth is the HTML prototype at the project root (`Aura.html`). When a
measurement or behaviour is ambiguous here, **open the prototype and match it**.

---

## How to read these docs

| File | What it covers | Read when |
|------|----------------|-----------|
| [`00_project_overview.md`](00_project_overview.md) | Product scope, the 7 screens, roles, the **stage‑by‑stage build plan** | First. Always. |
| [`01_setup_and_commands.md`](01_setup_and_commands.md) | `flutter create`, dependencies, fonts, every CLI command you'll run | Day 1 setup |
| [`02_architecture.md`](02_architecture.md) | Folder structure, state management, navigation, naming | Before writing code |
| [`03_design_system.md`](03_design_system.md) | Colors, typography, spacing, radii, shadows → `AppTheme` / Dart tokens | Building the theme |
| [`04_widgets.md`](04_widgets.md) | Every reusable widget (Avatar, Hearts, AuraValue, chips, progress…) with Dart skeletons | Building components |
| [`05_data_models.md`](05_data_models.md) | `Person`, `AuraEntry`, `DutyDay`, enums, and seed/mock data | Building the data layer |
| [`06_screens.md`](06_screens.md) | Each of the 7 screens broken into widgets + the heart‑loss & award animations | Building screens |

---

## Quick start

```bash
# 1. Create the app (see 01_setup_and_commands.md for the full flow)
flutter create --org com.aprd --project-name aura aura
cd aura

# 2. Add dependencies
flutter pub add google_fonts go_router flutter_riverpod

# 3. Drop the docs' theme/widgets/models in (lib/ structure in 02_architecture.md)

# 4. Run
flutter run
```

---

## Non‑negotiables (the things that make it "Aura")

1. **The Aura glow.** Points, progress fills and highlights use one violet→pink gradient
   (`#A855F7 → #EC4899`) with a soft outer glow. It must look identical on Home, Profile,
   Leaderboard and the Award flow. One widget (`AuraValue`) owns it.
2. **Hearts are emotional.** 8 hearts = the intern's remaining margin for error; losing all =
   trial ends. Losing one is an **animated, deliberate moment** (scale punch + shard burst +
   red screen pulse), never a silent state change.
3. **Dark‑first, light second.** Build the dark theme first; the light theme is a token swap,
   not a redesign.
4. **Bilingual‑ready (RU + EN).** Never hard‑pack text into fixed widths. All labels go through
   the localization layer; layouts must survive ~1.4× longer Russian strings.
5. **Neutral everything else.** Deep grays/near‑black, one sans (Manrope), numbers in Space
   Grotesk. No Material purple, no default elevation tints, no stock Material switches.

---

## Status of the prototype → app mapping

The HTML prototype already implements: tab navigation, the 4‑step Award flow, leaderboard
filters, the heart‑loss animation, the duty checklist, article reading view, settings with
per‑category notification toggles + quiet hours, and a light/dark toggle. **All of it is in
scope** — these docs cover all of it.
