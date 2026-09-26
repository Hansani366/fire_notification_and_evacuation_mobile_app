import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/api_client.dart';
import '../../data/api/api_fire_repository.dart';
import '../config/app_config.dart';

/// Background/terminated FCM handler. Must be a top-level, vm-entry-point
/// function. Our messages carry a `notification` block, so Android draws the
/// tray/heads-up itself — the only work here is closing the delivery round trip.
///
/// This runs in a SEPARATE ISOLATE with none of `main()`'s state: no repository
/// and no router. The base URL is compiled in, so it only has to read the device
/// token back from shared_preferences before posting. It is also the case that
/// matters most for Table 3.19 — an alert arriving on a phone in somebody's
/// pocket at night is the delivery the whole measurement is about, and it is the
/// one a foreground-only acknowledgement would never see.
///
/// Everything is wrapped: a failure here must never take down the handler that
/// Android relies on to deliver the notification.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final id = (message.data['incidentId'] as String?) ?? '';
    if (id.isEmpty) return;
    final token = await AppConfig.deviceToken();
    if (token == null) return;
    final api = ApiClient();
    try {
      await api.reportDelivered(id, token, state: 'background');
    } finally {
      api.close();
    }
  } catch (e) {
    debugPrint('[fcm-bg] delivery report failed: $e');
  }
}

/// Wires FCM + local notifications into the app: registers the device token,
/// builds the alert Android shows, and deep-links a tap to `/incident`.
///
/// WHO DRAWS THE NOTIFICATION DEPENDS ON THE APP'S STATE, AND BOTH PATHS ARE
/// REAL. `alert-service` sends a `notification` block alongside the data, so
/// when the app is backgrounded or terminated **Android** posts the alert from
/// that block: it appears on the real lock screen, on the fire channel, at
/// `Importance.max`. When the app is running, FCM hands the message to
/// [_onForeground] instead and the alert is built here, where a full-screen
/// intent can be attached.
///
/// The split is deliberate. A notification the system draws cannot be lost by
/// our isolate failing to start, which for a fire alarm is the failure that
/// matters most; the price is that the block carries no full-screen intent,
/// because FCM has no field for one. Moving fire pushes to data-only would buy
/// the takeover in every state and put the alarm behind our own code running
/// first — a trade this prototype does not make.
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

  /// A SEPARATE, QUIETER CHANNEL, ON PURPOSE.
  ///
  /// Gas sensors react to cooking, aerosols, solvents and vehicle exhaust, so
  /// gas warnings are the ones that will occasionally be wrong. If they arrived
  /// on [fireChannel] they would play the fire sound at full volume — and after
  /// two or three false alarms from someone's frying pan, people mute that
  /// channel. Muting it silences the *real* fire alert too. A quiet channel for
  /// the noisy signal is what keeps the loud one worth trusting.
  ///
  /// The id must match `fcm.WARNING_CHANNEL_ID` in alert-service exactly. Until
  /// this channel existed, Android had nowhere to put these and fell back to its
  /// own default.
  static const AndroidNotificationChannel gasChannel = AndroidNotificationChannel(
    'gas_warnings',
    'Gas warnings',
    description: 'Sensor readings above normal. Not a fire alarm.',
    importance: Importance.defaultImportance, // deliberately not .max
    playSound: false,
  );

  static const String _smallIcon = 'ic_stat_fire';

  /// SEPARATE IDS PER CHANNEL. With one fixed id, a gas warning arriving during
  /// a live fire replaced the fire's heads-up — the quiet message evicting the
  /// loud one. Within a channel the id stays fixed, so a newer alert still
  /// supersedes an older one of the same kind.
  static const int _fireNotifId = 42;
  static const int _gasNotifId = 43;

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
      await android?.createNotificationChannel(gasChannel);

      // Permissions: iOS prompt + Android 13+ POST_NOTIFICATIONS.
      await FirebaseMessaging.instance.requestPermission();
      await android?.requestNotificationsPermission();

      // Register this device's token, and keep it fresh.
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await AppConfig.saveDeviceToken(token);
        await _repo?.registerToken(token, label: 'FireWatch app');
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        await AppConfig.saveDeviceToken(t);
        await _repo?.registerToken(t, label: 'FireWatch app');
      });

      // Foreground alerts: build a heads-up ourselves + refresh state.
      FirebaseMessaging.onMessage.listen(_onForeground);

      // Taps that opened/brought the app forward.
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Terminated-launch: navigate after the first frame so the router exists.
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(initial.data));
      }
    } catch (e) {
      debugPrint('[NotificationService] init failed (push disabled): $e');
    }
  }

  /// True when this push is the quiet tier. Everything else — a fire, a
  /// dangerous-gas alarm, a fuel classification for an open fire — is loud.
  static bool _isWarning(Map<String, dynamic> data) =>
      data['type'] == 'gas_warning';

  /// Where a tap on this push should land.
  static String _routeFor(Map<String, dynamic> data) =>
      _isWarning(data) ? '/warning' : '/incident';

  Future<void> _onForeground(RemoteMessage msg) async {
    // Acknowledge first and without awaiting: this is instrumentation, and it
    // must not sit in front of the refresh that puts the fire on screen.
    _ack(msg.data, 'foreground');
    await _repo?.refresh(); // dashboard reflects the event immediately
    final n = msg.notification;
    final warning = _isWarning(msg.data);

    // THE CHANNEL IS CHOSEN FROM THE PAYLOAD, NOT FIXED. Previously every
    // foreground message was re-shown on the fire channel at Importance.max
    // with category: alarm — so a gas warning that was carefully sent quietly
    // by the backend arrived on the phone sounding exactly like a fire.
    final channel = warning ? gasChannel : fireChannel;
    await _fln.show(
      id: warning ? _gasNotifId : _fireNotifId,
      title: n?.title ?? (warning ? '⚠️ Gas levels rising' : '🔥 Fire detected'),
      body: n?.body ??
          (warning
              ? 'Sensor readings are above normal. No fire seen on camera.'
              : 'Tap for your safe route.'),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: warning ? Importance.defaultImportance : Importance.max,
          priority: warning ? Priority.defaultPriority : Priority.max,
          icon: _smallIcon,
          color: warning ? const Color(0xFFF59E0B) : const Color(0xFFFF3B30),
          // `alarm` makes Android treat it as an emergency (full volume, and it
          // can pierce Do Not Disturb). A warning is a status message.
          category: warning
              ? AndroidNotificationCategory.status
              : AndroidNotificationCategory.alarm,
          playSound: !warning,
          visibility: NotificationVisibility.public,
          // A FIRE TAKES OVER A LOCKED SCREEN; A GAS WARNING NEVER DOES.
          //
          // With this set, Android presents the alert itself rather than a card
          // the person has to notice and tap, and `showWhenLocked` on the
          // activity lets the route be read without unlocking. This replaces a
          // screen the app used to draw for itself — a fake lock screen with a
          // fake notification card on it — which was only ever a picture of this
          // behaviour and would have put a mock-up in front of the RO3.4
          // participants instead of the notification being evaluated.
          //
          // On Android 14+ the permission is special-access, so an ungranted
          // handset shows an ordinary heads-up instead. That is a quieter alert,
          // not a lost one, which is the right way for this to fail.
          fullScreenIntent: !warning,
        ),
      ),
      payload: jsonEncode(msg.data),
    );
  }

  void _onLocalTap(NotificationResponse resp) {
    final payload = resp.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      _open((jsonDecode(payload) as Map).cast<String, dynamic>());
    } catch (_) {/* ignore malformed payload */}
  }

  /// Load whatever this push refers to, then navigate.
  ///
  /// A `fire_classified` push carries the SAME `incidentId` as the `fire_alert`
  /// before it — it is the same fire with better information, not a second one.
  /// Looking the id up rather than building a new incident from the payload is
  /// what keeps one fire from becoming two on the screen.
  ///
  /// FCM does not guarantee ordering, so a classification can arrive before the
  /// alert it belongs to. That is fine: the id fetch below pulls the whole
  /// incident, and the payload is only ever a fallback for when the network is
  /// down at exactly that moment.
  /// Close the delivery round trip, fire and forget.
  void _ack(Map<String, dynamic> data, String state) {
    final id = (data['incidentId'] as String?) ?? '';
    if (id.isEmpty) return;
    unawaited(_repo?.reportDelivered(id, state: state) ?? Future<void>.value());
  }

  Future<void> _open(Map<String, dynamic> data) async {
    // A tap is also an arrival, and for a message the app never saw in the
    // foreground it may be the only one that gets recorded. The backend keeps
    // whichever acknowledgement lands first, so this cannot inflate a figure
    // that a faster path already closed.
    _ack(data, 'opened');
    final id = (data['incidentId'] as String?) ?? '';
    if (id.isNotEmpty) {
      await _repo?.loadIncident(id, fallbackData: data);
    } else {
      _repo?.applyFcmData(data);
    }
    _router?.go(_routeFor(data));
  }
}
