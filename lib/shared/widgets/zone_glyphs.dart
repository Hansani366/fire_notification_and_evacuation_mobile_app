import 'package:flutter/material.dart';

import '../../data/models/models.dart';

/// Renders the schematic icon for a zone tile. The four signature factory
/// glyphs (fabric roll, scissors, iron, boiler) are hand-painted from the
/// prototype's SVGs; the rest fall back to close Material symbols.
class ZoneGlyphIcon extends StatelessWidget {
  const ZoneGlyphIcon({
    super.key,
    required this.glyph,
    this.size = 28,
    required this.color,
  });

  final ZoneGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final material = switch (glyph) {
      ZoneGlyph.dyeing => Icons.local_laundry_service_outlined,
      ZoneGlyph.warehouse => Icons.warehouse_outlined,
      ZoneGlyph.finishing => Icons.checkroom_outlined,
      ZoneGlyph.kitchen => Icons.countertops_outlined,
      ZoneGlyph.bedroom => Icons.bed_outlined,
      ZoneGlyph.dining => Icons.dining_outlined,
      ZoneGlyph.living => Icons.weekend_outlined,
      ZoneGlyph.verander => Icons.deck_outlined,
      // Deliberately generic: a zone whose glyph this build does not know is
      // drawn as a room, not as one of the factory glyphs.
      ZoneGlyph.unknown => Icons.meeting_room_outlined,
      _ => null,
    };
    if (material != null) {
      return Icon(material, size: size, color: color);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter(glyph, color)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final ZoneGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24.0);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    switch (glyph) {
      case ZoneGlyph.fabricRoll:
        final body = Path()
          ..moveTo(4, 8)
          ..cubicTo(8, 5, 16, 5, 20, 8)
          ..lineTo(20, 17)
          ..cubicTo(16, 20, 8, 20, 4, 17)
          ..close();
        canvas.drawPath(body, stroke);
        for (final x in [8.0, 12.0, 16.0]) {
          final top = x == 12.0 ? 6.0 : 6.5;
          final len = x == 12.0 ? 12.0 : 11.0;
          canvas.drawLine(Offset(x, top), Offset(x, top + len), stroke);
        }
      case ZoneGlyph.scissors:
        canvas.drawPath(
          Path()
            ..moveTo(6, 4)
            ..lineTo(6, 11)
            ..lineTo(4, 14)
            ..lineTo(8, 17),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(18, 4)
            ..lineTo(18, 11)
            ..lineTo(20, 14)
            ..lineTo(16, 17),
          stroke,
        );
        canvas.drawCircle(const Offset(9, 9), 2.4, stroke);
        canvas.drawCircle(const Offset(15, 9), 2.4, stroke);
      case ZoneGlyph.iron:
        canvas.drawPath(
          Path()
            ..moveTo(4, 20)
            ..lineTo(18, 6)
            ..lineTo(20, 8)
            ..lineTo(6, 22)
            ..lineTo(4, 22)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(15, 9)
            ..lineTo(16, 5)
            ..lineTo(18, 7)
            ..close(),
          stroke,
        );
      case ZoneGlyph.boiler:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 8, 16, 12),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 8)
            ..lineTo(8, 6)
            ..arcToPoint(const Offset(16, 6),
                radius: const Radius.circular(4), clockwise: true)
            ..lineTo(16, 8),
          stroke,
        );
        canvas.drawCircle(const Offset(12, 14), 1.6, fill);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
