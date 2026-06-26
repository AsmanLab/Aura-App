import 'dart:async';

import 'package:aura_app/app/aura_app.dart';
import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/services/attendance_notification_service.dart';
import 'package:aura_app/core/services/push_service.dart';
import 'package:aura_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await setupDi();

  runApp(const ProviderScope(child: AuraApp()));

  unawaited(_initPush());
  unawaited(_initAttendanceNotifications());
}

Future<void> _initPush() async {
  try {
    await sl<PushService>().init();
  } catch (e) {
    debugPrint('Push init failed (non-fatal): $e');
  }
}

Future<void> _initAttendanceNotifications() async {
  try {
    final service = AttendanceNotificationService();
    await service.init();
  } catch (e) {
    debugPrint('Attendance notifications init failed (non-fatal): $e');
  }
}
