import 'package:aura_app/core/services/attendance_service.dart';
import 'package:aura_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:aura_app/core/models/attendance_transaction.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceService _service;

  AttendanceRepositoryImpl() : _service = AttendanceService();

  @override
  Future<void> checkIn(double latitude, double longitude) async {
    await _service.markAttendance(latitude: latitude, longitude: longitude);
  }

  @override
  Future<void> checkOut(String note) async {
    final uid = _service.auth.currentUser!.uid;
    await _service.checkOut(userId: uid, note: note);
  }

  @override
  Future<void> startLunch(String note) async {
    final uid = _service.auth.currentUser!.uid;
    await _service.startLunch(userId: uid, note: note);
  }

  @override
  Future<void> endLunch(String note) async {
    final uid = _service.auth.currentUser!.uid;
    await _service.endLunch(userId: uid, note: note);
  }

  @override
  Stream<List<AttendanceRecord>> watchMyAttendance(String userId) {
    return _service.watchAttendance(userId);
  }

  @override
  bool isWithinTimeWindow() {
    return _service.isWithinTimeWindow();
  }

  @override
  Stream<List<AttendanceStatus>> watchTodayStatuses() {
    return _service.watchTodayAllStatuses();
  }
}