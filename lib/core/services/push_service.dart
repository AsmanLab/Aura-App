import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
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

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _auraSub;

  PushService(this._fcm, this._db, this._auth);

  Future<void> init() async {
    await _fcm.requestPermission(); // iOS sheet; Android 13+ POST_NOTIFICATIONS

    // Foreground: suppress the OS banner (we show our own in-app banner).
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForeground);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onOpened(initial);

    // Persist a rotated token for whoever is signed in.
    _tokenRefreshSub = _fcm.onTokenRefresh.listen((t) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _save(uid, t).catchError((Object e) {
          debugPrint('PushService: token refresh save failed: $e');
        });
      }
    });

    // Cold start with a restored session: the user doc already exists, so
    // saving the token won't create a partial doc. (Interactive sign-in syncs
    // the token AFTER the user doc is created — see AuthRemoteDataSource — so
    // there's no race that writes only `fcmTokens`.)
    final current = _auth.currentUser;
    if (current != null) {
      await syncToken(current.uid);
      _listenAuraTransactions(current.uid);
    }

    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _auraSub?.cancel();
        _auraSub = null;
      } else {
        _listenAuraTransactions(user.uid);
      }
    });
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _auraSub?.cancel();
  }

  /// Save this device's current FCM token under the user. Only call once the
  /// user's Firestore doc exists (otherwise the merge creates a partial doc).
  Future<void> syncToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _save(uid, token);
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

  void _listenAuraTransactions(String uid) {
    _auraSub?.cancel();
    _auraSub = _db
        .collection('aura_transactions')
        .where('toUserId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        final txn = AuraTransaction.fromMap(data, change.doc.id);
        final sign = txn.points >= 0 ? '+' : '';
        final body = txn.fromName.isNotEmpty
            ? '$sign${txn.points} from ${txn.fromName}'
            : '$sign${txn.points} Aura';
        showInAppNotification(
          title: 'Aura ${txn.points >= 0 ? 'received' : 'deducted'}',
          body: body,
          route: '/aura/profile',
        );
      }
    });
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
}
