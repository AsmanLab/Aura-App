import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/router/navigation.dart';
import 'package:aura_app/core/widgets/notification_banner.dart';

/// Background (app terminated/backgrounded) message handler.
///
/// Top-level + @pragma('vm:entry-point') — runs in its own isolate. FCM shows
/// the system tray notification automatically when the app isn't foregrounded,
/// so nothing is needed here. Registered in main.dart.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// FCM glue. Foreground messages show a styled in-app banner; backgrounded /
/// terminated messages are shown by the OS (FCM), and tapping them deep-links.
///
/// You still need to: upload the APNs key (iOS, §3) and deploy the
/// `onAuraAwarded` Cloud Function that actually sends (§6) — see
/// commands/09_push_notifications.md.
class PushService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSub;

  PushService(this._fcm, this._db, this._auth);

  Future<void> init() async {
    await _fcm.requestPermission(); // iOS sheet; Android 13+ POST_NOTIFICATIONS

    // Foreground: suppress the OS banner (we show our own in-app banner).
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onOpened(initial);

    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) syncToken(user.uid);
    });
  }

  Future<void> syncToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _save(uid, token);
      _fcm.onTokenRefresh.listen((t) => _save(uid, t));
    } catch (e) {
      debugPrint('PushService.syncToken failed: $e');
    }
  }

  Future<void> _save(String uid, String token) => _db
      .collection('users')
      .doc(uid)
      .set({'fcmTokens': FieldValue.arrayUnion([token])},
          SetOptions(merge: true));

  /// Remove this device's token. Call BEFORE signing out (needs the uid).
  Future<void> removeToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).set(
          {'fcmTokens': FieldValue.arrayRemove([token])},
          SetOptions(merge: true),
        );
      }
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('PushService.removeToken failed: $e');
    }
  }

  void _onForeground(RemoteMessage m) {
    final n = m.notification;
    showInAppNotification(
      title: n?.title ?? m.data['title'] as String?,
      body: n?.body ?? m.data['body'] as String?,
      route: m.data['route'] as String?,
    );
  }

  void _onOpened(RemoteMessage m) {
    final route = m.data['route'] as String?;
    if (route != null) rootNavigatorKey.currentContext?.push(route);
  }

  void dispose() => _authSub?.cancel();
}
