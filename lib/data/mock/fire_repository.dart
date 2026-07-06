import 'package:flutter/widgets.dart';

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

  /// True when every zone is at rest (drives the dashboard "All clear" hero).
  bool get allClear;
  int get detectorCount;

  /// Personal "I'm safe" muster check-in for the active incident.
  /// No-op in the mock; the live repository posts it to the backend.
  Future<void> ackSafe() async {}

  /// Re-fetch live state. No-op in the mock; the live repository hits the API.
  Future<void> refresh() async {}
}

/// In-memory implementation seeded from [MockData]. Used for widget tests and
/// as a static fallback; the live app uses [ApiFireRepository].
class MockFireRepository extends FireRepository {
  MockFireRepository() : _now = DateTime.now() {
    _zones = MockData.zones(_now);
    _incident = MockData.incident(_now);
  }

  final DateTime _now;
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
