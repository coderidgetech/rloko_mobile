import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../network/dio_client.dart';

const _kNotifLogKey = 'fcm_notification_log';
const _kNotifMaxEntries = 50;

/// Android channel id — must match `default_notification_channel_id` in AndroidManifest.xml
/// so background notification-payload messages render on the same channel.
const _kAndroidChannelId = 'rloko_default';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
bool _localNotifInitialized = false;

/// Initializes the local-notifications plugin and creates the Android channel. Idempotent.
Future<void> initLocalNotifications() async {
  if (_localNotifInitialized) return;
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await _localNotifications.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _kAndroidChannelId,
        'General',
        description: 'Order updates and announcements',
        importance: Importance.high,
      ));
  _localNotifInitialized = true;
}

/// Shows a heads-up local notification for an FCM message (used for foreground messages,
/// which Android does NOT auto-display in the tray).
Future<void> _showLocalNotification(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'] ?? '';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  if (title.isEmpty && body.isEmpty) return;
  await initLocalNotifications();
  await _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _kAndroidChannelId,
        'General',
        channelDescription: 'Order updates and announcements',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

/// Background/terminated message handler. Runs in a separate isolate, so Firebase must be
/// re-initialized here. Registered via [FirebaseMessaging.onBackgroundMessage] in main().
/// Must be a top-level function (vm:entry-point) — not a class method or closure.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Already initialized in this isolate — ignore.
  }
  await FCMService._logMessage(message);
}

/// Handles FCM token registration, foreground message display, and local notification log.
/// Call [init] once after the user authenticates. Safe to call multiple times — subsequent
/// calls are no-ops guarded by [_initialized].
class FCMService {
  FCMService(this._client);

  final DioClient _client;
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await initLocalNotifications();
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);

      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((t) => _registerToken(t));

      // Foreground messages: Android won't show these in the tray, so display a local
      // heads-up notification AND log them for the in-app history.
      _messageSub = FirebaseMessaging.onMessage.listen((m) {
        _showLocalNotification(m);
        _logMessage(m);
      });
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] init error: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _client.dio.post<dynamic>(
        '/notifications/device-token',
        data: {'token': token, 'platform': defaultTargetPlatform.name.toLowerCase()},
        options: Options(extra: {'requiresAuth': true}),
      );
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[FCM] token registration error: ${e.message}');
    }
  }

  Future<void> deleteToken() async {
    _tokenRefreshSub?.cancel();
    _messageSub?.cancel();
    _tokenRefreshSub = null;
    _messageSub = null;
    _initialized = false;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _client.dio.delete<dynamic>(
        '/notifications/device-token',
        data: {'token': token},
        options: Options(extra: {'requiresAuth': true}),
      );
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] deleteToken error: $e');
    }
  }

  static Future<void> _logMessage(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_kNotifLogKey) ?? [];
      final entry = jsonEncode({
        'title': message.notification?.title ?? message.data['title'] ?? '',
        'body': message.notification?.body ?? message.data['body'] ?? '',
        'ts': DateTime.now().toIso8601String(),
        'data': message.data,
      });
      final updated = [entry, ...existing];
      if (updated.length > _kNotifMaxEntries) updated.removeRange(_kNotifMaxEntries, updated.length);
      await prefs.setStringList(_kNotifLogKey, updated);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] log error: $e');
    }
  }

  /// Reads the locally stored notification log (newest first).
  static Future<List<NotificationEntry>> readLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kNotifLogKey) ?? [];
    return raw.map((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return NotificationEntry(
          title: m['title'] as String? ?? '',
          body: m['body'] as String? ?? '',
          ts: DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
        );
      } catch (_) {
        return null;
      }
    }).whereType<NotificationEntry>().toList();
  }

  /// Clears the local notification log.
  static Future<void> clearLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kNotifLogKey);
  }
}

class NotificationEntry {
  const NotificationEntry({
    required this.title,
    required this.body,
    required this.ts,
  });
  final String title;
  final String body;
  final DateTime ts;
}
