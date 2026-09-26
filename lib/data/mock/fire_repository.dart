import 'package:flutter/widgets.dart';

import '../../core/config/app_config.dart';

import '../models/models.dart';
import 'mock_data.dart';

/// Narrow read interface the UI depends on. A real HTTP-backed implementation
/// ([ApiFireRepository]) replaces [MockFireRepository] without touching any
/// screen — they all read via `RepositoryScope.of(context)`.
///
/// It is a [ChangeNotifier]: a live backend refreshes an in-memory snapshot and
/// calls [notifyListeners], and [RepositoryScope] (an [InheritedNotifier])
/// rebuilds the widgets that depend on it. Screens stay synchronous.
abstract class FireRepository extends ChangeNotifier {
  String get siteName;
  List<Zone> get zones;
  List<HealthStat> get health;
  Incident get activeIncident;
  List<HistoryEvent> get history;

  Zone? zoneById(String id);
  HistoryEvent? historyById(String id);

  /// True when every zone is at rest.
  ///
  /// NOT sufficient on its own to show "All clear": during an open gas warning
  /// the backend reports this as true *and* hands over an active incident,
  /// deliberately, because nothing is burning and no zone should turn red.
  /// Combine it with [hasActiveIncident].
  bool get allClear;

  /// True when an incident is open right now.
  ///
  /// Separate from [activeIncident] being non-null, because it never is — the
  /// repository always holds a neutral placeholder so screens can read it
  /// synchronously.
  bool get hasActiveIncident => !activeIncident.isPlaceholder;

  int get detectorCount;

  /// Which floor plan to draw escape routes on.
  ///
  /// This is the phone's OWN setting (`AppConfig.exitLayout`), not the backend's
  /// [siteKey]. The two are independent on purpose: the dashboard has its own
  /// switch for what counts as a fire, and this one chooses the layout a
  /// responder sees. Neither reads the other.
  String get exitLayout => AppConfig.exitLayout;

  /// Which facility drawing to pair a route with.
  ///
  /// The backend owns the graph and the app owns the artwork, so this is the
  /// handshake between them (`GET /api/site/plan`). Defaults to the demo site,
  /// which is also the right answer when there is no backend at all.
  String get siteKey => 'industrial';

  /// Personal "I'm safe" muster check-in for the active incident.
  /// No-op in the mock; the live repository posts it to the backend.
  Future<void> ackSafe() async {}

  /// Tell listeners the local layout choice changed.
  ///
  /// The setting lives in [AppConfig], but screens read the repository, so the
  /// repository is what has to announce it.
  void notifyLayoutChanged() => notifyListeners();

  /// Re-fetch live state. No-op in the mock; the live repository hits the API.
  Future<void> refresh() async {}

  /// The record of a past incident, once [loadReport] has fetched it.
  ///
  /// Reports are fetched into the snapshot rather than awaited in a screen, so
  /// the "screens read the repository synchronously" rule holds for this screen
  /// too — no `FutureBuilder`, no async in `build`. Null simply means "not here
  /// yet", which the screen renders as a loading state.
  IncidentReport? reportFor(String incidentId) => null;

  /// Fetch one incident report. No-op in the mock.
  Future<void> loadReport(String incidentId) async {}
}

/// In-memory implementation seeded from [MockData]. Used for widget tests and
/// as a static fallback; the live app uses [ApiFireRepository].
class MockFireRepository extends FireRepository {
  /// [incident] and [live] exist so a test can stand up a specific situation —
  /// an open gas warning, a carbon-monoxide alarm, a fire confirmed while the
  /// scene model was unreachable — without a backend. Left alone, this is the
  /// resting all-clear state with a fire fixture behind the takeover screens.
  MockFireRepository({Incident? incident, this.live = false})
      : _now = DateTime.now() {
    _zones = MockData.zones(_now);
    _incident = incident ?? MockData.incident(_now);
  }

  final DateTime _now;

  /// Whether [activeIncident] represents something happening right now.
  final bool live;
  late final List<Zone> _zones;
  late final Incident _incident;

  @override
  String get siteName => MockData.siteName;

  @override
  List<Zone> get zones => _zones;

  @override
  List<HealthStat> get health => MockData.health;

  @override
  Incident get activeIncident => _incident;

  /// The mock's incident is a **fixture** for the takeover screens, not a live
  /// alarm: the mock dashboard is deliberately the resting, all-clear state.
  /// Reporting it as active would make the offline build — and the widget tests
  /// — open on a fire that is not happening. A test can opt in with `live: true`.
  @override
  bool get hasActiveIncident => live;

  @override
  List<HistoryEvent> get history => MockData.history;

  @override
  Zone? zoneById(String id) {
    for (final z in _zones) {
      if (z.id == id) return z;
    }
    return null;
  }

  @override
  HistoryEvent? historyById(String id) {
    for (final e in MockData.history) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  bool get allClear => _zones.every((z) => z.status == ZoneStatus.clear);

  @override
  int get detectorCount => _zones.length;
}

/// Exposes the [FireRepository] to the widget tree so screens read data via
/// `RepositoryScope.of(context)` — the single seam for swapping in a live
/// backend. Being an [InheritedNotifier], dependents rebuild whenever the
/// repository calls `notifyListeners()`.
class RepositoryScope extends InheritedNotifier<FireRepository> {
  const RepositoryScope({
    super.key,
    required FireRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static FireRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'No RepositoryScope found in context');
    return scope!.notifier!;
  }
}
