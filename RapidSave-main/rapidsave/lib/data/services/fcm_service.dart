import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/network/dio_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmService {
  FcmService._();
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'rapidsave_channel';
  static const _channelName = 'RapidSave Notifications';

  bool _initialized = false;

  /// Called after the user is authenticated.
  /// Sets up FCM and ensures the device token is sent to the backend.
  Future<void> init() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    if (!_initialized) {
      await _setupLocalNotifications();
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _initialized = true;
    }

    // Register the current token immediately, then listen for refreshes.
    await _registerToken();
    _fcm.onTokenRefresh.listen(_sendTokenToServer);
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'RapidSave order and delivery notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation();
    await androidImpl?.createNotificationChannel(channel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'RapidSave order and delivery notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  Future<void> _registerToken() async {
    // On Android, APNS is not used; on iOS the APNS token must be ready first.
    String? token;
    try {
      if (Platform.isIOS) {
        // Ensure APNS token is available before fetching FCM token on iOS.
        await Future.delayed(const Duration(seconds: 1));
      }
      token = await _fcm.getToken();
    } catch (e) {
      // FCM getToken can fail if not connected; retry once after a delay.
      await Future.delayed(const Duration(seconds: 3));
      try {
        token = await _fcm.getToken();
      } catch (_) {
        return;
      }
    }

    if (token == null) return;
    await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    // Retry up to 3 times in case of transient network issues.
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final authToken = await DioClient().getToken();
        if (authToken == null) return; // Not logged in — nothing to register

        await DioClient().dio.post(
          '/users/device-token',
          data: {
            'fcm_token': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
          },
        );
        return; // Success
      } catch (e) {
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
  }

  /// Force-refresh the token and re-register it with the backend.
  /// Call this after login to ensure a fresh token is on the server.
  Future<void> refreshAndRegisterToken() async {
    // deleteToken and registerToken are independent — a failure deleting
    // the old token must not prevent the new one from being registered.
    try {
      await _fcm.deleteToken();
      await Future.delayed(const Duration(seconds: 1));
    } catch (_) {
      // Deletion failed on some devices — continue to register anyway
    }
    await _registerToken();
  }

  Future<void> deleteToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        // Deactivate on backend first (DELETE /api/users/device-token/:token)
        try {
          final authToken = await DioClient().getToken();
          if (authToken != null) {
            await DioClient().dio.delete('/users/device-token/$token');
          }
        } catch (_) {}
      }
      await _fcm.deleteToken();
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }
}
