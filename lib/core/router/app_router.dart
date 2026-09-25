import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/history_detail/history_detail_screen.dart';
import '../../features/incident/incident_screen.dart';
import '../../features/lock/lock_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/warning/warning_screen.dart';
import '../../features/resolved/resolved_screen.dart';
import '../../features/zone_detail/zone_detail_screen.dart';
import 'home_shell.dart';

/// App routes for the two flows:
///  - Flow B shell (bottom nav): `/dashboard` ⇄ `/history`
///  - Pushed details (no nav): `/zone/:id`, `/history-detail/:id`
///  - Flow A takeovers (slide-up over everything): `/lock`, `/incident`, `/resolved`
GoRouter buildRouter({GlobalKey<NavigatorState>? navigatorKey}) => GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/dashboard',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              HomeShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const HistoryScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/zone/:id',
          builder: (context, state) =>
              ZoneDetailScreen(zoneId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/history-detail/:id',
          builder: (context, state) =>
              HistoryDetailScreen(eventId: state.pathParameters['id']!),
        ),
        // Read after the fact, so it is a pushed page rather than a takeover.
        GoRoute(
          path: '/report/:id',
          builder: (context, state) =>
              ReportScreen(incidentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/lock',
          pageBuilder: (context, state) =>
              _takeover(state.pageKey, const LockScreen()),
        ),
        // Tier 1a. A takeover like the others, but the screen behind it is
        // deliberately calm: a gas warning is not an evacuation.
        GoRoute(
          path: '/warning',
          pageBuilder: (context, state) =>
              _takeover(state.pageKey, const WarningScreen()),
        ),
        GoRoute(
          path: '/incident',
          pageBuilder: (context, state) =>
              _takeover(state.pageKey, const IncidentScreen()),
        ),
        GoRoute(
          path: '/resolved',
          pageBuilder: (context, state) =>
              _takeover(state.pageKey, const ResolvedScreen()),
        ),
      ],
    );

/// Full-screen takeover with a subtle slide-up + fade (the "takeover" feel).
Page<void> _takeover(LocalKey key, Widget child) => CustomTransitionPage<void>(
      key: key,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 320),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
