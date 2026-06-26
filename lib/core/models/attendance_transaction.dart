import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'user_model.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String dateKey;
  final double? latitude;
  final double? longitude;
  final String? checkOutNote;
  final int? durationMinutes;
  final DateTime? lunchStart;
  final DateTime? lunchEnd;
  final String? lunchNote;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.dateKey,
    this.latitude,
    this.longitude,
    this.checkOutNote,
    this.durationMinutes,
    this.lunchStart,
    this.lunchEnd,
    this.lunchNote,
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
      checkOutNote: map['checkOutNote'] as String?,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt(),
      lunchStart: (map['lunchStart'] as Timestamp?)?.toDate(),
      lunchEnd: (map['lunchEnd'] as Timestamp?)?.toDate(),
      lunchNote: map['lunchNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'dateKey': dateKey,
    };
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (checkOutNote != null) map['checkOutNote'] = checkOutNote;
    if (durationMinutes != null) map['durationMinutes'] = durationMinutes;
    if (lunchStart != null) map['lunchStart'] = Timestamp.fromDate(lunchStart!);
    if (lunchEnd != null) map['lunchEnd'] = Timestamp.fromDate(lunchEnd!);
    if (lunchNote != null) map['lunchNote'] = lunchNote;
    return map;
  }

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? dateKey,
    double? latitude,
    double? longitude,
    String? checkOutNote,
    int? durationMinutes,
    DateTime? lunchStart,
    DateTime? lunchEnd,
    String? lunchNote,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      dateKey: dateKey ?? this.dateKey,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      checkOutNote: checkOutNote ?? this.checkOutNote,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      lunchStart: lunchStart ?? this.lunchStart,
      lunchEnd: lunchEnd ?? this.lunchEnd,
      lunchNote: lunchNote ?? this.lunchNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        timestamp,
        dateKey,
        latitude,
        longitude,
        checkOutNote,
        durationMinutes,
        lunchStart,
        lunchEnd,
        lunchNote,
      ];
}

class AttendanceStatus {
  final UserModel user;
  final AttendanceRecord? record;

  const AttendanceStatus({required this.user, required this.record});

  bool get isPresent => record != null;
}

String _dateKey(DateTime date) {
  final utc = date.toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$month-$day';
}
