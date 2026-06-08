import 'package:flutter/material.dart';

/// Leaderboard period filter. Month/Week scale all-time scores so the filter
/// visibly re-ranks (replace with real period sums when the API lands).
enum LbFilter {
  allTime('All-time', 'Всё время', 1.0),
  month('Month', 'Месяц', 0.32),
  week('Week', 'Неделя', 0.06);

  const LbFilter(this.label, this.labelRu, this.scale);

  final String label;
  final String labelRu;
  final double scale;
}

/// Role accents + capabilities. Colors are theme-independent (constants).
/// See commands/05_data_models.md §5.1.
enum Role {
  intern('Intern', 'Стажёр', Color(0xFF22D3EE)),
  fullTime('Full-time', 'Сотрудник', Color(0xFF818CF8)),
  mentor('Mentor', 'Ментор', Color(0xFFC084FC)),
  admin('Admin', 'Админ', Color(0xFFFBBF24));

  const Role(this.label, this.labelRu, this.color);

  final String label;
  final String labelRu;
  final Color color;

  Color get tint => color.withValues(alpha: 0.13);
  bool get canAward => this != Role.intern;
  bool get hasTrial => this == Role.intern;
}

/// The five Aura categories. Icon is a Material glyph approximating the
/// prototype's stroke set (commands/04 §4.11 leaves the icon pack open).
enum AuraCategory {
  productivity(
    'Productivity',
    'Продуктивность',
    Icons.bolt,
    Color(0xFF34D399),
  ),
  initiative(
    'Initiative',
    'Инициатива',
    Icons.rocket_launch,
    Color(0xFFFBBF24),
  ),
  codeQuality(
    'Code Quality',
    'Качество кода',
    Icons.shield,
    Color(0xFFA78BFA),
  ),
  helping(
    'Helping Others',
    'Помощь',
    Icons.volunteer_activism,
    Color(0xFF22D3EE),
  ),
  reliability('Reliability', 'Надёжность', Icons.speed, Color(0xFF60A5FA));

  const AuraCategory(this.label, this.labelRu, this.icon, this.color);

  final String label;
  final String labelRu;
  final IconData icon;
  final Color color;

  Color get tint => color.withValues(alpha: 0.13);

  /// One-line guidance shown under the chip in the Award flow.
  String get hint => switch (this) {
    productivity => 'Shipping meaningful work consistently and on time.',
    initiative => 'Spotting a problem and acting on it without being asked.',
    codeQuality => 'Clean, well-tested, reviewable code.',
    helping => 'Lifting teammates up — pairing, reviews, docs.',
    reliability => 'Being someone the team can always count on.',
  };
}
