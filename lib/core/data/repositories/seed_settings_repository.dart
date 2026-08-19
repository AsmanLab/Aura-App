import 'package:aura_app/core/domain/entities/notif_pref.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import '../seed/notif_prefs_seed.dart';

class SeedSettingsRepository implements SettingsRepository {
  final List<NotifPref> _prefs = List.from(NotifPrefsSeed.prefs);

  @override
  Future<List<NotifPref>> getNotifPrefs() async => List.unmodifiable(_prefs);

  @override
  Future<void> setNotifPref(String id, bool enabled) async {
    final index = _prefs.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _prefs[index] = _prefs[index].copyWith(enabled: enabled);
    }
  }

  @override
  Stream<int?> watchLeaderboardHighlightColor() => const Stream.empty();

  @override
  Future<int?> getLeaderboardHighlightColor() async => null;

  @override
  Future<void> setLeaderboardHighlightColor(int colorValue) async {}
}
