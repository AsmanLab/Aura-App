import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/models/enums.dart';

abstract class LeaderboardRepository {
  /// Users ranked for the given period (all-time → totalAura, week →
  /// currentWeekAura).
  Future<List<UserModel>> getLeaderboard(LbFilter filter);

  /// The signed-in user's uid, to highlight their row.
  String? get currentUserId;
}
