/// Domain models for the FireWatch client.
///
/// Field names mirror the real detection backend so this UI can be wired to it
/// without reshaping: the VLM service returns `{detected, type, description}`
/// and YOLO returns a `confidence` (0–1). The JSON here matches the
/// `alert-service` contract (see `mid-demo-vision-system/alert-service`).
library;

// ── JSON parse helpers (tolerant of nulls / string-encoded numbers) ──────────
double _asDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
DateTime _asDate(dynamic v) =>
    v == null ? DateTime.now() : (DateTime.tryParse('$v')?.toLocal() ?? DateTime.now());

/// What the two-stage pipeline reports (`type` from the VLM, `null` → [none]).
enum DetectionType {
  fire,
  smoke,
  both,
  none;

  String get label => switch (this) {
        DetectionType.fire => 'Fire',
        DetectionType.smoke => 'Smoke',
        DetectionType.both => 'Both',
        DetectionType.none => 'None',
      };

  String get wire => name; // fire|smoke|both|none

  static DetectionType fromWire(String? s) => switch (s) {
        'fire' => DetectionType.fire,
        'smoke' => DetectionType.smoke,
        'both' => DetectionType.both,
        _ => DetectionType.none,
      };
}

/// A zone's resting monitoring state.
enum ZoneStatus {
  clear,
  smoke,
  fire;

  String get label => switch (this) {
        ZoneStatus.clear => 'Clear',
        ZoneStatus.smoke => 'Smoke',
        ZoneStatus.fire => 'Fire',
      };

  bool get isAlert => this == ZoneStatus.fire;
  bool get isWarn => this == ZoneStatus.smoke;

  String get wire => name; // clear|smoke|fire

  static ZoneStatus fromWire(String? s) => switch (s) {
        'fire' => ZoneStatus.fire,
        'smoke' => ZoneStatus.smoke,
        _ => ZoneStatus.clear,
      };
}

/// How a past incident ended (the history badge).
enum Resolution {
  userConfirmed,
  autoCleared,
  falseAlarm;

  String get label => switch (this) {
        Resolution.userConfirmed => 'User-confirmed',
        Resolution.autoCleared => 'Auto-cleared',
        Resolution.falseAlarm => 'False alarm',
      };

  String get wire => switch (this) {
        Resolution.userConfirmed => 'user_confirmed',
        Resolution.autoCleared => 'auto_cleared',
        Resolution.falseAlarm => 'false_alarm',
      };

  static Resolution fromWire(String? s) => switch (s) {
        'user_confirmed' => Resolution.userConfirmed,
        'false_alarm' => Resolution.falseAlarm,
        _ => Resolution.autoCleared,
      };
}

/// State of a single scene-AI note on the history timeline.
enum SceneState {
  fire,
  smoke,
  cleared;

  String get wire => name; // fire|smoke|cleared

  static SceneState fromWire(String? s) => switch (s) {
        'fire' => SceneState.fire,
        'smoke' => SceneState.smoke,
        _ => SceneState.cleared,
      };
}

/// Which schematic glyph represents a zone on the dashboard tile.
enum ZoneGlyph {
  fabricRoll,
  scissors,
  iron,
  boiler,
  dyeing,
  warehouse,
  finishing;

  String get wire => name;

  static ZoneGlyph fromWire(String? s) {
    if (s == null) return ZoneGlyph.fabricRoll;
    try {
      return ZoneGlyph.values.byName(s);
    } catch (_) {
      return ZoneGlyph.fabricRoll;
    }
  }
}

/// A monitored area watched by one detector.
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.floor,
    required this.detectorId,
    required this.status,
    required this.lastScanAt,
    required this.glyph,
  });

  final String id;
  final String name;
  final String floor;
  final String detectorId; // e.g. "Detector 01"
  final ZoneStatus status;
  final DateTime lastScanAt;
  final ZoneGlyph glyph;

  factory Zone.fromJson(Map<String, dynamic> j) => Zone(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        floor: j['floor'] as String? ?? '',
        detectorId: j['detectorId'] as String? ?? '',
        status: ZoneStatus.fromWire(j['status'] as String?),
        lastScanAt: _asDate(j['lastScanAt']),
        glyph: ZoneGlyph.fromWire(j['glyph'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'floor': floor,
        'detectorId': detectorId,
        'status': status.wire,
        'lastScanAt': lastScanAt.toUtc().toIso8601String(),
        'glyph': glyph.wire,
      };
}

/// A live detection record — the shape the backend delivers.
class DetectionEvent {
  const DetectionEvent({
    required this.zoneId,
    required this.type,
    required this.detected,
    required this.confidence,
    required this.description,
    required this.detectedAt,
  });

  final String zoneId;
  final DetectionType type;
  final bool detected; // VLM confirmation (stage 2)
  final double confidence; // YOLO score, 0..1 (stage 1)
  final String description; // VLM scene text
  final DateTime detectedAt;

  int get confidencePct => (confidence * 100).round();

  factory DetectionEvent.fromJson(Map<String, dynamic> j) => DetectionEvent(
        zoneId: j['zoneId'] as String? ?? '',
        type: DetectionType.fromWire(j['type'] as String?),
        detected: j['detected'] as bool? ?? false,
        confidence: _asDouble(j['confidence']),
        description: j['description'] as String? ?? '',
        detectedAt: _asDate(j['detectedAt']),
      );

  Map<String, dynamic> toJson() => {
        'zoneId': zoneId,
        'type': type.wire,
        'detected': detected,
        'confidence': confidence,
        'description': description,
        'detectedAt': detectedAt.toUtc().toIso8601String(),
      };
}

/// Head-count at the muster point during an incident.
class MusterRoll {
  const MusterRoll({required this.present, required this.total});

  final int present;
  final int total;

  int get missing => total - present;

  factory MusterRoll.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const MusterRoll(present: 42, total: 45);
    return MusterRoll(present: _asInt(j['present']), total: _asInt(j['total']));
  }

  Map<String, dynamic> toJson() => {'present': present, 'total': total};
}

/// An active, confirmed emergency (drives the incident + resolved screens).
class Incident {
  const Incident({
    this.id = '',
    required this.zone,
    required this.event,
    required this.muster,
  });

  final String id;
  final Zone zone;
  final DetectionEvent event;
  final MusterRoll muster;

  factory Incident.fromJson(Map<String, dynamic> j) => Incident(
        id: j['id'] as String? ?? '',
        zone: Zone.fromJson(j['zone'] as Map<String, dynamic>),
        event: DetectionEvent.fromJson(j['event'] as Map<String, dynamic>),
        muster: MusterRoll.fromJson(j['muster'] as Map<String, dynamic>?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'zone': zone.toJson(),
        'event': event.toJson(),
        'muster': muster.toJson(),
      };
}

/// One scene-AI observation logged during a past event.
class SceneNote {
  const SceneNote({
    required this.timeLabel,
    required this.text,
    required this.state,
  });

  final String timeLabel; // e.g. "19:30:04 · detected"
  final String text;
  final SceneState state;

  factory SceneNote.fromJson(Map<String, dynamic> j) => SceneNote(
        timeLabel: j['timeLabel'] as String? ?? '',
        text: j['text'] as String? ?? '',
        state: SceneState.fromWire(j['state'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'timeLabel': timeLabel,
        'text': text,
        'state': state.wire,
      };
}

/// A resolved event in the history log.
class HistoryEvent {
  const HistoryEvent({
    required this.id,
    required this.zoneName,
    required this.type,
    required this.whenLabel,
    required this.durationMin,
    required this.floor,
    required this.resolution,
    required this.peakConfidencePct,
    this.cause,
    this.sceneNotes = const [],
  });

  final String id;
  final String zoneName;
  final DetectionType type;
  final String whenLabel; // e.g. "Yesterday 19:30"
  final int durationMin;
  final String floor;
  final String? cause; // e.g. "dust", "steam"
  final Resolution resolution;
  final int peakConfidencePct;
  final List<SceneNote> sceneNotes;

  bool get hasDetail => sceneNotes.isNotEmpty;

  factory HistoryEvent.fromJson(Map<String, dynamic> j) => HistoryEvent(
        id: j['id'] as String? ?? '',
        zoneName: j['zoneName'] as String? ?? '',
        type: DetectionType.fromWire(j['type'] as String?),
        whenLabel: j['whenLabel'] as String? ?? '',
        durationMin: _asInt(j['durationMin']),
        floor: j['floor'] as String? ?? '',
        resolution: Resolution.fromWire(j['resolution'] as String?),
        peakConfidencePct: _asInt(j['peakConfidencePct']),
        cause: j['cause'] as String?,
        sceneNotes: (j['sceneNotes'] as List<dynamic>? ?? const [])
            .map((e) => SceneNote.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'zoneName': zoneName,
        'type': type.wire,
        'whenLabel': whenLabel,
        'durationMin': durationMin,
        'floor': floor,
        'resolution': resolution.wire,
        'peakConfidencePct': peakConfidencePct,
        'cause': cause,
        'sceneNotes': sceneNotes.map((n) => n.toJson()).toList(),
      };
}

/// A dashboard system-health tile.
class HealthStat {
  const HealthStat({
    required this.label,
    required this.value,
    this.ok = true,
  });

  final String label;
  final String value;
  final bool ok;

  factory HealthStat.fromJson(Map<String, dynamic> j) => HealthStat(
        label: j['label'] as String? ?? '',
        value: j['value'] as String? ?? '',
        ok: j['ok'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'label': label, 'value': value, 'ok': ok};
}
