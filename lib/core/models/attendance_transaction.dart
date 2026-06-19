import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A record of user attendance with optional location data.
class AttendanceRecord extends Equatable {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String dateKey;
  final double? latitude;
  final double? longitude;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.dateKey,
    this.latitude,
    this.longitude,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    final timestamp =
        (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return AttendanceRecord(
      id: id,
      userId: map['userId'] ?? '',
      timestamp: timestamp,
      dateKey: map['dateKey'] ?? _dateKey(timestamp),
      latitude: map['latitude'] != null
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'dateKey': dateKey,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    timestamp,
    dateKey,
    latitude,
    longitude,
  ];
}

String _dateKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
