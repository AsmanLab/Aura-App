import 'package:cloud_firestore/cloud_firestore.dart';

/// A heart change (mentor adds/removes a heart from an intern).
class HeartTransaction {
  final String id;
  final String fromUserId;
  final String fromName;
  final String? fromPhotoURL;
  final String toUserId;

  /// +1 (added) or -1 (removed).
  final int delta;

  /// Required when removing a heart; optional when adding.
  final String comment;

  final DateTime timestamp;
  final String weekId;
  final int schemaVersion;

  HeartTransaction({
    required this.id,
    required this.fromUserId,
    required this.fromName,
    this.fromPhotoURL,
    required this.toUserId,
    required this.delta,
    this.comment = '',
    required this.timestamp,
    required this.weekId,
    this.schemaVersion = 1,
  });

  factory HeartTransaction.fromMap(Map<String, dynamic> map, String id) {
    return HeartTransaction(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      fromName: map['fromName'] ?? '',
      fromPhotoURL: map['fromPhotoURL'],
      toUserId: map['toUserId'] ?? '',
      delta: map['delta'] ?? 0,
      comment: map['comment'] ?? '',
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekId: map['weekId'] ?? '',
      schemaVersion: map['schemaVersion'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromName': fromName,
      'fromPhotoURL': fromPhotoURL,
      'toUserId': toUserId,
      'delta': delta,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
      'weekId': weekId,
      'schemaVersion': schemaVersion,
    };
  }
}
