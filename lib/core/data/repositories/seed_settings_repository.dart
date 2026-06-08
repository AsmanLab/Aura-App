import 'package:aura_app/core/domain/entities/notif_pref.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import '../seed/seed_data.dart';

class SeedSettingsRepository implements SettingsRepository {
  @override
  Future<List<NotifPref>> getNotifPrefs() async => SeedData.notifPrefs;
}
