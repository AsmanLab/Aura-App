import 'dart:async';
import 'dart:convert';

import 'package:aura_app/core/domain/entities/notif_pref.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../seed/notif_prefs_seed.dart';

class SeedSettingsRepository implements SettingsRepository {
  SeedSettingsRepository(this._prefs, this._db, this._auth);

  final SharedPreferences _prefs;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _storageKey = 'notif_prefs';

  List<NotifPref> get _defaults => List.from(NotifPrefsSeed.prefs);

  @override
  Future<List<NotifPref>> getNotifPrefs() async {
    final stored = _prefs.getString(_storageKey);
    if (stored == null) {
      await _persist(_defaults);
      return List<NotifPref>.from(_defaults);
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) {
        await _persist(_defaults);
        return List<NotifPref>.from(_defaults);
      }
      final map = Map<String, dynamic>.from(decoded);
      final result = NotifPrefsSeed.prefs.map((p) {
        final raw = map[p.id];
        final enabled = raw is bool ? raw : p.enabled;
        return p.copyWith(enabled: enabled);
      }).toList();
      return List<NotifPref>.from(result);
    } on FormatException {
      await _persist(_defaults);
      return List<NotifPref>.from(_defaults);
    } on TypeError {
      await _persist(_defaults);
      return List<NotifPref>.from(_defaults);
    }
  }

  @override
  Future<void> setNotifPref(String id, bool enabled) async {
    final current = await getNotifPrefs();
    final updated = current
        .map((p) => p.id == id ? p.copyWith(enabled: enabled) : p)
        .toList();
    await _persist(updated);
    unawaited(_syncToFirestore(updated));
  }

  Future<void> _persist(List<NotifPref> prefs) async {
    final map = <String, bool>{};
    for (final p in prefs) {
      map[p.id] = p.enabled;
    }
    await _prefs.setString(_storageKey, jsonEncode(map));
  }

  Future<void> _syncToFirestore(List<NotifPref> prefs) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final map = <String, bool>{};
    for (final p in prefs) {
      map[p.id] = p.enabled;
    }
    try {
      await _db.collection('users').doc(uid).set({'notifPrefs': map}, SetOptions(merge: true));
    } catch (_) {
      // ignore sync failures; local prefs still work
    }
  }
}
