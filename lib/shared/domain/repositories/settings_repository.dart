import '../entities/notif_pref.dart';

abstract class SettingsRepository {
  Future<List<NotifPref>> getNotifPrefs();
}
