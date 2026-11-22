import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'local_prefs_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (LocalPrefsService.notificationsEnabled) {
    await NotificationService.showNow(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.data['title'] ?? '숙제버디',
      body: message.data['body'] ?? '',
    );
  }
}

class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen((message) {
      if (LocalPrefsService.notificationsEnabled) {
        NotificationService.showNow(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message.data['title'] ?? '숙제버디',
          body: message.data['body'] ?? '',
        );
      }
    });
  }

  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken().timeout(const Duration(seconds: 4));
    } catch (e) {
      return null;
    }
  }
}
