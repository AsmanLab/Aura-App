import 'package:equatable/equatable.dart';

import '../../models/enums.dart';

class AuraEntry extends Equatable {
  final int id;
  final AuraCategory category;
  final int points; // can be negative
  final String byPersonId; // who awarded it
  final String reason;
  final String when; // human label: "2h ago" (MVP). Use DateTime in prod.
  final String? linearId; // "APRD-512" or null

  const AuraEntry({
    required this.id,
    required this.category,
    required this.points,
    required this.byPersonId,
    required this.reason,
    required this.when,
    this.linearId,
  });

  bool get isNegative => points < 0;

  @override
  List<Object?> get props => [
    id,
    category,
    points,
    byPersonId,
    reason,
    when,
    linearId,
  ];
}
