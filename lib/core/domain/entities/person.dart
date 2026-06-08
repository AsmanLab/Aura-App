import 'package:equatable/equatable.dart';

import '../../models/enums.dart';

class Person extends Equatable {
  final String id;
  final String name;
  final String position; // "Frontend Intern"
  final Role role;
  final int aura;
  final int hearts; // 0..8 (interns)
  final bool isYou;
  final DateTime? trialStart; // interns only
  final DateTime? trialEnd;

  const Person({
    required this.id,
    required this.name,
    required this.position,
    required this.role,
    required this.aura,
    this.hearts = 8,
    this.isYou = false,
    this.trialStart,
    this.trialEnd,
  });

  /// Trial completion 0..1 and days remaining, computed against [now].
  /// Null for non-interns / no trial dates.
  ({double pct, int daysLeft})? trial(DateTime now) {
    if (trialStart == null || trialEnd == null) return null;
    final total = trialEnd!.difference(trialStart!).inSeconds;
    if (total <= 0) return null;
    final done = now.difference(trialStart!).inSeconds;
    final pct = (done / total).clamp(0.0, 1.0);
    final left = trialEnd!.difference(now).inDays.clamp(0, 999);
    return (pct: pct, daysLeft: left);
  }

  Person copyWith({int? aura, int? hearts}) => Person(
    id: id,
    name: name,
    position: position,
    role: role,
    aura: aura ?? this.aura,
    hearts: hearts ?? this.hearts,
    isYou: isYou,
    trialStart: trialStart,
    trialEnd: trialEnd,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    position,
    role,
    aura,
    hearts,
    isYou,
    trialStart,
    trialEnd,
  ];
}
