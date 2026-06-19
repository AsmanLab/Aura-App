import 'package:aura_app/core/models/enums.dart';
import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  /// Ranked entries for the period:
  /// all-time -> totalAura, week -> currentWeekAura, month -> sum of this
  /// month's aura_transactions.
  Stream<List<LeaderboardEntry>> watchLeaderboard(LbFilter filter);

  /// The signed-in user's uid, to highlight their row.
  String? get currentUserId;
}
