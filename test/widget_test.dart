import 'package:firewatch/app.dart';
import 'package:firewatch/core/router/app_router.dart';
import 'package:firewatch/data/mock/fire_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the app backed by the deterministic in-memory mock repository, so the
/// widget tests stay offline and independent of the live backend.
FireWatchApp _mockApp() =>
    FireWatchApp(repository: MockFireRepository(), router: buildRouter());

void main() {
  testWidgets('dashboard renders the all-clear site status', (tester) async {
    await tester.pumpWidget(_mockApp());
    await tester.pumpAndSettle();

    expect(find.text('Site status'), findsOneWidget);
    expect(find.text('All clear'), findsOneWidget);
    expect(find.text('Kitchen'), findsWidgets);
  });

  testWidgets('tapping a zone opens its detail, back returns home',
      (tester) async {
    await tester.pumpWidget(_mockApp());
    await tester.pumpAndSettle();

    // First zone is on-screen, so the dashboard scroll position is untouched.
    await tester.tap(find.text('Kitchen'));
    await tester.pumpAndSettle();
    expect(find.text('No fire or smoke'), findsOneWidget);

    await tester.tap(find.text('Site status')); // back label button
    await tester.pumpAndSettle();
    expect(find.text('All clear'), findsOneWidget);
  });

  testWidgets('history tab lists past events', (tester) async {
    await tester.pumpWidget(_mockApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.textContaining('past 30 days'), findsOneWidget);
    expect(find.text('User-confirmed'), findsWidgets);
  });
}
