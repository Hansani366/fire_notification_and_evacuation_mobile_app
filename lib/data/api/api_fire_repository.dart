import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../mock/fire_repository.dart';
import '../mock/mock_data.dart';
import 'api_client.dart';

/// Live [FireRepository] backed by the `alert-service` REST API.
///
/// Keeps an in-memory snapshot the screens read synchronously. The snapshot is
/// refreshed by an initial fetch, a 15-second poll, and on demand when a push
/// arrives — each update calls [notifyListeners] so `RepositoryScope`
/// (an `InheritedNotifier`) rebuilds the UI.
class ApiFireRepository extends FireRepository {
  ApiFireRepository({ApiClient? client}) : _api = client ?? ApiClient() {
    // Seed with the 7 known zones (all clear) so the dashboard renders instantly
    // and `activeIncident` is never null before the first fetch.
    _zones = MockData.zones(DateTime.now());
    _active = _placeholder(_zones.first);
  }

  final ApiClient _api;

  static const Duration _pollInterval = Duration(seconds: 15);

  String _siteName = MockData.siteName;
  late List<Zone> _zones;
  List<HealthStat> _health = MockData.health;
  List<HistoryEvent> _history = const [];
  final Map<String, IncidentReport> _reports = {};
  late Incident _active;
  bool _allClear = true;
  String _siteKey = 'home';

  /// This device's FCM token, kept so a check-out can be attributed to one
  /// handset and therefore counted exactly once.
  String? _token;
  Timer? _poll;

  // ── FireRepository surface (synchronous reads) ─────────────────────────────

  @override
  String get siteName => _siteName;
  @override
  List<Zone> get zones => _zones;
  @override
  List<HealthStat> get health => _health;
  @override
  Incident get activeIncident => _active;
  @override
  List<HistoryEvent> get history => _history;
  @override
  bool get allClear => _allClear;
  @override
  int get detectorCount => _zones.length;

  @override
  String get siteKey => _siteKey;

  @override
  Zone? zoneById(String id) {
    for (final z in _zones) {
      if (z.id == id) return z;
    }
    return null;
  }

  @override
  HistoryEvent? historyById(String id) {
    for (final e in _history) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Initial fetch + start the background poll. Safe to call once at startup;
  /// never throws (a dead backend just leaves the seeded snapshot in place).
  Future<void> init() async {
    await _loadSite();
    await refresh();
    _poll ??= Timer.periodic(_pollInterval, (_) => refresh());
  }

  /// Ask which facility the backend is routing for. Fetched once, not polled:
  /// a building does not change while the app is open. Never throws — with no
  /// backend `home`, the default on both sides, is exactly the right fallback.
  Future<void> _loadSite() async {
    try {
      final plan = await _api.getSitePlan();
      final key = plan['siteKey'] as String?;
      if (key != null && key.isNotEmpty) {
        _siteKey = key;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ApiFireRepository] site plan fetch failed: $e');
    }
  }

  /// Re-fetch state + history. Called by the poll and by the push handler.
  @override
  Future<void> refresh() async {
    try {
      _applyState(await _api.getState());
    } catch (e) {
      debugPrint('[ApiFireRepository] state refresh failed: $e');
    }
    try {
      _history = (await _api.getHistory())
          .map((e) => HistoryEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ApiFireRepository] history refresh failed: $e');
    }
    notifyListeners();
  }

  @override
  IncidentReport? reportFor(String incidentId) => _reports[incidentId];

  /// Fetch one incident report into the snapshot.
  ///
  /// Cached: a report describes a closed incident and does not change, so
  /// re-entering the screen should not re-fetch. Never throws — a failure leaves
  /// the screen on its loading state rather than taking it down.
  @override
  Future<void> loadReport(String incidentId) async {
    if (incidentId.isEmpty || _reports.containsKey(incidentId)) return;
    try {
      _reports[incidentId] =
          IncidentReport.fromJson(await _api.getReport(incidentId));
      notifyListeners();
    } catch (e) {
      debugPrint('[ApiFireRepository] loadReport failed: $e');
    }
  }

  /// Load a specific incident (on notification tap) so `/incident` shows it.
  /// If the network fails, falls back to building the incident from the FCM
  /// data payload so the screen still renders offline.
  Future<void> loadIncident(String id, {Map<String, dynamic>? fallbackData}) async {
    try {
      _active = Incident.fromJson(await _api.getIncident(id));
      _allClear = false;
    } catch (e) {
      debugPrint('[ApiFireRepository] loadIncident failed: $e');
      if (fallbackData != null) {
        _active = _fromFcmData(fallbackData);
        _allClear = false;
      }
    }
    notifyListeners();
  }

  /// Build a best-effort incident straight from an FCM `data` payload.
  void applyFcmData(Map<String, dynamic> data) {
    _active = _fromFcmData(data);
    _allClear = false;
    notifyListeners();
  }

  Future<void> registerToken(String token, {String? label}) async {
    _token = token;
    try {
      await _api.registerDevice(token, label: label);
    } catch (e) {
      // Keep the token even if registration failed — the backend may already
      // know it from a previous run, and a check-out still needs an identity.
      debugPrint('[ApiFireRepository] registerToken failed: $e');
    }
  }

  /// Close the delivery round trip for a push that just arrived.
  ///
  /// Instrumentation, so it is fire-and-forget and never blocks showing the
  /// alert. Silence here costs a data point; a delay here costs seconds in front
  /// of somebody who needs to start walking.
  Future<void> reportDelivered(String incidentId, {String? state}) async {
    final token = _token;
    if (token == null || incidentId.isEmpty) return;
    try {
      await _api.reportDelivered(incidentId, token, state: state);
    } catch (e) {
      debugPrint('[ApiFireRepository] reportDelivered failed: $e');
    }
  }

  /// Personal "I'm out" check-out for the active incident.
  ///
  /// Posted with this device's token so the backend counts it once however many
  /// times it arrives — a double tap under stress, a reopened notification, a
  /// retry after a timeout. Falls back to the old ack endpoint only if no token
  /// was ever obtained (push disabled, or Firebase absent), where the backend
  /// keeps its estimated muster instead.
  @override
  Future<void> ackSafe() async {
    final id = _active.id;
    if (id.isEmpty) return;
    try {
      final token = _token;
      if (token != null) {
        await _api.checkout(id, token);
      } else {
        await _api.ackIncident(id);
      }
    } catch (e) {
      debugPrint('[ApiFireRepository] ackSafe failed: $e');
    }
    await refresh();
  }

  Future<void> testAlert({String? zoneId}) => _api.testAlert(zoneId: zoneId);

  @override
  void dispose() {
    _poll?.cancel();
    _api.close();
    super.dispose();
  }

  // ── Internals ────────────────────────────────────────────────────────────

  void _applyState(Map<String, dynamic> s) {
    _siteName = s['siteName'] as String? ?? _siteName;
    _allClear = s['allClear'] as bool? ?? _allClear;

    final zonesJson = s['zones'] as List<dynamic>?;
    if (zonesJson != null && zonesJson.isNotEmpty) {
      _zones = zonesJson.map((z) => Zone.fromJson(z as Map<String, dynamic>)).toList();
    }
    final healthJson = s['health'] as List<dynamic>?;
    if (healthJson != null && healthJson.isNotEmpty) {
      _health = healthJson.map((h) => HealthStat.fromJson(h as Map<String, dynamic>)).toList();
    }

    final act = s['activeIncident'];
    _active = (act is Map<String, dynamic>)
        ? Incident.fromJson(act)
        : _placeholder(_zones.isNotEmpty ? _zones.first : MockData.zones(DateTime.now()).first);
  }

  /// Build a best-effort incident from an FCM `data` payload, for when the
  /// network is down at the moment the push lands.
  ///
  /// Every value on an FCM payload is a **string**, including the numbers, and
  /// an unknown one is sent as `""` rather than `"None"` — so `tryParse` failing
  /// is the normal "we don't know" case, not an error.
  Incident _fromFcmData(Map<String, dynamic> d) {
    final zoneId = (d['zoneId'] as String?) ?? _zones.first.id;
    final zone = zoneById(zoneId) ?? _zones.first;
    final severity = IncidentSeverity.fromWire(d['severity'] as String?);
    final event = DetectionEvent(
      zoneId: zoneId,
      type: DetectionType.fromWire(d['detectionType'] as String?),
      detected: true,
      // Do NOT default a missing confidence to 0.9 for a sensor-only alarm:
      // tier 1b legitimately carries 0.0, and inventing a figure for it is what
      // the screen is now careful not to display in the first place.
      confidence: double.tryParse('${d['confidence']}') ??
          (severity == IncidentSeverity.fire ? 0.9 : 0.0),
      description: (d['description'] as String?) ?? '',
      detectedAt: DateTime.tryParse('${d['detectedAt']}')?.toLocal() ?? DateTime.now(),
    );
    final occupancy = int.tryParse('${d['occupancy']}');
    return Incident(
      id: (d['incidentId'] as String?) ?? '',
      zone: zone,
      event: event,
      muster: const MusterRoll(present: 42, total: 45),
      severity: severity,
      verification: Verification.fromWire(d['verification'] as String?),
      occupancy: Occupancy(current: occupancy, peak: occupancy),
      classification: _classificationFromFcm(d),
      sensorSummary: (d['sensors'] as String?) ?? '',
      route: EvacRoute.fromFcm(d),
    );
  }

  /// A `fire_classified` push carries the fuel verdict inline, so the guidance
  /// can be shown without a round trip. The sentence is used exactly as sent —
  /// it comes from the backend's one guidance table.
  FireClassification? _classificationFromFcm(Map<String, dynamic> d) {
    final fuel = (d['fuelType'] as String?) ?? '';
    final guidance = (d['fuelGuidance'] as String?) ?? '';
    if (fuel.isEmpty && guidance.isEmpty) return null;
    return FireClassification(
      fuelType: fuel.isEmpty ? null : fuel,
      label: (d['fuelLabel'] as String?) ?? 'Fire',
      guidance: guidance,
      source: fuel.isEmpty ? 'unavailable' : 'model',
      confidence: double.tryParse('${d['fuelConfidence']}'),
      trainedOn: 'simulation',
    );
  }

  /// A neutral non-fire incident so `activeIncident` is always non-null.
  Incident _placeholder(Zone z) => Incident(
        zone: z,
        event: DetectionEvent(
          zoneId: z.id,
          type: DetectionType.none,
          detected: false,
          confidence: 0,
          description: '',
          detectedAt: DateTime.now(),
        ),
        muster: const MusterRoll(present: 42, total: 45),
      );
}
