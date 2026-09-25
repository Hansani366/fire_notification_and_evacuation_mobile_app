import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/models.dart';
import 'floor_plan_data.dart';

/// Renders a facility schematic in its own design space, scaled to fill the
/// given size. Animations (marching route, pulsing fire dot, YOU ripple) are
/// passed in as 0..1 phases so a parent controller can freeze them for
/// reduced-motion.
///
/// The drawing comes from [plan]; what the fire has changed comes from [route].
/// With no route it paints the building and the plan's own default frame, which
/// is what a dead backend or an old incident degrades to.
class FloorPlanPainter extends CustomPainter {
  FloorPlanPainter({
    required this.plan,
    required this.mode,
    this.route,
    this.focusRoomId,
    this.routePhase = 0,
    this.firePulse = 0,
    this.youPulse = 0,
  });

  final FloorPlan plan;
  final FloorPlanMode mode;

  /// The server's answer for this fire. Null falls back to [FloorPlan.defaultRoute].
  final EvacRoute? route;

  /// Which room to treat as the subject — the burning zone on an incident, the
  /// zone being inspected on zone-detail. Was hard-coded to the Fabric Store,
  /// which meant opening any zone highlighted a different one.
  final String? focusRoomId;

  final double routePhase; // 0..1, marches the safe route
  final double firePulse; // 0..1, fire-dot brightness
  final double youPulse; // 0..1, YOU ripple expansion

  bool get _incident => mode == FloorPlanMode.incidentRoute;

  /// A refuge answer has no path to march and no muster point to walk to.
  bool get _hasPath => _incident && !(route?.isRefuge ?? false);

  List<Offset> get _line =>
      (route != null && route!.isDrawable) ? route!.polyline : plan.defaultRoute;

  Offset get _youAt => route?.from ?? plan.youAt;
  Offset get _fireAt => route?.hazardAt ?? plan.fireAt;
  Offset get _musterAt => route?.musterAt ?? plan.musterAt;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / plan.designSize.width);

    _background(canvas);
    _walkways(canvas);
    _guides(canvas);
    _rooms(canvas);
    _doors(canvas);
    _exits(canvas);

    if (_incident) {
      if (_hasPath) {
        _route(canvas);
        _muster(canvas);
      } else if (route?.isRefuge ?? false) {
        _refuge(canvas);
      }
      _fire(canvas);
      _you(canvas);
    }
  }

  // ---- Base shell --------------------------------------------------------
  void _background(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, plan.designSize.width, plan.designSize.height),
      Paint()..color = AppColors.planBg,
    );
    final shell = RRect.fromRectAndRadius(
      plan.shell,
      const Radius.circular(10),
    );
    canvas.drawRRect(shell, Paint()..color = AppColors.planRoom);
    canvas.drawRRect(
      shell,
      Paint()
        ..color = AppColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _walkways(Canvas canvas) {
    final paint = Paint()..color = AppColors.planWalkway;
    for (final r in plan.walkways) {
      canvas.drawRect(r, paint);
    }
  }

  void _guides(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.planGuide
      ..strokeWidth = 1.4;
    for (final g in plan.guides) {
      _dashedLine(canvas, g.from, g.to, paint, 2, 6);
    }
  }

  // ---- Rooms -------------------------------------------------------------
  void _rooms(Canvas canvas) {
    for (final room in plan.rooms) {
      final isFocus = focusRoomId != null &&
          (room.zoneId == focusRoomId || room.id == focusRoomId);
      final rr = RRect.fromRectAndRadius(room.rect, const Radius.circular(6));

      if (isFocus && _incident) {
        canvas.drawRRect(rr, Paint()..color = AppColors.dangerBg);
        _hatch(canvas, room.rect);
        _dashedRRect(
          canvas,
          rr,
          Paint()
            ..color = AppColors.danger
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
          6,
          5,
        );
        _roomText(canvas, room, AppColors.dangerInk, sub: 'AVOID — fire');
      } else if (isFocus && !_incident) {
        canvas.drawRRect(rr, Paint()..color = AppColors.safeBg);
        canvas.drawRRect(
          rr,
          Paint()
            ..color = AppColors.safe
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
        _roomText(canvas, room, AppColors.safeInk, sub: 'this zone · clear');
        // Derived from the focus room, not pinned to the Fabric Store's corner.
        _check(canvas, room.checkAt, 10);
      } else {
        canvas.drawRRect(rr, Paint()..color = AppColors.planRoom);
        canvas.drawRRect(
          rr,
          Paint()
            ..color = AppColors.planRoomStroke
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        _roomText(canvas, room, AppColors.ink2);
      }
    }
  }

  void _hatch(Canvas canvas, Rect rect) {
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    final paint = Paint()
      ..color = AppColors.danger.withValues(alpha: 0.16)
      ..strokeWidth = 2;
    for (double x = rect.left - rect.height; x < rect.right; x += 10) {
      canvas.drawLine(
          Offset(x, rect.top), Offset(x + rect.height, rect.bottom), paint);
    }
    canvas.restore();
  }

  void _roomText(Canvas canvas, PlanRoom room, Color color, {String? sub}) {
    final focus = sub != null;   // only the subject room gets a sub-line
    final titleStyle = focus
        ? AppText.pjs(11, 800, color: color)
        : AppText.pjs(10.5, 700, color: color);
    final lines = <(_LineKind, String)>[
      (_LineKind.title, focus ? room.line1.toUpperCase() : room.line1),
      if (room.line2 != null) (_LineKind.title, room.line2!),
      if (sub != null) (_LineKind.sub, sub),
    ];

    final painters = [
      for (final (kind, text) in lines)
        TextPainter(
          text: TextSpan(
            text: text,
            style: kind == _LineKind.title
                ? titleStyle
                : AppText.inter(8.5, 400, color: color),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(),
    ];

    final totalH = painters.fold<double>(0, (a, p) => a + p.height) +
        (painters.length - 1) * 1.5;
    var y = room.rect.center.dy - totalH / 2;
    for (final p in painters) {
      p.paint(canvas, Offset(room.rect.center.dx - p.width / 2, y));
      y += p.height + 1.5;
    }
  }

  // ---- Doors -------------------------------------------------------------
  void _doors(Canvas canvas) {
    final paint = Paint()..color = AppColors.planDoor;
    for (final d in plan.doors) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(d, const Radius.circular(2)),
        paint,
      );
    }
  }

  // ---- Exits -------------------------------------------------------------
  //
  // Every bar and label used to be a literal, and the "North door · by fire"
  // caption was decorative — it said "by fire" whichever room was burning. Now
  // each exit is coloured by whether THIS fire cut it, so moving the fire two
  // rooms over turns a different door red.
  void _exits(Canvas canvas) {
    final blocked = route?.blockedExitIds ?? const <String>[];
    final chosen = route?.exitId;

    for (final e in plan.exits) {
      final isBlocked = _incident && blocked.contains(e.id);
      final isChosen = _incident && chosen != null && e.id == chosen;

      if (isBlocked) {
        _blockedBar(canvas, e.bar);
      } else {
        _exitBar(canvas, e.bar,
            isChosen || !_incident ? AppColors.safe : AppColors.planBlocked);
      }

      final String suffix;
      if (isBlocked) {
        suffix = ' · by fire';
      } else if (_incident && chosen != null && !isChosen) {
        suffix = ' · farther';
      } else {
        suffix = '';
      }

      final emphatic = e.primary && !isBlocked && (isChosen || !_incident);
      _baselineLabel(
        canvas,
        '${e.name}$suffix',
        emphatic
            ? AppText.pjs(8.5, 800, color: AppColors.safeInk)
            : AppText.inter(7.5, 400, color: AppColors.ink3),
        e.labelCx,
        e.labelBaselineY,
      );
    }
  }

  void _exitBar(Canvas canvas, Rect r, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()..color = color,
    );
  }

  void _blockedBar(Canvas canvas, Rect r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()..color = AppColors.planBlocked,
    );
    // small red X
    final x = Paint()
      ..color = AppColors.danger
      ..strokeWidth = 1.6;
    canvas.drawLine(r.topLeft, r.bottomRight, x);
    canvas.drawLine(r.topRight, r.bottomLeft, x);
  }

  // ---- Incident overlays -------------------------------------------------
  void _route(Canvas canvas) {
    final pts = _line;
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.safe.withValues(alpha: 0.26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    _dashedPath(
      canvas,
      path,
      Paint()
        ..color = AppColors.safe
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
      2,
      12,
      routePhase * 14, // one full period of travel
    );

    // Arrow head at the exit end, pointed along the last leg. Was a fixed
    // triangle at the east exit, which quietly assumed there was only ever one
    // route — it pointed east even when the route ran north.
    _arrowHead(canvas, pts[pts.length - 2], pts.last, AppColors.safe);
  }

  /// A filled triangle at [to], aimed along `from -> to`.
  void _arrowHead(Canvas canvas, Offset from, Offset to, Color color,
      {double len = 11, double halfWidth = 6}) {
    final d = to - from;
    final m = d.distance;
    if (m < 0.01) return;
    final ux = d.dx / m, uy = d.dy / m;
    final base = Offset(to.dx - ux * len, to.dy - uy * len);
    // Perpendicular, for the two back corners.
    final px = -uy * halfWidth, py = ux * halfWidth;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx + px, base.dy + py)
        ..lineTo(to.dx, to.dy)
        ..lineTo(base.dx - px, base.dy - py)
        ..close(),
      Paint()..color = color,
    );
  }

  /// Shelter-in-place: no path to march and no muster to walk to, so the room
  /// the occupant should stay in is haloed instead.
  ///
  /// The animation keeps running underneath (the fire still pulses, YOU still
  /// ripples) because a frozen canvas reads as a crashed app, which is the last
  /// impression to give somebody who has just been told to stay put.
  void _refuge(Canvas canvas) {
    final pts = _line;
    final at = pts.isNotEmpty ? pts.last : _youAt;
    PlanRoom? room;
    for (final r in plan.rooms) {
      if (r.rect.contains(at)) {
        room = r;
        break;
      }
    }
    final target = room?.rect ?? Rect.fromCircle(center: at, radius: 34);
    final rr = RRect.fromRectAndRadius(target, const Radius.circular(6));
    canvas.drawRRect(rr, Paint()..color = AppColors.warn.withValues(alpha: 0.18));
    canvas.drawRRect(
      rr,
      Paint()
        ..color = AppColors.warn
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    _baselineLabel(canvas, 'SHELTER HERE',
        AppText.pjs(9, 800, color: AppColors.warnInk),
        target.center.dx, target.bottom - 9);
  }

  /// The muster dot, wherever this route actually ends.
  ///
  /// Everything here used to be pinned to the east exit's coordinates, so a
  /// route north still drew its muster point beside the east door.
  void _muster(Canvas canvas) {
    final at = _musterAt;
    canvas.drawCircle(at, 8, Paint()..color = AppColors.safe);

    // A small white chevron inside the dot, aimed the way the route arrived.
    final pts = _line;
    if (pts.length >= 2) {
      final from = pts[pts.length - 2];
      _arrowHead(canvas, from, at, Colors.white, len: 5, halfWidth: 3);
    }

    // Keep the label inside the canvas whichever edge the exit sits on.
    final below = at.dy < plan.designSize.height - 26;
    _baselineLabel(canvas, 'MUSTER',
        AppText.pjs(7.5, 800, color: AppColors.safeInk),
        at.dx, below ? at.dy + 21 : at.dy - 13);
  }

  void _fire(Canvas canvas) {
    final opacity = 0.6 + 0.4 * firePulse;
    final at = _fireAt;
    canvas.drawCircle(
      at,
      12,
      Paint()..color = AppColors.danger.withValues(alpha: opacity),
    );
    final tp = TextPainter(
      text: const TextSpan(text: '🔥', style: TextStyle(fontSize: 13)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at.translate(-tp.width / 2, -tp.height / 2));
  }

  void _you(Canvas canvas) {
    final at = _youAt;
    final r = 9 + youPulse * 9;
    canvas.drawCircle(
      at,
      r,
      Paint()..color = AppColors.you.withValues(alpha: 0.35 * (1 - youPulse)),
    );
    canvas.drawCircle(at, 7, Paint()..color = AppColors.you);
    canvas.drawCircle(
      at,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Above the dot, unless that would push the label off the top edge.
    final above = at.dy > 30;
    _baselineLabel(canvas, 'YOU',
        AppText.pjs(9, 800, color: AppColors.you),
        at.dx, above ? at.dy - 16 : at.dy + 24);
  }

  // ---- Primitives --------------------------------------------------------
  void _check(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r, Paint()..color = AppColors.safe);
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 5, center.dy)
        ..lineTo(center.dx - 1.5, center.dy + 3.5)
        ..lineTo(center.dx + 6, center.dy - 4),
      p,
    );
  }

  /// Horizontally-centred label whose *baseline* sits near [baselineY]
  /// (matching the SVG `text` y coordinate).
  void _baselineLabel(
      Canvas canvas, String text, TextStyle style, double cx, double baselineY) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, baselineY - tp.height));
  }

  void _dashedLine(
      Canvas canvas, Offset a, Offset b, Paint paint, double dash, double gap) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final start = a + dir * d;
      final end = a + dir * (d + dash).clamp(0, total);
      canvas.drawLine(start, end, paint);
      d += dash + gap;
    }
  }

  void _dashedRRect(
      Canvas canvas, RRect rrect, Paint paint, double dash, double gap) {
    final path = Path()..addRRect(rrect);
    _dashedPath(canvas, path, paint, dash, gap, 0);
  }

  void _dashedPath(Canvas canvas, Path path, Paint paint, double dash,
      double gap, double phase) {
    final period = dash + gap;
    for (final metric in path.computeMetrics()) {
      double dist = -(phase % period);
      while (dist < metric.length) {
        final start = dist < 0 ? 0.0 : dist;
        final end = (dist + dash).clamp(0.0, metric.length);
        if (end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        dist += period;
      }
    }
  }

  @override
  bool shouldRepaint(FloorPlanPainter old) =>
      // The plan compares on site + revision, not on sixty-odd Rects: this runs
      // every frame, and the geometry is immutable const data keyed by revision.
      old.plan != plan ||
      old.route != route ||
      old.focusRoomId != focusRoomId ||
      old.mode != mode ||
      old.routePhase != routePhase ||
      old.firePulse != firePulse ||
      old.youPulse != youPulse;
}

enum _LineKind { title, sub }
