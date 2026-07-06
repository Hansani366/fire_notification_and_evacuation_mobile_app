import 'package:flutter/painting.dart';

/// Which schematic to draw.
enum FloorPlanMode {
  /// Incident: fire zone hatched + avoided, YOU marker, marching safe route,
  /// muster point, blocked north door.
  incidentRoute,

  /// Zone detail: one room highlighted safe (with a check), north exit open,
  /// no route / fire / muster.
  zoneSafe,
}

/// Static geometry of the Meridian Garments · Unit 7 main floor, in the
/// prototype's `360 × 348` design space. The painter scales this to any width.
class FloorPlan {
  FloorPlan._();

  static const Size designSize = Size(360, 348);

  /// The id used for the fire (incident) / highlighted (zone) room.
  static const fabricStoreId = 'fabric-store';

  static const List<PlanRoom> rooms = [
    PlanRoom(fabricStoreId, Rect.fromLTWH(18, 18, 130, 66), 'Fabric Store'),
    PlanRoom('cutting', Rect.fromLTWH(18, 88, 130, 66), 'Cutting Floor'),
    PlanRoom('dyeing', Rect.fromLTWH(178, 18, 150, 66), 'Dyeing Section'),
    PlanRoom('warehouse', Rect.fromLTWH(178, 88, 150, 66), 'Warehouse'),
    PlanRoom('finishing', Rect.fromLTWH(18, 188, 130, 58), 'Finishing'),
    PlanRoom('boiler', Rect.fromLTWH(18, 252, 130, 68), 'Boiler Room'),
    PlanRoom('sewing', Rect.fromLTWH(178, 188, 150, 58), 'Sewing Floor'),
    PlanRoom('packing', Rect.fromLTWH(178, 252, 150, 68), 'Packing &', 'Dispatch'),
  ];

  /// Light corridor strips (vertical + horizontal).
  static const List<Rect> walkways = [
    Rect.fromLTWH(150, 16, 26, 308),
    Rect.fromLTWH(16, 158, 314, 26),
  ];

  /// Black door studs along the corridors.
  static const List<Rect> doors = [
    Rect.fromLTWH(145, 48, 6, 14),
    Rect.fromLTWH(145, 112, 6, 14),
    Rect.fromLTWH(175, 48, 6, 14),
    Rect.fromLTWH(175, 112, 6, 14),
    Rect.fromLTWH(145, 210, 6, 14),
    Rect.fromLTWH(145, 280, 6, 14),
    Rect.fromLTWH(175, 210, 6, 14),
    Rect.fromLTWH(175, 280, 6, 14),
    Rect.fromLTWH(118, 152, 14, 6),
    Rect.fromLTWH(205, 152, 14, 6),
  ];

  /// The safe evacuation route (incident): YOU → corridor → East fire exit.
  static const List<Offset> route = [
    Offset(138, 55),
    Offset(163, 55),
    Offset(163, 171),
    Offset(336, 171),
  ];

  static const Offset youAt = Offset(138, 55);
  static const Offset fireAt = Offset(42, 66);
  static const Offset musterAt = Offset(346, 171);
}

class PlanRoom {
  const PlanRoom(this.id, this.rect, this.line1, [this.line2]);

  final String id;
  final Rect rect;
  final String line1;
  final String? line2;
}
