import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'data/api/api_fire_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = ApiFireRepository();
  final router = buildRouter();

  // Firebase is required for push, but the app still runs against the REST
  // backend if it isn't configured yet — so init defensively.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[main] Firebase init skipped (push disabled): $e');
  }

  // Fire-and-forget so the UI paints immediately from the seeded snapshot.
  unawaited(repository.init());
  unawaited(NotificationService.instance.init(repo: repository, router: router));

  runApp(FireWatchApp(repository: repository, router: router));
}
