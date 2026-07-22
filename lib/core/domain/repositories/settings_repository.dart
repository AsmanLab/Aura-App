import '../entities/notif_pref.dart';

abstract class SettingsRepository {
  Future<List<NotifPref>> getNotifPrefs();

  /// Optional accent color for current user's leaderboard row.
  /// Returns null when not set, or an ARGB int color.
  Stream<int?> watchLeaderboardHighlightColor();
}
