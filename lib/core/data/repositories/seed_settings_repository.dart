import 'dart:async';

import 'package:aura_app/core/domain/entities/notif_pref.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import '../seed/notif_prefs_seed.dart';

class SeedSettingsRepository implements SettingsRepository {
  static final StreamController<int?> _controller =
      StreamController<int?>.broadcast()..add(0xFF8B5CF6);

  @override
  Stream<int?> watchLeaderboardHighlightColor() => _controller.stream;

  @override
  Future<int?> getLeaderboardHighlightColor() async => 0xFF8B5CF6;

  @override
  Future<void> setLeaderboardHighlightColor(int colorValue) async {
    _controller.add(colorValue);
  }

  @override
  Future<List<NotifPref>> getNotifPrefs() async => NotifPrefsSeed.prefs;

  @override
  Future<void> setNotifPref(String id, bool enabled) async {}
}
