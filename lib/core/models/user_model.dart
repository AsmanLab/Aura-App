import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? photoURL;
  final int currentWeekAura;
  final int totalAura;
  final DateTime? lastRouletteDate;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.currentWeekAura,
    required this.totalAura,
    this.lastRouletteDate,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'],
      currentWeekAura: map['currentWeekAura'] ?? 0,
      totalAura: map['totalAura'] ?? 0,
      lastRouletteDate: (map['lastRouletteDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'currentWeekAura': currentWeekAura,
      'totalAura': totalAura,
      'lastRouletteDate': lastRouletteDate != null 
          ? Timestamp.fromDate(lastRouletteDate!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    int? currentWeekAura,
    int? totalAura,
    DateTime? lastRouletteDate,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      currentWeekAura: currentWeekAura ?? this.currentWeekAura,
      totalAura: totalAura ?? this.totalAura,
      lastRouletteDate: lastRouletteDate ?? this.lastRouletteDate,
      createdAt: createdAt,
    );
  }
}