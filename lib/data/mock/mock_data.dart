import '../models/models.dart';

/// Sample content for the first paint and for widget tests.
///
/// MIRRORED CONTRACT with `alert-service/sites/*.json`: the ids, names, floors,
/// detector ids and glyphs here are what the phone renders before the backend
/// answers. They must match the site files, or the dashboard shows rooms that
/// the building does not have.
///
/// Both facilities are held, because the app can draw either one. `home` is the
/// default on the phone and in `alert-service`, so it is what the dashboard
/// paints while the first fetch is in flight. Pass `siteKey: 'industrial'` for
/// the demonstration hall, transcribed from `App_design_v5.html`
/// (Meridian Garments).
///
/// Zones and the active incident depend on "now" so their relative timestamps
/// read naturally; history is static.
class MockData {
  MockData._();

  /// The default facility's display name. See [siteNameFor] for the other one.
  static const siteName = 'Home';
  static const industrialSiteName = 'Industrial Unit';

  static String siteNameFor(String siteKey) =>
      siteKey == 'industrial' ? industrialSiteName : siteName;

  /// Zones of the given facility, all clear (resting "All clear" state).
  ///
  /// Defaults to `home`, so a phone with no backend shows the trial facility
  /// rather than a factory it is not standing in.
  static List<Zone> zones(DateTime now, {String siteKey = 'home'}) =>
      siteKey == 'industrial' ? industrialZones(now) : homeZones(now);

  /// The 8 rooms of the trial house, mirroring `sites/home.json`.
  static List<Zone> homeZones(DateTime now) => [
        Zone(
          id: 'kitchen',
          name: 'Kitchen',
          floor: 'Ground floor',
          detectorId: 'Detector 01',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 2)),
          glyph: ZoneGlyph.kitchen,
        ),
        Zone(
          id: 'dining',
          name: 'Dining Area',
          floor: 'Ground floor',
          detectorId: 'Detector 02',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 3)),
          glyph: ZoneGlyph.dining,
        ),
        Zone(
          id: 'living',
          name: 'Living Area',
          floor: 'Ground floor',
          detectorId: 'Detector 03',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 3)),
          glyph: ZoneGlyph.living,
        ),
        Zone(
          id: 'verander',
          name: 'Verander',
          floor: 'Ground floor',
          detectorId: 'Detector 04',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 4)),
          glyph: ZoneGlyph.verander,
        ),
        Zone(
          id: 'bedroom-west',
          name: 'Bedroom (West)',
          floor: 'Ground floor',
          detectorId: 'Detector 05',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 4)),
          glyph: ZoneGlyph.bedroom,
        ),
        Zone(
          id: 'bedroom-southwest',
          name: 'Bedroom (SW)',
          floor: 'Ground floor',
          detectorId: 'Detector 06',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 5)),
          glyph: ZoneGlyph.bedroom,
        ),
        Zone(
          id: 'bedroom-northeast',
          name: 'Bedroom (NE)',
          floor: 'Ground floor',
          detectorId: 'Detector 07',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 5)),
          glyph: ZoneGlyph.bedroom,
        ),
        Zone(
          id: 'bedroom-southeast',
          name: 'Bedroom (SE)',
          floor: 'Ground floor',
          detectorId: 'Detector 08',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 6)),
          glyph: ZoneGlyph.bedroom,
        ),
      ];

  /// The 7 zones of the demonstration hall, mirroring `sites/industrial.json`.
  static List<Zone> industrialZones(DateTime now) => [
        Zone(
          id: 'fabric-store',
          name: 'Fabric Store',
          floor: 'Main floor',
          detectorId: 'Detector 01',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 2)),
          glyph: ZoneGlyph.fabricRoll,
        ),
        Zone(
          id: 'cutting-floor',
          name: 'Cutting Floor',
          floor: 'Main floor',
          detectorId: 'Detector 02',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 3)),
          glyph: ZoneGlyph.scissors,
        ),
        Zone(
          id: 'dyeing',
          name: 'Dyeing Section',
          floor: 'Main floor',
          detectorId: 'Detector 03',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 4)),
          glyph: ZoneGlyph.dyeing,
        ),
        Zone(
          id: 'sewing-a',
          name: 'Sewing Line A',
          floor: 'Main floor',
          detectorId: 'Detector 04',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 4)),
          glyph: ZoneGlyph.iron,
        ),
        Zone(
          id: 'warehouse',
          name: 'Warehouse',
          floor: 'Main floor',
          detectorId: 'Detector 05',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 5)),
          glyph: ZoneGlyph.warehouse,
        ),
        Zone(
          id: 'boiler',
          name: 'Boiler Room',
          floor: 'Main floor',
          detectorId: 'Detector 06',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 5)),
          glyph: ZoneGlyph.boiler,
        ),
        Zone(
          id: 'finishing',
          name: 'Finishing',
          floor: 'Main floor',
          detectorId: 'Detector 07',
          status: ZoneStatus.clear,
          lastScanAt: now.subtract(const Duration(seconds: 6)),
          glyph: ZoneGlyph.finishing,
        ),
      ];

  static const List<HealthStat> health = [
    HealthStat(label: 'Detectors', value: '8 online'),
    HealthStat(label: 'AI pipeline', value: 'Active'),
    HealthStat(label: 'Alerts', value: 'Armed'),
  ];

  /// The demo alarm (Flow A): Fabric Store fire, confirmed by both stages.
  static Incident incident(DateTime now) => Incident(
        zone: Zone(
          id: 'fabric-store',
          name: 'Fabric Store',
          floor: 'Main floor',
          detectorId: 'Detector 01',
          status: ZoneStatus.fire,
          lastScanAt: now,
          glyph: ZoneGlyph.fabricRoll,
        ),
        event: DetectionEvent(
          zoneId: 'fabric-store',
          type: DetectionType.fire,
          detected: true,
          confidence: 0.92,
          description:
              'Open flames are visible among the fabric rolls with smoke '
              'rising toward the ceiling.',
          detectedAt: now.subtract(const Duration(seconds: 32)),
        ),
        muster: const MusterRoll(present: 42, total: 45),
      );

  static const List<HistoryEvent> history = [
    HistoryEvent(
      id: 'h1',
      zoneName: 'Fabric Store',
      type: DetectionType.fire,
      whenLabel: 'Yesterday 19:30',
      durationMin: 6,
      floor: 'Main floor',
      resolution: Resolution.userConfirmed,
      peakConfidencePct: 92,
      sceneNotes: [
        SceneNote(
          timeLabel: '19:30:04 · detected',
          text: 'Open flames are visible among the fabric rolls with smoke '
              'rising toward the ceiling.',
          state: SceneState.fire,
        ),
        SceneNote(
          timeLabel: '19:31:40',
          text: 'Flames persist at the roll racks; thick smoke now filling '
              'the upper half of the store.',
          state: SceneState.fire,
        ),
        SceneNote(
          timeLabel: '19:36:12 · cleared',
          text: 'No flame detected; residual haze dissipating. Floor confirmed '
              'clear, user marked safe.',
          state: SceneState.cleared,
        ),
      ],
    ),
    HistoryEvent(
      id: 'h2',
      zoneName: 'Boiler Room',
      type: DetectionType.smoke,
      whenLabel: 'Mon 14:02',
      durationMin: 3,
      floor: 'Main floor',
      resolution: Resolution.autoCleared,
      peakConfidencePct: 58,
    ),
    HistoryEvent(
      id: 'h3',
      zoneName: 'Cutting Floor',
      type: DetectionType.smoke,
      whenLabel: 'Sun 08:12',
      durationMin: 1,
      floor: 'Main floor',
      cause: 'dust',
      resolution: Resolution.falseAlarm,
      peakConfidencePct: 41,
    ),
    HistoryEvent(
      id: 'h4',
      zoneName: 'Dyeing',
      type: DetectionType.both,
      whenLabel: 'Jun 24',
      durationMin: 11,
      floor: 'Main floor',
      resolution: Resolution.userConfirmed,
      peakConfidencePct: 88,
    ),
    HistoryEvent(
      id: 'h5',
      zoneName: 'Finishing',
      type: DetectionType.smoke,
      whenLabel: 'Jun 19',
      durationMin: 2,
      floor: 'Main floor',
      cause: 'steam',
      resolution: Resolution.falseAlarm,
      peakConfidencePct: 37,
    ),
  ];
}
