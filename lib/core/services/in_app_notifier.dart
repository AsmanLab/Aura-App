import 'package:aura_app/core/widgets/notification_banner.dart';

class InAppNotifier {
  static void awardSuccess({required int points, required int count}) {
    final title = count > 1 ? 'Aura awarded' : 'Aura awarded';
    final body = count > 1 ? '+$points to $count people' : '+$points aura';
    showInAppNotification(title: title, body: body);
  }

  static void heartChanged({required String userName, required int delta}) {
    final sign = delta > 0 ? '+' : '';
    showInAppNotification(
      title: 'Hearts updated',
      body: '$userName: $sign$delta heart(s)',
    );
  }

  static void dutyChanged({required String userName, required String date}) {
    showInAppNotification(
      title: 'Duty updated',
      body: '$userName on $date',
    );
  }

  static void settingsChanged({required String label}) {
    showInAppNotification(
      title: 'Settings updated',
      body: '$label preference changed',
    );
  }
}
