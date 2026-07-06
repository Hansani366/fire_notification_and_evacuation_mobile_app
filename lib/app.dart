import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/mock/fire_repository.dart';

/// Root widget: provides the (live) repository to the tree and hosts the router.
/// Both are created in `main()` and injected so notifications can share the
/// same repository + router instances.
class FireWatchApp extends StatelessWidget {
  const FireWatchApp({
    super.key,
    required this.repository,
    required this.router,
  });

  final FireRepository repository;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: repository,
      child: MaterialApp.router(
        title: 'FireWatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) {
          // Support large-font accessibility while keeping the giant display
          // numerals from overflowing on small screens.
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.6),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
