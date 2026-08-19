import 'package:go_router/go_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:aura_app/core/router/navigation.dart';
import 'package:aura_app/core/widgets/notification_banner.dart';

Future<void> initOneSignal() async {
  await OneSignal.initialize('6582a9d4-e360-46c8-94c5-2f537ea2afca');

  await OneSignal.Notifications.requestPermission(true);

  OneSignal.Notifications.addClickListener(_onClicked);
  OneSignal.Notifications.addForegroundWillDisplayListener(_onForeground);
}

void _onForeground(OSNotificationWillDisplayEvent event) {
  event.preventDefault();
  final notification = event.notification;
  showInAppNotification(
    title: notification.title,
    body: notification.body,
    route: notification.additionalData?['route'] as String?,
  );
  OneSignal.Notifications.displayNotification(notification.notificationId);
}

void _onClicked(OSNotificationClickEvent event) {
  final route = event.notification.additionalData?['route'] as String?;
  if (route != null) {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).push(route);
    }
  }
}
