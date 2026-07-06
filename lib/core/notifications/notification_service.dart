import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_fire_repository.dart';

/// Background/terminated FCM handler. Must be a top-level, vm-entry-point
/// function. Our messages carry a `notification` block, so Android shows the
/// tray/heads-up automatically here — nothing to do but exist and be registered
/// (in `main()`, before `runApp`).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Wires FCM + local notifications into the app: registers the device token,
/// shows a heads-up on foreground alerts, and deep-links a tap to `/incident`.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel fireChannel = AndroidNotificationChannel(
    'fire_alerts', // MUST match the channel_id alert-service sends and the manifest meta-data
    'Fire alerts',
    description: 'Critical fire-detection alerts',
    importance: Importance.max,
    playSound: true,
  );

  static const String _smallIcon = 'ic_stat_fire';
  static const int _notifId = 42; // fixed id → a new alert replaces the previous heads-up

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  ApiFireRepository? _repo;
  GoRouter? _router;
  bool _inited = false;

  Future<void> init({required ApiFireRepository repo, required GoRouter router}) async {
    if (_inited) return;
    _inited = true;
    _repo = repo;
    _router = router;

    try {
      // Local notifications (used to display foreground alerts) + the channel.
      const androidInit = AndroidInitializationSettings(_smallIcon);
      await _fln.initialize(
        settings: const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: _onLocalTap,
      );
      final android = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(fireChannel);

      // Permissions: iOS prompt + Android 13+ POST_NOTIFICATIONS.
      await FirebaseMessaging.instance.requestPermission();
      await android?.requestNotificationsPermission();

      // Register this device's token, and keep it fresh.
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _repo?.registerToken(token, label: 'FireWatch app');
      }
      FirebaseMessaging.instance.onTokenRefresh
          .listen((t) => _repo?.registerToken(t, label: 'FireWatch app'));

      // Foreground alerts: build a heads-up ourselves + refresh state.
      FirebaseMessaging.onMessage.listen(_onForeground);

      // Taps that opened/brought the app forward.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _openIncident(m.data));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Terminated-launch: navigate after the first frame so the router exists.
        WidgetsBinding.instance.addPostFrameCallback((_) => _openIncident(initial.data));
      }
    } catch (e) {
      debugPrint('[NotificationService] init failed (push disabled): $e');
    }
  }

  Future<void> _onForeground(RemoteMessage msg) async {
    await _repo?.refresh(); // dashboard reflects the fire immediately
    final n = msg.notification;
    await _fln.show(
      id: _notifId,
      title: n?.title ?? '🔥 Fire detected',
      body: n?.body ?? 'Two AI checks confirmed flames. Tap for your safe route.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          fireChannel.id,
          fireChannel.name,
          channelDescription: fireChannel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: _smallIcon,
          color: const Color(0xFFFF3B30),
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: jsonEncode(msg.data),
    );
  }

  void _onLocalTap(NotificationResponse resp) {
    final payload = resp.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      _openIncident((jsonDecode(payload) as Map).cast<String, dynamic>());
    } catch (_) {/* ignore malformed payload */}
  }

  Future<void> _openIncident(Map<String, dynamic> data) async {
    final id = (data['incidentId'] as String?) ?? '';
    if (id.isNotEmpty) {
      await _repo?.loadIncident(id, fallbackData: data);
    } else {
      _repo?.applyFcmData(data);
    }
    _router?.go('/incident');
  }
}
