import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'floor_plan_data.dart';

/// Renders the factory schematic in the `360 × 348` design space, scaled to
/// fill the given size. Animations (marching route, pulsing fire dot, YOU
/// ripple) are passed in as 0..1 phases so a parent controller can freeze them
/// for reduced-motion.
class FloorPlanPainter extends CustomPainter {
  FloorPlanPainter({
    required this.mode,
    this.routePhase = 0,
    this.firePulse = 0,
    this.youPulse = 0,
  });

  final FloorPlanMode mode;
  final double routePhase; // 0..1, marches the safe route
  final double firePulse; // 0..1, fire-dot brightness
  final double youPulse; // 0..1, YOU ripple expansion

  bool get _incident => mode == FloorPlanMode.incidentRoute;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / FloorPlan.designSize.width);

    _background(canvas);
    _walkways(canvas);
    _guides(canvas);
    _rooms(canvas);
    _doors(canvas);
    _exits(canvas);

    if (_incident) {
      _route(canvas);
      _muster(canvas);
      _fire(canvas);
      _you(canvas);
    }
  }

  // ---- Base shell --------------------------------------------------------
  void _background(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 360, 348),
      Paint()..color = AppColors.planBg,
    );
    final shell = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 14, 318, 312),
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
    for (final r in FloorPlan.walkways) {
      canvas.drawRect(r, paint);
    }
  }

  void _guides(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.planGuide
      ..strokeWidth = 1.4;
    _dashedLine(canvas, const Offset(163, 18), const Offset(163, 322), paint, 2, 6);
    _dashedLine(canvas, const Offset(18, 171), const Offset(328, 171), paint, 2, 6);
  }

  // ---- Rooms -------------------------------------------------------------
  void _rooms(Canvas canvas) {
    for (final room in FloorPlan.rooms) {
      final isFocus = room.id == FloorPlan.fabricStoreId;
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
        _check(canvas, const Offset(74, 70), 10);
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
    final focus = room.id == FloorPlan.fabricStoreId && sub != null;
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
    for (final d in FloorPlan.doors) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(d, const Radius.circular(2)),
        paint,
      );
    }
  }

  // ---- Exits (mode-specific) --------------------------------------------
  void _exits(Canvas canvas) {
    // East fire exit — permanent, both modes.
    _exitBar(canvas, const Rect.fromLTWH(329, 158, 9, 26), AppColors.safe);
    _baselineLabel(canvas, 'EAST FIRE EXIT',
        AppText.pjs(8.5, 800, color: AppColors.safeInk), 298, 150);

    if (_incident) {
      _blockedBar(canvas, const Rect.fromLTWH(46, 9, 38, 9));
      _baselineLabel(canvas, 'North door · by fire',
          AppText.inter(7.5, 400, color: AppColors.ink3), 65, 6);
      _blockedBar(canvas, const Rect.fromLTWH(58, 322, 34, 9));
      _baselineLabel(canvas, 'South door · farther',
          AppText.inter(7.5, 400, color: AppColors.ink3), 75, 342);
    } else {
      _exitBar(canvas, const Rect.fromLTWH(150, 9, 26, 9), AppColors.safe);
      _baselineLabel(canvas, 'NORTH EXIT',
          AppText.pjs(7, 800, color: AppColors.safeInk), 163, 6);
      _blockedBar(canvas, const Rect.fromLTWH(58, 322, 34, 9));
      _baselineLabel(canvas, 'South door',
          AppText.inter(7.5, 400, color: AppColors.ink3), 75, 342);
    }
    _blockedBar(canvas, const Rect.fromLTWH(238, 322, 48, 9));
    _baselineLabel(canvas, 'Loading bay',
        AppText.inter(7.5, 400, color: AppColors.ink3), 262, 342);
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
    final path = Path()..moveTo(FloorPlan.route.first.dx, FloorPlan.route.first.dy);
    for (final p in FloorPlan.route.skip(1)) {
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

    // Arrow head at the exit end.
    final arrow = Path()
      ..moveTo(322, 165)
      ..lineTo(333, 171)
      ..lineTo(322, 177)
      ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.safe);
  }

  void _muster(Canvas canvas) {
    canvas.drawCircle(FloorPlan.musterAt, 8, Paint()..color = AppColors.safe);
    final arrow = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(343, 167), const Offset(343, 175), arrow);
    canvas.drawPath(
      Path()
        ..moveTo(343, 167)
        ..lineTo(348, 168.5)
        ..lineTo(343, 170),
      arrow,
    );
    _baselineLabel(canvas, 'MUSTER',
        AppText.pjs(7.5, 800, color: AppColors.safeInk), 346, 192);
  }

  void _fire(Canvas canvas) {
    final opacity = 0.6 + 0.4 * firePulse;
    canvas.drawCircle(
      FloorPlan.fireAt,
      12,
      Paint()..color = AppColors.danger.withValues(alpha: opacity),
    );
    final tp = TextPainter(
      text: const TextSpan(text: '🔥', style: TextStyle(fontSize: 13)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        FloorPlan.fireAt.translate(-tp.width / 2, -tp.height / 2));
  }

  void _you(Canvas canvas) {
    final r = 9 + youPulse * 9;
    canvas.drawCircle(
      FloorPlan.youAt,
      r,
      Paint()..color = AppColors.you.withValues(alpha: 0.35 * (1 - youPulse)),
    );
    canvas.drawCircle(FloorPlan.youAt, 7, Paint()..color = AppColors.you);
    canvas.drawCircle(
      FloorPlan.youAt,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    _baselineLabel(canvas, 'YOU',
        AppText.pjs(9, 800, color: AppColors.you), 138, 39);
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
      old.mode != mode ||
      old.routePhase != routePhase ||
      old.firePulse != firePulse ||
      old.youPulse != youPulse;
}

enum _LineKind { title, sub }
