/// Notification service stub. Fill in per-project requirements.
///
/// Uses `firebase_messaging` for push notifications and
/// `flutter_local_notifications` for local display.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Initialize notification channels and request permissions.
  Future<void> init() async {
    // TODO: Initialize firebase_messaging and flutter_local_notifications.
    // 1. Create Android notification channel
    // 2. Request iOS provisional/full notification permission
    // 3. Listen for foreground messages
    // 4. Handle background/terminated message taps
  }

  /// Request notification permission from the user.
  Future<void> requestPermission() async {
    // TODO: Use firebase_messaging to request permission.
  }

  /// Get the FCM device token for push registration.
  Future<String?> getToken() async {
    // TODO: Return FirebaseMessaging.instance.getToken()
    return null;
  }
}
