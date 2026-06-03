import '../../shared/domain/entities/aura_entry.dart';
import '../../shared/domain/entities/duty_day.dart';
import '../../shared/domain/entities/knowledge_doc.dart';
import '../../shared/domain/entities/notif_pref.dart';
import '../../shared/domain/entities/person.dart';
import '../../shared/models/enums.dart';

/// In-memory seed mirroring the prototype. Swap for a real backend behind the
/// same repository interfaces when the API lands. See commands/05_data_models.md.
class SeedData {
  const SeedData._();

  /// "Now" the whole app keys off (trial math, duty week).
  static final DateTime now = DateTime(2026, 6, 3); // Wednesday

  static const String onDutyId = 'ruslan';

  static final List<Person> people = [
    Person(
      id: 'aibek',
      name: 'Aibek Toktosunov',
      position: 'Frontend Intern',
      role: Role.intern,
      aura: 1840,
      hearts: 6,
      isYou: true,
      trialStart: DateTime(2026, 4, 15),
      trialEnd: DateTime(2026, 7, 15),
    ),
    Person(
      id: 'aizada',
      name: 'Aizada Saparova',
      position: 'Backend Intern',
      role: Role.intern,
      aura: 2120,
      hearts: 8,
      trialStart: DateTime(2026, 4, 1),
      trialEnd: DateTime(2026, 7, 1),
    ),
    Person(
      id: 'daniyar',
      name: 'Daniyar Usenov',
      position: 'Frontend Intern',
      role: Role.intern,
      aura: 1980,
      hearts: 7,
      trialStart: DateTime(2026, 4, 20),
      trialEnd: DateTime(2026, 7, 20),
    ),
    Person(
      id: 'bermet',
      name: 'Bermet Asanova',
      position: 'QA Intern',
      role: Role.intern,
      aura: 1610,
      hearts: 8,
      trialStart: DateTime(2026, 5, 2),
      trialEnd: DateTime(2026, 8, 2),
    ),
    Person(
      id: 'nurlan',
      name: 'Nurlan Beishenov',
      position: 'DevOps Intern',
      role: Role.intern,
      aura: 1490,
      hearts: 5,
      trialStart: DateTime(2026, 4, 10),
      trialEnd: DateTime(2026, 7, 10),
    ),
    Person(
      id: 'cholpon',
      name: 'Cholpon Kydyrova',
      position: 'Backend Intern',
      role: Role.intern,
      aura: 1325,
      hearts: 7,
      trialStart: DateTime(2026, 5, 12),
      trialEnd: DateTime(2026, 8, 12),
    ),
    Person(
      id: 'emir',
      name: 'Emir Satkynov',
      position: 'Mobile Intern',
      role: Role.intern,
      aura: 1180,
      hearts: 8,
      trialStart: DateTime(2026, 5, 20),
      trialEnd: DateTime(2026, 8, 20),
    ),
    Person(
      id: 'ruslan',
      name: 'Ruslan Ismailov',
      position: 'Senior Backend',
      role: Role.fullTime,
      aura: 4200,
    ),
    Person(
      id: 'elena',
      name: 'Elena Kim',
      position: 'Product Engineer',
      role: Role.fullTime,
      aura: 3650,
    ),
    Person(
      id: 'aida',
      name: 'Aida Nurlanova',
      position: 'Frontend Lead',
      role: Role.mentor,
      aura: 5120,
    ),
    Person(
      id: 'bakyt',
      name: 'Bakyt Osmonov',
      position: 'Platform Lead',
      role: Role.mentor,
      aura: 4880,
    ),
    Person(
      id: 'damir',
      name: 'Damir Sultanov',
      position: 'Engineering Manager',
      role: Role.admin,
      aura: 6010,
    ),
  ];

  /// Aibek's feed, newest first.
  static const List<AuraEntry> history = [
    AuraEntry(
      id: 1,
      category: AuraCategory.codeQuality,
      points: 40,
      byPersonId: 'aida',
      when: '2h ago',
      linearId: 'APRD-512',
      reason: 'Refactored the auth module — clean, well-tested PR.',
    ),
    AuraEntry(
      id: 2,
      category: AuraCategory.helping,
      points: 25,
      byPersonId: 'bakyt',
      when: 'Yesterday',
      reason: 'Paired with Emir for 2h to unblock the build pipeline.',
    ),
    AuraEntry(
      id: 3,
      category: AuraCategory.initiative,
      points: 50,
      byPersonId: 'aida',
      when: '2d ago',
      linearId: 'APRD-498',
      reason: 'Proposed and shipped the dark-mode token system.',
    ),
    AuraEntry(
      id: 4,
      category: AuraCategory.productivity,
      points: 30,
      byPersonId: 'elena',
      when: '3d ago',
      linearId: 'APRD-477',
      reason: 'Closed 6 issues in the sprint, ahead of schedule.',
    ),
    AuraEntry(
      id: 5,
      category: AuraCategory.reliability,
      points: 20,
      byPersonId: 'bakyt',
      when: '5d ago',
      reason: 'On-duty shift handled with zero missed alerts.',
    ),
    AuraEntry(
      id: 6,
      category: AuraCategory.codeQuality,
      points: -15,
      byPersonId: 'aida',
      when: '1w ago',
      linearId: 'APRD-460',
      reason: 'Merged without review — please wait for approvals.',
    ),
    AuraEntry(
      id: 7,
      category: AuraCategory.helping,
      points: 35,
      byPersonId: 'aida',
      when: '1w ago',
      linearId: 'APRD-441',
      reason: 'Wrote the onboarding doc the whole team now uses.',
    ),
    AuraEntry(
      id: 8,
      category: AuraCategory.initiative,
      points: 45,
      byPersonId: 'bakyt',
      when: '2w ago',
      linearId: 'APRD-419',
      reason: 'Built an internal CLI to speed up local setup.',
    ),
  ];

  /// Mon–Sun, today = Wed 03.
  static const List<DutyDay> dutyWeek = [
    DutyDay(day: 'Mon', date: '01', personId: 'ruslan'),
    DutyDay(day: 'Tue', date: '02', personId: 'elena'),
    DutyDay(day: 'Wed', date: '03', personId: 'aibek', isToday: true),
    DutyDay(day: 'Thu', date: '04', personId: 'daniyar'),
    DutyDay(day: 'Fri', date: '05', personId: 'aizada'),
    DutyDay(day: 'Sat', date: '06', personId: 'bakyt'),
    DutyDay(day: 'Sun', date: '07', personId: 'nurlan'),
  ];

  /// Aibek's Wed shift checklist.
  static const List<ChecklistItem> checklist = [
    ChecklistItem(id: 'c1', text: 'Check monitoring dashboards', done: true),
    ChecklistItem(id: 'c2', text: 'Triage incoming alerts', done: true),
    ChecklistItem(id: 'c3', text: 'Acknowledge P1 within 15 min'),
    ChecklistItem(id: 'c4', text: 'Post status in #on-duty'),
    ChecklistItem(id: 'c5', text: 'Write handoff note'),
  ];

  static const List<KnowledgeDoc> docs = [
    KnowledgeDoc(
      id: 'on-duty-guide',
      title: 'On-Duty Guide',
      titleRu: 'Гид по дежурству',
      description: 'Everything you need for your first responder shift.',
      readTime: '6 min',
      tag: 'Operations',
      icon: 'shield',
      featured: true,
      body: [
        DocBlock(BlockType.heading, 'Before your shift'),
        DocBlock(
          BlockType.paragraph,
          'Confirm access to dashboards and the alert channel the day before.',
        ),
        DocBlock(BlockType.bullet, 'Open the monitoring dashboards.'),
        DocBlock(BlockType.bullet, 'Acknowledge alerts within 15 minutes.'),
        DocBlock(
          BlockType.callout,
          'A missed P1 costs the team a heart — stay reachable.',
        ),
      ],
    ),
    KnowledgeDoc(
      id: 'how-aura-works',
      title: 'How Aura Works',
      titleRu: 'Как работает Aura',
      description: 'Points, categories, and what they mean.',
      readTime: '4 min',
      tag: 'Culture',
      icon: 'sparkle',
      body: [
        DocBlock(BlockType.heading, 'The five categories'),
        DocBlock(
          BlockType.paragraph,
          'Mentors and full-timers award points across five categories.',
        ),
      ],
    ),
    KnowledgeDoc(
      id: 'hearts-and-trial',
      title: 'Hearts & the Trial',
      titleRu: 'Сердца и испытательный',
      description: 'Your margin for error during the 3-month trial.',
      readTime: '5 min',
      tag: 'Onboarding',
      icon: 'heart',
      body: [
        DocBlock(BlockType.heading, 'Eight hearts'),
        DocBlock(
          BlockType.paragraph,
          'You start with eight hearts. Losing all of them ends the trial.',
        ),
      ],
    ),
    KnowledgeDoc(
      id: 'incident-runbook',
      title: 'Incident Runbook',
      titleRu: 'Регламент инцидентов',
      description: 'Step-by-step for production incidents.',
      readTime: '9 min',
      tag: 'Operations',
      icon: 'flag',
      body: [
        DocBlock(BlockType.heading, 'Declare an incident'),
        DocBlock(
          BlockType.paragraph,
          'Page the on-call, open a channel, assign a commander.',
        ),
      ],
    ),
    KnowledgeDoc(
      id: 'team-handbook',
      title: 'Team Handbook',
      titleRu: 'Справочник команды',
      description: 'How we work at APRD.',
      readTime: '12 min',
      tag: 'Culture',
      icon: 'book',
      body: [
        DocBlock(BlockType.heading, 'Ways of working'),
        DocBlock(
          BlockType.paragraph,
          'Async-first, review everything, ship small.',
        ),
      ],
    ),
  ];

  static const List<NotifPref> notifPrefs = [
    NotifPref(
      id: 'duty',
      icon: 'shield',
      label: 'Duty',
      labelRu: 'Дежурство',
      description: 'Shift reminders and handoffs.',
      enabled: true,
    ),
    NotifPref(
      id: 'aura',
      icon: 'sparkle',
      label: 'Aura',
      labelRu: 'Aura',
      description: 'When someone awards you points.',
      enabled: true,
    ),
    NotifPref(
      id: 'hearts',
      icon: 'heart',
      label: 'Hearts',
      labelRu: 'Сердца',
      description: 'Heart changes and trial status.',
      enabled: true,
    ),
    NotifPref(
      id: 'milestones',
      icon: 'trophy',
      label: 'Milestones',
      labelRu: 'Этапы',
      description: 'Rank changes and achievements.',
      enabled: true,
    ),
    NotifPref(
      id: 'announcements',
      icon: 'bell',
      label: 'Announcements',
      labelRu: 'Объявления',
      description: 'Team-wide news.',
      enabled: false,
    ),
  ];
}
