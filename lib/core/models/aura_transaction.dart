import 'package:cloud_firestore/cloud_firestore.dart';

class AuraTransaction {
  final String id;
  final String fromUserId;
  final String toUserId;
  final int points;
  final String comment;
  final DateTime timestamp;
  final String weekId;

  AuraTransaction({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.points,
    required this.comment,
    required this.timestamp,
    required this.weekId,
  });

  factory AuraTransaction.fromMap(Map<String, dynamic> map, String id) {
    return AuraTransaction(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      points: map['points'] ?? 0,
      comment: map['comment'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      weekId: map['weekId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'points': points,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
      'weekId': weekId,
    };
  }
}