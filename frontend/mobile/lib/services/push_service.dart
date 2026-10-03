import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../screens/notifications_screen.dart';

/// Must be a top-level (or static) function — FCM runs this in a
/// separate isolate when a push arrives while the app is fully
/// terminated or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing to do here: FCM automatically shows a system tray
  // notification for background/terminated messages using the
  // "notification" payload the backend sends. This handler exists so
  // Android permits background delivery at all — actual navigation on
  // tap is handled by onMessageOpenedApp / getInitialMessage below.
}

class PushService {
  /// A global navigator key so we can push screens from outside the
  /// widget tree (e.g. when a notification is tapped while the app
  /// was in the background).
  static final navigatorKey = GlobalKey<NavigatorState>();

  static bool _listenersAttached = false;

  /// Call once per app session after the user is authenticated
  /// (on login, and on every app launch if already logged in).
  /// Requests permission, gets the device's FCM token, and sends it
  /// to the backend so it can target this device with pushes.
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // User said no — in-app notifications still work, just no push.
      return;
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Keep the backend's copy fresh if FCM rotates the token.
    messaging.onTokenRefresh.listen(_registerToken);

    _attachListeners();
  }

  static Future<void> _registerToken(String token) async {
    try {
      await ApiService.put("/users/fcm-token", {"fcmToken": token});
    } catch (_) {
      // Non-fatal — the app still works without push, just retry next launch.
    }
  }

  static void _attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    // App was in the foreground when the push arrived: FCM does NOT
    // auto-show a system notification in this case, so surface it
    // ourselves with a lightweight in-app banner.
    FirebaseMessaging.onMessage.listen((message) {
      final context = navigatorKey.currentContext;
      final notification = message.notification;
      if (context == null || notification == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${notification.title}: ${notification.body}"),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "View",
            onPressed: () => _openNotifications(),
          ),
        ),
      );
    });

    // App was in the background and the user tapped the system notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _openNotifications());

    // App was fully terminated and launched by tapping the notification.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _openNotifications();
    });
  }

  static void _openNotifications() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }
}
