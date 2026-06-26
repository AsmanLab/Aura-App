import 'package:aura_app/core/models/attendance_transaction.dart';

abstract class AttendanceRepository {
  Future<void> checkIn(double latitude, double longitude);
  Future<void> checkOut(String note);
  Future<void> startLunch(String note);
  Future<void> endLunch(String note);
  Stream<List<AttendanceRecord>> watchMyAttendance(String userId);
  Stream<List<AttendanceStatus>> watchTodayStatuses();
  bool isWithinTimeWindow();
}