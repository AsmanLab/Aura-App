import '../../shared/domain/entities/notif_pref.dart';
import '../../shared/domain/repositories/settings_repository.dart';
import '../seed/seed_data.dart';

class SeedSettingsRepository implements SettingsRepository {
  @override
  Future<List<NotifPref>> getNotifPrefs() async => SeedData.notifPrefs;
}
