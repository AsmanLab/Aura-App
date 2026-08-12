import 'package:aura_app/core/domain/entities/knowledge_doc.dart';

class KnowledgeDocs {
  const KnowledgeDocs._();

  static const List<DocBlock> onDutyBody = [
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
  ];

  static const List<DocBlock> howAuraWorksBody = [
    DocBlock(BlockType.heading, 'The five categories'),
    DocBlock(
      BlockType.paragraph,
      'Mentors and full-timers award points across five categories.',
    ),
  ];

  static const List<DocBlock> heartsTrialBody = [
    DocBlock(BlockType.heading, 'Eight hearts'),
    DocBlock(
      BlockType.paragraph,
      'You start with eight hearts. Losing all of them ends the trial.',
    ),
  ];

  static const List<DocBlock> incidentRunbookBody = [
    DocBlock(BlockType.heading, 'Declare an incident'),
    DocBlock(
      BlockType.paragraph,
      'Page the on-call, open a channel, assign a commander.',
    ),
  ];

  static const List<DocBlock> teamHandbookBody = [
    DocBlock(BlockType.heading, 'Ways of working'),
    DocBlock(
      BlockType.paragraph,
      'Async-first, review everything, ship small.',
    ),
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
      body: onDutyBody,
    ),
    KnowledgeDoc(
      id: 'how-aura-works',
      title: 'How Aura Works',
      titleRu: 'Как работает Aura',
      description: 'Points, categories, and what they mean.',
      readTime: '4 min',
      tag: 'Culture',
      icon: 'sparkle',
      body: howAuraWorksBody,
    ),
    KnowledgeDoc(
      id: 'hearts-and-trial',
      title: 'Hearts & the Trial',
      titleRu: 'Сердца и испытательный',
      description: 'Your margin for error during the 3-month trial.',
      readTime: '5 min',
      tag: 'Onboarding',
      icon: 'heart',
      body: heartsTrialBody,
    ),
    KnowledgeDoc(
      id: 'incident-runbook',
      title: 'Incident Runbook',
      titleRu: 'Регламент инцидентов',
      description: 'Step-by-step for production incidents.',
      readTime: '9 min',
      tag: 'Operations',
      icon: 'flag',
      body: incidentRunbookBody,
    ),
    KnowledgeDoc(
      id: 'team-handbook',
      title: 'Team Handbook',
      titleRu: 'Справочник команды',
      description: 'How we work at APRD.',
      readTime: '12 min',
      tag: 'Culture',
      icon: 'book',
      body: teamHandbookBody,
    ),
  ];
}
