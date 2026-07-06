import 'package:flutter/material.dart';

/// The FireWatch brand flame, reproduced from the prototype's SVG path
/// (`M12 2c1 3-1 4-1 6…`, 24×24 viewBox). Filled with [color]. Reused in the
/// logo, detection panel, history tiles and resolved screen.
class FlameIcon extends StatelessWidget {
  const FlameIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FlamePainter(color ?? IconTheme.of(context).color ?? Colors.black),
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    canvas.scale(s);

    final path = Path()
      ..moveTo(12, 2)
      ..cubicTo(13, 5, 11, 6, 11, 8)
      ..cubicTo(11, 9, 12, 10, 12, 10)
      // smooth cubic s2 -1 2 -3 (reflected control == current point)
      ..cubicTo(12, 10, 14, 9, 14, 7)
      ..cubicTo(16, 9, 17, 11, 17, 14)
      // a5 5 0 1 1 -10 0  → semicircle under the flame
      ..arcToPoint(const Offset(7, 14),
          radius: const Radius.circular(5), largeArc: true, clockwise: true)
      ..cubicTo(7, 12, 8, 11, 9, 10)
      ..cubicTo(8.5, 12, 10, 13, 10, 13)
      // smooth cubic s-1 -4 2 -8
      ..cubicTo(10, 13, 9, 9, 12, 5)
      ..close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => oldDelegate.color != color;
}
