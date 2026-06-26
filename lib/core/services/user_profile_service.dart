import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';

/// Aggregates all per-user data streams into one place.
/// Used by [UserProfileCubit] to drive the unified other-user profile page.
class UserProfileService {
  const UserProfileService(this._profile, this._attendance);

  final ProfileRepository _profile;
  final AttendanceRepository _attendance;

  Stream<UserModel?> watchUser(String id) => _profile.watchUser(id);

  Stream<List<AuraTransaction>> watchAuraHistory(String id) =>
      _profile.watchHistory(id);

  Future<List<HeartTransaction>> getHeartHistory(String id) =>
      _profile.getHeartHistory(id);

  Stream<List<AttendanceRecord>> watchAttendance(String id) =>
      _attendance.watchMyAttendance(id);
}
