import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  static const bool _geofenceEnabled = bool.fromEnvironment(
    'ATTENDANCE_GEOFENCE_ENABLED',
    defaultValue: false,
  );
  static final double _classLatitude =
      double.tryParse(
        const String.fromEnvironment('ATTENDANCE_CLASS_LATITUDE'),
      ) ??
      0;
  static final double _classLongitude =
      double.tryParse(
        const String.fromEnvironment('ATTENDANCE_CLASS_LONGITUDE'),
      ) ??
      0;
  static final double _classRadiusMeters =
      double.tryParse(
        const String.fromEnvironment('ATTENDANCE_CLASS_RADIUS_METERS'),
      ) ??
      150;

  Future<void> markAttendance({
    required double latitude,
    required double longitude,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    if (!isWithinTimeWindow()) {
      throw Exception('Attendance is available Monday-Friday, 11:00-13:00');
    }
    if (!_isWithinClassLocation(latitude, longitude)) {
      throw Exception('You are outside the class location');
    }

    final now = DateTime.now();
    final dateKey = attendanceDateKey(now);
    final recordId = '${currentUser.uid}_$dateKey';
    final record = AttendanceRecord(
      id: recordId,
      userId: currentUser.uid,
      timestamp: now,
      dateKey: dateKey,
      latitude: latitude,
      longitude: longitude,
    );

    await _firestore
        .collection('attendance')
        .doc(record.id.isEmpty ? _uuid.v4() : record.id)
        .set(record.toMap(), SetOptions(merge: false));
  }

  Stream<List<AttendanceRecord>> watchAttendance(String userId) {
    return _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<AttendanceRecord>> getAttendanceForMonth(
    String userId,
    DateTime month,
  ) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(
      month.year,
      month.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));

    final snapshot = await _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
        .toList();
  }

  bool isWithinTimeWindow() {
    final now = DateTime.now();
    final weekday = now.weekday;

    if (weekday < DateTime.monday || weekday > DateTime.friday) return false;

    final timeInMinutes = now.hour * 60 + now.minute;
    const startMinutes = 11 * 60;
    const endMinutes = 13 * 60;

    return timeInMinutes >= startMinutes && timeInMinutes <= endMinutes;
  }

  String attendanceDateKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Stream<List<UserModel>> watchInterns() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: Role.intern.name)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => UserModel.fromMap(doc.data(), doc.id))
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName)),
        );
  }

  Stream<List<AttendanceRecord>> watchAttendanceForDate(DateTime date) {
    return _firestore
        .collection('attendance')
        .where('dateKey', isEqualTo: attendanceDateKey(date))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<AttendanceStatus>> watchTodayInternStatuses() {
    late StreamController<List<AttendanceStatus>> controller;
    StreamSubscription<List<UserModel>>? internsSub;
    StreamSubscription<List<AttendanceRecord>>? attendanceSub;
    List<UserModel> interns = const [];
    List<AttendanceRecord> records = const [];

    void emit() {
      if (controller.isClosed) return;
      final byUser = <String, AttendanceRecord>{};
      for (final record in records) {
        final previous = byUser[record.userId];
        if (previous == null || record.timestamp.isBefore(previous.timestamp)) {
          byUser[record.userId] = record;
        }
      }
      controller.add(
        interns
            .map(
              (user) => AttendanceStatus(user: user, record: byUser[user.id]),
            )
            .toList(),
      );
    }

    controller = StreamController<List<AttendanceStatus>>(
      onListen: () {
        internsSub = watchInterns().listen((value) {
          interns = value;
          emit();
        }, onError: controller.addError);
        attendanceSub = watchAttendanceForDate(DateTime.now()).listen((value) {
          records = value;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await internsSub?.cancel();
        await attendanceSub?.cancel();
      },
    );

    return controller.stream;
  }

  bool _isWithinClassLocation(double latitude, double longitude) {
    if (!_geofenceEnabled) return true;
    final distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      _classLatitude,
      _classLongitude,
    );
    return distance <= _classRadiusMeters;
  }
}

class AttendanceStatus {
  final UserModel user;
  final AttendanceRecord? record;

  const AttendanceStatus({required this.user, required this.record});

  bool get isPresent => record != null;
}
