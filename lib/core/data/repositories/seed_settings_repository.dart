import 'package:aura_app/core/domain/entities/notif_pref.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import '../seed/notif_prefs_seed.dart';

class SeedSettingsRepository implements SettingsRepository {
  @override
  Future<List<NotifPref>> getNotifPrefs() async => NotifPrefsSeed.prefs;

  @override
  Future<void> setNotifPref(String id, bool enabled) async {}
}
