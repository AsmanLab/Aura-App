import 'package:aura_app/core/models/user_model.dart';

/// A ranked user + their score for the active period.
class LeaderboardEntry {
  final UserModel user;
  final int score;
  const LeaderboardEntry(this.user, this.score);
}
