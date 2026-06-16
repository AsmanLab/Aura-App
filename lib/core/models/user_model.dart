import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? photoURL;
  final int currentWeekAura;
  final int totalAura;
  final Role role;

  /// Job title, e.g. "Frontend Intern". Free text; defaults to the role label.
  final String position;

  /// Remaining hearts (0..maxHearts). Interns lose hearts on negative aura.
  final int hearts;

  final DateTime? lastRouletteDate;

  /// Daily aura-giving quota for non-mentors. `awardDay` is a UTC `yyyymmdd`
  /// key; `awardCount` is how many awards were given on that day. Reset when
  /// the day rolls over. See [DateUtils.currentDayKeyUtc].
  final int awardDay;
  final int awardCount;

  final DateTime createdAt;

  /// Schema version for forward migrations. Bump when the doc shape changes.
  final int schemaVersion;

  /// Forward-compat bucket for experimental/not-yet-typed fields.
  final Map<String, dynamic> metadata;

  static const maxHearts = 8;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.currentWeekAura,
    required this.totalAura,
    this.role = Role.intern,
    this.position = '',
    this.hearts = maxHearts,
    this.lastRouletteDate,
    this.awardDay = 0,
    this.awardCount = 0,
    required this.createdAt,
    this.schemaVersion = 1,
    this.metadata = const {},
  });

  bool get canAward => role.canAward;

  /// Falls back to the role's label when no explicit position is set.
  String get positionLabel => position.isNotEmpty ? position : role.label;

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      currentWeekAura: map['currentWeekAura'] ?? 0,
      totalAura: map['totalAura'] ?? 0,
      role: Role.values.asNameMap()[map['role']] ?? Role.intern,
      position: map['position'] ?? '',
      hearts: map['hearts'] ?? maxHearts,
      lastRouletteDate: (map['lastRouletteDate'] as Timestamp?)?.toDate(),
      awardDay: map['awardDay'] ?? 0,
      awardCount: map['awardCount'] ?? 0,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      schemaVersion: map['schemaVersion'] ?? 1,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? const {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'currentWeekAura': currentWeekAura,
      'totalAura': totalAura,
      'role': role.name,
      'position': position,
      'hearts': hearts,
      'lastRouletteDate':
          lastRouletteDate != null ? Timestamp.fromDate(lastRouletteDate!) : null,
      'awardDay': awardDay,
      'awardCount': awardCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    int? currentWeekAura,
    int? totalAura,
    Role? role,
    String? position,
    int? hearts,
    DateTime? lastRouletteDate,
    int? awardDay,
    int? awardCount,
    int? schemaVersion,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      currentWeekAura: currentWeekAura ?? this.currentWeekAura,
      totalAura: totalAura ?? this.totalAura,
      role: role ?? this.role,
      position: position ?? this.position,
      hearts: hearts ?? this.hearts,
      lastRouletteDate: lastRouletteDate ?? this.lastRouletteDate,
      awardDay: awardDay ?? this.awardDay,
      awardCount: awardCount ?? this.awardCount,
      createdAt: createdAt,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }
}
