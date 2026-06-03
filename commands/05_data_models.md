# 05 · Data Models & Seed Data

Plain Dart models + an in‑memory seed repository. No backend in MVP — providers read the seed.
When the API arrives, swap the seed repo for a real one behind the same provider interface.

---

## 5.1 Enums — `data/models/enums.dart`

```dart
import 'package:flutter/material.dart';

enum Role {
  intern   ('Intern',    'Стажёр',    Color(0xFF22D3EE)),
  fullTime ('Full-time', 'Сотрудник', Color(0xFF818CF8)),
  mentor   ('Mentor',    'Ментор',    Color(0xFFC084FC)),
  admin    ('Admin',     'Админ',     Color(0xFFFBBF24));

  const Role(this.label, this.labelRu, this.color);
  final String label, labelRu;
  final Color color;

  Color get tint => color.withOpacity(0.13);
  bool get canAward => this != Role.intern;
  bool get hasTrial => this == Role.intern;
}

enum AuraCategory {
  productivity ('Productivity',   'Продуктивность', 'bolt',   Color(0xFF34D399)),
  initiative   ('Initiative',     'Инициатива',     'rocket', Color(0xFFFBBF24)),
  codeQuality  ('Code Quality',   'Качество кода',  'shield', Color(0xFFA78BFA)),
  helping      ('Helping Others', 'Помощь',         'hands',  Color(0xFF22D3EE)),
  reliability  ('Reliability',    'Надёжность',     'gauge',  Color(0xFF60A5FA));

  const AuraCategory(this.label, this.labelRu, this.icon, this.color);
  final String label, labelRu, icon;
  final Color color;

  /// One-line guidance shown under the chip in the Award flow.
  String get hint => switch (this) {
    productivity => 'Shipping meaningful work consistently and on time.',
    initiative   => 'Spotting a problem and acting on it without being asked.',
    codeQuality  => 'Clean, well-tested, reviewable code.',
    helping      => 'Lifting teammates up — pairing, reviews, docs.',
    reliability  => 'Being someone the team can always count on.',
  };
}
```

---

## 5.2 Models — `data/models/`

### `Person`
```dart
class Person {
  final String id;
  final String name;
  final String position;     // "Frontend Intern"
  final Role role;
  final int aura;
  final int hearts;          // 0..8 (interns)
  final bool isYou;
  final DateTime? trialStart; // interns only
  final DateTime? trialEnd;

  const Person({required this.id, required this.name, required this.position,
    required this.role, required this.aura, this.hearts = 8, this.isYou = false,
    this.trialStart, this.trialEnd});

  /// Trial completion 0..1 and days remaining, computed against `now`.
  ({double pct, int daysLeft})? trial(DateTime now) {
    if (trialStart == null || trialEnd == null) return null;
    final total = trialEnd!.difference(trialStart!).inSeconds;
    final done  = now.difference(trialStart!).inSeconds;
    final pct   = (done / total).clamp(0.0, 1.0);
    final left  = trialEnd!.difference(now).inDays.clamp(0, 999);
    return (pct: pct, daysLeft: left);
  }
}
```

### `AuraEntry`
```dart
class AuraEntry {
  final int id;
  final AuraCategory category;
  final int points;          // can be negative
  final String byPersonId;   // who awarded it
  final String reason;
  final String when;         // human label: "2h ago", "Yesterday" (MVP). Use DateTime in prod.
  final String? linearId;    // "APRD-512" or null
  bool get isNegative => points < 0;
}
```

### `DutyDay`
```dart
class DutyDay {
  final String day;          // "Mon"
  final String date;         // "01"
  final String personId;
  final bool isToday;
}

class ChecklistItem {
  final String id;
  final String text;
  final bool done;
  ChecklistItem copyWith({bool? done}) => ...;
}
```

### `KnowledgeDoc`
```dart
enum BlockType { heading, paragraph, bullet, callout }
class DocBlock { final BlockType type; final String text; }

class KnowledgeDoc {
  final String id, title, titleRu, description, readTime, tag, icon;
  final List<DocBlock> body;
}
```

### `NotificationCategory`
```dart
class NotifPref {
  final String id, icon, label, labelRu, description;
  final bool enabled;
}
```

---

## 5.3 Seed data — `data/seed/seed_data.dart`

Mirror the prototype exactly so screens look identical. Key facts:

**"Now" = 2026‑06‑03 (Wednesday).** Trial math and the duty week key off this.

### People (12)
| id | name | position | role | aura | hearts | trial start→end |
|----|------|----------|------|------|--------|-----------------|
| `aibek` *(you)* | Aibek Toktosunov | Frontend Intern | Intern | 1840 | 6 | 2026‑04‑15 → 07‑15 |
| `aizada` | Aizada Saparova | Backend Intern | Intern | 2120 | 8 | 04‑01 → 07‑01 |
| `daniyar` | Daniyar Usenov | Frontend Intern | Intern | 1980 | 7 | 04‑20 → 07‑20 |
| `bermet` | Bermet Asanova | QA Intern | Intern | 1610 | 8 | 05‑02 → 08‑02 |
| `nurlan` | Nurlan Beishenov | DevOps Intern | Intern | 1490 | 5 | 04‑10 → 07‑10 |
| `cholpon` | Cholpon Kydyrova | Backend Intern | Intern | 1325 | 7 | 05‑12 → 08‑12 |
| `emir` | Emir Satkynov | Mobile Intern | Intern | 1180 | 8 | 05‑20 → 08‑20 |
| `ruslan` | Ruslan Ismailov | Senior Backend | Full‑time | 4200 | — | — |
| `elena` | Elena Kim | Product Engineer | Full‑time | 3650 | — | — |
| `aida` | Aida Nurlanova | Frontend Lead | Mentor | 5120 | — | — |
| `bakyt` | Bakyt Osmonov | Platform Lead | Mentor | 4880 | — | — |
| `damir` | Damir Sultanov | Engineering Manager | Admin | 6010 | — | — |

- **`onDutyNow` = `ruslan`** (the live shift owner shown on Home/Duty).
- **Leaderboard** ranks **interns only** by `aura`. All‑time order: Aizada, Daniyar, Aibek (you,
  rank 3), Bermet, Nurlan, Cholpon, Emir. Month/Week scale the scores (×0.32 / ×0.06) so the
  filter visibly re‑ranks — replace with real period sums when the API lands.

### Aura history (Aibek's feed, newest first)
| pts | category | by | when | linear | reason |
|----|----------|----|------|--------|--------|
| +40 | Code Quality | aida | 2h ago | APRD‑512 | Refactored the auth module — clean, well‑tested PR. |
| +25 | Helping Others | bakyt | Yesterday | — | Paired with Emir for 2h to unblock the build pipeline. |
| +50 | Initiative | aida | 2d ago | APRD‑498 | Proposed and shipped the dark‑mode token system. |
| +30 | Productivity | elena | 3d ago | APRD‑477 | Closed 6 issues in the sprint, ahead of schedule. |
| +20 | Reliability | bakyt | 5d ago | — | On‑duty shift handled with zero missed alerts. |
| **−15** | Code Quality | aida | 1w ago | APRD‑460 | Merged without review — please wait for approvals. |
| +35 | Helping Others | aida | 1w ago | APRD‑441 | Wrote the onboarding doc the whole team now uses. |
| +45 | Initiative | bakyt | 2w ago | APRD‑419 | Built an internal CLI to speed up local setup. |

### Duty week (Mon–Sun, today = Wed 03)
`Mon 01 ruslan · Tue 02 elena · Wed 03 aibek (today) · Thu 04 daniyar · Fri 05 aizada ·
Sat 06 bakyt · Sun 07 nurlan`

My‑shift checklist (Aibek, Wed): monitoring dashboards ✓, triage alerts ✓, P1 within 15 min ☐,
post status in #on‑duty ☐, write handoff note ☐.

### Knowledge docs (5)
`On-Duty Guide` (Operations, 6 min) · `How Aura Works` (Culture, 4 min) ·
`Hearts & the Trial` (Onboarding, 5 min) · `Incident Runbook` (Operations, 9 min) ·
`Team Handbook` (Culture, 12 min). The first is the **featured "START HERE"** card. Full block
content is in the prototype's `aura/data.jsx → DOCS`; copy it verbatim.

### Notification categories (defaults)
Duty ✓ · Aura ✓ · Hearts ✓ · Milestones ✓ · Announcements ☐. Plus **quiet hours** on, 22:00–09:00.

---

## 5.4 Providers — `data/providers/`

```dart
final nowProvider        = Provider<DateTime>((_) => DateTime(2026, 6, 3));   // swap for DateTime.now() in prod
final peopleProvider     = Provider<List<Person>>((_) => SeedData.people);
final meProvider         = Provider<Person>((ref) => ref.watch(peopleProvider).firstWhere((p) => p.isYou));
final onDutyProvider     = Provider<Person>((ref) => ref.read(peopleProvider).firstWhere((p) => p.id == 'ruslan'));

final leaderboardProvider = Provider.family<List<Person>, LbFilter>((ref, f) { /* interns, scaled, sorted */ });

final auraHistoryProvider = Provider<List<AuraEntry>>((_) => SeedData.history);
final dutyWeekProvider    = Provider<List<DutyDay>>((_) => SeedData.dutyWeek);
final checklistProvider   = NotifierProvider<ChecklistNotifier, List<ChecklistItem>>(...); // tickable
final docsProvider        = Provider<List<KnowledgeDoc>>((_) => SeedData.docs);
final notifPrefsProvider  = NotifierProvider<NotifPrefsNotifier, List<NotifPref>>(...);     // persisted

// Award flow draft (cleared on close)
final awardDraftProvider  = NotifierProvider<AwardDraftNotifier, AwardDraft>(...);
```

`AwardDraft { String? internId; AuraCategory? category; int points = 25; String comment = '';
bool attachLinear = false; }` — mutated step‑by‑step, validated before "Award".
