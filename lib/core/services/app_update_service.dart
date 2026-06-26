import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_app/core/utils/dialogs/update_bottom_sheet.dart';

class AppUpdateService {
  AppUpdateService(this._remoteConfig, this._prefs);

  final FirebaseRemoteConfig _remoteConfig;
  final SharedPreferences _prefs;

  static const _snoozeKey = 'update_snoozed_until';

  Future<void> init() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration(
        // In debug mode fetch every time; prod cache 1 hour.
        hours: const bool.fromEnvironment('dart.vm.product') ? 1 : 0,
      ),
    ));

    await _remoteConfig.setDefaults({
      'latest_build_number': 0,
      'min_build_number': 0,
      'update_url_ios': '',
      'update_url_android': '',
      'update_message': 'A new version is available with improvements and bug fixes.',
    });
  }

  /// Call once after the user is authenticated (cold-start only).
  Future<void> checkAndPrompt(BuildContext context) async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Remote Config unreachable — silently skip, defaults apply.
      return;
    }

    final latestBuild = _remoteConfig.getInt('latest_build_number');
    final minBuild = _remoteConfig.getInt('min_build_number');

    if (latestBuild == 0) return; // Remote Config not yet configured.

    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;

    if (currentBuild >= latestBuild) return; // Already up to date.

    final isForced = minBuild > 0 && currentBuild < minBuild;

    if (!isForced) {
      final snoozedUntil = _prefs.getInt(_snoozeKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < snoozedUntil) return;
    }

    final message = _remoteConfig.getString('update_message');
    final url = Platform.isIOS
        ? _remoteConfig.getString('update_url_ios')
        : _remoteConfig.getString('update_url_android');

    if (url.isEmpty || !context.mounted) return;

    await showUpdateBottomSheet(
      context,
      message: message,
      updateUrl: url,
      isForced: isForced,
      onSnooze: () {
        final until = DateTime.now()
            .add(const Duration(hours: 24))
            .millisecondsSinceEpoch;
        _prefs.setInt(_snoozeKey, until);
      },
    );
  }
}
