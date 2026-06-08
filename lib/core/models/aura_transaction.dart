import 'package:cloud_firestore/cloud_firestore.dart';

class AuraTransaction {
  final String id;
  final String fromUserId;
  final String toUserId;
  final int points;
  final String comment;

  /// Category key (e.g. 'codeQuality'). Empty for legacy ±1 transactions.
  final String category;

  // Denormalized giver fields so the history feed renders without extra reads.
  final String fromName;
  final String? fromPhotoURL;

  final DateTime timestamp;
  final String weekId;
  final int schemaVersion;

  AuraTransaction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.points,
    required this.comment,
    this.category = '',
    this.fromName = '',
    this.fromPhotoURL,
    required this.timestamp,
    required this.weekId,
    this.schemaVersion = 1,
  });

  factory AuraTransaction.fromMap(Map<String, dynamic> map, String id) {
    return AuraTransaction(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      points: map['points'] ?? 0,
      comment: map['comment'] ?? '',
      category: map['category'] ?? '',
      fromName: map['fromName'] ?? '',
      fromPhotoURL: map['fromPhotoURL'],
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekId: map['weekId'] ?? '',
      schemaVersion: map['schemaVersion'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'points': points,
      'comment': comment,
      'category': category,
      'fromName': fromName,
      'fromPhotoURL': fromPhotoURL,
      'timestamp': Timestamp.fromDate(timestamp),
      'weekId': weekId,
      'schemaVersion': schemaVersion,
    };
  }
}
