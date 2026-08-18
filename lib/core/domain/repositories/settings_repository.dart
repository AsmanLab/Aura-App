import '../entities/notif_pref.dart';

abstract class SettingsRepository {
  Future<List<NotifPref>> getNotifPrefs();
  Future<void> setNotifPref(String id, bool enabled);
}
