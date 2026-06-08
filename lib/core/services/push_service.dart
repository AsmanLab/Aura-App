import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background (app terminated/backgrounded) message handler.
///
/// Must be a top-level function with @pragma('vm:entry-point') — it runs in a
/// separate isolate. Keep it light. Registered in main.dart via
/// `FirebaseMessaging.onBackgroundMessage`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM already shows tray notifications when the app isn't foregrounded, so
  // nothing is required here. Add background data processing if ever needed.
}

/// FCM + local-notification glue. See commands/09_push_notifications.md.
///
/// In-app side is wired. The platform setup is on you:
///   - iOS: upload the APNs key to Firebase + enable Push / Background
///     "Remote notifications" capabilities in Xcode (§3).
///   - Deploy the `onAuraAwarded` Cloud Function that actually sends on award (§6).
class PushService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _local = FlutterLocalNotificationsPlugin();

  StreamSubscription<User?>? _authSub;

  PushService(this._fcm, this._db, this._auth);

  static const _channel = AndroidNotificationChannel(
    'aura',
    'Aura',
    description: 'Aura points and team updates',
    importance: Importance.high,
  );

  Future<void> init() async {
    // Permission prompt (iOS sheet; Android 13+ POST_NOTIFICATIONS).
    await _fcm.requestPermission();

    // Local-notification setup (used to display FCM messages in foreground).
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        // TODO(you): route from a tapped foreground notification using
        // resp.payload (e.g. GoRouter.of(context).push(payload)).
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // iOS: also show the system banner while in foreground.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages → display via local notifications (FCM won't).
    FirebaseMessaging.onMessage.listen(_showLocal);

    // App opened from a background notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App launched from a terminated state by tapping a notification.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleTap(initial);

    // Save the token whenever a user is signed in (login + cold start).
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) syncToken(user.uid);
    });
  }

  /// Save the device token under the user + keep it fresh.
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

  void _showLocal(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: m.data['route'] as String?,
    );
  }

  void _handleTap(RemoteMessage m) {
    // TODO(you): deep-link to m.data['route'] (e.g. '/aura/profile').
    // Needs the app's router/navigator key — wire when you add deep links.
    debugPrint('Notification tapped, route: ${m.data['route']}');
  }

  void dispose() => _authSub?.cancel();
}
