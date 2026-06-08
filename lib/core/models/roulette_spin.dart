import 'package:cloud_firestore/cloud_firestore.dart';

class RouletteSpin {
  final String userId;
  final int result;
  final DateTime timestamp;

  RouletteSpin({
    required this.userId,
    required this.result,
    required this.timestamp,
  });

  factory RouletteSpin.fromMap(Map<String, dynamic> map) {
    return RouletteSpin(
      userId: map['userId'] ?? '',
      result: map['result'] ?? 0,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'result': result,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}