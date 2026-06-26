import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AttendanceService();

  FirebaseAuth get auth => _auth;

  static DateTime get _now => DateTime.now().toUtc();
  static String get _todayKey => _dateKey(_now);

  Future<void> markAttendance({required double latitude, required double longitude}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    if (!isWithinTimeWindow()) throw Exception('Attendance is available Monday-Friday, 13:00-15:00');
    if (!await _isWithinClassLocation(latitude, longitude)) throw Exception('You are outside the office location');
    final now = _now;
    final recordId = '${currentUser.uid}_${attendanceDateKey(now)}';
    await _firestore.collection('attendance').doc(recordId).set(AttendanceRecord(
      id: recordId,
      userId: currentUser.uid,
      timestamp: now,
      dateKey: attendanceDateKey(now),
      latitude: latitude,
      longitude: longitude,
    ).toMap());
  }

  Future<void> checkOut({required String userId, required String note}) async {
    final now = _now;
    final dateKey = _todayKey;
    final recordRef = _firestore.collection('attendance').doc('${userId}_$dateKey');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(recordRef);
      if (!snapshot.exists) throw Exception('No check-in record found for today');
      transaction.update(recordRef, {'checkOutTimestamp': Timestamp.fromDate(now), 'checkOutNote': note});
    });
  }

  Future<void> startLunch({required String userId, required String note}) async {
    final now = _now;
    final dateKey = _todayKey;
    final recordRef = _firestore.collection('attendance').doc('${userId}_$dateKey');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(recordRef);
      if (!snapshot.exists) throw Exception('No check-in record found');
      transaction.update(recordRef, {'lunchStart': Timestamp.fromDate(now), 'lunchNote': note});
    });
  }

  Future<void> endLunch({required String userId, required String note}) async {
    final now = _now;
    final dateKey = _todayKey;
    final recordRef = _firestore.collection('attendance').doc('${userId}_$dateKey');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(recordRef);
      if (!snapshot.exists) throw Exception('No check-in record found');
      transaction.update(recordRef, {'lunchEnd': Timestamp.fromDate(now), 'lunchNote': note});
    });
  }

  Stream<List<AttendanceRecord>> watchAttendance(String userId) {
    return _firestore.collection('attendance')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id)).toList());
  }

  bool isWithinTimeWindow() {
    final now = _now;
    final weekday = now.weekday;
    if (weekday < 1 || weekday > 5) return false;
    final timeInMinutes = now.hour * 60 + now.minute;
    return timeInMinutes >= 7 * 60 && timeInMinutes <= 9 * 60;
  }

  static String attendanceDateKey(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }

  Stream<List<AttendanceStatus>> watchTodayAllStatuses() {
    late StreamController<List<AttendanceStatus>> controller;
    StreamSubscription<List<UserModel>>? usersSub;
    StreamSubscription<List<AttendanceRecord>>? attendanceSub;
    List<UserModel> users = const [];
    List<AttendanceRecord> records = const [];
    void emit() {
      if (controller.isClosed) return;
      final byUser = <String, AttendanceRecord>{};
      for (final record in records) {
        final prev = byUser[record.userId];
        if (prev == null || record.timestamp.isBefore(prev.timestamp)) byUser[record.userId] = record;
      }
      controller.add(users.map((u) => AttendanceStatus(user: u, record: byUser[u.id])).toList());
    }
    controller = StreamController<List<AttendanceStatus>>(
      onListen: () {
        usersSub = watchAllUsers().listen((v) { users = v; emit(); });
        attendanceSub = watchAttendanceForDate(_now).listen((v) { records = v; emit(); });
      },
      onCancel: () async { await usersSub?.cancel(); await attendanceSub?.cancel(); },
    );
    return controller.stream;
  }

  Stream<List<UserModel>> watchAllUsers() {
    return _firestore.collection('users').snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<AttendanceRecord>> watchAttendanceForDate(DateTime date) {
    return _firestore.collection('attendance').where('dateKey', isEqualTo: attendanceDateKey(date)).snapshots()
        .map((s) => s.docs.map((d) => AttendanceRecord.fromMap(d.data(), d.id)).toList());
  }

  Future<bool> _isWithinClassLocation(double latitude, double longitude) async {
    await _loadOffice();
    _officeLat ??= 42.8735;
    _officeLng ??= 74.5752;
    final distance = Geolocator.distanceBetween(latitude, longitude, _officeLat!, _officeLng!);
    return distance <= 50.0;
  }

  double? _officeLat;
  double? _officeLng;
  Future<void>? _loadingOffice;

  Future<void> _loadOffice() async {
    _loadingOffice ??= _firestore.collection('config').doc('office').get().then((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _officeLat = (data['latitude'] as num?)?.toDouble() ?? 42.8735;
        _officeLng = (data['longitude'] as num?)?.toDouble() ?? 74.5752;
      } else {
        _officeLat = 42.8735;
        _officeLng = 74.5752;
      }
    }).catchError((_) {
      _officeLat = 42.8735;
      _officeLng = 74.5752;
    });
    await _loadingOffice!;
  }

  static String _dateKey(DateTime date) {
    final utc = date.toUtc();
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')}';
  }
}
