import 'dart:async';

import 'package:aura_app/core/domain/entities/notif_pref.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import '../seed/seed_data.dart';

class SeedSettingsRepository implements SettingsRepository {
  static final StreamController<int?> _controller =
      StreamController<int?>.broadcast()..add(0xFF8B5CF6);

  @override
  Stream<int?> watchLeaderboardHighlightColor() => _controller.stream;

  @override
  Future<List<NotifPref>> getNotifPrefs() async => SeedData.notifPrefs;

  @override
  Future<void> setNotifPref(String id, bool enabled) async {
    final prefs = SeedData.notifPrefs;
    final index = prefs.indexWhere((p) => p.id == id);
    if (index >= 0) {
      prefs[index] = prefs[index].copyWith(enabled: enabled);
    }
  }

  @override
  Future<int?> getLeaderboardHighlightColor() async => null;

  @override
  Stream<int?> watchLeaderboardHighlightColor() => const Stream.empty();

  @override
  Future<void> setLeaderboardHighlightColor(int colorValue) async {}
}
